import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Jalankan [fn] sekarang, atau setelah frame ini kalau sedang fase build.
///
/// Listener ImageStream dipanggil SINKRON kalau gambarnya sudah ada di cache —
/// bisa terjadi di tengah build widget lain (mis. saat halaman baru dibuka dan
/// me-resolve gambar yang sama). setState di situ melempar error yang lalu
/// dilaporkan ke SEMUA listener gambar tersebut, sehingga Image menampilkan
/// errorBuilder ("Gagal memuat gambar") padahal gambarnya baik-baik saja.
void runOutsideBuild(VoidCallback fn) {
  if (SchedulerBinding.instance.schedulerPhase ==
      SchedulerPhase.persistentCallbacks) {
    SchedulerBinding.instance.addPostFrameCallback((_) => fn());
  } else {
    fn();
  }
}

/// Warna latar saat gambar belum siap — kotak polos seperti Instagram,
/// bukan shimmer.
const Color kImagePlaceholderColor = Color(0xFFEFEFEF);

// Parameter tanda tangan signed URL (GCS/S3/CloudFront). Nilainya berubah
// setiap kali backend membuat ulang URL, padahal objek gambarnya sama.
const _signingParamPrefixes = ['x-goog-', 'x-amz-'];
const _signingParams = {
  'expires',
  'signature',
  'googleaccessid',
  'policy',
  'key-pair-id',
  'token',
};

/// Kunci cache yang tetap sama walau signed URL-nya diperbarui.
///
/// Media dari API berupa signed URL ber-expiry: setiap fetch list mengembalikan
/// query string baru untuk gambar yang SAMA. Tanpa kunci stabil, cache memori
/// dan disk selalu miss → gambar didownload ulang tiap refresh/scroll balik.
/// Hanya parameter tanda tangan yang dibuang; parameter lain (yang mungkin
/// memang menentukan gambar mana) dipertahankan, jadi dua gambar berbeda
/// tidak mungkin berbagi kunci.
String stableImageKey(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasQuery) return url;
  final kept = Map.of(uri.queryParameters)
    ..removeWhere((k, _) {
      final key = k.toLowerCase();
      return _signingParams.contains(key) ||
          _signingParamPrefixes.any(key.startsWith);
    });
  // replace(queryParameters: null) justru MEMPERTAHANKAN query lama — kalau
  // semua parameter terbuang, susun ulang tanpa query.
  if (kept.isEmpty) return '${uri.scheme}://${uri.authority}${uri.path}';
  return uri.replace(queryParameters: kept).toString();
}

/// ImageProvider dengan cache disk + kunci stabil, untuk tempat yang butuh
/// provider langsung (precacheImage, ResizeImage, stream listener).
ImageProvider appImageProvider(String url, {int? decodeWidth}) {
  final ImageProvider provider =
      CachedNetworkImageProvider(url, cacheKey: stableImageKey(url));
  return decodeWidth == null
      ? provider
      : ResizeImage(provider, width: decodeWidth);
}

/// Muat semua gambar ke memori sekaligus dengan provider yang identik dengan
/// saat ditampilkan (lihat [appImageProvider]) — dipakai carousel post supaya
/// slide ke-2, ke-3, dst. sudah siap sebelum user swipe.
void precacheImages(
  BuildContext context,
  Iterable<String> urls, {
  required int decodeWidth,
}) {
  for (final url in urls) {
    if (url.isEmpty) continue;
    precacheImage(appImageProvider(url, decodeWidth: decodeWidth), context);
  }
}

/// Lebar decode = lebar tampil × pixel ratio. Mendecode gambar sebesar yang
/// benar-benar ditampilkan membuat jauh lebih banyak gambar muat di cache
/// memori, jadi gambar yang di-scroll lewat tidak cepat terbuang.
int decodeWidthFor(BuildContext context, double logicalWidth) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  return (logicalWidth * dpr).round().clamp(64, 1080);
}

/// Lebar decode gambar feed (selebar layar). Dipakai bersama oleh kartu feed
/// dan precache di splash supaya keduanya berbagi entri cache memori yang
/// sama — beda lebar decode = entri berbeda = decode ulang.
int feedDecodeWidth(BuildContext context) =>
    decodeWidthFor(context, MediaQuery.sizeOf(context).width);

/// Gambar jaringan standar app: cache disk, kunci stabil, langsung tampil
/// tanpa animasi fade, dan placeholder kotak polos (bukan shimmer).
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    required this.decodeWidth,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
  });

  final String url;

  /// Lebar decode dalam pixel fisik — pakai [decodeWidthFor].
  final int decodeWidth;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _error();
    return CachedNetworkImage(
      imageUrl: url,
      cacheKey: stableImageKey(url),
      memCacheWidth: decodeWidth,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      useOldImageOnUrlChange: true,
      placeholder: (_, __) => const ColoredBox(color: kImagePlaceholderColor),
      errorWidget: (_, __, ___) => _error(),
    );
  }

  Widget _error() =>
      errorWidget ??
      const ColoredBox(
        color: kImagePlaceholderColor,
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.black26),
        ),
      );
}
