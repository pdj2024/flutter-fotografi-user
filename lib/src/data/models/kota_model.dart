class KotaModel {
  final String no_id;
  final String nama_kota;
  final String status;


  KotaModel({
    required this.no_id,
    required this.nama_kota,
    required this.status,
   
  });

  factory KotaModel.fromJson(Map<String, dynamic> json) {
  return KotaModel(
    no_id: json['No_Id'].toString(),
    nama_kota: json['Nama_Kota']?.toString() ?? '',
    status: (json['Status'] == true) ? 'aktif' : 'nonaktif',
  
  );
}


  Map<String, dynamic> toJson() {
    return {
      'No_Id': no_id,
      'Nama_Kota': nama_kota,
      'Status': status,
   
    };
  }
}
