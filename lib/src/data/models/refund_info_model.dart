/// Hasil perhitungan refund dari server untuk SATU pesanan
/// (`GET /order/info-refund`). Semua nominal & tier sudah dihitung backend —
/// app hanya menampilkan, tidak menghitung ulang.
class RefundInfoModel {
  final DateTime? jamServer;
  final DateTime? tglRealisasi;

  /// Sisa jam menuju tglRealisasi, dihitung terhadap jam server (bukan jam
  /// device) — bisa pecahan, bisa negatif kalau sudah lewat.
  final double jamRemain;

  final String idPesanan;
  final String noTrackingPesanan;

  /// Tier refund yang berlaku. Padanannya `No_Id` di master refund
  /// (`MasRefund/getAll`) — di sana bertipe String, di sini int.
  final int idRefund;
  final int jamLimit;
  final double persen;
  final String keterangan;

  final num refundTotal;

  /// Nominal yang diterima customer — ini yang ditampilkan ke user.
  final num refundCustomer;
  final num refundVendor;

  /// False = customer tidak mendapat pengembalian (tier 0%) — pembatalan
  /// langsung dieksekusi, tanpa form rekening.
  bool get adaDanaKembali => refundCustomer > 0;

  RefundInfoModel({
    this.jamServer,
    this.tglRealisasi,
    this.jamRemain = 0,
    this.idPesanan = '',
    this.noTrackingPesanan = '',
    this.idRefund = 0,
    this.jamLimit = 0,
    this.persen = 0,
    this.keterangan = '',
    this.refundTotal = 0,
    this.refundCustomer = 0,
    this.refundVendor = 0,
  });

  factory RefundInfoModel.fromJson(Map<String, dynamic> json) {
    return RefundInfoModel(
      jamServer: DateTime.tryParse(json['Jam_Server']?.toString() ?? ''),
      tglRealisasi: DateTime.tryParse(json['Tgl_Realisasi']?.toString() ?? ''),
      jamRemain: (json['Jam_Remain'] as num?)?.toDouble() ?? 0,
      idPesanan: json['Id_Pesanan']?.toString() ?? '',
      noTrackingPesanan: json['No_Tracking_Pesanan']?.toString() ?? '',
      idRefund: (json['Id_Refund'] as num?)?.toInt() ?? 0,
      jamLimit: (json['Jam_Limit'] as num?)?.toInt() ?? 0,
      persen: (json['Persen'] as num?)?.toDouble() ?? 0,
      keterangan: json['Keterangan']?.toString() ?? '',
      refundTotal: (json['Refund_Total'] as num?) ?? 0,
      refundCustomer: (json['Refund_Customer'] as num?) ?? 0,
      refundVendor: (json['Refund_Vendor'] as num?) ?? 0,
    );
  }
}
