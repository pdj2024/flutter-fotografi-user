class PortofolioModel {
  final String noId;
  final String idVendor;
 
  final String idMedia;
  final String idMediaVendor;
  final String idKategori;
  final String usernameVendor;
  final String namaVendor;
  final String kota;
  final List<String> idPaket;
  final DateTime tglCreated;
  final int jumlahPaket;
  final String status;
  final double ratingVendor;
  final int hargaMinPaket;
  final int hargaMaxPaket;
  final int jumlahPortofolio;
  final int likes;
  final int saves;
  final int matchKota;
  final int fromSavedVendor;
  final bool isSaved;
   final bool isLiked;
  final double skorTotal;
  final String contentType;
  final String thumbUrl;
  final List<MediaItem> mediaUrls;

  PortofolioModel({
    required this.noId,
    required this.idVendor,
   
    required this.idMedia,
    required this.idMediaVendor,
    required this.idKategori,
    required this.usernameVendor,
    required this.namaVendor,
    required this.kota,
    required this.idPaket,
    required this.tglCreated,
    required this.jumlahPaket,
    required this.status,
    required this.ratingVendor,
    required this.hargaMinPaket,
    required this.hargaMaxPaket,
    required this.jumlahPortofolio,
    required this.likes,
    required this.saves,
    required this.matchKota,
    required this.fromSavedVendor,
    required this.isSaved,
     required this.isLiked,
    required this.skorTotal,
    required this.contentType,
    required this.thumbUrl,
    required this.mediaUrls,
  });

  factory PortofolioModel.fromJson(Map<String, dynamic> json) {
    final mediaRaw = json['MediaUrls'] as List<dynamic>?;

    final mediaList = mediaRaw != null
        ? mediaRaw.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList()
        : <MediaItem>[];

    final firstMedia = mediaList.isNotEmpty ? mediaList.first : null;

    return PortofolioModel(
      noId: json['No_Id']?.toString() ?? "",
      idVendor: json['Id_Vendor']?.toString() ?? "",
      
      idMedia: json['Id_Media']?.toString() ?? "",
      idMediaVendor: json['Id_Media_Vendor']?.toString() ?? "",
      idKategori: json['Id_Kategori']?.toString() ?? "",
      usernameVendor: json['Username_Vendor']?.toString() ?? "",
      namaVendor: json['Nama_Vendor']?.toString() ?? "",
      kota: json['Kota']?.toString() ?? "",
      idPaket: (json['Id_Paket'] is List)
          ? (json['Id_Paket'] as List).map((e) => e.toString()).toList()
          : [],
      tglCreated: DateTime.tryParse(json['Tgl_Created']?.toString() ?? "") ?? DateTime(2000),
      jumlahPaket: json['Jumlah_Paket'] is int ? json['Jumlah_Paket'] : 0,
      status: json['Status']?.toString() ?? "",
      ratingVendor: (json['Rating_Vendor'] is num)
          ? (json['Rating_Vendor'] as num).toDouble()
          : 0.0,
      hargaMinPaket: (json['Harga_Min_Paket'] is num) ? json['Harga_Min_Paket'] : 0,
      hargaMaxPaket: (json['Harga_Max_Paket'] is num) ? json['Harga_Max_Paket'] : 0,
      jumlahPortofolio: json['Jumlah_Portofolio'] is int ? json['Jumlah_Portofolio'] : 0,
      likes: json['Likes'] is int ? json['Likes'] : 0,
      saves: json['Saves'] is int ? json['Saves'] : 0,
      matchKota: json['Match_Kota'] is int ? json['Match_Kota'] : 0,
      fromSavedVendor:
          json['From_Saved_Vendor'] is int ? json['From_Saved_Vendor'] : 0,
      isSaved: json['Is_Saved'] == true,
        isLiked: json['Is_Liked'] == true,
      skorTotal: (json['Skor_Total'] is num)
          ? (json['Skor_Total'] as num).toDouble()
          : 0.0,
      contentType: firstMedia?.contentType ?? "",
      thumbUrl: firstMedia?.thumbUrl ?? firstMedia?.url ?? "",
      mediaUrls: mediaList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'No_Id': noId,
      'Id_Vendor': idVendor,
      'Id_Media': idMedia,
      'Id_Media_Vendor': idMediaVendor,
      'Id_Kategori': idKategori,
      'Username_Vendor': usernameVendor,
      'Nama_Vendor': namaVendor,
      'Kota': kota,
      'Id_Paket': idPaket,
      'Tgl_Created': tglCreated.toIso8601String(),
      'Jumlah_Paket': jumlahPaket,
      'Status': status,
      'Rating_Vendor': ratingVendor,
      'Harga_Min_Paket': hargaMinPaket,
      'Harga_Max_Paket': hargaMaxPaket,
      'Jumlah_Portofolio': jumlahPortofolio,
      'Likes': likes,
      'Saves': saves,
      'Match_Kota': matchKota,
      'From_Saved_Vendor': fromSavedVendor,
      'Is_Saved': isSaved,
      'Is_Liked': isLiked,
      'Skor_Total': skorTotal,
      'Content_Type': contentType,
      'Thumb_Url': thumbUrl,
      'MediaUrls': mediaUrls.map((e) => e.toJson()).toList(),
    };
  }
}

class MediaItem {
  final String? url;
  final String? contentType;
  final String? thumbUrl;

  MediaItem({
    this.url,
    this.contentType,
    this.thumbUrl,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      url: json['Url']?.toString(),
      contentType: json['ContentType']?.toString(),
      thumbUrl: json['ThumbUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Url': url,
      'ContentType': contentType,
      'ThumbUrl': thumbUrl,
    };
  }
}
