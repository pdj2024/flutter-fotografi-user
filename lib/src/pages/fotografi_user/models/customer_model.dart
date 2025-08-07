class CustomerModel {
  final String no_id;
  final String user_name;
  final String nama_display;
  final String email;
  final String kota;
  final String status;
  final bool pernah_order;
  final List<String> saves;
  final List<String> likes;
  final DateTime tgl_created;
  final DateTime? tgl_non_aktif;

  CustomerModel({
    required this.no_id,
    required this.user_name,
    required this.nama_display,
    required this.email,
    required this.kota,
    required this.status,
    required this.pernah_order,
    required this.saves,
    required this.likes,
    required this.tgl_created,
    this.tgl_non_aktif,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      no_id: json['No_Id'] ?? '',
      user_name: json['UserName'] ?? '',
      nama_display: json['Nama_Display'] ?? '',
      email: json['Email'] ?? '',
      kota: json['Kota'] ?? '',
      status: json['Status'] ?? '',
      pernah_order: json['Pernah_Order'] ?? false,
      saves: (json['Saves'] as List? ?? []).map((e) => e.toString()).toList(),
      likes: (json['Likes'] as List? ?? []).map((e) => e.toString()).toList(),
      tgl_created:
          DateTime.tryParse(json['Tgl_Created'] ?? '') ?? DateTime(2000),
      tgl_non_aktif: json['Tgl_NonAktif'] != null
          ? DateTime.tryParse(json['Tgl_NonAktif'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'No_Id': no_id,
      'UserName': user_name,
      'Nama_Display': nama_display,
      'Email': email,
      'Kota': kota,
      'Status': status,
      'Pernah_Order': pernah_order,
      'Saves': saves,
      'Likes': likes,
      'Tgl_Created': tgl_created.toIso8601String(),
      'Tgl_NonAktif': tgl_non_aktif?.toIso8601String(),
    };
  }
}
