class PaketModel {
  final String no_id;
  final String nama_paket;
  final String id_vendor;
  final int harga;
  final String rincian;
  final bool aktif;

  PaketModel({
    required this.no_id,
    required this.nama_paket,
    required this.id_vendor,
    required this.harga,
    required this.rincian,
    required this.aktif,
  });

  factory PaketModel.fromJson(Map<String, dynamic> json) {
    return PaketModel(
      no_id: json['No_Id'] ?? 0,
      nama_paket: json['Nama_Paket'] ?? '',
      id_vendor: json['Id_Vendor'] ?? '',
      harga: json['Harga'] ?? 0,
      rincian: json['Rincian'] ?? '',
      aktif: json['Aktif'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
  return {
    'No_Id': no_id,
    'Nama_Paket': nama_paket,
    'Id_Vendor': id_vendor,
    'Harga': harga,
    'Rincian': rincian,
    'Aktif': aktif,
  };
}

}
