class CustomerModel {
  final String noId;
  final String userName;
  final String namaDisplay;
  final String email;
  final String kota;
  final String namaKota;
  final String status;
  final bool pernahOrder;
  final List<String> saves;
  final List<String> likes;
  final DateTime tglCreated;
  final DateTime? tglNonAktif;
  final List<String> deviceToken;

  CustomerModel({
    required this.noId,
    required this.userName,
    required this.namaDisplay,
    required this.email,
    required this.kota,
    required this.namaKota,
    required this.status,
    required this.pernahOrder,
    required this.saves,
    required this.likes,
    required this.tglCreated,
    this.tglNonAktif,
    required this.deviceToken,
  });

  // ================================
  // FROM JSON
  // ================================
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      noId: json['No_Id'] ?? '',
      userName: json['UserName'] ?? '',
      namaDisplay: json['Nama_Display'] ?? '',
      email: json['Email'] ?? '',
      kota: json['Kota'] ?? '',
      namaKota: json['Nama_Kota'] ?? '',
      status: json['Status'] ?? '',
      pernahOrder: json['Pernah_Order'] ?? false,
      saves: (json['Saves'] as List? ?? []).map((e) => e.toString()).toList(),
      likes: (json['Likes'] as List? ?? []).map((e) => e.toString()).toList(),
      tglCreated: DateTime.tryParse(json['Tgl_Created'] ?? '')?.toLocal() ??
          DateTime(2000),
      tglNonAktif: json['Tgl_NonAktif'] != null
          ? DateTime.tryParse(json['Tgl_NonAktif'])?.toLocal()
          : null,
      deviceToken: (json['Device_Token'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  // ================================
  // TO JSON
  // ================================
  Map<String, dynamic> toJson() {
    return {
      'No_Id': noId,
      'UserName': userName,
      'Nama_Display': namaDisplay,
      'Email': email,
      'Kota': kota,
      'Nama_Kota': namaKota,
      'Status': status,
      'Pernah_Order': pernahOrder,
      'Saves': saves,
      'Likes': likes,
      'Tgl_Created': tglCreated.toIso8601String(),
      'Tgl_NonAktif': tglNonAktif?.toIso8601String(),
      'Device_Token': deviceToken,
    };
  }

  Map<String, dynamic> toJsonUpdate() {
    return {
      'userName': userName,
      'nama_Display': namaDisplay,
      'email': email,
      'kota': kota,
      'status': status,
      'pernah_Order': pernahOrder,
      'saves': saves,
      'likes': likes,
      'tgl_NonAktif': tglNonAktif?.toIso8601String(),
    };
  }

  // ================================
  // COPY WITH
  // ================================
  CustomerModel copyWith({
    String? noId,
    String? userName,
    String? namaDisplay,
    String? email,
    String? kota,
    String? namaKota,
    String? status,
    bool? pernahOrder,
    List<String>? saves,
    List<String>? likes,
    DateTime? tglCreated,
    DateTime? tglNonAktif,
    List<String>? deviceToken,
  }) {
    return CustomerModel(
      noId: noId ?? this.noId,
      userName: userName ?? this.userName,
      namaDisplay: namaDisplay ?? this.namaDisplay,
      email: email ?? this.email,
      kota: kota ?? this.kota,
      namaKota: namaKota ?? this.namaKota,
      status: status ?? this.status,
      pernahOrder: pernahOrder ?? this.pernahOrder,
      saves: saves ?? this.saves,
      likes: likes ?? this.likes,
      tglCreated: tglCreated ?? this.tglCreated,
      tglNonAktif: tglNonAktif ?? this.tglNonAktif,
      deviceToken: deviceToken ?? this.deviceToken,
    );
  }
}
