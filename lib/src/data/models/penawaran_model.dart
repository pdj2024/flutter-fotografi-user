class PenawaranModel {
  final String noId;
  final String noTrackingPenawaran;
  final String noPesanan;
  final String idVendor;
  final String namaVendor;
  final String idCustomer;
  final String namaCustomer;
  final String idPaket;
  final String namaPaket;
  final int harga;
  final String status;
  final String lokasi;
  final String kota;
  final String namaKota;
  final DateTime tglRealisasi;
  final DateTime createdAt;
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
      tglRealisasi: tglRealisasi ?? this.tglRealisasi,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
