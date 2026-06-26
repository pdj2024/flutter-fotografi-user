// ═══════════════════════════════════════════════════════════════
// DEFAULT VALUE MODELS
// ═══════════════════════════════════════════════════════════════

/// Data PPN, biaya platform, dan konfigurasi app
class PpnModel {
  final int ppn; // % PPN (0 = tidak ada PPN)
  final bool inclPpn; // true = harga input sudah termasuk PPN
  final double platform; // % biaya platform

  const PpnModel({
    required this.ppn,
    required this.inclPpn,
    required this.platform,
  });

  factory PpnModel.fromJson(Map<String, dynamic> json) {
    return PpnModel(
      ppn: (json['Ppn'] as num?)?.toInt() ?? 0,
      inclPpn: json['Incl_Ppn'] as bool? ?? false,
      platform: (json['Platform'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Apakah PPN berlaku
  bool get hasPpn => ppn > 0;

  /// Hitung estimasi pendapatan vendor dari harga yang diinput.
  ///
  /// [harga]    — harga paket dari penawaran
  /// [adminFee] — biaya metode pembayaran (gateway fee), default 0
  ///
  /// ── INCL. PPN (inclPpn = true) ─────────────────────────────
  ///   Harga input sudah termasuk PPN.
  ///
  ///   Rumus:
  ///     DPP Paket    = Harga ÷ (1 + Rate/100)
  ///     PPN Paket    = Harga - DPP Paket
  ///     DPP Admin    = Admin Fee ÷ (1 + Rate/100)
  ///     PPN Admin    = Admin Fee - DPP Admin
  ///     Total PPN    = PPN Paket + PPN Admin
  ///     Platform Fee = DPP Paket × Rate Platform / 100
  ///     Bersih       = DPP Paket - Platform Fee
  ///     Total Bayar  = Harga + Admin Fee  (keduanya sudah incl PPN)
  ///
  /// ── EXCL. PPN (inclPpn = false) ────────────────────────────
  ///   Harga input = DPP (belum termasuk PPN).
  ///   PPN dihitung dari (DPP paket + admin fee) dan ditanggung customer.
  ///
  ///   Rumus:
  ///     DPP Total    = Harga + Admin Fee
  ///     PPN          = DPP Total × Rate / 100
  ///     Platform Fee = Harga × Rate Platform / 100
  ///     Bersih       = Harga - Platform Fee
  ///     Total Bayar  = Harga + Admin Fee + PPN
  EstimasiBiaya hitungEstimasi(int harga, {int adminFee = 0}) {
    if (hasPpn && inclPpn) {
      // ── INCL. PPN ────────────────────────────────────────────

      // DPP & PPN dari harga paket
      final dppPaketRaw = harga / (1 + ppn / 100);
      final dppPaket = dppPaketRaw.round();
      final ppnPaket = harga - dppPaket;

      // DPP & PPN dari admin fee (admin fee juga incl PPN)
      final dppAdminRaw = adminFee / (1 + ppn / 100);
      final dppAdmin = dppAdminRaw.round();
      final ppnAdmin = adminFee - dppAdmin;

      // Total PPN
      final totalPpn = ppnPaket + ppnAdmin;

      // Platform fee dari DPP paket saja (bukan dari admin)
      final biayaPlatform = (dppPaket * platform / 100).round();

      // Pendapatan bersih vendor
      final bersih = dppPaket - biayaPlatform;

      // Total bayar customer = harga + admin (keduanya sudah incl PPN)
      final totalCustomer = harga + adminFee;

      return EstimasiBiaya(
        hargaDasar: harga,
        dpp: dppPaket,
        biayaPpn: totalPpn,
        ppnPaket: ppnPaket,
        ppnAdmin: ppnAdmin,
        biayaAdmin: adminFee,
        biayaPlatform: biayaPlatform,
        inclPpn: true,
        ppnPersen: ppn,
        platformPersen: platform,
        totalCustomer: totalCustomer,
        pendapatanBersih: bersih,
      );
    } else if (hasPpn && !inclPpn) {
      // ── EXCL. PPN ────────────────────────────────────────────

      // DPP = harga input (belum termasuk PPN)
      final dpp = harga;

      // PPN dihitung dari (DPP paket + admin fee)
      // Keduanya belum termasuk PPN, jadi PPN ditambahkan di atas
      final dppTotal = dpp + adminFee;
      final totalPpn = (dppTotal * ppn / 100).round();

      // Breakdown PPN per komponen (untuk transparansi)
      final ppnPaket = (dpp * ppn / 100).round();
      final ppnAdmin = totalPpn - ppnPaket;

      // Total yang dibayar customer
      final totalCustomer = dpp + adminFee + totalPpn;

      // Biaya platform dari DPP paket saja
      final biayaPlatform = (dpp * platform / 100).round();

      // Pendapatan bersih vendor (PPN tidak mengurangi)
      final bersih = dpp - biayaPlatform;

      return EstimasiBiaya(
        hargaDasar: harga,
        dpp: dpp,
        biayaPpn: totalPpn,
        ppnPaket: ppnPaket,
        ppnAdmin: ppnAdmin,
        biayaAdmin: adminFee,
        biayaPlatform: biayaPlatform,
        inclPpn: false,
        ppnPersen: ppn,
        platformPersen: platform,
        totalCustomer: totalCustomer,
        pendapatanBersih: bersih,
      );
    } else {
      // ── TANPA PPN ─────────────────────────────────────────────

      final biayaPlatform = (harga * platform / 100).round();
      final bersih = harga - biayaPlatform;
      final totalCustomer = harga + adminFee;

      return EstimasiBiaya(
        hargaDasar: harga,
        dpp: harga,
        biayaPpn: 0,
        ppnPaket: 0,
        ppnAdmin: 0,
        biayaAdmin: adminFee,
        biayaPlatform: biayaPlatform,
        inclPpn: false,
        ppnPersen: 0,
        platformPersen: platform,
        totalCustomer: totalCustomer,
        pendapatanBersih: bersih,
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// ESTIMASI BIAYA
// ═══════════════════════════════════════════════════════════════

/// Hasil kalkulasi estimasi biaya dari harga penawaran.
///
/// Contoh — Harga Rp 3.500.000, Admin Fee Rp 4.000, PPN 11%, Platform 5%:
///
///   EXCL. PPN:
///     DPP Paket        = Rp 3.500.000
///     Admin Fee        = Rp 4.000
///     DPP Total        = Rp 3.504.000
///     PPN (11%)        = Rp 385.440  (dari DPP Total)
///       - PPN Paket    = Rp 385.000
///       - PPN Admin    = Rp 440
///     Total Customer   = 3.500.000 + 4.000 + 385.440 = Rp 3.889.440
///     Platform Fee (5%)= Rp 175.000  (dari DPP Paket saja)
///     Pendapatan Bersih= Rp 3.325.000
class EstimasiBiaya {
  /// Harga yang diinput vendor
  final int hargaDasar;

  /// DPP — Dasar Pengenaan Pajak (dari harga paket saja)
  final int dpp;

  /// Total nilai PPN (paket + admin)
  final int biayaPpn;

  /// PPN dari harga paket saja
  final int ppnPaket;

  /// PPN dari biaya admin saja
  final int ppnAdmin;

  /// Biaya admin (gateway fee), sebelum PPN
  final int biayaAdmin;

  /// Biaya platform = DPP × rate platform
  final int biayaPlatform;

  final bool inclPpn;
  final int ppnPersen;
  final double platformPersen;

  /// Total yang dibayar customer (sudah termasuk PPN + admin)
  final int totalCustomer;

  /// Pendapatan bersih vendor = DPP - biayaPlatform
  final int pendapatanBersih;

  const EstimasiBiaya({
    required this.hargaDasar,
    required this.dpp,
    required this.biayaPpn,
    required this.ppnPaket,
    required this.ppnAdmin,
    required this.biayaAdmin,
    required this.biayaPlatform,
    required this.inclPpn,
    required this.ppnPersen,
    required this.platformPersen,
    required this.totalCustomer,
    required this.pendapatanBersih,
  });

  bool get hasPpn => ppnPersen > 0;
}

// ═══════════════════════════════════════════════════════════════
// APP CONFIG MODEL
// ═══════════════════════════════════════════════════════════════

/// Konfigurasi umum aplikasi: Chat_Help & Batas_Revisi
class AppConfigModel {
  /// Teks pesan default untuk WA customer service
  final String chatHelp;

  /// Batas revisi default saat vendor membuat paket baru
  final int batasRevisi;

  const AppConfigModel({
    required this.chatHelp,
    required this.batasRevisi,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      chatHelp: json['Chat_Help'] as String? ?? 'Hai',
      batasRevisi: (json['Batas_Revisi'] as num?)?.toInt() ?? 3,
    );
  }

  static const AppConfigModel fallback = AppConfigModel(
    chatHelp: 'Hai',
    batasRevisi: 3,
  );
}

// ═══════════════════════════════════════════════════════════════
// VERSION MODEL
// ═══════════════════════════════════════════════════════════════

/// Data versi aplikasi, database, dan API
class VersionModel {
  final String versionApp;
  final String versionAppCustomer;
  final String versionAppVendor;
  final String versionDatabase;
  final String versionApi;
  final String linkPlaystoreCustomer;
  final String linkPlaystoreVendor;

  const VersionModel({
    required this.versionApp,
    required this.versionAppCustomer,
    required this.versionAppVendor,
    required this.versionDatabase,
    required this.versionApi,
    required this.linkPlaystoreCustomer,
    required this.linkPlaystoreVendor,
  });

  factory VersionModel.fromJson(Map<String, dynamic> json) {
    return VersionModel(
      versionApp: json['Version_App'] as String? ?? '',
      versionAppCustomer: json['Version_App_Customer'] as String? ?? '',
      versionAppVendor: json['Version_App_Vendor'] as String? ?? '',
      versionDatabase: json['Version_Database'] as String? ?? '',
      versionApi: json['Version_Api'] as String? ?? '',
      linkPlaystoreCustomer: json['Link_Playstore_Customer'] as String? ?? '',
      linkPlaystoreVendor: json['Link_Playstore_Vendor'] as String? ?? '',
    );
  }
}