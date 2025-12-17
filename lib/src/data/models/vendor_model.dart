class VendorModel {
  final String noId;
  final String username;
  final String namaDisplay;
  final String email;
  final String kota;
  final String namaKota;
  final double rating;
  final List<String>
      portofolio; // ID portofolio, bisa digunakan untuk fetch detail
  final List<String>
      paket; // Nama paket, bisa digunakan untuk fetch detail paket
  final int hargaMinPaket;
  final int hargaMaxPaket;
  final DateTime tglCreated;
  final String idMedia;
  final String deskripsiBio;

  VendorModel({
    required this.noId,
    required this.username,
    required this.namaDisplay,
    required this.email,
    required this.kota,
    required this.namaKota,
    required this.rating,
    required this.portofolio,
    required this.paket,
    required this.hargaMinPaket,
    required this.hargaMaxPaket,
    required this.tglCreated,
    required this.idMedia,
    required this.deskripsiBio,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) => VendorModel(
        noId: json['No_Id'] ?? '',
        username: json['UserName'] ?? '',
        namaDisplay: json['Nama_Display'] ?? '',
        email: json['Email'] ?? '',
        kota: json['Kota'] ?? '',
        namaKota: json['Nama_Kota'] ?? '',
        rating: (json['Rating'] ?? 0).toDouble(),
        portofolio: (json['Portofolio'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        paket: (json['Paket'] as List? ?? []).map((e) => e.toString()).toList(),
        hargaMinPaket: json['Harga_Min_Paket'] ?? 0,
        hargaMaxPaket: json['Harga_Max_Paket'] ?? 0,
        tglCreated:
            DateTime.tryParse(json['Tgl_Created'] ?? '') ?? DateTime(2000),
        idMedia: json['Id_Media'] ?? '',
        deskripsiBio: json['Deskripsi_Bio'] ?? '',
      );

  Map<String, dynamic> toJson() {
    return {
      'No_Id': noId,
      'UserName': username,
      'Nama_Display': namaDisplay,
      'Email': email,
      'Kota': kota,
      "Nama_Kota": namaKota,
      'Rating': rating,
      'Portofolio': portofolio,
      'Paket': paket,
      'Harga_Min_Paket': hargaMinPaket,
      'Harga_Max_Paket': hargaMaxPaket,
      'Tgl_Created': tglCreated.toIso8601String(),
      'Id_Media': idMedia,
      'Deskripsi_Bio': deskripsiBio,
    };
  }
}
