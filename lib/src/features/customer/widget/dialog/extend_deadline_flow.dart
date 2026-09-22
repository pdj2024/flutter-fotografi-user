import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/extend_deadline_dialog.dart';

/// Buka dialog perpanjang batas pengerjaan, simpan, lalu refresh data
/// pesanan. Satu-satunya tempat logic ini hidup -- dipanggil dari
/// DetailOrderPageV2 (LocationSection & profile card) DAN dari
/// ChatPesananCard, supaya tidak ada duplikasi.
///
/// [roomId] opsional -- isi kalau dipanggil dari dalam room chat (lihat
/// ChatPesananCard) supaya snapshot pesanan yang ter-embed di pesan chat
/// ikut disegarkan (`ChatProvider.refreshEmbeddedPesananInRoom`, pola yang
/// sama dipakai penawaran). Tanpa ini, kartu pesanan di chat tetap
/// menampilkan batas pengerjaan LAMA sampai ada pesan baru masuk ke room
/// itu -- PesananProvider.refreshOrder() di bawah cuma menyegarkan cache
/// provider, bukan snapshot yang sudah ter-embed di pesan lama.
Future<void> showExtendDeadlineFlow(BuildContext context, PesananModel pesanan,
    {String? roomId}) async {
  final deadline = pesanan.tglPengerjaanMax;
  if (deadline == null) return;

  final newDeadline = await showDialog<DateTime>(
    context: context,
    builder: (_) => ExtendDeadlineDialog(currentDeadline: deadline),
  );
  if (newDeadline == null) return;
  if (!context.mounted) return;

  try {
    await PesananService()
        .update(pesanan.copyWith(tglPengerjaanMax: newDeadline));

    // Catat perubahan sebagai history progres -- status TETAP sama seperti
    // sekarang (cuma menambah entri timeline, bukan mengubah tahap pesanan),
    // supaya vendor & customer sama-sama lihat kapan & ke tanggal berapa
    // batas pengerjaan diperbarui.
    final status = pesanan.statusProgresPesanan;
    if (status != null && status.isNotEmpty) {
      final history = HistoryOrderService.createHistory(
        noOrder: pesanan.noBukti,
        senderId: pesanan.idCustomer,
        statusProgressPesanan: status,
        customTipeUser: 'Customer',
        customDeskripsi: 'User memperbarui estimasi tanggal pengerjaan '
            'selesai ke: ${Helper.formatTanggal(newDeadline)}, '
            '${Helper.toLocalTime(newDeadline)}',
      );
      await HistoryOrderService().create(history);
    }

    if (!context.mounted) return;
    await context.read<PesananProvider>().refreshOrder(pesanan.noBukti);

    if (roomId != null && roomId.isNotEmpty) {
      // Fire-and-forget -- kartu chat menyusul update begitu selesai,
      // tidak perlu memblokir snackbar sukses di bawah.
      unawaited(context
          .read<ChatProvider>()
          .refreshEmbeddedPesananInRoom(roomId, pesanan.noBukti));
    }

    if (context.mounted) {
      CustomSnackbar.showSuccessSnackbar(
          context, 'Batas pengerjaan berhasil diperpanjang.');
    }
  } catch (e) {
    if (context.mounted) {
      CustomSnackbar.showErrorSnackbar(context, e.toString());
    }
  }
}
