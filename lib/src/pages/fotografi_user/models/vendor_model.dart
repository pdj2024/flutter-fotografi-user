class VendorModel {
  final String noId;
  final String userName;
  final String namaDisplay;
  final String email;
  final String kota;
  final double rating;
  final List<String>
      portofolio; // ID portofolio, bisa digunakan untuk fetch detail
  final List<String>
      paket; // Nama paket, bisa digunakan untuk fetch detail paket
  final int hargaMinPaket;
  final int hargaMaxPaket;
  final DateTime tglCreated;
  final String id_media;
  final String deskripsi_bio;

  VendorModel({
    required this.noId,
    required this.userName,
    required this.namaDisplay,
    required this.email,
    required this.kota,
    required this.rating,
    required this.portofolio,
    required this.paket,
    required this.hargaMinPaket,
    required this.hargaMaxPaket,
    required this.tglCreated,
    required this.id_media,
    required this.deskripsi_bio,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) => VendorModel(
        noId: json['No_Id'] ?? '',
        userName: json['UserName'] ?? '',
        namaDisplay: json['Nama_Display'] ?? '',
        email: json['Email'] ?? '',
        kota: json['Kota'] ?? '',
        rating: (json['Rating'] ?? 0).toDouble(),
        portofolio: (json['Portofolio'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        paket: (json['Paket'] as List? ?? []).map((e) => e.toString()).toList(),
        hargaMinPaket: json['Harga_Min_Paket'] ?? 0,
        hargaMaxPaket: json['Harga_Max_Paket'] ?? 0,
        tglCreated:
            DateTime.tryParse(json['Tgl_Created'] ?? '') ?? DateTime(2000),
        id_media: json['Id_Media'] ??  '',
         deskripsi_bio: json['Deskripsi_Bio'] ??  '',
      );

      Map<String, dynamic> toJson() {
  return {
    'No_Id': noId,
    'UserName': userName,
    'Nama_Display': namaDisplay,
    'Email': email,
    'Kota': kota,
    'Rating': rating,
    'Portofolio': portofolio,
    'Paket': paket,
    'Harga_Min_Paket': hargaMinPaket,
    'Harga_Max_Paket': hargaMaxPaket,
    'Tgl_Created': tglCreated.toIso8601String(),
    'Id_Media': id_media,
    'Deskripsi_Bio': deskripsi_bio,
  };
}

}
