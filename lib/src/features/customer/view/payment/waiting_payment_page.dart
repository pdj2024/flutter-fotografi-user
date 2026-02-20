import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
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
  final PesananService _pesananService = PesananService();
  final HistoryOrderService _historyOrderService = HistoryOrderService();
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  late PesananModel _currentData;
  Duration _remainingTime = const Duration(minutes: 5);
  Timer? _countdownTimer;
  Timer? _pollingTimer;
  StreamSubscription<PesananModel>? _fcmSubscription;

  bool _isExpiredHandled = false;
  bool _isNavigating = false;
  bool _isRefreshing = false;
  DateTime? _paymentStartTime;

  static const int _timeoutMinutes = 5;
  static const int _pollingIntervalSeconds = 10;

  @override
  void initState() {
    super.initState();
    _currentData = widget.paymentData;
    _initTimer();
    _startPolling();
    // FCM listener dipasang setelah frame pertama agar context tersedia
    WidgetsBinding.instance.addPostFrameCallback((_) => _listenFCM());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    _fcmSubscription?.cancel();
    _refreshController.dispose();
    super.dispose();
  }

  // =========================================
  // FCM LISTENER
  // Listen ke PesananProvider.paymentUpdateStream
  // Ini yang di-trigger saat webhook FCM masuk
  // =========================================
  void _listenFCM() {
    _fcmSubscription = context
        .read<PesananProvider>()
        .paymentUpdateStream
        .where((p) => p.noBukti == widget.paymentData.noBukti)
        .listen((updated) {
      debugPrint('[WaitingPayment] 🔔 FCM update received via stream');
      debugPrint('[WaitingPayment]    statusBayar: ${updated.statusBayar}');

      if (!mounted || _isNavigating) return;

      setState(() => _currentData = updated);

      if (PesananProvider.isPaymentSettled(updated.statusBayar)) {
        _handleSuccess();
      }
    });

    debugPrint('[WaitingPayment] ✅ FCM stream listener attached');
  }

  // =========================================
  // COUNTDOWN TIMER
  // =========================================
  Future<void> _initTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final startKey = 'payment_start_${widget.paymentData.noBukti}';
    final statusKey = 'payment_status_${widget.paymentData.noBukti}';
    final storedTime = prefs.getString(startKey);
    final storedStatus = prefs.getString(statusKey);

    if (storedTime != null && storedStatus != 'expired') {
      _paymentStartTime = DateTime.parse(storedTime);
    } else {
      _paymentStartTime = DateTime.now();
      await prefs.setString(startKey, _paymentStartTime!.toIso8601String());
      await prefs.remove(statusKey);
    }

    _recalcRemaining();
    _startCountdown();
  }

  void _recalcRemaining() {
    if (_paymentStartTime == null) return;
    final elapsed = DateTime.now().difference(_paymentStartTime!);
    final timeout = Duration(minutes: _timeoutMinutes);
    _remainingTime =
        elapsed >= timeout ? Duration.zero : timeout - elapsed;
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _recalcRemaining();
      if (_remainingTime.inSeconds <= 0) {
        _countdownTimer?.cancel();
        if (!_isExpiredHandled) {
          _isExpiredHandled = true;
          _handleExpired();
        }
      } else {
        setState(() {});
      }
    });
  }

  // =========================================
  // POLLING (fallback jika FCM tidak sampai)
  // =========================================
  void _startPolling() {
    _pollingTimer = Timer.periodic(
      const Duration(seconds: _pollingIntervalSeconds),
      (_) {
        if (!_isRefreshing && !_isNavigating) _pollStatus();
      },
    );
  }

  Future<void> _pollStatus() async {
    try {
      final list = await _pesananService
          .getAll(noBukti: widget.paymentData.noBukti)
          .timeout(const Duration(seconds: 10), onTimeout: () => []);

      if (!mounted || list.isEmpty) return;

      final fresh = list.first;

      if (fresh.statusBayar != _currentData.statusBayar) {
        debugPrint(
            '[WaitingPayment] 📊 Poll status changed: ${_currentData.statusBayar} → ${fresh.statusBayar}');
        setState(() => _currentData = fresh);

        if (PesananProvider.isPaymentSettled(fresh.statusBayar)) {
          _handleSuccess();
        }
      }
    } catch (e) {
      debugPrint('[WaitingPayment] ⚠️ Poll error: $e');
    }
  }

  // =========================================
  // MANUAL REFRESH (pull-to-refresh)
  // =========================================
  Future<void> _manualRefresh() async {
    if (_isRefreshing || _isNavigating) {
      _refreshController.refreshCompleted();
      return;
    }

    setState(() => _isRefreshing = true);

    try {
      final updated = await context
          .read<PesananProvider>()
          .fetchSingleOrder(widget.paymentData.noBukti)
          .timeout(const Duration(seconds: 15), onTimeout: () => null);

      if (!mounted) return;

      if (updated != null) {
        setState(() => _currentData = updated);
        _refreshController.refreshCompleted();

        if (PesananProvider.isPaymentSettled(updated.statusBayar)) {
          _handleSuccess();
          return;
        }

        _showSnack('Status pembayaran diperbarui', Colors.green.shade600);
      } else {
        _refreshController.refreshFailed();
        _showSnack('Gagal memperbarui status', Colors.orange);
      }
    } catch (e) {
      _refreshController.refreshFailed();
      _showSnack('Error: $e', Colors.red.shade600);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  // =========================================
  // HANDLE SUCCESS
  // =========================================
  Future<void> _handleSuccess() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    _fcmSubscription?.cancel();

    // Bersihkan timer storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('payment_start_${widget.paymentData.noBukti}');
    await prefs.remove('payment_status_${widget.paymentData.noBukti}');

    if (!mounted) return;

    try {
      await context.read<HistoryOrderProvider>().createPersiapan(
            _currentData.noBukti,
            _currentData.idCustomer,
          );

      await context.read<PesananProvider>().loadOrder(context);
      context.read<OrderTabProvider>().setSelectedTabIndex(1);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentSuccessSplashScreen(
            orderNumber: _currentData.noTrackingPesanan ?? '',
            amount: _currentData.grandTotal,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[WaitingPayment] ❌ handleSuccess error: $e');
      if (mounted) {
        setState(() => _isNavigating = false);
        _showSnack('Error saat memproses pembayaran', Colors.red.shade600);
      }
    }
  }

  // =========================================
  // HANDLE EXPIRED
  // =========================================
  Future<void> _handleExpired() async {
    if (!mounted || _isNavigating) return;
    setState(() => _isNavigating = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'payment_status_${widget.paymentData.noBukti}', 'expired');

    if (!mounted) return;
    CustomDialog.showTimeoutDialog(
      context: context,
      onTap: () {
        context.read<NavigationProvider>().popAllToRoot();
        context.read<NavigationProvider>().changeTab(2, context);
      },
    );
  }

  // =========================================
  // UTIL
  // =========================================
  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  // =========================================
  // BUILD
  // =========================================
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isNavigating,
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
            'Menunggu Pembayaran',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            // ── Countdown Banner ──────────────────────────────────────────
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
                    child: const Icon(Icons.timer,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selesaikan pembayaran dalam',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Helper.formatDuration(_remainingTime),
                        style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── FCM Status Indicator ──────────────────────────────────────
            // Ditampilkan saat sedang navigate (payment sukses terdeteksi)
            if (_isNavigating)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 16),
                color: Colors.green.shade50,
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                            Colors.green.shade600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Pembayaran berhasil! Memproses pesanan...',
                      style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: SmartRefresher(
                controller: _refreshController,
                enablePullDown: !_isNavigating,
                onRefresh: _manualRefresh,
                physics: const BouncingScrollPhysics(),
                header: _buildRefreshHeader(),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildPaymentCodeSection(),
                    const SizedBox(height: 16),
                    _buildOrderDetail(),
                    const SizedBox(height: 16),
                    _buildPaymentSummary(),
                    const SizedBox(height: 24),
                    _buildWaitingIndicator(),
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

  // ── Payment code widget ────────────────────────────────────────────────
  Widget _buildPaymentCodeSection() {
    final metode = _currentData.metodeBayar ?? '';
    final p1 = _currentData.paymentNumber1 ?? '';
    final p2 = _currentData.paymentNumber2 ?? '';
    final total = _currentData.grandTotal;

    if (metode.contains('QRIS')) {
      return QrisPaymentCard(qrUrl: p1, amount: total);
    }
    if (metode.contains('VA') || metode.contains('BANK')) {
      if (metode.toLowerCase().contains('mandiri')) {
        return VaPaymentCard(
            bankName: metode,
            vaNumber: '',
            amount: total,
            billCode: p1,
            billKey: p2);
      }
      return VaPaymentCard(bankName: metode, vaNumber: p1, amount: total);
    }
    if (metode.contains('ALFAMART') || metode.contains('INDOMARET')) {
      return CounterPaymentCard(
          storeName: metode,
          paymentCode: p1,
          merchantCode: p2,
          amount: total);
    }
    return const SizedBox.shrink();
  }

  // ── Order detail card ──────────────────────────────────────────────────
  Widget _buildOrderDetail() {
    return _card(
      title: 'Detail Pesanan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.timeline_outlined, 'Nomor Bukti',
              _currentData.noTrackingPesanan ?? '-',
              copyable: true),
          const SizedBox(height: 12),
          _infoRow(Icons.inventory_2_outlined, 'Paket', _currentData.namaPaket),
          const SizedBox(height: 12),
          _infoRow(Icons.calendar_today_outlined, 'Tanggal',
              Helper.formatTanggal(_currentData.tglRealisasi)),
          const SizedBox(height: 12),
          _infoRow(Icons.access_time, 'Waktu',
              Helper.toLocalTime(_currentData.tglRealisasi)),
          const SizedBox(height: 12),
          _infoRow(Icons.location_city_outlined, 'Kota',
              _currentData.namaKota ?? ''),
          const SizedBox(height: 12),
          _infoRow(Icons.location_on_outlined, 'Alamat', _currentData.lokasi),
        ],
      ),
    );
  }

  // ── Payment summary card ───────────────────────────────────────────────
  Widget _buildPaymentSummary() {
    return _card(
      title: 'Ringkasan Pembayaran',
      child: Column(
        children: [
          _priceRow('Subtotal (termasuk PPN)',
              Helper.formatCurrency(_currentData.subtotal)),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _priceRow('Total Pembayaran',
              Helper.formatCurrency(_currentData.grandTotal),
              isBold: true,
              valueColor: Constants.primaryColorVendor,
              fontSize: 18),
        ],
      ),
    );
  }

  // ── Waiting indicator ──────────────────────────────────────────────────
  Widget _buildWaitingIndicator() {
    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(Constants.primaryColorVendor),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Menunggu konfirmasi pembayaran...',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            'Notifikasi otomatis akan diterima\nsaat pembayaran berhasil',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Constants.primaryColorVendor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: Constants.primaryColorVendor),
                const SizedBox(width: 8),
                Text(
                  'Tarik ke bawah untuk refresh manual',
                  style: TextStyle(
                      fontSize: 12,
                      color: Constants.primaryColorVendor,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Refresh header ─────────────────────────────────────────────────────
  Widget _buildRefreshHeader() {
    return CustomHeader(
      builder: (context, mode) {
        final content = switch (mode) {
          RefreshStatus.refreshing => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                            Constants.primaryColorVendor))),
                const SizedBox(width: 12),
                const Text('Memperbarui status...',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          RefreshStatus.completed => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle,
                    size: 16, color: Colors.green.shade400),
                const SizedBox(width: 8),
                const Text('Berhasil diperbarui',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          RefreshStatus.canRefresh => const Text('Lepaskan untuk refresh',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          _ => const Text('Tarik untuk refresh',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        };

        return Container(
          height: 55,
          color: Colors.white,
          child: Center(child: content),
        );
      },
    );
  }

  // ── Reusable widgets ───────────────────────────────────────────────────
  Widget _card({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {bool copyable = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                  if (copyable)
                    InkWell(
                      onTap: () =>
                          Helper.copyToClipboard(context, value, label),
                      child: Icon(Icons.copy_rounded,
                          size: 18, color: Constants.primaryColorVendor),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value,
      {bool isBold = false, Color? valueColor, double fontSize = 14}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight:
                    isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight:
                    isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? Colors.black87)),
      ],
    );
  }
}