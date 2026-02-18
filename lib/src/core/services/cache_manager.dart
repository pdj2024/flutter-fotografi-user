import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/data/hive_entity/media_url_model.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

/// ═══════════════════════════════════════════════════════════════
/// CACHE MANAGER - Hybrid Cache Orchestrator
///
/// Perubahan dari versi sebelumnya:
/// - ✅ Lazy init: tidak perlu panggil initialize() secara manual
///   dari luar. _ensureInitialized() akan auto-init jika belum siap.
/// - ✅ Satu Future _initFuture untuk guard concurrent init calls
/// ═══════════════════════════════════════════════════════════════

enum CachePriority { high, normal, low }

class CacheManager {
  // ── Singleton ──────────────────────────────────────────────
  static final CacheManager instance = CacheManager._internal();
  CacheManager._internal();

  // ── State ──────────────────────────────────────────────────
  late Box<PortofolioModel> _portofolioBox;
  late Directory _cacheDir;
  bool _initialized = false;

  // Guard: jika init sedang berjalan, tunggu Future yang sama
  // bukan spawn init baru. Ini aman untuk concurrent calls.
  Future<void>? _initFuture;

  final Map<String, Future<MediaUrlModel>> _downloadTasks = {};

  int _totalDownloads = 0;
  int _totalHits = 0;
  int _totalMisses = 0;

  // ── Init ───────────────────────────────────────────────────

  /// Panggil ini di main() untuk eager init (opsional).
  /// Jika tidak dipanggil, lazy init akan berjalan otomatis
  /// saat pertama kali cacheMedia() dipanggil.
  Future<void> initialize() async {
    await _ensureInitialized();
  }

