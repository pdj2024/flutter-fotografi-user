import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/data/hive_entity/media_url_model.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

// Import revised models

/// ═══════════════════════════════════════════════════════════════
/// CACHE MANAGER - Hybrid Cache Orchestrator
/// ═══════════════════════════════════════════════════════════════
///
/// Responsibilities:
/// - Download & cache media files to disk
/// - Track cache metadata in Hive
/// - LRU cleanup for old files
/// - Prevent duplicate downloads
/// - Monitor cache statistics
///
/// Strategy:
/// - Metadata (URLs, paths, timestamps) → Hive
/// - Binary files (images, videos) → File system
/// - Singleton pattern for global access
///
/// ═══════════════════════════════════════════════════════════════

enum CachePriority {
  high, // Download immediately (user tapped)
  normal, // Download soon (visible on screen)
  low, // Download later (background preload)
}

class CacheManager {
  // ───────────────────────────────────────────────────
  // SINGLETON PATTERN
  // ───────────────────────────────────────────────────

  static final CacheManager instance = CacheManager._internal();
  CacheManager._internal();

  // ───────────────────────────────────────────────────
  // STATE
  // ───────────────────────────────────────────────────

  late Box<PortofolioModel> _portofolioBox;
  late Directory _cacheDir;
  bool _initialized = false;

  // Track ongoing downloads to prevent duplicates
  final Map<String, Future<MediaUrlModel>> _downloadTasks = {};

  // Statistics
  int _totalDownloads = 0;
  int _totalHits = 0;
  int _totalMisses = 0;

  // ───────────────────────────────────────────────────
  // INITIALIZATION
  // ───────────────────────────────────────────────────

