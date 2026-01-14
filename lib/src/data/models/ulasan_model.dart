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
  });

  /// Factory constructor untuk parsing dari JSON response (GET)
  factory UlasanModel.fromJson(Map<String, dynamic> json) {
    return UlasanModel(
      noId: json['No_Id'] as String,
      noOrder: json['No_Order'] as String,
      rating: json['Rating'] as int,
      isiUlasan: json['Isi_Ulasan'] as String,
      tglUlasan: DateTime.parse(json['Tgl_Ulasan'] as String),
      adaBalasan: json['Ada_Balasan'] as bool?,
      isiBalasan: json['Isi_Balasan'] as String?,
      tglBalasan: json['Tgl_Balasan'] != null
          ? DateTime.parse(json['Tgl_Balasan'] as String)
          : null,
      status: json['Status'] as String,
    );
  }

  /// Konversi ke JSON untuk CREATE request (POST)
  Map<String, dynamic> toJsonCreate() {
    return {
      'no_order': noOrder,
      'rating': rating,
      'isi_ulasan': isiUlasan,
      'tgl_ulasan': tglUlasan.toUtc().toIso8601String(),
      'status': status,
    };
  }

  /// Konversi ke JSON lengkap (untuk keperluan lain jika dibutuhkan)
  Map<String, dynamic> toJson() {
    return {
      'No_Id': noId,
      'No_Order': noOrder,
      'Rating': rating,
      'Isi_Ulasan': isiUlasan,
      'Tgl_Ulasan': tglUlasan.toUtc().toIso8601String(),
      'Ada_Balasan': adaBalasan,
      'Isi_Balasan': isiBalasan,
      'Tgl_Balasan': tglBalasan?.toUtc().toIso8601String(),
      'Status': status,
    };
  }

  /// CopyWith untuk membuat salinan dengan nilai yang diubah
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
    );
  }

  /// Helper untuk membuat ulasan baru dengan default DateTime.now()
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
    );
  }

  /// Parse list dari JSON
  static List<UlasanModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => UlasanModel.fromJson(json)).toList();
  }

  @override
  String toString() {
    return 'UlasanModel(noId: $noId, noOrder: $noOrder, rating: $rating, '
        'isiUlasan: $isiUlasan, tglUlasan: $tglUlasan, adaBalasan: $adaBalasan, '
        'isiBalasan: $isiBalasan, tglBalasan: $tglBalasan, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UlasanModel &&
        other.noId == noId &&
        other.noOrder == noOrder &&
        other.rating == rating &&
        other.isiUlasan == isiUlasan &&
        other.tglUlasan == tglUlasan &&
        other.adaBalasan == adaBalasan &&
        other.isiBalasan == isiBalasan &&
        other.tglBalasan == tglBalasan &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      noId,
      noOrder,
      rating,
      isiUlasan,
      tglUlasan,
      adaBalasan,
      isiBalasan,
      tglBalasan,
      status,
    );
  }
}
