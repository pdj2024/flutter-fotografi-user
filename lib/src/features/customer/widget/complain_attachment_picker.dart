import 'package:image_picker/image_picker.dart';
import 'package:mpjnew/src/core/utils/attachment_compressor.dart';

/// Batas jumlah lampiran per pesan Complain.
const int kMaxComplainAttachments = 5;

/// Hasil satu sesi pilih lampiran. Sengaja tidak menyentuh BuildContext —
/// tiap halaman yang menampilkan pesannya sendiri.
class AttachmentPickResult {
  /// Gambar yang lolos: sudah dikompres dan siap upload.
  final List<PreparedAttachment> accepted;

  /// Nama file yang tidak bisa ditekan sampai di bawah batas ukuran.
  final List<String> rejectedTooLarge;

  /// Jumlah gambar yang dibuang karena melewati kuota slot.
  final int rejectedOverflow;

  /// Galeri gagal dibuka.
  final Object? error;

  const AttachmentPickResult({
    this.accepted = const [],
    this.rejectedTooLarge = const [],
    this.rejectedOverflow = 0,
    this.error,
  });
}

/// Buka galeri, kompres tiap gambar, dan tolak yang tidak memenuhi syarat —
/// semuanya SEBELUM user menekan Kirim.
Future<AttachmentPickResult> pickComplainAttachments({
  required int currentCount,
  int max = kMaxComplainAttachments,
}) async {
  final remaining = max - currentCount;
  if (remaining <= 0) {
    return const AttachmentPickResult(rejectedOverflow: 1);
  }

  final List<XFile> picked;
  try {
    picked = await ImagePicker().pickMultiImage(limit: remaining);
  } catch (e) {
    return AttachmentPickResult(error: e);
  }
  if (picked.isEmpty) return const AttachmentPickResult();

  // `limit` baru dihormati Android 13+/iOS 14+, jadi tetap potong sendiri.
  final selected = picked.take(remaining).toList();

  final accepted = <PreparedAttachment>[];
  final rejectedTooLarge = <String>[];
  for (final file in selected) {
    final prepared = await AttachmentCompressor.prepare(file);
    if (prepared == null) {
      rejectedTooLarge.add(file.name);
    } else {
      accepted.add(prepared);
    }
  }

  return AttachmentPickResult(
    accepted: accepted,
    rejectedTooLarge: rejectedTooLarge,
    rejectedOverflow: picked.length - selected.length,
  );
}

/// Satu pesan feedback untuk hasil pilih — null kalau semuanya mulus.
/// Dipakai bersama supaya teksnya tidak berbeda-beda antar halaman.
String? attachmentPickMessage(AttachmentPickResult result,
    {int max = kMaxComplainAttachments}) {
  if (result.error != null) return 'Gagal membuka galeri: ${result.error}';
  if (result.rejectedTooLarge.isNotEmpty) {
    return 'Gambar terlalu besar (maks 2MB): '
        '${result.rejectedTooLarge.join(", ")}';
  }
  if (result.rejectedOverflow > 0) return 'Maksimal $max lampiran per pesan';
  return null;
}
