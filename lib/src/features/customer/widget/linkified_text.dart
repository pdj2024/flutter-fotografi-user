// ignore_for_file: prefer_interpolation_to_compose_strings
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/features/customer/view/history/webview_page.dart';

/// Daftar TLD yang dikenali untuk domain TANPA skema/"www." (mis. user
/// menulis langsung "pictmax.com" atau "drive.google.com/file/..."). Dibatasi
/// ke TLD yang realistis dipakai (termasuk shortlink umum seperti goo.gl,
/// bit.ly) supaya tidak salah menandai kalimat biasa yang kebetulan
/// mengandung titik (mis. "Dr.John", "5.30") sebagai link.
const String _bareDomainTlds = '(?:com|net|org|id|co|io|me|info|biz|xyz|'
    'link|app|dev|ai|site|online|store|shop|gl|ly|tv|to|cloud|photo|photos|'
    'pics|pictures)';

/// Regex praktis untuk mendeteksi URL di dalam teks bebas — baik yang
/// memakai skema eksplisit ("https://..."), diawali "www.", MAUPUN domain
/// polos tanpa keduanya (mis. "pictmax.com" atau "drive.google.com/xyz").
final RegExp _urlPattern = RegExp(
  r'((https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z]{2,24}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)'
  r'|\b(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+' +
      _bareDomainTlds +
      r'\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?',
  caseSensitive: false,
);

/// Menampilkan [text] sebagai teks biasa, tapi setiap URL yang terdeteksi
/// dijadikan tautan yang bisa ditekan. Tidak pernah membuka webview
/// langsung — selalu lewat [openLinkSafely] supaya user melihat dulu
/// tujuan link sebenarnya sebelum halaman dibuka. Ini penting karena
/// pesan Complain bisa ditulis siapa saja (customer/vendor/admin), jadi
/// tautan di dalamnya tidak bisa otomatis dipercaya.
class LinkifiedText extends StatelessWidget {
  const LinkifiedText({
    super.key,
    required this.text,
    this.style,
    this.linkColor,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final Color? linkColor;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        style ?? const TextStyle(fontSize: 14, color: Colors.black87);
    final matches = _urlPattern.allMatches(text).toList();

    if (matches.isEmpty) {
      return Text(text,
          style: baseStyle, maxLines: maxLines, overflow: overflow);
    }

    final spans = <InlineSpan>[];
    int cursor = 0;
    for (final m in matches) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start)));
      }
      final raw = m.group(0)!;
      spans.add(TextSpan(
        text: raw,
        style: TextStyle(
          color: linkColor ?? Constants.primaryColor,
          decoration: TextDecoration.underline,
          decorationColor: linkColor ?? Constants.primaryColor,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => openLinkSafely(context, raw),
      ));
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}

class _LinkCheck {
  const _LinkCheck({required this.allowed, this.warning});
  final bool allowed;
  final String? warning;
}

final RegExp _ipHostPattern = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');

_LinkCheck _checkLink(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') {
    return const _LinkCheck(
      allowed: false,
      warning: 'Skema tautan ini tidak didukung dan tidak bisa dibuka.',
    );
  }
  if (uri.host.isEmpty) {
    return const _LinkCheck(allowed: false, warning: 'Tautan tidak valid.');
  }
  if (uri.userInfo.isNotEmpty) {
    return const _LinkCheck(
      allowed: false,
      warning:
          'Tautan mencurigakan: menyembunyikan info login di dalam alamatnya.',
    );
  }
  if (_ipHostPattern.hasMatch(uri.host)) {
    return const _LinkCheck(
      allowed: true,
      warning:
          'Tautan ini menuju alamat IP langsung, bukan nama domain. Berhati-hatilah.',
    );
  }
  if (uri.host.contains('xn--')) {
    return const _LinkCheck(
      allowed: true,
      warning:
          'Nama domain mengandung karakter internasional yang bisa menyerupai domain lain.',
    );
  }
  return const _LinkCheck(allowed: true);
}

/// Normalisasi teks link mentah dari pesan (bisa tanpa skema, mis.
/// "www.contoh.com") menjadi URL yang valid untuk dibuka.
Uri? _normalizeLink(String raw) {
  var value = raw.trim();
  if (!value.toLowerCase().startsWith('http://') &&
      !value.toLowerCase().startsWith('https://')) {
    value = 'https://$value';
  }
  try {
    final uri = Uri.parse(value);
    return uri.host.isEmpty ? null : uri;
  } catch (_) {
    return null;
  }
}

/// Satu-satunya jalur untuk membuka link dari pesan Complain: selalu lewat
/// pengecekan skema/host, lalu dialog konfirmasi yang menampilkan tujuan
/// sebenarnya, supaya user tidak asal menekan tautan dari pesan yang bisa
/// ditulis siapa saja di thread ini.
Future<void> openLinkSafely(BuildContext context, String rawUrl) async {
  final uri = _normalizeLink(rawUrl);
  if (uri == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Tautan tidak valid.')));
    return;
  }

  final check = _checkLink(uri);
  if (!check.allowed) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(check.warning ?? 'Tautan tidak bisa dibuka.')),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: const Color(0xfff9f9f9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                check.warning != null
                    ? Icons.warning_amber_rounded
                    : Icons.open_in_new_rounded,
                size: 48,
                color:
                    check.warning != null ? Colors.orange : Constants.primaryColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'Buka Tautan?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tautan ini berasal dari pesan pengguna lain. Pastikan Anda '
                'mengenali dan mempercayai sumbernya sebelum membukanya.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded,
                        size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        uri.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (check.warning != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          check.warning!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Buka',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  if (confirmed == true && context.mounted) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WebviewPage(url: uri.toString()),
    ));
  }
}
