import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'media_url_model.g.dart';

/// Status cache untuk tracking lifecycle media
@HiveType(typeId: 1)
enum MediaCacheStatus {
  @HiveField(0)
  notCached,    // Belum di-download
  
  @HiveField(1)
  cached,       // Sudah tersimpan di local
  
  @HiveField(2)
  failed,       // Download gagal
  
  @HiveField(3)
  expired,      // File masih ada tapi URL expired
}

/// Model untuk menyimpan metadata media (image/video) dengan hybrid cache
/// 
/// Strategy:
/// - Metadata (URL, expiry) → Hive
/// - File binary → Local file system
/// - Gunakan localPath untuk referensi file
@HiveType(typeId: 2)
class MediaUrlModel extends Equatable {
  // =====================================
  // FIELDS DARI BACKEND (JANGAN DIUBAH)
  // =====================================
  
  @HiveField(0)
  final String? url;
  
  @HiveField(1)
  final DateTime? expiredAt;
  
  @HiveField(2)
  final bool? isCompressed;
  
  @HiveField(3)
  final String? contentType;
  
  @HiveField(4)
  final String? thumbUrl;
  
  @HiveField(5)
  final int? size;
  
  @HiveField(6)
  final String? idMedia;
  
  @HiveField(7)
  final String? noIdMedia;
  
  // =====================================
  // FIELDS UNTUK CACHE MANAGEMENT
  // =====================================
  
  /// Path file di local storage
  /// Example: /data/user/0/com.app/app_flutter/cache/media_123.jpg
  @HiveField(8)
  final String? localPath;
  
  /// Path thumbnail di local storage (untuk video)
  @HiveField(9)
  final String? localThumbPath;
  
  /// Kapan file pertama kali di-cache
  @HiveField(10)
  final DateTime? cachedAt;
  
  /// Kapan terakhir diakses (untuk LRU cleanup)
  @HiveField(11)
  final DateTime? lastAccessedAt;
  
  /// Status cache saat ini
  @HiveField(12)
  final MediaCacheStatus cacheStatus;

  const MediaUrlModel({
    this.url,
    this.expiredAt,
    this.isCompressed,
    this.contentType,
    this.thumbUrl,
    this.size,
    this.idMedia,
    this.noIdMedia,
    this.localPath,
    this.localThumbPath,
    this.cachedAt,
    this.lastAccessedAt,
    this.cacheStatus = MediaCacheStatus.notCached,
  });

  @override
  List<Object?> get props => [
        url,
        expiredAt,
        isCompressed,
        contentType,
        thumbUrl,
        size,
        idMedia,
        noIdMedia,
        localPath,
        localThumbPath,
        cachedAt,
        lastAccessedAt,
        cacheStatus,
      ];

  // =====================================
  // COMPUTED PROPERTIES
  // =====================================
  
  /// Apakah media adalah video
  bool get isVideo => contentType?.startsWith('video') ?? false;
  
  /// Apakah media adalah gambar
  bool get isImage => contentType?.startsWith('image') ?? false;
  
  /// Apakah file sudah ter-cache di local
  bool get isCached => 
      cacheStatus == MediaCacheStatus.cached && 
      localPath != null;
  
  /// Apakah URL sudah expired
  bool get isExpired {
    if (expiredAt == null) return false;
    return DateTime.now().isAfter(expiredAt!);
  }
  
  /// Apakah perlu refresh URL dari server
  /// 
  /// Return true jika:
  /// - URL expired atau akan expired dalam 1 jam
  /// - URL null tapi file ada (edge case)
  bool shouldRefreshUrl() {
    if (url == null) return true;
    if (expiredAt == null) return false;
    
    // Buffer 1 jam sebelum expired
    final bufferTime = expiredAt!.subtract(const Duration(hours: 1));
    return DateTime.now().isAfter(bufferTime);
  }
  
  /// URL yang tepat untuk display
  /// Priority: local cache → cloud URL
  String? get displayUrl {
    // Prioritas 1: Gunakan local cache jika ada
    if (isCached) return localPath;
    
    // Prioritas 2: Gunakan cloud URL
    if (isVideo) {
      return thumbUrl ?? idMedia;
    }
    return url ?? idMedia;
  }
  
  /// URL thumbnail (untuk video atau preview)
  String? get thumbnailUrl {
    if (localThumbPath != null) return localThumbPath;
    return thumbUrl ?? (isVideo ? thumbUrl : url);
  }
  
  /// Berapa lama file sudah tidak diakses (untuk LRU)
  Duration? get idleDuration {
    if (lastAccessedAt == null) return null;
    return DateTime.now().difference(lastAccessedAt!);
  }
  