  /// Lazy init — aman dipanggil berkali-kali secara concurrent.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    // Jika sudah ada init yang sedang berjalan, tunggu saja
    _initFuture ??= _doInit();
    await _initFuture;
  }

  Future<void> _doInit() async {
    try {
      _cacheDir = await _getCacheDirectory();
      debugPrint('[CacheManager] 📁 Cache dir: ${_cacheDir.path}');

      if (!Hive.isBoxOpen('portfolios_cache')) {
        _portofolioBox =
            await Hive.openBox<PortofolioModel>('portfolios_cache');
      } else {
        _portofolioBox = Hive.box<PortofolioModel>('portfolios_cache');
      }

      debugPrint(
          '[CacheManager] 📦 Hive box: ${_portofolioBox.length} items');

      _initialized = true;
      debugPrint('[CacheManager] ✅ Initialized');

      // Cleanup lama di background
      Future.delayed(const Duration(seconds: 5), () {
        cleanupStaleCache(maxAgeDays: 90);
      });
    } catch (e, st) {
      // Reset agar bisa dicoba ulang
      _initFuture = null;
      debugPrint('[CacheManager] ❌ Init failed: $e\n$st');
      rethrow;
    }
  }

  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/media_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ── Cache Operations ───────────────────────────────────────

  /// Download dan cache media ke disk.
  /// Auto-init jika CacheManager belum diinisialisasi.
  Future<MediaUrlModel> cacheMedia(
    MediaUrlModel media, {
    CachePriority priority = CachePriority.normal,
  }) async {
    // ✅ Lazy init — tidak akan throw "not initialized" lagi
    await _ensureInitialized();

    // Sudah cached dan file masih ada
    if (media.isCached && media.localPath != null) {
      final file = File(media.localPath!);
      if (await file.exists()) {
        _totalHits++;
        return media.markAccessed();
      }
      // File hilang — re-download
      debugPrint('[CacheManager] ⚠️ File missing, re-downloading: ${media.localPath}');
    }

    _totalMisses++;

    final key = media.idMedia ?? media.noIdMedia;
    if (key == null) {
      debugPrint('[CacheManager] ❌ Media ID is null, skip cache');
      return media;
    }

    // Reuse task jika download sudah berjalan
    if (_downloadTasks.containsKey(key)) {
      debugPrint('[CacheManager] 🔄 Reusing task: $key');
      return _downloadTasks[key]!;
    }

    final task = _performDownload(media, priority);
    _downloadTasks[key] = task;

    try {
      return await task;
    } finally {
      _downloadTasks.remove(key);
    }
  }

  Future<MediaUrlModel> _performDownload(
    MediaUrlModel media,
    CachePriority priority,
  ) async {
    try {
      final url = media.url ?? media.idMedia;
      if (url == null || url.isEmpty) {
        debugPrint('[CacheManager] ❌ No URL: ${media.idMedia}');
        return media.markFailed();
      }

      debugPrint('[CacheManager] 📥 Downloading: ${media.idMedia} (${priority.name})');

      Uri uri;
      try {
        uri = Uri.parse(url);
      } catch (e) {
        debugPrint('[CacheManager] ❌ Invalid URL: $e');
        return media.markFailed();
      }

      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Timeout 30s'),
      );

      if (response.statusCode != 200) {
        debugPrint('[CacheManager] ❌ HTTP ${response.statusCode}');
        return media.markFailed();
      }

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        debugPrint('[CacheManager] ❌ Empty response');
        return media.markFailed();
      }

      final safeId = _sanitizeFilename(media.idMedia ?? 'media');
      final ext = _getExtension(media.contentType);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${_cacheDir.path}/${safeId}_$ts.$ext';

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (!await file.exists() || await file.length() == 0) {
        debugPrint('[CacheManager] ❌ File save failed: $filePath');
        if (await file.exists()) await file.delete();
        return media.markFailed();
      }

      _totalDownloads++;
      final kb = (bytes.length / 1024).toStringAsFixed(1);
      debugPrint('[CacheManager] ✅ Saved: ${file.path.split('/').last} ($kb KB)');

      return media.markCached(path: filePath);
    } on TimeoutException catch (e) {
      debugPrint('[CacheManager] ⏱️ Timeout: $e');
      return media.markFailed();
    } on http.ClientException catch (e) {
      debugPrint('[CacheManager] 🌐 Network error: $e');
      return media.markFailed();
    } on FileSystemException catch (e) {
      debugPrint('[CacheManager] 💾 FS error: $e');
      return media.markFailed();
    } catch (e, st) {
      debugPrint('[CacheManager] ❌ Unexpected: $e\n$st');
      return media.markFailed();
    }
  }

  String _sanitizeFilename(String name) {
    final sanitized = name
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return sanitized.length > 50 ? sanitized.substring(0, 50) : sanitized;
  }

  String _getExtension(String? contentType) {
    if (contentType == null) return 'bin';
    final t = contentType.toLowerCase();
    if (t.contains('jpeg') || t.contains('jpg')) return 'jpg';
    if (t.contains('png')) return 'png';
    if (t.contains('webp')) return 'webp';
    if (t.contains('gif')) return 'gif';
    if (t.contains('mp4')) return 'mp4';
    if (t.contains('mov')) return 'mov';
    return 'bin';
  }

  // ── Cleanup ────────────────────────────────────────────────

  Future<void> cleanupStaleCache({int maxAgeDays = 30}) async {
    await _ensureInitialized();
    try {
      final now = DateTime.now();
      final files = _cacheDir.listSync();
      int deleted = 0;
      int freedBytes = 0;

      for (final f in files) {
        if (f is File) {
          final age = now.difference((await f.stat()).modified);
          if (age.inDays > maxAgeDays) {
            freedBytes += await f.length();
            await f.delete();
            deleted++;
          }
        }
      }

      if (deleted > 0) {
        final mb = (freedBytes / 1024 / 1024).toStringAsFixed(2);
        debugPrint('[CacheManager] 🗑️ Cleanup: $deleted files, $mb MB freed');
      }
    } catch (e) {
      debugPrint('[CacheManager] ⚠️ Cleanup error: $e');
    }
  }

  Future<void> clearAllCache() async {
    await _ensureInitialized();
    try {
      int deleted = 0;
      for (final f in _cacheDir.listSync()) {
        if (f is File) {
          await f.delete();
          deleted++;
        }
      }
      await _portofolioBox.clear();
      _totalDownloads = 0;
      _totalHits = 0;
      _totalMisses = 0;
      debugPrint('[CacheManager] ✅ All cleared: $deleted files');
    } catch (e) {
      debugPrint('[CacheManager] ❌ Clear error: $e');
    }
  }

  // ── Utility ────────────────────────────────────────────────

  Future<bool> isCached(String mediaId) async {
    await _ensureInitialized();
    try {
      return _cacheDir
          .listSync()
          .any((f) => f.path.contains(mediaId));
    } catch (_) {
      return false;
    }
  }

  Future<String?> getCachedPath(String mediaId) async {
    await _ensureInitialized();
    try {
      final match = _cacheDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains(mediaId))
          .firstOrNull;
      return match?.path;
    } catch (_) {
      return null;
    }
  }

  // ── Stats ──────────────────────────────────────────────────

  Future<CacheStats> getStats() async {
    await _ensureInitialized();
    try {
      int totalFiles = 0;
      int totalSize = 0;
      for (final f in _cacheDir.listSync()) {
        if (f is File) {
          totalFiles++;
          totalSize += await f.length();
        }
      }
      final total = _totalHits + _totalMisses;
      return CacheStats(
        totalCached: totalFiles,
        totalSizeMB: totalSize / (1024 * 1024),
        hitRate: total > 0 ? _totalHits / total : 0.0,
        expiredUrls: 0,
        totalDownloads: _totalDownloads,
        totalHits: _totalHits,
        totalMisses: _totalMisses,
      );
    } catch (e) {
      return CacheStats.empty();
    }
  }

  Future<void> printStats() async {
    final s = await getStats();
    debugPrint('═══════════════════════════════════════');
    debugPrint('📊 CACHE STATISTICS');
    debugPrint('   Files  : ${s.totalCached}');
    debugPrint('   Size   : ${s.totalSizeMB.toStringAsFixed(2)} MB');
    debugPrint('   Hits   : ${s.totalHits} | Misses: ${s.totalMisses}');
    debugPrint('   HitRate: ${(s.hitRate * 100).toStringAsFixed(1)}%');
    debugPrint('═══════════════════════════════════════');
  }
}

// ── Stats Model ────────────────────────────────────────────────

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
        totalSizeMB: 0,
        hitRate: 0,
        expiredUrls: 0,
      );
}