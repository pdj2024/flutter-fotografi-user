import 'dart:io';

import 'package:flutter/foundation.dart';
// XFile & Uint8List ikut dari sini (keduanya bersumber dari cross_file /
// typed_data yang sama dengan image_picker).
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

/// Satu lampiran yang sudah siap di-upload — hidup sepenuhnya di memory.
/// Hasil kompresi sengaja TIDAK ditulis ke storage.
@immutable
class PreparedAttachment {
  /// Bytes yang benar-benar di-PUT ke signed URL.
  final Uint8List bytes;

  /// Nama file dengan ekstensi yang sudah menyesuaikan hasil kompresi.
  final String fileName;

  /// Ekstensi berikut titiknya ('.jpg') — mengikuti kontrak `reqMediaURL`
  /// yang selama ini dikirimi hasil `p.extension(...)`.
  final String extension;

  final String contentType;

  /// Ukuran file asli sebelum kompresi — untuk log/telemetri saja.
  final int originalSize;

  const PreparedAttachment({
    required this.bytes,
    required this.fileName,
    required this.extension,
    required this.contentType,
    required this.originalSize,
  });

  /// Ukuran yang benar-benar diunggah.
  int get size => bytes.length;
}

/// Menyiapkan gambar hasil pilih user untuk di-upload: resize + re-encode
/// JPEG sampai muat batas ukuran, tanpa menulis file baru ke storage.
///
/// JPEG dipakai di kedua platform karena itu satu-satunya format lossy yang
/// bisa di-encode Android maupun iOS lewat `flutter_image_compress` (WebP
/// hanya didukung Android). Turunan WebP untuk konsumsi web dibuat server.
class AttachmentCompressor {
  AttachmentCompressor._();

  /// Batas ukuran per lampiran.
  static const int maxBytes = 2 * 1024 * 1024;

  /// Di bawah ambang ini gambar dipakai apa adanya — re-encode hanya
  /// membuang kualitas tanpa manfaat ukuran yang berarti.
  static const int _passThroughBytes = 512 * 1024;

  /// `[sisi terpendek minimum, quality]`, dicoba berurutan sampai muat.
  /// Foto HP normal selesai di baris pertama.
  static const List<List<int>> _ladder = [
    [1600, 80],
    [1600, 65],
    [1280, 60],
    [1024, 50],
    [720, 45],
  ];

  static const Map<String, String> _knownImageTypes = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp',
  };

  static bool get _isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Kompres [picked] sampai muat [maxBytes].
  ///
  /// Mengembalikan `null` kalau gambar tidak bisa ditekan — pemanggil
  /// menolaknya saat user memilih, bukan setelah menekan Kirim.
  static Future<PreparedAttachment?> prepare(XFile picked) async {
    final originalSize = await picked.length();
    final ext = p.extension(picked.path).toLowerCase();
    final baseName = p.basenameWithoutExtension(picked.path);

    // Desktop/web tidak punya implementasi native plugin ini. Jangan sampai
    // MissingPluginException — cukup validasi ukuran apa adanya.
    if (!_isMobile) {
      final contentType = _knownImageTypes[ext];
      if (contentType == null) return null;
      final bytes = await picked.readAsBytes();
      if (bytes.length > maxBytes) return null;
      return PreparedAttachment(
        bytes: bytes,
        fileName: '$baseName$ext',
        extension: ext,
        contentType: contentType,
        originalSize: originalSize,
      );
    }

    // Sudah kecil dan formatnya dikenal -> lewati kompresi.
    final passThroughType = _knownImageTypes[ext];
    if (originalSize <= _passThroughBytes && passThroughType != null) {
      final bytes = await picked.readAsBytes();
      return PreparedAttachment(
        bytes: bytes,
        fileName: '$baseName$ext',
        extension: ext,
        contentType: passThroughType,
        originalSize: originalSize,
      );
    }

    for (final step in _ladder) {
      try {
        final out = await FlutterImageCompress.compressWithFile(
          picked.path,
          minWidth: step[0],
          minHeight: step[0],
          quality: step[1],
          format: CompressFormat.jpeg,
          keepExif: false, // buang GPS & metadata lain
          autoCorrectionAngle: true, // tanpa ini foto portrait ter-upload miring
        );
        // Decoder gagal — anak tangga berikutnya tidak akan menolong.
        if (out == null) break;
        if (out.length <= maxBytes) {
          return PreparedAttachment(
            bytes: out,
            fileName: '$baseName.jpg',
            extension: '.jpg',
            contentType: 'image/jpeg',
            originalSize: originalSize,
          );
        }
      } catch (e) {
        debugPrint('[AttachmentCompressor] gagal kompres ${picked.name}: $e');
        break;
      }
    }

    return null;
  }
}
