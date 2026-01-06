class PaketModel {
  final String no_id;
  final String nama_paket;
  final String id_vendor;
  final int harga;
  final String rincian;
  final String status;

  PaketModel({
    required this.no_id,
    required this.nama_paket,
    required this.id_vendor,
    required this.harga,
    required this.rincian,
    required this.status,
  });

  factory PaketModel.fromJson(Map<String, dynamic> json) {
    return PaketModel(
      no_id: json['No_Id'] ?? 0,
      nama_paket: json['Nama_Paket'] ?? '',
      id_vendor: json['Id_Vendor'] ?? '',
      harga: json['Harga'] ?? 0,
      rincian: json['Rincian'] ?? '',
      status: json['Status'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'No_Id': no_id,
      'nama_paket': nama_paket,
      'id_vendor': id_vendor,
      'harga': harga,
      'rincian': rincian,
      'status': status,
    };
  }

  PaketModel copyWith({
    String? no_id,
    String? nama_paket,
    String? id_vendor,
    int? harga,
    String? rincian,
    String? status,
  }) {
    return PaketModel(
      no_id: no_id ?? this.no_id,
      nama_paket: nama_paket ?? this.nama_paket,
      id_vendor: id_vendor ?? this.id_vendor,
      harga: harga ?? this.harga,
      rincian: rincian ?? this.rincian,
      status: status ?? this.status,
    );
  }

  /// ⬇⬇⬇ Tambahkan ini untuk CREATE
  Map<String, dynamic> toJsonAPI() => {
        "nama_paket": nama_paket,
        "id_vendor": id_vendor,
        "harga": harga,
        "rincian": rincian,
        "status": status,
      };

}
