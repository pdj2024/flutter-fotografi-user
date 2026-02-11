import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:mpjnew/src/data/hive_entity/media_url_model.dart';

part 'portofolio_model.g.dart';

/// Model untuk Portfolio dengan support hybrid cache strategy
/// 
/// Cache Strategy:
/// - Metadata portfolio → Hive database
/// - Media files → Local file system
/// - Gunakan MediaUrlModel.localPath untuk referensi
@HiveType(typeId: 6)
class PortofolioModel extends Equatable {
  // =====================================
  // CORE FIELDS (DARI BACKEND)
  // =====================================
  
  @HiveField(0)
  final String noId;
  
  @HiveField(1)
  final String idVendor;
  
  @HiveField(2)
  final List<String> idMedia;
  
  @HiveField(3)
  final String? idMediaVendor;
  
  @HiveField(4)
  final String? idKategori;
  
  @HiveField(5)
  final String? namaKategori;
  
  @HiveField(6)
  final String? jenisMedia;
  
  @HiveField(7)
  final String? usernameVendor;
  
  @HiveField(8)
  final String? namaVendor;
  
  @HiveField(9)
  final String? kota;
  
  @HiveField(10)
  final String? namaKota;
  
  @HiveField(11)
  final List<String> idPaket;
  
  @HiveField(12)
  final dynamic paket;
  
  @HiveField(13)
  final DateTime tglCreated;
  
  @HiveField(14)
  final int? jumlahPaket;
  
  @HiveField(15)
  final String status;
  
  @HiveField(16)
  final int? ratingVendor;
  
  @HiveField(17)
  final int? hargaMinPaket;
  
  @HiveField(18)
  final int? hargaMaxPaket;
  
  @HiveField(19)
  final int? jumlahPortofolio;
  
  @HiveField(20)
  final int likes;
  
  @HiveField(21)
  final int saves;
  
  @HiveField(22)
  final int? matchKota;
  
  @HiveField(23)
  final int? fromSavedVendor;
  
  @HiveField(24)
  final bool? isSaved;
  
  @HiveField(25)
  final bool? isLiked;
  
  @HiveField(26)
  final double? skorTotal;
  
  @HiveField(27)
  final List<MediaUrlModel> mediaUrls;
  
  // =====================================
  // CACHE & SYNC FIELDS
  // =====================================
  
  @HiveField(28)
  final DateTime? lastUpdated;
  
  @HiveField(29)
  final DateTime? lastSynced;

  const PortofolioModel({
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
    this.lastUpdated,
    this.lastSynced,
  });

  @override
  List<Object?> get props => [
        noId,
        idVendor,
        idMedia,
        idMediaVendor,
        idKategori,
        namaKategori,
        jenisMedia,
        usernameVendor,
        namaVendor,
        kota,
        namaKota,
        idPaket,
        paket,
        tglCreated,
        jumlahPaket,
        status,
        ratingVendor,
        hargaMinPaket,
        hargaMaxPaket,
        jumlahPortofolio,
        likes,
        saves,
        matchKota,
        fromSavedVendor,
        isSaved,
        isLiked,
        skorTotal,
        mediaUrls,
        lastUpdated,
        lastSynced,
      ];

  // =====================================
  // STATUS HELPERS
  // =====================================
  
  /// Apakah portofolio aktif
  bool get isActive => status.toLowerCase() == 'aktif';
  
  /// Apakah portofolio diarsipkan
  bool get isArchived => status.toLowerCase() == 'nonaktif';
  
  /// Apakah portofolio dihapus
  bool get isDeleted => status.toLowerCase() == 'hapus';

  // =====================================
  // MEDIA CACHE HELPERS
  // =====================================
  
  /// Get semua media yang sudah ter-cache
  List<MediaUrlModel> get cachedMedia {
    return mediaUrls.where((m) => m.isCached).toList();
  }
  
  /// Get semua thumbnail (untuk grid view, list preview)
  List<MediaUrlModel> get thumbnails {
    return mediaUrls.map((media) {
      // Untuk video, gunakan thumbnail
      if (media.isVideo && media.localThumbPath != null) {
        return media;
      }
      // Untuk image, gunakan compressed version jika ada
      if (media.isImage && media.isCompressed == true) {
        return media;
      }
      return media;
    }).toList();
  }
  
