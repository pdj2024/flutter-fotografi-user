// ═══════════════════════════════════════════════════════════════
// DEFAULT VALUE MODELS
// ═══════════════════════════════════════════════════════════════

/// Data PPN, biaya platform, dan konfigurasi app
class PpnModel {
  final int ppn;        // % PPN (0 = tidak ada PPN)
  final bool inclPpn;   // true = harga input sudah termasuk PPN
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
  /// ── INCL. PPN (inclPpn = true) ─────────────────────────────
  ///   Harga input sudah termasuk PPN. Vendor harus menyetorkan
  ///   PPN ke pemerintah, sehingga PPN mengurangi pendapatan.
  ///
  ///   Rumus:
  ///     DPP          = Harga ÷ (1 + Rate/100)
  ///     PPN          = Harga - DPP          ← lebih akurat dari Harga×Rate/(1+Rate)
  ///     Platform Fee = DPP × Rate Platform / 100
  ///     Bersih       = DPP - Platform Fee
  ///
  /// ── EXCL. PPN (inclPpn = false) ────────────────────────────
  ///   Harga input = DPP (belum termasuk PPN).
  ///   PPN ditambahkan di atas harga dan ditanggung customer.
  ///   Vendor menerima harga penuh → PPN tidak mengurangi pendapatan.
  ///
  ///   Rumus:
  ///     DPP          = Harga (itu sendiri)
  ///     PPN          = DPP × Rate / 100
  ///     Total Bayar  = DPP + PPN
  ///     Platform Fee = DPP × Rate Platform / 100
  ///     Bersih       = DPP - Platform Fee
  EstimasiBiaya hitungEstimasi(int harga) {
    if (hasPpn && inclPpn) {
      // ── INCL. PPN ────────────────────────────────────────────

      // Langkah 1: Hitung DPP (ekstrak dari dalam harga)
      // Gunakan double untuk presisi sebelum dibulatkan
      final dppRaw = harga / (1 + ppn / 100);
      final dpp = dppRaw.round();

      // Langkah 2: Hitung PPN
      // PPN = Harga - DPP  → lebih akurat karena tidak ada selisih pembulatan
      // DPP + PPN selalu = Harga
      final biayaPpn = harga - dpp;

      // Langkah 3: Hitung biaya platform dari DPP (bukan dari harga total)
      final biayaPlatform = (dpp * platform / 100).round();

      // Langkah 4: Pendapatan bersih vendor
      final bersih = dpp - biayaPlatform;

      return EstimasiBiaya(
        hargaDasar:       harga,
        dpp:              dpp,
        biayaPpn:         biayaPpn,
        biayaPlatform:    biayaPlatform,
        inclPpn:          true,
        ppnPersen:        ppn,
        platformPersen:   platform,
        totalCustomer:    harga, // customer bayar harga input saja
        pendapatanBersih: bersih,
      );
    } else if (hasPpn && !inclPpn) {
      // ── EXCL. PPN ────────────────────────────────────────────

      // Langkah 1: DPP = harga input (belum termasuk PPN)
      final dpp = harga;

      // Langkah 2: Hitung PPN yang ditanggung customer
      final biayaPpn = (dpp * ppn / 100).round();

      // Langkah 3: Total yang dibayar customer
      final totalCustomer = dpp + biayaPpn;

      // Langkah 4: Biaya platform dari DPP
      final biayaPlatform = (dpp * platform / 100).round();

      // Langkah 5: Pendapatan bersih vendor (PPN tidak mengurangi)
      final bersih = dpp - biayaPlatform;

      return EstimasiBiaya(
        hargaDasar:       harga,
        dpp:              dpp,
        biayaPpn:         biayaPpn,
        biayaPlatform:    biayaPlatform,
        inclPpn:          false,
        ppnPersen:        ppn,
        platformPersen:   platform,
        totalCustomer:    totalCustomer,
        pendapatanBersih: bersih,
      );
    } else {
      // ── TANPA PPN ─────────────────────────────────────────────

      final biayaPlatform = (harga * platform / 100).round();
      final bersih = harga - biayaPlatform;

      return EstimasiBiaya(
        hargaDasar:       harga,
        dpp:              harga,
        biayaPpn:         0,
        biayaPlatform:    biayaPlatform,
        inclPpn:          false,
        ppnPersen:        0,
        platformPersen:   platform,
        totalCustomer:    harga,
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
/// Contoh — Harga input Rp 3.500.000, PPN 11%, Platform 5%:
///
///   INCL. PPN:
///     DPP              = 3.500.000 ÷ 1,11  = Rp 3.153.153
///     PPN (11%)        = 3.500.000 - DPP   = Rp 346.847
///     Platform Fee (5%)= DPP × 5%          = Rp 157.658
///     Pendapatan Bersih= DPP - Platform Fee = Rp 2.995.495
///
///   EXCL. PPN:
///     DPP              = 3.500.000         = Rp 3.500.000
///     PPN (11%)        = DPP × 11%         = Rp 385.000   ← ditanggung customer
///     Total Customer   = DPP + PPN         = Rp 3.885.000
///     Platform Fee (5%)= DPP × 5%          = Rp 175.000
///     Pendapatan Bersih= DPP - Platform Fee = Rp 3.325.000
class EstimasiBiaya {
  /// Harga yang diinput vendor
  final int hargaDasar;

  /// DPP — Dasar Pengenaan Pajak
  /// Incl: harga ÷ (1 + rate)  |  Excl: harga itu sendiri
  final int dpp;

  /// Nilai PPN
  /// Incl: harga - dpp  |  Excl: dpp × rate  |  Tanpa PPN: 0
  final int biayaPpn;

  /// Biaya platform = DPP × rate platform
  final int biayaPlatform;

  final bool inclPpn;
  final int ppnPersen;
  final double platformPersen;

  /// Total yang dibayar customer
  /// Incl: = hargaDasar  |  Excl: = dpp + biayaPpn
  final int totalCustomer;

  /// Pendapatan bersih vendor = DPP - biayaPlatform
  final int pendapatanBersih;

  const EstimasiBiaya({
    required this.hargaDasar,
    required this.dpp,
    required this.biayaPpn,
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
// VERSION MODEL
// ═══════════════════════════════════════════════════════════════

/// Data versi aplikasi, database, dan API
class VersionModel {
  final String versionApp;
  final String versionDatabase;
  final String versionApi;

  const VersionModel({
    required this.versionApp,
    required this.versionDatabase,
    required this.versionApi,
  });

  factory VersionModel.fromJson(Map<String, dynamic> json) {
    return VersionModel(
      versionApp: json['Version_App'] as String? ?? '',
      versionDatabase: json['Version_Database'] as String? ?? '',
      versionApi: json['Version_Api'] as String? ?? '',
    );
  }
}