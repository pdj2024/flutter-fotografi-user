class PortofolioModel {
  final String noId;
  final String idVendor;
  final List<String> idMedia;
  final String? idMediaVendor;
  final String? idKategori;
  final String? namaKategori;
  final String? jenisMedia;
  final String? usernameVendor;
  final String? namaVendor;
  final String? kota;
  final String? namaKota;
  final List<String> idPaket;
  final dynamic paket;
  final DateTime tglCreated;
  final int? jumlahPaket;
  final String status;
  final double? ratingVendor;
  final int? hargaMinPaket;
  final int? hargaMaxPaket;
  final int? jumlahPortofolio;
  final int likes;
  final int saves;
  final int? matchKota;
  final int? fromSavedVendor;
  final bool? isSaved;
  final bool? isLiked;
  final double? skorTotal;
  final List<MediaUrlModel> mediaUrls;

  PortofolioModel({
    required this.noId,
    required this.idVendor,
    required this.idMedia,
    this.idMediaVendor,
    this.idKategori,
    this.namaKategori,
    this.jenisMedia,
    this.usernameVendor,
    this.namaVendor,
    this.kota,
    this.namaKota,
    required this.idPaket,
    this.paket,
    required this.tglCreated,
    this.jumlahPaket,
    required this.status,
    this.ratingVendor,
    this.hargaMinPaket,
    this.hargaMaxPaket,
    this.jumlahPortofolio,
    required this.likes,
    required this.saves,
    this.matchKota,
    this.fromSavedVendor,
    this.isSaved,
    this.isLiked,
    this.skorTotal,
    required this.mediaUrls,
  });

  // ---------------------------
  // FROM JSON
  // ---------------------------
  factory PortofolioModel.fromJson(Map<String, dynamic> json) {
    return PortofolioModel(
      noId: json['No_Id'],
      idVendor: json['Id_Vendor'],
      idMedia:
          json['Id_Media'] != null ? List<String>.from(json['Id_Media']) : [],
      idMediaVendor: json['Id_Media_Vendor'],
      idKategori: json['Id_Kategori'],
      namaKategori: json['Nama_Kategori'],
      jenisMedia: json['Jenis_Media'],
      usernameVendor: json['Username_Vendor'],
      namaVendor: json['Nama_Vendor'],
      kota: json['Kota'],
      namaKota: json['Nama_Kota'],
      idPaket:
          json['Id_Paket'] != null ? List<String>.from(json['Id_Paket']) : [],
      paket: json['Paket'],
      tglCreated: DateTime.parse(json['Tgl_Created']),
      jumlahPaket: json['Jumlah_Paket'],
      status: json['Status'],
      ratingVendor: json['Rating_Vendor'].toDouble(),
      hargaMinPaket: json['Harga_Min_Paket'],
      hargaMaxPaket: json['Harga_Max_Paket'],
      jumlahPortofolio: json['Jumlah_Portofolio'],
      likes: json['Likes'],
      saves: json['Saves'],
      matchKota: json['Match_Kota'],
      fromSavedVendor: json['From_Saved_Vendor'],
      isSaved: json['Is_Saved'],
      isLiked: json['Is_Liked'],
      skorTotal: (json['Skor_Total'] is int)
          ? (json['Skor_Total'] as int).toDouble()
          : json['Skor_Total'],
      mediaUrls: json['MediaUrls'] != null
          ? (json['MediaUrls'] as List)
              .map((e) => MediaUrlModel.fromJson(e))
              .toList()
          : [],
    );
  }

  // ---------------------------
  // COPY WITH
  // ---------------------------
  PortofolioModel copyWith({
    String? noId,
    String? idVendor,
    List<String>? idMedia,
    String? idMediaVendor,
    String? idKategori,
    String? namaKategori,
    String? jenisMedia,
    String? usernameVendor,
    String? namaVendor,
    String? kota,
    String? namaKota,
    List<String>? idPaket,
    dynamic paket,
    DateTime? tglCreated,
    int? jumlahPaket,
    String? status,
    double? ratingVendor,
    int? hargaMinPaket,
    int? hargaMaxPaket,
    int? jumlahPortofolio,
    int? likes,
    int? saves,
    int? matchKota,
    int? fromSavedVendor,
    bool? isSaved,
    bool? isLiked,
    double? skorTotal,
    List<MediaUrlModel>? mediaUrls,
  }) {
    return PortofolioModel(
      noId: noId ?? this.noId,
      idVendor: idVendor ?? this.idVendor,
      idMedia: idMedia ?? this.idMedia,
      idMediaVendor: idMediaVendor ?? this.idMediaVendor,
      idKategori: idKategori ?? this.idKategori,
      namaKategori: namaKategori ?? this.namaKategori,
      jenisMedia: jenisMedia ?? this.jenisMedia,
      usernameVendor: usernameVendor ?? this.usernameVendor,
      namaVendor: namaVendor ?? this.namaVendor,
      kota: kota ?? this.kota,
      namaKota: namaKota ?? this.namaKota,
      idPaket: idPaket ?? this.idPaket,
      paket: paket ?? this.paket,
      tglCreated: tglCreated ?? this.tglCreated,
      jumlahPaket: jumlahPaket ?? this.jumlahPaket,
      status: status ?? this.status,
      ratingVendor: ratingVendor ?? this.ratingVendor,
      hargaMinPaket: hargaMinPaket ?? this.hargaMinPaket,
      hargaMaxPaket: hargaMaxPaket ?? this.hargaMaxPaket,
      jumlahPortofolio: jumlahPortofolio ?? this.jumlahPortofolio,
      likes: likes ?? this.likes,
      saves: saves ?? this.saves,
      matchKota: matchKota ?? this.matchKota,
      fromSavedVendor: fromSavedVendor ?? this.fromSavedVendor,
      isSaved: isSaved ?? this.isSaved,
      isLiked: isLiked ?? this.isLiked,
      skorTotal: skorTotal ?? this.skorTotal,
      mediaUrls: mediaUrls ?? this.mediaUrls,
    );
  }

  // ---------------------------
  // TO JSON (CREATE)
  // ---------------------------
  Map<String, dynamic> toJsonCreate() {
    return {
      "id_vendor": idVendor,
      "id_kategori": idKategori,
      "id_paket": idPaket,
      "jenis_media": jenisMedia,
      "status": status,
      "id_media": idMedia,
    };
  }

  // ---------------------------
  // TO JSON (UPDATE)
  // ---------------------------
  Map<String, dynamic> toJsonUpdate() {
    return {
      "id_vendor": idVendor,
      "id_kategori": idKategori,
      "id_paket": idPaket,
      "jenis_media": jenisMedia,
      "status": status,
      "id_media": idMedia,
    };
  }
}

