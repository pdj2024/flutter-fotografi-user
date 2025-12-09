class KotaModel {
  final String noId;
  final String namaKota;
  final String keterangan;
  final String status;

  KotaModel({
    required this.noId,
    required this.namaKota,
    required this.keterangan,
    required this.status,
  });

  /// Factory: parsing dari JSON
  factory KotaModel.fromJson(Map<String, dynamic> json) {
    return KotaModel(
      noId: json["No_Id"] ?? "",
      namaKota: json["Nama_Kota"] ?? "",
      keterangan: json["Keterangan"] ?? "",
      status: json["Status"] ?? "",
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      "No_Id": noId,
      "Nama_Kota": namaKota,
      "Keterangan": keterangan,
      "Status": status,
    };
  }

  /// CopyWith untuk memodifikasi data tanpa merusak objek lama
  KotaModel copyWith({
    String? noId,
    String? namaKota,
    String? keterangan,
    String? status,
  }) {
    return KotaModel(
      noId: noId ?? this.noId,
      namaKota: namaKota ?? this.namaKota,
      keterangan: keterangan ?? this.keterangan,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return "CityModel(noId: $noId, namaKota: $namaKota, keterangan: $keterangan, status: $status)";
  }
}
