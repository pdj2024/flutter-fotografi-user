import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mpjnew/src/core/services/refund_rule_service.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/refund_rule_model.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/view/complain/complain_thread_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/complain_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/confirm_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ComplainMenuAction extends StatelessWidget {
  const ComplainMenuAction({super.key, required this.pesanan});

  final PesananModel pesanan;

  // Sama dengan nomor WA di HelpFab/SettingPage — customer tidak bisa lagi
  // mengajukan complain baru dari app (hanya bisa melihat yang sudah ada),
  // jadi kalau order ini belum punya complain, satu-satunya jalan komplain
  // adalah menghubungi admin langsung, tanpa pesan default (beda dari
  // HelpFab yang mengirim template pesan).
  static const _adminWaNumber = '62895353837000';

  Future<void> _contactAdmin() async {
    final uri = Uri.parse('https://wa.me/$_adminWaNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PesananProvider, ComplainProvider>(
      builder: (context, pesananProvider, complainProv, _) {
        final order =
            pesananProvider.getPesananByNoOrder(pesanan.noBukti) ??
                pesanan;
        final noOrder = pesanan.noBukti;
        final checking = complainProv.isChecking(noOrder);
        final error = complainProv.getCheckError(noOrder);
        final existing = complainProv.getCachedForOrder(noOrder);
        final canCancel = PesananProvider.canCancel(order);

        Color dotColor = Colors.grey;
        if (existing != null) {
          dotColor = existing.isClosed ? Colors.green : Colors.orange;
        }

        return PopupMenuButton<String>(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black26,
          popUpAnimationStyle: AnimationStyle(
            duration: const Duration(milliseconds: 150),
          ),
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onSelected: (value) {
            if (value == 'batal') {
              _confirmBatalkan(context, order);
              return;
            }
            if (value != 'complain') return;
            if (checking) return;
            if (error != null) {
              complainProv.checkForOrder(noOrder);
              return;
            }
            if (existing == null) {
              _contactAdmin();
            } else {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ComplainThreadPage(
                  noComplain: existing.noComplain,
                  noOrder: noOrder,
                  showOrderAction: false,
                ),
              ));
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'complain',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  existing == null && error == null && !checking
                      ? const FaIcon(FontAwesomeIcons.whatsapp,
                          size: 18, color: Color(0xFF25D366))
                      : Icon(Icons.report_problem_outlined,
                          size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 10),
                  Text(
                    error != null
                        ? 'Complain (coba lagi)'
                        : checking
                            ? 'Memuat...'
                            : existing == null
                                ? 'Hubungi Admin'
                                : 'Lihat Complain',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (existing != null && error == null) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: dotColor),
                    ),
                  ],
                ],
              ),
            ),
            // Hanya muncul selagi order belum masuk pengerjaan/pemotretan —
            // aturan tunggalnya ada di PesananProvider.canCancel, dipakai
            // juga oleh OrderHistoryCard supaya kedua tempat konsisten.
            if (canCancel)
              const PopupMenuItem(
                value: 'batal',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel_outlined,
                        size: 18, color: Color(0xFFDC2626)),
                    SizedBox(width: 10),
                    Text(
                      'Batalkan Pesanan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmBatalkan(BuildContext context, PesananModel order) async {
    final needsRefund = PesananProvider.needsRefund(order);
    RefundRuleModel? refundTier;

    if (needsRefund) {
      try {
        final rules = await RefundRuleService().getAll();
        final sisaJam = order.tglRealisasi
            .difference(DateTime.now())
            .inHours
            .toDouble();
        refundTier = RefundRuleService().resolveTier(rules, sisaJam);
      } catch (e) {
        debugPrint('[ComplainMenuAction] ⚠️ Gagal ambil aturan refund: $e');
      }
    }

    if (!context.mounted) return;

    ConfirmDialog.showBatalkanPesananDialog(
      context: context,
      isRefund: needsRefund,
      refundTier: refundTier,
      onConfirm: () => _batalkanPesanan(context, order),
    );
  }


  Future<void> _batalkanPesanan(BuildContext context, PesananModel order) async {
    try {
      if (PesananProvider.needsRefund(order)) {
        await PesananService().batalDenganRefund(order);
      } else {
        await PesananService().batal(order.noBukti);
      }
      final history = HistoryOrderService.createDibatalkan(
        noOrder: order.noBukti,
        senderId: order.idCustomer,
        customDeskripsi: 'Pesanan ini dibatalkan oleh customer.',
      );
      await HistoryOrderService().create(history);

      if (!context.mounted) return;
      await context.read<PesananProvider>().refreshOrder(order.noBukti);

      if (!context.mounted) return;
      CustomSnackbar.showSuccessSnackbar(context, 'Pesanan berhasil dibatalkan.');
    } catch (e) {
      if (context.mounted) CustomSnackbar.showErrorSnackbar(context, e.toString());
    }
  }
}