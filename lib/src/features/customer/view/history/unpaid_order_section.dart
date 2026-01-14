import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/features/customer/view/payment/waiting_payment_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/pesanan_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnpaidOrderSection extends StatefulWidget {
  const UnpaidOrderSection({super.key});

  @override
  State<UnpaidOrderSection> createState() => _UnpaidOrderSectionState();
}

class _UnpaidOrderSectionState extends State<UnpaidOrderSection> {
  Map<String, PaymentTimerStatus> _timerStatuses = {};
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _loadTimerStatuses();
    _startPeriodicUpdate();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicUpdate() {
    // Update timer setiap 1 detik
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _loadTimerStatuses();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadTimerStatuses() async {
    final progressOrder = context.read<PesananProvider>().pesananUnpaid;
    final prefs = await SharedPreferences.getInstance();
    final Map<String, PaymentTimerStatus> statuses = {};

    for (var order in progressOrder) {
      final storageKey = 'payment_start_${order.noBukti}';
      final statusKey = 'payment_status_${order.noBukti}';

      final storedTime = prefs.getString(storageKey);
      final paymentStatus = prefs.getString(statusKey);

      if (storedTime != null) {
        final startTime = DateTime.parse(storedTime);
        final elapsed = DateTime.now().difference(startTime);
        final timeout = const Duration(minutes: 5);
        final remaining = timeout - elapsed;

        if (remaining.inSeconds <= 0 || paymentStatus == 'expired') {
          statuses[order.noBukti] = PaymentTimerStatus(
            isExpired: true,
            remainingTime: Duration.zero,
          );

          // Auto-mark as expired di SharedPreferences jika belum
          if (paymentStatus != 'expired' && remaining.inSeconds <= 0) {
            await prefs.setString(statusKey, 'expired');
          }
        } else {
          statuses[order.noBukti] = PaymentTimerStatus(
            isExpired: false,
            remainingTime: remaining,
          );
        }
      } else {
        // Belum ada timer
        statuses[order.noBukti] = PaymentTimerStatus(
          isExpired: false,
          remainingTime: null,
        );
      }
    }

    if (mounted) {
      setState(() {
        _timerStatuses = statuses;
      });
    }
  }

  Future<void> _retryPayment(String noBukti) async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = 'payment_start_$noBukti';
    final statusKey = 'payment_status_$noBukti';

    // Reset timer - buat timer baru
    await prefs.setString(storageKey, DateTime.now().toIso8601String());
    await prefs.remove(statusKey);

    // Reload status
    await _loadTimerStatuses();
  }

  @override
  Widget build(BuildContext context) {
    final progressOrder = context.watch<PesananProvider>().pesananUnpaid;

    // ✅ Cek data kosong SEBELUM ListView
    if (progressOrder.isEmpty) {
      return Container(
        height: 500,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // ✅ Tambahkan ini
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 100,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "Belum ada pesanan yang belum dibayar",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // ✅ Jika ada data, tampilkan ListView
    return ListView.builder(
      itemCount: progressOrder.length,
      itemBuilder: (context, index) {
        final item = progressOrder[index];
        final status = _timerStatuses[item.noBukti];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: PesananCard(
            clientName: item.namaVendor ?? "Vendor",
            imgUrl: item.idMediaVendor ?? "",
            kategori: item.namaPaket,
            dateValue: DateFormat("dd MMMM yyyy").format(item.tglRealisasi),
            timeValue: Helper.toLocalTime(item.tglRealisasi),
            location: item.lokasi,
            paymentTimerStatus: status,
            statusProgress: item.statusProgresPesanan ?? "proses",
            deskripsiProgress: item.deskripsiProgresPesanan ?? "",
            onTap: () {
              context.read<NavigationProvider>().navigateToPage(
                    context,
                    targetTabIndex: 2,
                    WaitingPaymentPage(
                      paymentData: item,
                    ),
                  );
            },
            onRetryPayment: status?.isExpired == true
                ? () async {
                    await _retryPayment(item.noBukti);
                    if (!context.mounted) return;

                    context.read<NavigationProvider>().navigateToPage(
                          context,
                          targetTabIndex: 2,
                          WaitingPaymentPage(
                            paymentData: item,
                          ),
                        );
                  }
                : null,
            onStartPayment:
                status?.remainingTime == null && status?.isExpired == false
                    ? () async {
                        await _retryPayment(item.noBukti);
                        if (!context.mounted) return;

                        context.read<NavigationProvider>().navigateToPage(
                              context,
                              targetTabIndex: 2,
                              WaitingPaymentPage(
                                paymentData: item,
                              ),
                            );
                      }
                    : null,
          ),
        );
      },
    );
  }
}