  /// Get semua full-size images
  List<MediaUrlModel> get fullImages {
    return mediaUrls.where((m) => 
      m.isImage && (m.isCompressed == false || m.isCompressed == null)
    ).toList();
  }
  
  /// Get media untuk display (prioritas cache)
  List<MediaUrlModel> get displayMedia {
    return mediaUrls.map((m) => m.markAccessed()).toList();
  }
  
  /// Apakah ada media yang sudah ter-cache
  bool get hasCachedMedia {
    return mediaUrls.any((m) => m.isCached);
  }
  
  /// Apakah semua media sudah ter-cache
  bool get isFullyCached {
    if (mediaUrls.isEmpty) return false;
    return mediaUrls.every((m) => m.isCached);
  }
  
  /// Get media yang perlu di-download
  List<MediaUrlModel> get mediaNeedDownload {
    return mediaUrls.where((m) => 
      !m.isCached && 
      m.cacheStatus != MediaCacheStatus.failed
    ).toList();
  }
  
  /// Get media yang URL-nya expired
  List<MediaUrlModel> get expiredMedia {
    return mediaUrls.where((m) => m.isExpired).toList();
  }
  
  /// Apakah ada media yang URL-nya perlu di-refresh
  bool get needsUrlRefresh {
    return mediaUrls.any((m) => m.shouldRefreshUrl());
  }
  
  /// Get first media URL untuk preview/thumbnail
  String? get firstMediaUrl {
    if (mediaUrls.isEmpty) return null;
    return mediaUrls.first.displayUrl;
  }
  
  /// Get first thumbnail URL
  String? get firstThumbnailUrl {
    if (mediaUrls.isEmpty) return null;
    return mediaUrls.first.thumbnailUrl;
  }
  
  /// Total size cache (dalam bytes)
  int get totalCacheSize {
    return mediaUrls
        .where((m) => m.isCached)
        .fold(0, (sum, m) => sum + (m.size ?? 0));
  }
  
  /// Persentase media yang sudah ter-cache (0.0 - 1.0)
  double get cacheProgress {
    if (mediaUrls.isEmpty) return 0.0;
    final cached = mediaUrls.where((m) => m.isCached).length;
    return cached / mediaUrls.length;
  }

  // =====================================
  // SYNC HELPERS
  // =====================================
  
  /// Apakah data sudah outdated (perlu sync dari server)
  bool needsSync({Duration threshold = const Duration(hours: 1)}) {
    if (lastSynced == null) return true;
    final diff = DateTime.now().difference(lastSynced!);
    return diff > threshold;
  }

  // =====================================
  // SERIALIZATION
  // =====================================
  
  /// FROM JSON (dari backend)
  factory PortofolioModel.fromJson(Map<String, dynamic> json) {
    return PortofolioModel(
      noId: json['No_Id'] ?? '',
      idVendor: json['Id_Vendor'] ?? '',
      idMedia: json['Id_Media'] != null 
          ? List<String>.from(json['Id_Media']) 
          : [],
      idMediaVendor: json['Id_Media_Vendor'],
      idKategori: json['Id_Kategori'],
      namaKategori: json['Nama_Kategori'],
      jenisMedia: json['Jenis_Media'],
      usernameVendor: json['Username_Vendor'],
      namaVendor: json['Nama_Vendor'],
      kota: json['Kota'],
      namaKota: json['Nama_Kota'],
      idPaket: json['Id_Paket'] != null 
          ? List<String>.from(json['Id_Paket']) 
          : [],
      paket: json['Paket'],
      tglCreated: json['Tgl_Created'] != null
          ? DateTime.parse(json['Tgl_Created'])
          : DateTime.now(),
      jumlahPaket: json['Jumlah_Paket'],
      status: json['Status'] ?? '',
      ratingVendor: json['Rating_Vendor'],
      hargaMinPaket: json['Harga_Min_Paket'],
      hargaMaxPaket: json['Harga_Max_Paket'],
      jumlahPortofolio: json['Jumlah_Portofolio'],
      likes: json['Likes'] ?? 0,
      saves: json['Saves'] ?? 0,
      matchKota: json['Match_Kota'],
      fromSavedVendor: json['From_Saved_Vendor'],
      isSaved: json['Is_Saved'],
      isLiked: json['Is_Liked'],
      skorTotal: json['Skor_Total'] is int
          ? (json['Skor_Total'] as int).toDouble()
          : json['Skor_Total'],
      mediaUrls: json['MediaUrls'] != null
          ? (json['MediaUrls'] as List)
              .map((e) => MediaUrlModel.fromJson(e))
              .toList()
          : [],
      lastUpdated: json['Last_Updated'] != null
          ? DateTime.parse(json['Last_Updated'])
          : null,
      lastSynced: json['Last_Synced'] != null
          ? DateTime.parse(json['Last_Synced'])
          : null,
    );
  }

