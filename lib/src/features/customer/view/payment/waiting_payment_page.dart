import 'dart:async';

import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/view/payment/payment_success_splash_screen.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/order_tab_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/payment/counter_payment_card.dart';
import 'package:mpjnew/src/features/customer/widget/payment/qris_payment_cart.dart';
import 'package:mpjnew/src/features/customer/widget/payment/va_payment_card.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaitingPaymentPage extends StatefulWidget {
  final PesananModel paymentData;

  const WaitingPaymentPage({
    super.key,
    required this.paymentData,
  });

  @override
  State<WaitingPaymentPage> createState() => _WaitingPaymentPageState();
}

class _WaitingPaymentPageState extends State<WaitingPaymentPage> {
  PesananService pesananService = PesananService();
  HistoryOrderService historyOrderService = HistoryOrderService();
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  Duration remainingTime = const Duration(minutes: 5, seconds: 0);
  Timer? _timer;
  bool _isExpiredHandled = false;
  Timer? _checkPaymentTimer;

  // ✅ Current payment data (can be updated)
  late PesananModel _currentPaymentData;

  PaketModel? paket;

  bool isPackageExpanded = false;

  String? statusBayar;
  DateTime? _paymentStartTime;
  static const int _paymentTimeoutMinutes = 5;

  // ✅ Refresh state
  bool _isRefreshing = false;
  bool _isNavigating = false; // ✅ Prevent multiple navigation

  @override
  void initState() {
    super.initState();
    _currentPaymentData = widget.paymentData;
    _initializePaymentTimer();
    _startPaymentCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _checkPaymentTimer?.cancel();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _initializePaymentTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = 'payment_start_${widget.paymentData.noBukti}';
    final statusKey = 'payment_status_${widget.paymentData.noBukti}';

    // Cek apakah pembayaran ini sudah expired atau dibatalkan sebelumnya
    final paymentStatus = prefs.getString(statusKey);

    // Ambil waktu mulai dari storage
    final storedTime = prefs.getString(storageKey);

    if (storedTime != null && paymentStatus != 'expired') {
      // Ada timer sebelumnya dan belum expired
      _paymentStartTime = DateTime.parse(storedTime);
      _calculateRemainingTime();

      // Jika ternyata sudah expired, tandai sebagai expired
      if (remainingTime.inSeconds <= 0) {
        await prefs.setString(statusKey, 'expired');
      }
    } else {
      // Buat timer baru jika:
      // 1. Belum ada timer sebelumnya
      // 2. Timer sebelumnya sudah expired dan user ingin coba bayar lagi
      _paymentStartTime = DateTime.now();
      await prefs.setString(storageKey, _paymentStartTime!.toIso8601String());
      await prefs.remove(statusKey); // Reset status
      _calculateRemainingTime();
    }

    _startCountdown();
  }

  void _calculateRemainingTime() {
    if (_paymentStartTime == null) return;

    final elapsed = DateTime.now().difference(_paymentStartTime!);
    final timeout = Duration(minutes: _paymentTimeoutMinutes);

    if (elapsed >= timeout) {
      remainingTime = Duration.zero;
    } else {
      remainingTime = timeout - elapsed;
    }
  }

  void _startCountdown() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _calculateRemainingTime();

