import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/models/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/view/payment/payment_success_splash_screen.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/payment/counter_payment_card.dart';
import 'package:mpjnew/src/features/customer/widget/payment/qris_payment_cart.dart';
import 'package:mpjnew/src/features/customer/widget/payment/va_payment_card.dart';
import 'package:provider/provider.dart';

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
  Duration remainingTime = const Duration(minutes: 5, seconds: 0);
  Timer? _timer;
  bool _isExpiredHandled = false;
  Timer? _checkPaymentTimer;

  String? statusBayar;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startPaymentCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _checkPaymentTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel(); // pastikan tidak double timer

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (remainingTime.inSeconds <= 0) {
        timer.cancel();

        if (_isExpiredHandled) return;
        _isExpiredHandled = true;

        _handlePaymentExpired();
      } else {
        setState(() {
          remainingTime -= const Duration(seconds: 1);
        });
      }
    });
  }

  void _startPaymentCheck() {
    // Check payment status every 10 seconds
    _checkPaymentTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      // TODO: Call API to check payment status
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    try {
      final pesanan = await pesananService.getAll(
        noBukti: widget.paymentData.noBukti,
        orderBy: "no_bukti",
      );

      statusBayar = pesanan.first.statusBayar;

      if (statusBayar == "settlement" || statusBayar == "berhasil") {
        // Stop timers
        _timer?.cancel();
        _checkPaymentTimer?.cancel();

        // Navigate to splash screen
        if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    final String orderNumber = widget.paymentData.noBukti;
    final String trackingNumber = widget.paymentData.noTrackingPesanan ?? '-';
    final int grandTotal = widget.paymentData.grandTotal;
    final int subtotal = widget.paymentData.subtotal;
    final int ppn = widget.paymentData.totPpn ?? 0;

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

                  // Order Details
                  _buildCardSection(
                    title: "Detail Pesanan",
                    icon: Icons.receipt_long_rounded,
                    content: Column(
                      children: [
                        _buildDetailRow(
                          "No. Pesanan",
                          orderNumber,
                          copyable: true,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          "No. Tracking",
                          trackingNumber,
                          copyable: true,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          "Paket",
                          widget.paymentData.namaPaket,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          "Tanggal Realisasi",
                          DateFormat("dd MMM yyyy", "id_ID")
                              .format(DateTime.now()),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          "Lokasi",
                          "${widget.paymentData.lokasi}, ${widget.paymentData.namaKota}",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment Summary
                  _buildCardSection(
                    title: "Ringkasan Pembayaran",
                    icon: Icons.receipt_rounded,
                    content: Column(
                      children: [
                        _buildPriceRow("Subtotal (termasuk PPN)",
                            Helper.formatCurrency(subtotal)),
                        const SizedBox(height: 12),
                        _buildPriceRow("PPN (11%)", Helper.formatCurrency(ppn)),
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

    // QRIS
    if (metodeBayar.contains('QRIS')) {
      return QrisPaymentCard(qrUrl: paymentNumber1, amount: grandTotal);
    }

    // Virtual Account (VA)
    if (metodeBayar.contains('VA') || metodeBayar.contains('BANK')) {
      return VaPaymentCard(
          bankName: metodeBayar, vaNumber: paymentNumber1, amount: grandTotal);
    }

    // Counter (Alfamart/Indomaret)
    if (metodeBayar.contains('ALFAMART') || metodeBayar.contains('INDOMARET')) {
      return CounterPaymentCard(
          storeName: metodeBayar,
          paymentCode: paymentNumber1,
          merchantCode: paymentNumber2,
          amount: grandTotal);
    }

    return const SizedBox.shrink();
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: Constants.primaryColorVendor),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool copyable = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (copyable)
                InkWell(
                  onTap: () => Helper.copyToClipboard(context, value, label),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: Constants.primaryColorVendor,
                    ),
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