  /// TO JSON (untuk storage dan API)
  Map<String, dynamic> toJson() {
    return {
      'No_Id': noId,
      'Id_Vendor': idVendor,
      'Id_Media': idMedia,
      'Id_Media_Vendor': idMediaVendor,
      'Id_Kategori': idKategori,
      'Nama_Kategori': namaKategori,
      'Jenis_Media': jenisMedia,
      'Username_Vendor': usernameVendor,
      'Nama_Vendor': namaVendor,
      'Kota': kota,
      'Nama_Kota': namaKota,
      'Id_Paket': idPaket,
      'Paket': paket,
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
      'MediaUrls': mediaUrls.map((e) => e.toJson()).toList(),
      'Last_Updated': lastUpdated?.toIso8601String(),
      'Last_Synced': lastSynced?.toIso8601String(),
    };
  }

  /// TO JSON CREATE (untuk POST ke API)
  Map<String, dynamic> toJsonCreate() {
    return {
      'id_vendor': idVendor,
      'id_kategori': idKategori,
      'id_paket': idPaket,
      'jenis_media': jenisMedia,
      'status': status,
      'id_media': idMedia,
    };
  }

  /// TO JSON UPDATE (untuk PUT ke API)
  Map<String, dynamic> toJsonUpdate() {
    return {
      'id_vendor': idVendor,
      'id_kategori': idKategori,
      'id_paket': idPaket,
      'jenis_media': jenisMedia,
      'status': status,
      'id_media': idMedia,
    };
  }

  // =====================================
  // COPY WITH
  // =====================================
  
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
    int? ratingVendor,
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
    DateTime? lastUpdated,
    DateTime? lastSynced,
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
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastSynced: lastSynced ?? this.lastSynced,
    );
  }

  // =====================================
  // CACHE MANAGEMENT
  // =====================================
  
  /// Update specific media dengan cache info
  PortofolioModel updateMedia(String mediaId, MediaUrlModel updatedMedia) {
    final updatedList = mediaUrls.map((m) {
      if (m.idMedia == mediaId || m.noIdMedia == mediaId) {
        return updatedMedia;
      }
      return m;
    }).toList();
    
    return copyWith(
      mediaUrls: updatedList,
      lastUpdated: DateTime.now(),
    );
  }
  
  /// Mark portfolio sebagai sudah di-sync
  PortofolioModel markSynced() {
    return copyWith(
      lastSynced: DateTime.now(),
    );
  }
  
  /// Refresh semua expired URLs
  PortofolioModel refreshExpiredUrls(
    Map<String, MediaUrlModel> refreshedMedia,
  ) {
    final updatedList = mediaUrls.map((m) {
      final key = m.idMedia ?? m.noIdMedia;
      if (key != null && refreshedMedia.containsKey(key)) {
        return refreshedMedia[key]!;
      }
      return m;
    }).toList();
    
    return copyWith(
      mediaUrls: updatedList,
      lastSynced: DateTime.now(),
    );
  }

  // =====================================
  // LIST PARSER
  // =====================================
  
  static List<PortofolioModel> fromJsonList(List<dynamic> list) {
    return list.map((e) => PortofolioModel.fromJson(e)).toList();
  }
}