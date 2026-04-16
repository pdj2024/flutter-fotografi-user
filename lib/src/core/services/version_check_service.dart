import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/default_value_service.dart';
import 'package:mpjnew/src/data/models/default_value_model.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionCheckService {
  final DefaultValueService _defaultValueService = DefaultValueService();

  Future<VersionCheckResult> checkVersion() async {
    try {
      final serverVersion = await _defaultValueService.getVersionApp();
      return _compare(serverVersion);
    } catch (e) {
      debugPrint('[VersionCheck] Gagal fetch versi: $e');
      // Jika gagal fetch, anggap kompatibel agar app tetap bisa dibuka
      return VersionCheckResult.compatible();
    }
  }

  /// Bandingkan versi lokal dengan versi server.
  VersionCheckResult _compare(VersionModel server) {
    // Gunakan Version_App_Customer (field khusus customer)
    final serverAppVersion = server.versionAppCustomer.trim();

    final incompatibilities = <_VersionMismatch>[];

    // Cek Version_App_Customer
    if (serverAppVersion.isNotEmpty &&
        _isServerNewer(Constants.versionApp, serverAppVersion)) {
      incompatibilities.add(_VersionMismatch(
        label: 'Versi Aplikasi',
        local: Constants.versionApp,
        server: serverAppVersion,
      ));
    }

    // Cek Version_Api
    if (_isServerNewer(Constants.versionApi, server.versionApi)) {
      incompatibilities.add(_VersionMismatch(
        label: 'Versi API',
        local: Constants.versionApi,
        server: server.versionApi,
      ));
    }

    // Cek Version_Database
    if (_isServerNewer(Constants.versionDatabase, server.versionDatabase)) {
      incompatibilities.add(_VersionMismatch(
        label: 'Versi Database',
        local: Constants.versionDatabase,
        server: server.versionDatabase,
      ));
    }

    if (incompatibilities.isEmpty) {
      debugPrint('[VersionCheck] ✅ Semua versi kompatibel');
      return VersionCheckResult.compatible();
    }

    for (final m in incompatibilities) {
      debugPrint(
          '[VersionCheck] ⚠️ ${m.label} tidak kompatibel — lokal: ${m.local}, server: ${m.server}');
    }

    return VersionCheckResult.incompatible(
      incompatibilities,
      linkPlaystore: server.linkPlaystoreCustomer,
    );
  }

  /// Kembalikan true jika versi server LEBIH BARU dari versi lokal.
  /// Format: MAJOR.MINOR.PATCH
  bool _isServerNewer(String local, String server) {
    try {
      final l = _parse(local);
      final s = _parse(server);

      for (int i = 0; i < 3; i++) {
        if (s[i] > l[i]) return true;
        if (s[i] < l[i]) return false;
      }
      return false; // sama persis → kompatibel
    } catch (e) {
      debugPrint(
          '[VersionCheck] Gagal parse versi lokal="$local" server="$server": $e');
      return false;
    }
  }

  List<int> _parse(String version) {
    final parts = version.trim().split('.');
    return List.generate(
        3, (i) => i < parts.length ? int.tryParse(parts[i]) ?? 0 : 0);
  }

  // ── Dialog ───────────────────────────────────────────────────

  /// Tampilkan dialog update jika ada ketidakcocokan versi.
  /// Dialog tidak bisa di-dismiss (barrierDismissible: false).
  static Future<void> showUpdateDialogIfNeeded(
    BuildContext context,
    VersionCheckResult result,
  ) async {
    if (result.isCompatible) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UpdateDialog(result: result),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HASIL CEK VERSI
// ═══════════════════════════════════════════════════════════════

class VersionCheckResult {
  final bool isCompatible;
  final List<_VersionMismatch> mismatches;
  final String linkPlaystore;

  const VersionCheckResult._({
    required this.isCompatible,
    required this.mismatches,
    this.linkPlaystore = '',
  });

  factory VersionCheckResult.compatible() =>
      const VersionCheckResult._(isCompatible: true, mismatches: []);

  factory VersionCheckResult.incompatible(
    List<_VersionMismatch> mismatches, {
    String linkPlaystore = '',
  }) =>
      VersionCheckResult._(
        isCompatible: false,
        mismatches: mismatches,
        linkPlaystore: linkPlaystore,
      );
}

class _VersionMismatch {
  final String label;
  final String local;
  final String server;

  const _VersionMismatch({
    required this.label,
    required this.local,
    required this.server,
  });
}

// ═══════════════════════════════════════════════════════════════
// UPDATE DIALOG
// ═══════════════════════════════════════════════════════════════

class _UpdateDialog extends StatelessWidget {
  final VersionCheckResult result;

  const _UpdateDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Cegah user menutup dialog dengan tombol back
      canPop: false,
      child: AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.system_update_rounded,
                  color: Colors.orange.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Pembaruan Tersedia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aplikasi Anda perlu diperbarui untuk melanjutkan penggunaan.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // Detail versi yang tidak kompatibel
            ...result.mismatches.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.red.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Lokal: ${m.local}  →  Terbaru: ${m.server}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          // Tombol Update — buka Play Store
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openPlayStore(),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text(
                'Update di Play Store',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff3b3add),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Tombol Keluar — tutup aplikasi
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _closeApp(),
              icon: const Icon(Icons.exit_to_app, size: 18),
              label: const Text(
                'Keluar dari Aplikasi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPlayStore() async {
    // Gunakan link dari server, fallback ke Constants jika kosong
    final url = result.linkPlaystore.isNotEmpty
        ? result.linkPlaystore
        : Constants.playStoreUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('[VersionCheck] Gagal buka Play Store: $url');
    }
  }

  void _closeApp() {
    // Tutup app secara paksa — cross-platform safe
    if (Platform.isAndroid) {
      SystemNavigator.pop(); // Android: pop dari task stack
    } else {
      exit(0); // iOS / lainnya
    }
  }
}