class MediaUrlModel {
  final String? url;
  final DateTime? expiredAt;
  final bool? isCompressed;
  final String? contentType;
  final String? thumbUrl;
  final int? size;
  final String? idMedia;
  final String? noIdMedia;

  MediaUrlModel({
    this.url,
    this.expiredAt,
    this.isCompressed,
    this.contentType,
    this.thumbUrl,
    this.size,
    this.idMedia,
    this.noIdMedia,
  });

  factory MediaUrlModel.fromJson(Map<String, dynamic> json) {
    return MediaUrlModel(
      url: json['Id_Media'],
      expiredAt: json['Expired_At'] != null
          ? DateTime.parse(json['Expired_At'])
          : null,
      isCompressed: json['IsCompressed'],
      contentType: json['ContentType'],
      thumbUrl: json['ThumbUrl'],
      size: json['Size'],
      idMedia: json['Id_Media'],
      noIdMedia: json['No_Id_Media'],
    );
  }

  MediaUrlModel copyWith({
    String? url,
    DateTime? expiredAt,
    bool? isCompressed,
    String? contentType,
    String? thumbUrl,
    int? size,
    String? idMedia,
    String? noIdMedia,
  }) {
    return MediaUrlModel(
      url: url ?? this.url,
      expiredAt: expiredAt ?? this.expiredAt,
      isCompressed: isCompressed ?? this.isCompressed,
      contentType: contentType ?? this.contentType,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      size: size ?? this.size,
      idMedia: idMedia ?? this.idMedia,
      noIdMedia: noIdMedia ?? this.noIdMedia,
    );
  }
}