  /// Initialize cache manager
  /// Call this in main() after Hive.initFlutter()
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('[CacheManager] ⚠️ Already initialized');
      return;
    }

    try {
      // 1. Setup cache directory
      _cacheDir = await _getCacheDirectory();
      debugPrint('[CacheManager] 📁 Cache dir: ${_cacheDir.path}');

      // 2. Open Hive box for portfolio metadata
      _portofolioBox = await Hive.openBox<PortofolioModel>('portfolios_cache');
      debugPrint(
          '[CacheManager] 📦 Hive box opened: ${_portofolioBox.length} items');

      _initialized = true;
      debugPrint('[CacheManager] ✅ Initialized successfully');

      // 3. Optional: Run initial cleanup
      _cleanupOnStartup();
    } catch (e, st) {
      debugPrint('[CacheManager] ❌ Initialization failed: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/media_cache');

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
      debugPrint('[CacheManager] Created cache directory');
    }

    return cacheDir;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
          'CacheManager not initialized. Call CacheManager.instance.initialize() first.');
    }
  }

  // ───────────────────────────────────────────────────
  // CACHE OPERATIONS
  // ───────────────────────────────────────────────────

  /// Download dan cache media ke disk
  ///
  /// Returns: Updated MediaUrlModel dengan localPath
  /// Throws: Exception jika download gagal
  Future<MediaUrlModel> cacheMedia(
    MediaUrlModel media, {
    CachePriority priority = CachePriority.normal,
  }) async {
    _ensureInitialized();

    // Jika sudah cached, return existing
    if (media.isCached && media.localPath != null) {
      final file = File(media.localPath!);
      if (await file.exists()) {
        _totalHits++;
        return media.markAccessed();
      } else {
        // File hilang, perlu re-download
        debugPrint('[CacheManager] ⚠️ Cache file missing: ${media.localPath}');
      }
    }

    _totalMisses++;

    // Get unique key untuk media
    final key = media.idMedia ?? media.noIdMedia;
    if (key == null) {
      throw Exception('Media ID is null, cannot cache');
    }

    // Reuse existing download task jika ada
    if (_downloadTasks.containsKey(key)) {
      debugPrint('[CacheManager] 🔄 Reusing download task: $key');
      return _downloadTasks[key]!;
    }

    // Create new download task
    final task = _performDownload(media, priority);
    _downloadTasks[key] = task;

    try {
      final result = await task;
      return result;
    } finally {
      _downloadTasks.remove(key);
    }
  }

  /// Internal: Perform actual download
  Future<MediaUrlModel> _performDownload(
    MediaUrlModel media,
    CachePriority priority,
  ) async {
    try {
      // Get URL untuk download
      final url = media.url ?? media.idMedia;
      if (url == null || url.isEmpty) {
        debugPrint('[CacheManager] ❌ No URL available');
        debugPrint('[CacheManager]    Media ID: ${media.idMedia}');
        return media.markFailed();
      }

      debugPrint('[CacheManager] 📥 Downloading...');
      debugPrint('[CacheManager]    Media ID: ${media.idMedia}');
      debugPrint('[CacheManager]    URL length: ${url.length} chars');
      debugPrint('[CacheManager]    Priority: $priority');

      // Parse URL dengan error handling
      Uri uri;
      try {
        uri = Uri.parse(url);
      } catch (e) {
        debugPrint('[CacheManager] ❌ Invalid URL format: $e');
        return media.markFailed();
      }

      // Download file dengan timeout
      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Download timeout after 30s');
        },
      );

      if (response.statusCode != 200) {
        debugPrint('[CacheManager] ❌ HTTP ${response.statusCode}');
        debugPrint(
            '[CacheManager]    Response: ${response.body.substring(0, 100)}...');
        return media.markFailed();
      }

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        debugPrint('[CacheManager] ❌ Empty response body');
        return media.markFailed();
      }

      // Generate safe filename (remove special chars dari idMedia)
      final safeMediaId = _sanitizeFilename(media.idMedia ?? 'media');
      final ext = _getExtension(media.contentType);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${safeMediaId}_$timestamp.$ext';
      final filePath = '${_cacheDir.path}/$fileName';

      // Save to disk
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Verify file saved correctly
      if (!await file.exists()) {
        debugPrint('[CacheManager] ❌ File not saved: $filePath');
        return media.markFailed();
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        debugPrint('[CacheManager] ❌ File is empty');
        await file.delete();
        return media.markFailed();
      }

      _totalDownloads++;

      debugPrint('[CacheManager] ✅ Saved: $fileName');
      debugPrint(
          '[CacheManager]    Size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      debugPrint('[CacheManager]    Path: $filePath');

      // Return updated media dengan cache info
      return media.markCached(path: filePath);
    } on TimeoutException catch (e) {
      debugPrint('[CacheManager] ⏱️ Timeout: $e');
      return media.markFailed();
    } on http.ClientException catch (e) {
      debugPrint('[CacheManager] 🌐 Network error: $e');
      return media.markFailed();
    } on FileSystemException catch (e) {
      debugPrint('[CacheManager] 💾 File system error: $e');
      return media.markFailed();
    } catch (e, st) {
      debugPrint('[CacheManager] ❌ Unexpected error: $e');
      debugPrint('[CacheManager] Stack trace:');
      debugPrint(st.toString());
      return media.markFailed();
    }
  }

  /// Sanitize filename untuk keamanan
  String _sanitizeFilename(String filename) {
    // Remove special characters, keep only alphanumeric, dash, underscore
    return filename
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_') // Replace multiple underscores with one
        .substring(
            0, filename.length > 50 ? 50 : filename.length); // Limit length
  }

  String _getExtension(String? contentType) {
    if (contentType == null) return 'bin';

    final type = contentType.toLowerCase();

    if (type.contains('jpeg') || type.contains('jpg')) return 'jpg';
    if (type.contains('png')) return 'png';
    if (type.contains('webp')) return 'webp';
    if (type.contains('gif')) return 'gif';
    if (type.contains('mp4')) return 'mp4';
    if (type.contains('mov')) return 'mov';

    return 'bin';
  }

  // ───────────────────────────────────────────────────
  // LRU & ACCESS TRACKING
  // ───────────────────────────────────────────────────

  /// Mark media sebagai diakses (update timestamp)
  Future<void> markMediaAccessed(MediaUrlModel media) async {
    _ensureInitialized();

    try {
      // Update last accessed timestamp
      final updated = media.markAccessed();

      // Optional: Update di Hive jika disimpan
      // Implementasi tergantung struktur storage Anda

      debugPrint('[CacheManager] 👆 Marked accessed: ${media.idMedia}');
    } catch (e) {
      debugPrint('[CacheManager] ⚠️ Mark access failed: $e');
    }
  }

  // ───────────────────────────────────────────────────
  // CLEANUP & MAINTENANCE
  // ───────────────────────────────────────────────────

  /// Cleanup cache files yang sudah tidak diakses > maxAgeDays
  Future<void> cleanupStaleCache({int maxAgeDays = 30}) async {
    _ensureInitialized();

    try {
      debugPrint(
          '[CacheManager] 🗑️ Starting cleanup (max age: $maxAgeDays days)');

      final now = DateTime.now();
      final files = _cacheDir.listSync();
      int deletedCount = 0;
      int deletedBytes = 0;

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);

          if (age.inDays > maxAgeDays) {
            final size = await file.length();
            await file.delete();
            deletedCount++;
            deletedBytes += size;

            debugPrint(
                '[CacheManager]    Deleted: ${file.path} (${age.inDays} days old)');
          }
        }
      }

      debugPrint('[CacheManager] ✅ Cleanup complete:');
      debugPrint('[CacheManager]    Files deleted: $deletedCount');
      debugPrint(
          '[CacheManager]    Space freed: ${(deletedBytes / 1024 / 1024).toStringAsFixed(2)} MB');
    } catch (e, st) {
      debugPrint('[CacheManager] ❌ Cleanup error: $e');
      debugPrint(st.toString());
    }
  }

  /// Cleanup saat app startup (hapus file corrupt atau sangat lama)
  Future<void> _cleanupOnStartup() async {
    try {
      // Cleanup file > 90 hari di background
      Future.delayed(const Duration(seconds: 5), () {
        cleanupStaleCache(maxAgeDays: 90);
      });
    } catch (e) {
      debugPrint('[CacheManager] Startup cleanup failed: $e');
    }
  }

  /// Clear ALL cache (untuk logout atau reset)
  Future<void> clearAllCache() async {
    _ensureInitialized();

    try {
      debugPrint('[CacheManager] 🗑️ Clearing all cache...');

      final files = _cacheDir.listSync();
      int deletedCount = 0;

      for (final file in files) {
        if (file is File) {
          await file.delete();
          deletedCount++;
        }
      }

      // Clear Hive box juga
      await _portofolioBox.clear();

      debugPrint('[CacheManager] ✅ All cache cleared: $deletedCount files');

      // Reset statistics
      _totalDownloads = 0;
      _totalHits = 0;
      _totalMisses = 0;
    } catch (e, st) {
      debugPrint('[CacheManager] ❌ Clear cache error: $e');
      debugPrint(st.toString());
    }
  }

  // ───────────────────────────────────────────────────
  // STATISTICS & MONITORING
  // ───────────────────────────────────────────────────

  /// Get cache statistics
  Future<CacheStats> getStats() async {
    _ensureInitialized();

    try {
      final files = _cacheDir.listSync();
      int totalFiles = 0;
      int totalSize = 0;
      int expiredCount = 0;

      for (final file in files) {
        if (file is File) {
          totalFiles++;
          totalSize += await file.length();
        }
      }

      // Calculate hit rate
      final totalRequests = _totalHits + _totalMisses;
      final hitRate = totalRequests > 0 ? _totalHits / totalRequests : 0.0;

      return CacheStats(
        totalCached: totalFiles,
        totalSizeMB: totalSize / (1024 * 1024),
        hitRate: hitRate,
        expiredUrls: expiredCount,
        totalDownloads: _totalDownloads,
        totalHits: _totalHits,
        totalMisses: _totalMisses,
      );
    } catch (e) {
      debugPrint('[CacheManager] ⚠️ Stats error: $e');
      return CacheStats.empty();
    }
  }

  /// Print current stats (untuk debugging)
  Future<void> printStats() async {
    final stats = await getStats();

    debugPrint('═══════════════════════════════════════');
    debugPrint('📊 CACHE STATISTICS');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Files cached: ${stats.totalCached}');
    debugPrint('Total size: ${stats.totalSizeMB.toStringAsFixed(2)} MB');
    debugPrint('Hit rate: ${(stats.hitRate * 100).toStringAsFixed(1)}%');
    debugPrint('Downloads: ${stats.totalDownloads}');
    debugPrint('Hits: ${stats.totalHits}');
    debugPrint('Misses: ${stats.totalMisses}');
    debugPrint('═══════════════════════════════════════');
  }

  // ───────────────────────────────────────────────────
  // UTILITY METHODS
  // ───────────────────────────────────────────────────

  /// Check if file exists di cache
  Future<bool> isCached(String mediaId) async {
    _ensureInitialized();

    try {
      final files = _cacheDir.listSync();

      for (final file in files) {
        if (file.path.contains(mediaId)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get file path jika sudah cached
  Future<String?> getCachedPath(String mediaId) async {
    _ensureInitialized();

    try {
      final files = _cacheDir.listSync();

      for (final file in files) {
        if (file.path.contains(mediaId)) {
          return file.path;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// CACHE STATISTICS MODEL
// ═══════════════════════════════════════════════════════════════

class CacheStats {
  final int totalCached;
  final double totalSizeMB;
  final double hitRate;
  final int expiredUrls;
  final int totalDownloads;
  final int totalHits;
  final int totalMisses;

  const CacheStats({
    required this.totalCached,
    required this.totalSizeMB,
    required this.hitRate,
    required this.expiredUrls,
    this.totalDownloads = 0,
    this.totalHits = 0,
    this.totalMisses = 0,
  });

  factory CacheStats.empty() => const CacheStats(
        totalCached: 0,
        totalSizeMB: 0.0,
        hitRate: 0.0,
        expiredUrls: 0,
        totalDownloads: 0,
        totalHits: 0,
        totalMisses: 0,
      );

  Map<String, dynamic> toJson() => {
        'total_cached': totalCached,
        'total_size_mb': totalSizeMB,
        'hit_rate': hitRate,
        'expired_urls': expiredUrls,
        'total_downloads': totalDownloads,
        'total_hits': totalHits,
        'total_misses': totalMisses,
      };

  @override
  String toString() {
    return 'CacheStats(cached: $totalCached, size: ${totalSizeMB.toStringAsFixed(2)}MB, '
        'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
}
