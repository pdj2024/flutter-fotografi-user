import 'package:hive/hive.dart';

part 'penawaran_model.g.dart';

@HiveType(typeId: 3)
class PenawaranModel {
  @HiveField(0)
  final String noId;
  
  @HiveField(1)
  final String noTrackingPenawaran;
  
  @HiveField(2)
  final String noPesanan;
  
  @HiveField(3)
  final String idVendor;
  
  @HiveField(4)
  final String namaVendor;
  
  @HiveField(5)
  final String idCustomer;
  
  @HiveField(6)
  final String namaCustomer;
  
  @HiveField(7)
  final String idPaket;
  
  @HiveField(8)
  final String namaPaket;
  
  @HiveField(9)
  final int harga;
  
  @HiveField(10)
  final String status;
  
  @HiveField(11)
  final String lokasi;
  
  @HiveField(12)
  final String namaKota;
  
  @HiveField(13)
  final String kota;
  
  @HiveField(14)
  final String deskripsi;
  
  @HiveField(15)
  final DateTime tglRealisasi;
  
  @HiveField(16)
  final DateTime createdAt;
  
  @HiveField(17)
  final DateTime? updatedAt;

  PenawaranModel({
    required this.noId,
    required this.noTrackingPenawaran,
    required this.noPesanan,
    required this.idVendor,
    required this.namaVendor,
    required this.idCustomer,
    required this.namaCustomer,
    required this.idPaket,
    required this.namaPaket,
    required this.harga,
    required this.status,
    required this.lokasi,
    required this.kota,
    required this.namaKota,
    required this.deskripsi,
    required this.tglRealisasi,
    required this.createdAt,
    this.updatedAt,
  });

  // FROM JSON
  factory PenawaranModel.fromJson(Map<String, dynamic> json) {
    return PenawaranModel(
      noId: json["No_Id"] ?? "",
      noTrackingPenawaran: json["No_Tracking_Penawaran"] ?? "",
      noPesanan: json["No_Pesanan"] ?? "",
      idVendor: json["Id_Vendor"] ?? "",
      namaVendor: json["Nama_Vendor"] ?? "",
      idCustomer: json["Id_Customer"] ?? "",
      namaCustomer: json["Nama_Customer"] ?? "",
      idPaket: json["Id_Paket"] ?? "",
      namaPaket: json["Nama_Paket"] ?? "",
      harga: json["Harga"] ?? 0,
      status: json["Status"] ?? "",
      lokasi: json["Lokasi"] ?? "",
      kota: json["Kota"] ?? "",
      namaKota: json["Nama_Kota"] ?? "",
      deskripsi: json["Deskripsi"] ?? "",
      tglRealisasi: DateTime.parse(json["Tgl_Realisasi"]),
      createdAt: DateTime.parse(json["Created_At"]),
      updatedAt: json["Updated_At"] != null
          ? DateTime.parse(json["Updated_At"])
          : null,
    );
  }

  // TO JSON
  Map<String, dynamic> toJson() {
    return {
      "No_Id": noId,
      "No_Tracking_Penawaran": noTrackingPenawaran,
      "No_Pesanan": noPesanan,
      "Id_Vendor": idVendor,
      "Nama_Vendor": namaVendor,
      "Id_Customer": idCustomer,
      "Nama_Customer": namaCustomer,
      "Id_Paket": idPaket,
      "Nama_Paket": namaPaket,
      "Harga": harga,
      "Status": status,
      "Lokasi": lokasi,
      "Kota": kota,
      "Nama_Kota": namaKota,
      "Deskripsi": deskripsi,
      "Tgl_Realisasi": tglRealisasi.toIso8601String(),
      "Created_At": createdAt.toIso8601String(),
      "Updated_At": updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonCreate() {
    return {
      "id_vendor": idVendor,
      "id_customer": idCustomer,
      "id_paket": idPaket,
      "nama_paket": namaPaket,
      "kota": kota,
      "harga": harga,
      "lokasi": lokasi,
      "deskripsi": lokasi,
      "tgl_realisasi": tglRealisasi.toIso8601String(),
      "status": status,
    };
  }

  // COPY WITH
  PenawaranModel copyWith({
    String? noId,
    String? noTrackingPenawaran,
    String? noPesanan,
    String? idVendor,
    String? namaVendor,
    String? idCustomer,
    String? namaCustomer,
    String? idPaket,
    String? namaPaket,
    int? harga,
    String? status,
    String? lokasi,
    String? kota,
    String? namaKota,
    String? deskripsi,
    DateTime? tglRealisasi,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PenawaranModel(
      noId: noId ?? this.noId,
      noTrackingPenawaran: noTrackingPenawaran ?? this.noTrackingPenawaran,
      noPesanan: noPesanan ?? this.noPesanan,
      idVendor: idVendor ?? this.idVendor,
      namaVendor: namaVendor ?? this.namaVendor,
      idCustomer: idCustomer ?? this.idCustomer,
      namaCustomer: namaCustomer ?? this.namaCustomer,
      idPaket: idPaket ?? this.idPaket,
      namaPaket: namaPaket ?? this.namaPaket,
      harga: harga ?? this.harga,
      status: status ?? this.status,
      lokasi: lokasi ?? this.lokasi,
      kota: kota ?? this.kota,
      namaKota: namaKota ?? this.namaKota,
      deskripsi: deskripsi ?? this.deskripsi,
      tglRealisasi: tglRealisasi ?? this.tglRealisasi,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}