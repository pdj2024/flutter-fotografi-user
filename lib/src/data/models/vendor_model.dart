class VendorModel {
  final String no_id;
  final String user_name;
  final String nama_display;
  final String email;
  final String kota;
  final double rating;
  final List<String>
      portofolio; // ID portofolio, bisa digunakan untuk fetch detail
  final List<String>
      paket; // Nama paket, bisa digunakan untuk fetch detail paket
  final int hargaMinPaket;
  final int hargaMaxPaket;
  final DateTime tgl_created;
  final String id_media;
  final String deskripsi_bio;

  VendorModel({
    required this.no_id,
    required this.user_name,
    required this.nama_display,
    required this.email,
    required this.kota,
    required this.rating,
    required this.portofolio,
    required this.paket,
    required this.hargaMinPaket,
    required this.hargaMaxPaket,
    required this.tgl_created,
    required this.id_media,
    required this.deskripsi_bio,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) => VendorModel(
        no_id: json['No_Id'] ?? '',
        user_name: json['UserName'] ?? '',
        nama_display: json['Nama_Display'] ?? '',
        email: json['Email'] ?? '',
        kota: json['Kota'] ?? '',
        rating: (json['Rating'] ?? 0).toDouble(),
        portofolio: (json['Portofolio'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        paket: (json['Paket'] as List? ?? []).map((e) => e.toString()).toList(),
        hargaMinPaket: json['Harga_Min_Paket'] ?? 0,
        hargaMaxPaket: json['Harga_Max_Paket'] ?? 0,
        tgl_created:
            DateTime.tryParse(json['Tgl_Created'] ?? '') ?? DateTime(2000),
        id_media: json['Id_Media'] ??  '',
         deskripsi_bio: json['Deskripsi_Bio'] ??  '',
      );

      Map<String, dynamic> toJson() {
  return {
    'No_Id': no_id,
    'UserName': user_name,
    'Nama_Display': nama_display,
    'Email': email,
    'Kota': kota,
    'Rating': rating,
    'Portofolio': portofolio,
    'Paket': paket,
    'Harga_Min_Paket': hargaMinPaket,
    'Harga_Max_Paket': hargaMaxPaket,
    'Tgl_Created': tgl_created.toIso8601String(),
    'Id_Media': id_media,
    'Deskripsi_Bio': deskripsi_bio,
  };
}

}
