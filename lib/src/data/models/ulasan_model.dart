class UlasanModel {
  final String noId;
  final String noOrder;

  final int rating;
  final String isiUlasan;
  final DateTime tglUlasan;

  final bool? adaBalasan;
  final String? isiBalasan;
  final DateTime? tglBalasan;

  final String status;

  // ===== RELASI / DISPLAY DATA =====
  final String idPaket;
  final String namaPaket;

  final String idVendor;
  final String namaVendor;

  final String idCustomer;
  final String namaCustomer;

  UlasanModel({
    required this.noId,
    required this.noOrder,
    required this.rating,
    required this.isiUlasan,
    required this.tglUlasan,
    this.adaBalasan,
    this.isiBalasan,
    this.tglBalasan,
    required this.status,
    required this.idPaket,
    required this.namaPaket,
    required this.idVendor,
    required this.namaVendor,
    required this.idCustomer,
    required this.namaCustomer,
  });

  /// ===============================
  /// FROM JSON (GET)
  /// ===============================
  factory UlasanModel.fromJson(Map<String, dynamic> json) {
    return UlasanModel(
      noId: json['No_Id'],
      noOrder: json['No_Order'],
      rating: json['Rating'],
      isiUlasan: json['Isi_Ulasan'],
      tglUlasan: DateTime.parse(json['Tgl_Ulasan']),
      adaBalasan: json['Ada_Balasan'],
      isiBalasan: json['Isi_Balasan'],
      tglBalasan: json['Tgl_Balasan'] != null
          ? DateTime.parse(json['Tgl_Balasan'])
          : null,
      status: json['Status'],
      idPaket: json['Id_Paket'],
      namaPaket: json['Nama_Paket'],
      idVendor: json['Id_Vendor'],
      namaVendor: json['Nama_Vendor'],
      idCustomer: json['Id_Customer'],
      namaCustomer: json['Nama_Customer'],
    );
  }

  factory UlasanModel.create({
    required String noOrder,
    required int rating,
    required String isiUlasan,
    DateTime? tglUlasan,
    String status = 'aktif',
  }) {
    return UlasanModel(
      noId: '',
      noOrder: noOrder,
      rating: rating,
      isiUlasan: isiUlasan,
      tglUlasan: tglUlasan ?? DateTime.now(),
      status: status,
      idPaket: '',
      namaPaket: '',
      idVendor: '',
      namaVendor: '',
      idCustomer: '',
      namaCustomer: '',
    );
  }

  /// ===============================
  /// CREATE (POST)
  /// ===============================
  Map<String, dynamic> toJsonCreate() {
    return {
      'no_order': noOrder,
      'rating': rating,
      'isi_ulasan': isiUlasan,
      'tgl_ulasan': tglUlasan.toUtc().toIso8601String(),
      'status': status,
    };
  }

  /// ===============================
  /// UPDATE BALASAN (PUT)
  /// ===============================
  Map<String, dynamic> toJsonUpdate() {
    return {
      'rating': rating,
      'no_order': noOrder,
      'isi_ulasan': isiUlasan,
      'tgl_ulasan': tglUlasan.toUtc().toIso8601String(),
      'ada_balasan': adaBalasan ?? false,
      'isi_balasan': isiBalasan,
      'tgl_balasan': tglBalasan?.toUtc().toIso8601String(),
      'status': status,
    };
  }

  /// ===============================
  /// COPY WITH
  /// ===============================
  UlasanModel copyWith({
    String? noId,
    String? noOrder,
    int? rating,
    String? isiUlasan,
    DateTime? tglUlasan,
    bool? adaBalasan,
    String? isiBalasan,
    DateTime? tglBalasan,
    String? status,
    String? idPaket,
    String? namaPaket,
    String? idVendor,
    String? namaVendor,
    String? idCustomer,
    String? namaCustomer,
  }) {
    return UlasanModel(
      noId: noId ?? this.noId,
      noOrder: noOrder ?? this.noOrder,
      rating: rating ?? this.rating,
      isiUlasan: isiUlasan ?? this.isiUlasan,
      tglUlasan: tglUlasan ?? this.tglUlasan,
      adaBalasan: adaBalasan ?? this.adaBalasan,
      isiBalasan: isiBalasan ?? this.isiBalasan,
      tglBalasan: tglBalasan ?? this.tglBalasan,
      status: status ?? this.status,
      idPaket: idPaket ?? this.idPaket,
      namaPaket: namaPaket ?? this.namaPaket,
      idVendor: idVendor ?? this.idVendor,
      namaVendor: namaVendor ?? this.namaVendor,
      idCustomer: idCustomer ?? this.idCustomer,
      namaCustomer: namaCustomer ?? this.namaCustomer,
    );
  }

  /// ===============================
  /// LIST PARSER
  /// ===============================
  static List<UlasanModel> fromJsonList(List<dynamic> list) {
    return list.map((e) => UlasanModel.fromJson(e)).toList();
  }
}