      if (remainingTime.inSeconds <= 0) {
        timer.cancel();

        if (_isExpiredHandled) return;
        _isExpiredHandled = true;

        _handlePaymentExpired();
      } else {
        setState(() {});
      }
    });
  }

  void _startPaymentCheck() {
    _checkPaymentTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_isRefreshing && !_isNavigating) {
        _checkPaymentStatus();
      }
    });
  }

  /// ✅ IMPROVED: Refresh payment data from provider with better error handling
  Future<void> _refreshPaymentData() async {
    if (_isRefreshing || _isNavigating) {
      _refreshController.refreshCompleted();
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      debugPrint("[WaitingPayment] 🔄 Refreshing payment data...");

      final pesananProvider = context.read<PesananProvider>();

      // ✅ Use timeout to prevent hanging
      final updatedOrder = await pesananProvider
          .fetchSingleOrder(
        widget.paymentData.noBukti,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint("[WaitingPayment] ⏱️ Refresh timeout");
          return null;
        },
      );

      if (!mounted) return;

      if (updatedOrder != null) {
        debugPrint("[WaitingPayment] ✅ Payment data refreshed");
        debugPrint(
            "[WaitingPayment]    Status: ${updatedOrder.statusProgresPesanan}");
        debugPrint(
            "[WaitingPayment]    Status Bayar: ${updatedOrder.statusBayar}");

        setState(() {
          _currentPaymentData = updatedOrder;
          statusBayar = updatedOrder.statusBayar;
        });

        // ✅ Check if payment is complete
        if (statusBayar == "settlement" || statusBayar == "berhasil") {
          await _handlePaymentSuccess();
          return; // Don't call refreshCompleted if navigating
        }

        _refreshController.refreshCompleted();

        // ✅ Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Status pembayaran diperbarui'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        debugPrint("[WaitingPayment] ⚠️ Failed to refresh payment data");
        _refreshController.refreshFailed();

        // ✅ Show error feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memperbarui status, coba lagi'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("[WaitingPayment] ❌ Refresh error: $e");

      if (mounted) {
        _refreshController.refreshFailed();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /// ✅ IMPROVED: Check payment status with better error handling
  Future<void> _checkPaymentStatus() async {
    if (_isNavigating) return;

    try {
      final pesanan = await pesananService
          .getAll(
        noBukti: widget.paymentData.noBukti,
        orderBy: "no_bukti",
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint("[WaitingPayment] ⏱️ Check payment timeout");
          return [];
        },
      );

      if (!mounted || pesanan.isEmpty) return;

      final newStatusBayar = pesanan.first.statusBayar;

      // ✅ Only update if status changed
      if (newStatusBayar != statusBayar) {
        debugPrint(
            "[WaitingPayment] 📊 Status changed: $statusBayar → $newStatusBayar");

        setState(() {
          statusBayar = newStatusBayar;
          _currentPaymentData = pesanan.first;
        });

        if (statusBayar == "settlement" || statusBayar == "berhasil") {
          await _handlePaymentSuccess();
        }
      }

      debugPrint("[WaitingPayment] ✓ Payment status: $statusBayar");
    } catch (e) {
      debugPrint("[WaitingPayment] ❌ Error checking payment status: $e");
    }
  }

  /// ✅ IMPROVED: Handle payment success with navigation guard
  Future<void> _handlePaymentSuccess() async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    _timer?.cancel();
    _checkPaymentTimer?.cancel();

    // Hapus waktu mulai dari storage karena pembayaran berhasil
    await _clearPaymentTimer();

    if (!mounted) return;

    try {
      final pesananProvider = context.read<PesananProvider>();

      // Create history progress
      await context.read<HistoryOrderProvider>().createPersiapan(
            _currentPaymentData.noBukti,
            _currentPaymentData.idCustomer,
          );

      // Reload all orders
      await pesananProvider.loadOrder(context);
      context.read<OrderTabProvider>().setSelectedTabIndex(1);

      if (!mounted) return;

      // ✅ Navigate to success page with replacement to prevent back
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentSuccessSplashScreen(
            orderNumber: _currentPaymentData.noTrackingPesanan ?? "",
            amount: _currentPaymentData.grandTotal,
          ),
        ),
      );
    } catch (e) {
      debugPrint("[WaitingPayment] ❌ Error handling payment success: $e");

      if (mounted) {
        setState(() {
          _isNavigating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error saat memproses pembayaran'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handlePaymentExpired() async {
    if (!mounted || _isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    // Tandai pembayaran ini sebagai expired
    final prefs = await SharedPreferences.getInstance();
    final statusKey = 'payment_status_${widget.paymentData.noBukti}';
    await prefs.setString(statusKey, 'expired');

    try {
      if (!mounted) return;
      CustomDialog.showTimeoutDialog(
          context: context,
          onTap: () {
            context.read<NavigationProvider>().popAllToRoot();
            context.read<NavigationProvider>().changeTab(2, context);
          });
    } catch (e) {
      debugPrint("❌ Gagal update status pembayaran: $e");
    }
  }

  Future<void> _clearPaymentTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = 'payment_start_${widget.paymentData.noBukti}';
    final statusKey = 'payment_status_${widget.paymentData.noBukti}';
    await prefs.remove(storageKey);
    await prefs.remove(statusKey);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Use current payment data instead of widget.paymentData
    final int grandTotal = _currentPaymentData.grandTotal;
    final int subtotal = _currentPaymentData.subtotal;

    return WillPopScope(
      onWillPop: () async {
        // ✅ Prevent back if navigating
        return !_isNavigating;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: _isNavigating
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
          title: const Text(
            "Menunggu Pembayaran",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            // Timer Warning
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.timer, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Selesaikan pembayaran dalam",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Helper.formatDuration(remainingTime),
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SmartRefresher(
                controller: _refreshController,
                enablePullDown: !_isNavigating, // ✅ Disable when navigating
                enablePullUp: false,
                onRefresh: _refreshPaymentData,
                physics: const BouncingScrollPhysics(),
                // ✅ Improved custom header
                header: CustomHeader(
                  builder: (BuildContext context, RefreshStatus? mode) {
                    Widget body;

                    if (mode == RefreshStatus.idle) {
                      body = const Text(
                        "Tarik untuk refresh",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      );
                    } else if (mode == RefreshStatus.refreshing) {
                      body = Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                Constants.primaryColorVendor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Memperbarui status...",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      );
                    } else if (mode == RefreshStatus.canRefresh) {
                      body = const Text(
                        "Lepaskan untuk refresh",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      );
                    } else if (mode == RefreshStatus.completed) {
                      body = Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green.shade400,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Berhasil diperbarui",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      );
                    } else {
                      body = Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: Colors.orange.shade400,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Gagal refresh, coba lagi",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      );
                    }

                    return Container(
                      height: 55.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(child: body),
                    );
                  },
                ),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildPaymentCodeSection(),

                    const SizedBox(height: 16),

                    _buildCardSection(
                      title: "Detail Pesanan",
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            icon: Icons.timeline_outlined,
                            label: "Nomor Bukti",
                            copyable: true,
                            value: _currentPaymentData.noTrackingPesanan ?? "-",
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.inventory_2_outlined,
                            label: "Paket",
                            value: _currentPaymentData.namaPaket,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: "Tanggal",
                            value: Helper.formatTanggal(
                                _currentPaymentData.tglRealisasi),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.access_time,
                            label: "Waktu",
                            value: Helper.toLocalTime(
                                _currentPaymentData.tglRealisasi),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.location_city_outlined,
                            label: "Kota",
                            value: _currentPaymentData.namaKota ?? "",
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 20,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Alamat Lengkap",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _currentPaymentData.lokasi,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Payment Summary
                    _buildCardSection(
                      title: "Ringkasan Pembayaran",
                      content: Column(
                        children: [
                          _buildPriceRow("Subtotal (termasuk PPN)",
                              Helper.formatCurrency(subtotal)),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          _buildPriceRow(
                            "Total Pembayaran",
                            Helper.formatCurrency(grandTotal),
                            isBold: true,
                            valueColor: Constants.primaryColorVendor,
                            fontSize: 18,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ✅ Improved loading indicator
                    Center(
                      child: Column(
                        children: [
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Constants.primaryColorVendor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Menunggu pembayaran...",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Status akan diperbarui otomatis\nsetiap 10 detik",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // ✅ Improved manual refresh hint
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Constants.primaryColorVendor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Constants.primaryColorVendor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Tarik ke bawah untuk refresh manual",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Constants.primaryColorVendor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCodeSection() {
    final String metodeBayar = _currentPaymentData.metodeBayar ?? "";
    final String paymentNumber1 = _currentPaymentData.paymentNumber1 ?? "";
    final String paymentNumber2 = _currentPaymentData.paymentNumber2 ?? "";
    final int grandTotal = _currentPaymentData.grandTotal;

    if (metodeBayar.contains('QRIS')) {
      return QrisPaymentCard(qrUrl: paymentNumber1, amount: grandTotal);
    }

    if (metodeBayar.contains('VA') || metodeBayar.contains('BANK')) {
      if (metodeBayar.toLowerCase().contains("mandiri")) {
        return VaPaymentCard(
          bankName: metodeBayar,
          vaNumber: "", // Bisa dikosongkan atau diisi bill key
          amount: grandTotal,
          billCode: paymentNumber1, // Kode perusahaan
          billKey: paymentNumber2, // Nomor VA
        );
      }

      return VaPaymentCard(
          bankName: metodeBayar, vaNumber: paymentNumber1, amount: grandTotal);
    }

    if (metodeBayar.contains('ALFAMART') || metodeBayar.contains('INDOMARET')) {
      return CounterPaymentCard(
          storeName: metodeBayar,
          paymentCode: paymentNumber1,
          merchantCode: paymentNumber2,
          amount: grandTotal);
    }

    return const SizedBox.shrink();
  }

  /// =======================
  /// 🎨 WIDGET BUILDERS
  /// =======================

  Widget _buildCardSection({
    required String title,
    required Widget content,
    bool isRequired = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                const Text(
                  "*",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.black,
    bool copyable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.black54,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  if (copyable) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () =>
                          Helper.copyToClipboard(context, value, label),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 20,
                        color: Constants.primaryColorVendor,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    double fontSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
