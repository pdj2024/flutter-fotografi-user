import 'package:flutter/material.dart';

class Constants {
  // ── Versi Aplikasi ────────────────────────────────────────────
  // Ketiga nilai ini dibandingkan dengan data dari server.
  // Update nilai ini setiap kali ada perubahan yang membutuhkan
  // versi minimum tertentu.

  /// Versi app customer (index 0 dari "customer_ver, vendor_ver")
  static const String versionApp = '1.0.3';

  /// Versi API minimum yang kompatibel dengan app ini
  static const String versionApi = '1.0.0';

  /// Versi database minimum yang kompatibel dengan app ini
  static const String versionDatabase = '1.0.0';

  // ── Warna ─────────────────────────────────────────────────────
  static const Color primaryColor = Color(0xff3b3add);
  static const Color primaryColorVendor = Color(0xff3b3add);

  // ── Role ──────────────────────────────────────────────────────
  static const String customer = 'customer';
  static const String vendor = 'vendor';

  // ── URL ───────────────────────────────────────────────────────
  static const String baseUrl = 'https://fotoapi1.padajaya.biz.id';

  // ── Play Store ────────────────────────────────────────────────
  /// URL Play Store untuk halaman update app customer
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=app.pacificdatajaya.fotograficustomer';
}
