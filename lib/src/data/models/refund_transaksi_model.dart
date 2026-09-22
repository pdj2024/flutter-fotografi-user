/// Satu baris transaksi refund dari `GET /TransaksiRefund/getAll`.
///
/// `fromJson` sengaja tidak mungkin melempar — pemanggilnya (halaman detail
/// pesanan) harus tetap tampil walau satu baris datanya tidak lengkap.
class RefundTransaksiModel {
  final int? noId;
  final String idPesanan;

  /// Total pembayaran yang dibagi.
  final num nilai;

  /// Bagian yang dikembalikan ke customer.
  final num refundCust;

  /// Bagian yang menjadi hak vendor.
  final num refundVen;

  final DateTime? refundTime;

  /// 'refund' = dana sedang diproses, 'refund paid' = dana sudah dikembalikan.
  final String status;

  RefundTransaksiModel({
    this.noId,
    this.idPesanan = '',
    this.nilai = 0,
    this.refundCust = 0,
    this.refundVen = 0,
    this.refundTime,
    this.status = '',
  });

  bool get isPaid => status.toLowerCase().trim() == 'refund paid';
  bool get isProses => status.toLowerCase().trim() == 'refund';
  bool get adaDanaCustomer => refundCust > 0;

  factory RefundTransaksiModel.fromJson(Map<String, dynamic> json) {
    num angka(String key) => json[key] is num ? json[key] as num : 0;

    return RefundTransaksiModel(
      noId: (json['No_Id'] as num?)?.toInt(),
      idPesanan: json['Id_Pesanan']?.toString() ?? '',
      nilai: angka('Nilai'),
      refundCust: angka('Refund_Cust'),
      refundVen: angka('Refund_Ven'),
      refundTime:
          DateTime.tryParse(json['Refund_Time']?.toString() ?? '')?.toLocal(),
      status: json['Status']?.toString() ?? '',
    );
  }
}
