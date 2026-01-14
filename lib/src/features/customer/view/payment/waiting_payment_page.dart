import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/models/paket_model.dart';
import 'package:mpjnew/src/data/models/pesanan_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/view/payment/payment_success_splash_screen.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/payment/counter_payment_card.dart';
import 'package:mpjnew/src/features/customer/widget/payment/qris_payment_cart.dart';
import 'package:mpjnew/src/features/customer/widget/payment/va_payment_card.dart';
import 'package:provider/provider.dart';
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
  Duration remainingTime = const Duration(minutes: 5, seconds: 0);
  Timer? _timer;
  bool _isExpiredHandled = false;
  Timer? _checkPaymentTimer;

  PaketModel? paket;

  bool isPackageExpanded = false;

  String? statusBayar;
  DateTime? _paymentStartTime;
  static const int _paymentTimeoutMinutes = 5;

  @override
  void initState() {
    super.initState();
    _initializePaymentTimer();
    _startPaymentCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _checkPaymentTimer?.cancel();
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
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    try {
      final pesanan = await pesananService.getAll(
        noBukti: widget.paymentData.noBukti,
        orderBy: "no_bukti",
      );
      final pesananProvider = await context.read<PesananProvider>();

      statusBayar = pesanan.first.statusBayar;

      if (statusBayar == "settlement" || statusBayar == "berhasil") {
        _timer?.cancel();
        _checkPaymentTimer?.cancel();

        // Hapus waktu mulai dari storage karena pembayaran berhasil
        await _clearPaymentTimer();

        if (!mounted) return;

        final historyPersiapan = HistoryOrderService.createPersiapan(
          noOrder: pesanan.first.noBukti,
          senderId: pesanan.first.idCustomer,
        );

        await pesananProvider.loadOrder(userId: pesanan.first.idCustomer);
        await historyOrderService.create(historyPersiapan);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PaymentSuccessSplashScreen(
              orderNumber: widget.paymentData.noBukti,
              amount: widget.paymentData.grandTotal,
            ),
          ),
        );
      }

      setState(() {});
      print("Checking payment status for order: ${widget.paymentData.noBukti}");
    } catch (e) {
      debugPrint("Error checking payment status: $e");
    }
  }

  Future<void> _handlePaymentExpired() async {
    if (!mounted) return;

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
      debugPrint("Gagal update status pembayaran: $e");
    }
  }

  Future<void> _clearPaymentTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = 'payment_start_${widget.paymentData.noBukti}';
    await prefs.remove(storageKey);
  }

  @override
  Widget build(BuildContext context) {
    final int grandTotal = widget.paymentData.grandTotal;
    final int subtotal = widget.paymentData.subtotal;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: CustomBackButton(),
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
                  child: const Icon(Icons.timer, color: Colors.white, size: 24),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          label: "No. Tracking",
                          copyable: true,
                          value: widget.paymentData.noTrackingPesanan ?? "-",
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.inventory_2_outlined,
                          label: "Paket",
                          value: widget.paymentData.namaPaket,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: "Tanggal",
                          value: DateFormat("dd MMM yyyy", "id_ID")
                              .format(widget.paymentData.tglRealisasi),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.access_time,
                          label: "Waktu",
                          value: Helper.toLocalTime(
                              widget.paymentData.tglRealisasi),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.location_city_outlined,
                          label: "Kota",
                          value: widget.paymentData.namaKota ?? "",
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
                                    widget.paymentData.lokasi,
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

                  // Loading Indicator
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
                          "Halaman akan otomatis terbarui\nsetelah pembayaran berhasil",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
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
    );
  }

  Widget _buildPaymentCodeSection() {
    final String metodeBayar = widget.paymentData.metodeBayar ?? "";
    final String paymentNumber1 = widget.paymentData.paymentNumber1 ?? "";
    final String paymentNumber2 = widget.paymentData.paymentNumber2 ?? "";
    final int grandTotal = widget.paymentData.grandTotal;

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
