import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Menghasilkan string device deskriptif untuk dicatat sebagai lokasi
/// persetujuan dokumen legal (field `*_Loc`).
///
/// Serial hardware asli tidak bisa diakses di Android 10+ / iOS modern,
/// jadi dipakai identifier terdekat yang tersedia (`id` / `identifierForVendor`).
class DeviceInfoHelper {
  static String? _cached;

  static Future<String> describe() async {
    if (_cached != null) return _cached!;

    try {
      final plugin = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        _cached = '${info.manufacturer} ${info.model} '
            '| Android ${info.version.release} | id: ${info.id}';
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        _cached = '${info.name} ${info.model} '
            '| iOS ${info.systemVersion} '
            '| id: ${info.identifierForVendor ?? '-'}';
      } else {
        _cached = 'unknown device (${Platform.operatingSystem})';
      }
    } catch (e) {
      // Jangan sampai gagal baca device menggagalkan proses persetujuan.
      debugPrint('[DeviceInfo] Gagal baca info device: $e');
      _cached = 'unknown device';
    }

    return _cached!;
  }
}
