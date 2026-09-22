import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';

/// Status pesanan yang punya deadline pengerjaan aktif -- HARUS sama persis
/// dengan set status yang dipakai auto-complete overdue di pesanan_provider.dart
/// supaya reminder & auto-complete selalu konsisten soal pesanan mana yang relevan.
const kDeadlineEligibleStatuses = {'proses', 'review', 'revisi'};

/// null kalau reminder belum perlu tampil (status tidak eligible, deadline
/// null, atau sisa waktu masih > 25% dari estimasiPengerjaan).
Duration? remainingIfNearDeadline(PesananModel pesanan) {
  final status = pesanan.statusProgresPesanan?.trim().toLowerCase();
  if (status == null || !kDeadlineEligibleStatuses.contains(status)) {
    return null;
  }

  final deadline = pesanan.tglPengerjaanMax;
  if (deadline == null || pesanan.estimasiPengerjaan <= 0) return null;

  final remaining = deadline.difference(DateTime.now());
  final threshold = Duration(hours: pesanan.estimasiPengerjaan) * 0.25;

  if (remaining > threshold) return null;
  return remaining; // bisa negatif -- formatRemainingDeadline menanganinya
}

/// "2 hari 3 jam lagi" / "45 menit lagi" / "Waktu pengerjaan telah habis".
String formatRemainingDeadline(Duration remaining) {
  if (remaining.isNegative || remaining == Duration.zero) {
    return 'Waktu pengerjaan telah habis';
  }

  final days = remaining.inDays;
  final hours = remaining.inHours % 24;
  final minutes = remaining.inMinutes % 60;

  if (days > 0) {
    return hours > 0 ? '$days hari $hours jam lagi' : '$days hari lagi';
  }
  if (remaining.inHours > 0) {
    return minutes > 0
        ? '${remaining.inHours} jam $minutes menit lagi'
        : '${remaining.inHours} jam lagi';
  }
  return '$minutes menit lagi';
}
