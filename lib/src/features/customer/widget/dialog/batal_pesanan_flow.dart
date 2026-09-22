import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/services/refund_rule_service.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/refund_info_model.dart';
import 'package:mpjnew/src/data/models/refund_rule_model.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/view/history/refund_form_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/confirm_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';

/// Satu-satunya pintu masuk pembatalan pesanan oleh customer.
///
/// Sebelumnya logika ini tersebar di empat tempat (MainOrderPage,
/// RoomChatPage, ComplainMenuAction, WaitingPaymentPage) dengan aturan
/// refund yang saling berbeda. Semuanya sekarang memanggil fungsi ini.
///
/// Dua jalur:
/// - **Belum dibayar** → dialog konfirmasi biasa, langsung batal.
/// - **Sudah dibayar & masih `persiapan`** → tampilkan nominal refund hasil
///   hitungan server, lalu arahkan ke [RefundFormPage] untuk mengisi rekening
///   tujuan. Pembatalannya sendiri dieksekusi di halaman itu.
///
/// [roomId] diisi kalau dipanggil dari dalam room chat, supaya snapshot
/// pesanan yang ter-embed di pesan chat ikut disegarkan.
Future<void> showBatalPesananFlow(
  BuildContext context,
  PesananModel pesanan, {
  String? roomId,
  VoidCallback? onSuccess,
}) async {
  final perluRefund = PesananProvider.needsRefund(pesanan);

  RefundInfoModel? info;
  List<RefundRuleModel> rules = const [];

  if (perluRefund) {
    // Kedua request jalan berbarengan; masing-masing menelan errornya
    // sendiri supaya satu endpoint yang bermasalah tidak menjatuhkan yang
    // lain — dan pembatalan tetap bisa dilanjutkan tanpa keduanya.
    final infoFuture = PesananService()
        .getInfoRefund(
      idPesanan: pesanan.noBukti,
      noTrackingPesanan: pesanan.noTrackingPesanan ?? '',
      idCustomer: pesanan.idCustomer,
    )
        .catchError((e) {
      debugPrint('[BatalPesananFlow] ⚠️ Gagal ambil info refund: $e');
      return null;
    });
    final rulesFuture = RefundRuleService().getAll().catchError((e) {
      debugPrint('[BatalPesananFlow] ⚠️ Gagal ambil aturan refund: $e');
      return <RefundRuleModel>[];
    });

    // Navigator dipegang SEBELUM await: kalau halaman pemanggil keburu
    // ditutup selagi request jalan, context-nya tidak bisa dipakai lagi dan
    // dialog loading akan tertinggal di layar.
    final navigator = Navigator.of(context, rootNavigator: true);
    _tampilkanLoading(context);
    info = await infoFuture;
    rules = await rulesFuture;
    navigator.pop();
  }

  if (!context.mounted) return;

  // Form rekening hanya perlu kalau memang ada dana yang dikembalikan. Info
  // gagal dimuat (null) → nominal belum pasti, tetap minta rekening.
  final perluRekening = perluRefund && (info?.adaDanaKembali ?? true);

  ConfirmDialog.showBatalkanPesananDialog(
    context: context,
    isRefund: perluRefund,
    lanjutKeForm: perluRekening,
    refundInfo: info,
    rules: rules,
    onConfirm: () {
      if (perluRekening) {
        context.read<NavigationProvider>().navigateToPage(
              context,
              RefundFormPage(
                pesanan: pesanan,
                refundInfo: info,
                rules: rules,
                roomId: roomId,
                onSuccess: onSuccess,
              ),
              // Pembatalan bisa dipicu dari tab mana pun (pesanan, chat,
              // akun), jadi tidak bisa mengandalkan targetTabIndex tetap.
              fullscreen: true,
            );
      } else {
        // Belum dibayar, atau refund 0%: langsung batal. Tanpa tgl_refund,
        // karena tidak ada dana yang perlu dikembalikan.
        unawaited(eksekusiBatalPesanan(
          context,
          pesanan,
          denganRefund: false,
          roomId: roomId,
          onSuccess: onSuccess,
        ));
      }
    },
  );
}

/// Eksekusi pembatalan + pencatatan history + penyegaran data.
///
/// Dipakai dua kali: jalur tanpa refund (langsung dari dialog) dan jalur
/// refund (setelah rekening tersimpan di [RefundFormPage]). Mengembalikan
/// true kalau berhasil.
Future<bool> eksekusiBatalPesanan(
  BuildContext context,
  PesananModel pesanan, {
  required bool denganRefund,
  String? roomId,
  VoidCallback? onSuccess,
}) async {
  try {
    await PesananService().batalkanPesanan(pesanan, denganRefund: denganRefund);

    final history = HistoryOrderService.createDibatalkan(
      noOrder: pesanan.noBukti,
      senderId: pesanan.idCustomer,
      customDeskripsi: 'Pesanan ini dibatalkan oleh customer.',
    );
    await HistoryOrderService().create(history);

    if (!context.mounted) return true;
    await context.read<PesananProvider>().refreshOrder(pesanan.noBukti);

    if (roomId != null && roomId.isNotEmpty && context.mounted) {
      unawaited(context
          .read<ChatProvider>()
          .refreshEmbeddedPesananInRoom(roomId, pesanan.noBukti));
    }

    if (context.mounted) {
      CustomSnackbar.showSuccessSnackbar(
          context, 'Pesanan berhasil dibatalkan.');
    }
    onSuccess?.call();
    return true;
  } catch (e) {
    if (context.mounted)
      CustomSnackbar.showErrorSnackbar(context, e.toString());
    return false;
  }
}

void _tampilkanLoading(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
}
