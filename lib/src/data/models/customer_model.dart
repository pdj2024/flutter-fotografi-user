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

  // Rekening tujuan pengembalian dana. Hanya diisi lewat alur pembatalan
  // pesanan berbayar (RefundFormPage) — tidak bisa diubah dari edit profil.
  final String namaBank;
  final String nomorRekening;

  // Persetujuan dokumen legal — kosong berarti belum pernah menyetujui.
  final String tncLoc;
  final String tncVersion;
  final DateTime? tncTime;
  final String ppLoc;
  final String ppVersion;
  final DateTime? ppTime;

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
    this.namaBank = '',
    this.nomorRekening = '',
    this.tncLoc = '',
    this.tncVersion = '',
    this.tncTime,
    this.ppLoc = '',
    this.ppVersion = '',
    this.ppTime,
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
      // Casing key belum terkonfirmasi dari response GET — body PUT memakai
      // 'Nama_bank', field lain di sini memakai Pascal_Snake_Case.
      namaBank: (json['Nama_Bank'] ?? json['Nama_bank'] ?? '').toString(),
      nomorRekening:
          (json['Nomor_Rekening'] ?? json['nomor_rekening'] ?? '').toString(),
      tncLoc: json['Tnc_Loc'] ?? '',
      tncVersion: json['Tnc_Version'] ?? '',
      tncTime: json['Tnc_Time'] != null
          ? DateTime.tryParse(json['Tnc_Time'])?.toLocal()
          : null,
      ppLoc: json['Pp_Loc'] ?? '',
      ppVersion: json['Pp_Version'] ?? '',
      ppTime: json['Pp_Time'] != null
          ? DateTime.tryParse(json['Pp_Time'])?.toLocal()
          : null,
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
      'Nama_Bank': namaBank,
      'Nomor_Rekening': nomorRekening,
      'Tnc_Loc': tncLoc,
      'Tnc_Version': tncVersion,
      'Tnc_Time': tncTime?.toIso8601String(),
      'Pp_Loc': ppLoc,
      'Pp_Version': ppVersion,
      'Pp_Time': ppTime?.toIso8601String(),
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
      // Ikut dikirim di SETIAP update supaya data rekening tidak tertimpa
      // kosong saat user menyimpan perubahan dari halaman Edit Profile.
      'Nama_bank': namaBank,
      'nomor_rekening': nomorRekening,
      // Key PascalCase — sesuai yang diminta backend untuk field persetujuan.
      'Tnc_Loc': tncLoc,
      'Tnc_Version': tncVersion,
      'Tnc_Time': tncTime?.toUtc().toIso8601String(),
      'Pp_Loc': ppLoc,
      'Pp_Version': ppVersion,
      'Pp_Time': ppTime?.toUtc().toIso8601String(),
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
    String? namaBank,
    String? nomorRekening,
    String? tncLoc,
    String? tncVersion,
    DateTime? tncTime,
    String? ppLoc,
    String? ppVersion,
    DateTime? ppTime,
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
      namaBank: namaBank ?? this.namaBank,
      nomorRekening: nomorRekening ?? this.nomorRekening,
      tncLoc: tncLoc ?? this.tncLoc,
      tncVersion: tncVersion ?? this.tncVersion,
      tncTime: tncTime ?? this.tncTime,
      ppLoc: ppLoc ?? this.ppLoc,
      ppVersion: ppVersion ?? this.ppVersion,
      ppTime: ppTime ?? this.ppTime,
    );
  }
}