  /// Apakah file sudah idle > 30 hari (kandidat cleanup)
  bool get isStale {
    final idle = idleDuration;
    if (idle == null) return false;
    return idle.inDays > 30;
  }

  // =====================================
  // SERIALIZATION
  // =====================================
  
  /// FROM JSON (dari backend)
  factory MediaUrlModel.fromJson(Map<String, dynamic> json) {
    return MediaUrlModel(
      url: json['Url'],
      expiredAt: json['Expired_At'] != null
          ? DateTime.parse(json['Expired_At'])
          : null,
      isCompressed: json['IsCompressed'],
      contentType: json['ContentType'],
      thumbUrl: json['ThumbUrl'],
      size: json['Size'],
      idMedia: json['Id_Media'],
      noIdMedia: json['No_Id_Media'],
      // Cache fields tidak ada di JSON backend
      localPath: json['local_path'],
      localThumbPath: json['local_thumb_path'],
      cachedAt: json['cached_at'] != null
          ? DateTime.parse(json['cached_at'])
          : null,
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.parse(json['last_accessed_at'])
          : null,
      cacheStatus: _parseCacheStatus(json['cache_status']),
    );
  }

  /// TO JSON (untuk storage)
  Map<String, dynamic> toJson() {
    return {
      'Url': url,
      'Expired_At': expiredAt?.toIso8601String(),
      'IsCompressed': isCompressed,
      'ContentType': contentType,
      'ThumbUrl': thumbUrl,
      'Size': size,
      'Id_Media': idMedia,
      'No_Id_Media': noIdMedia,
      // Cache fields
      'local_path': localPath,
      'local_thumb_path': localThumbPath,
      'cached_at': cachedAt?.toIso8601String(),
      'last_accessed_at': lastAccessedAt?.toIso8601String(),
      'cache_status': cacheStatus.name,
    };
  }

  // =====================================
  // CACHE MANAGEMENT METHODS
  // =====================================
  
  /// Mark media sebagai sudah diakses (update timestamp)
  MediaUrlModel markAccessed() {
    return copyWith(
      lastAccessedAt: DateTime.now(),
    );
  }
  
  /// Mark media sebagai ter-cache dengan path
  MediaUrlModel markCached({
    required String path,
    String? thumbPath,
  }) {
    return copyWith(
      localPath: path,
      localThumbPath: thumbPath,
      cachedAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
      cacheStatus: MediaCacheStatus.cached,
    );
  }
  
  /// Mark media sebagai expired (URL habis masa berlaku)
  MediaUrlModel markExpired() {
    return copyWith(
      cacheStatus: MediaCacheStatus.expired,
    );
  }
  
  /// Mark download failed
  MediaUrlModel markFailed() {
    return copyWith(
      cacheStatus: MediaCacheStatus.failed,
      lastAccessedAt: DateTime.now(),
    );
  }
  
  /// Clear cache data (tetapi simpan metadata)
  MediaUrlModel clearCache() {
    return copyWith(
      localPath: null,
      localThumbPath: null,
      cachedAt: null,
      cacheStatus: MediaCacheStatus.notCached,
    );
  }
  
  /// Update dengan URL baru dari server (refresh signed URL)
  MediaUrlModel refreshUrl({
    required String newUrl,
    DateTime? newExpiredAt,
    String? newThumbUrl,
  }) {
    return copyWith(
      url: newUrl,
      expiredAt: newExpiredAt,
      thumbUrl: newThumbUrl,
      cacheStatus: isCached 
          ? MediaCacheStatus.cached 
          : MediaCacheStatus.notCached,
    );
  }

  // =====================================
  // COPY WITH
  // =====================================
  
  MediaUrlModel copyWith({
    String? url,
    DateTime? expiredAt,
    bool? isCompressed,
    String? contentType,
    String? thumbUrl,
    int? size,
    String? idMedia,
    String? noIdMedia,
    String? localPath,
    String? localThumbPath,
    DateTime? cachedAt,
    DateTime? lastAccessedAt,
    MediaCacheStatus? cacheStatus,
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
      localPath: localPath ?? this.localPath,
      localThumbPath: localThumbPath ?? this.localThumbPath,
      cachedAt: cachedAt ?? this.cachedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      cacheStatus: cacheStatus ?? this.cacheStatus,
    );
  }

  // =====================================
  // HELPERS
  // =====================================
  
  static MediaCacheStatus _parseCacheStatus(dynamic value) {
    if (value == null) return MediaCacheStatus.notCached;
    if (value is MediaCacheStatus) return value;
    
    final str = value.toString().toLowerCase();
    switch (str) {
      case 'cached':
        return MediaCacheStatus.cached;
      case 'failed':
        return MediaCacheStatus.failed;
      case 'expired':
        return MediaCacheStatus.expired;
      default:
        return MediaCacheStatus.notCached;
    }
  }
}