class KategoriModel {
  final String no_id;
  final String nama_kategori;
  final String status;
  final String id_media;

  KategoriModel({
    required this.no_id,
    required this.nama_kategori,
    required this.status,
    required this.id_media,
  });

  factory KategoriModel.fromJson(Map<String, dynamic> json) {
  return KategoriModel(
    no_id: json['No_Id'].toString(),
    nama_kategori: json['Nama_Kategori']?.toString() ?? '',
    status: (json['Status'] == true) ? 'aktif' : 'nonaktif',
    id_media: json['Id_Media'].toString(),
  );
}


  Map<String, dynamic> toJson() {
    return {
      'No_Id': no_id,
      'Nama_Kategori': nama_kategori,
      'Status': status,
      'Id_Media': id_media,
    };
  }
}
