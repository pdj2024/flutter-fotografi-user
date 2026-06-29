import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';

/// Service untuk preload gambar portofolio di background
/// 
/// Strategy:
/// - Load semua gambar saat portofolio di-fetch
/// - Gunakan priority queue (portofolio yang di-view dulu)
/// - Cache di memory & disk
/// - Throttle untuk tidak overwhelm network
class MediaPreloadService {
  static final MediaPreloadService _instance = MediaPreloadService._internal();
  factory MediaPreloadService() => _instance;
  MediaPreloadService._internal();

  // ═══════════════════════════════════════════════════════════
  // CONFIGURATION
  // ═══════════════════════════════════════════════════════════
  
  /// Max concurrent downloads
  static const int _maxConcurrent = 3;
  
  /// Max images to preload per batch
  static const int _maxPerBatch = 30;
  
  /// Delay between batches (ms)
  static const int _batchDelay = 500;
  
  /// Cache manager
  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  
  // ═══════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════
  
  /// Currently loading URLs
  final Set<String> _loadingUrls = {};
  
  /// Successfully preloaded URLs
  final Set<String> _preloadedUrls = {};
  
  /// Failed URLs (untuk retry logic)
  final Map<String, int> _failedUrls = {};
  
  /// Is service currently preloading
  bool _isPreloading = false;
  
  /// Priority queue untuk URL yang perlu di-load
  final List<_PreloadTask> _queue = [];
  
  // ═══════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════
  
  bool get isPreloading => _isPreloading;
  int get queueLength => _queue.length;
  int get preloadedCount => _preloadedUrls.length;
  int get failedCount => _failedUrls.length;
  
  /// Get preload statistics
  Map<String, dynamic> getStats() {
    return {
      'isPreloading': _isPreloading,
      'queueLength': _queue.length,
      'loadingCount': _loadingUrls.length,
      'preloadedCount': _preloadedUrls.length,
      'failedCount': _failedUrls.length,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // MAIN API
  // ═══════════════════════════════════════════════════════════
  
  /// Preload semua gambar dari list portofolio
  /// 
  /// Priority:
  /// 1. First 10 portfolios (yang muncul di screen)
  /// 2. Remaining portfolios
  Future<void> preloadPortfolios(
    List<PortofolioModel> portfolios, {
    int priorityCount = 10,
  }) async {
    if (portfolios.isEmpty) {
      debugPrint('[MediaPreload] 📭 No portfolios to preload');
      return;
    }

    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('[MediaPreload] 🚀 START PRELOAD');
    debugPrint('[MediaPreload]    Portfolios: ${portfolios.length}');
    debugPrint('[MediaPreload]    Priority: first $priorityCount');
    debugPrint('═══════════════════════════════════════════════════');

    // ✅ Split into priority & normal
    final priority = portfolios.take(priorityCount).toList();
    final normal = portfolios.skip(priorityCount).toList();

    // ✅ Preload priority portfolios first
    await _preloadBatch(priority, priority: 10);

    // ✅ Then preload remaining in background
    if (normal.isNotEmpty) {
      // Don't await - run in background
      unawaited(_preloadBatch(normal, priority: 5));
    }

    debugPrint('[MediaPreload] ✅ Priority batch queued');
  }

  /// Preload single portfolio (untuk detail view)
  Future<void> preloadPortfolio(
    PortofolioModel portfolio, {
    bool highPriority = true,
  }) async {
    await _preloadBatch(
      [portfolio],
      priority: highPriority ? 10 : 5,
    );
  }

  /// Preload specific media URLs
  Future<void> preloadUrls(
    List<String> urls, {
    int priority = 5,
  }) async {
    for (final url in urls) {
      if (!_shouldPreload(url)) continue;
      
      _queue.add(_PreloadTask(
        url: url,
        priority: priority,
        addedAt: DateTime.now(),
      ));
    }

    _queue.sort((a, b) => b.priority.compareTo(a.priority));
    
    if (!_isPreloading) {
      unawaited(_processQueue());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BATCH PROCESSING
  // ═══════════════════════════════════════════════════════════
  
  Future<void> _preloadBatch(
    List<PortofolioModel> portfolios, {
    required int priority,
  }) async {
    final tasks = <_PreloadTask>[];

    for (final portfolio in portfolios) {
      // Extract all media URLs
      final urls = _extractMediaUrls(portfolio);
      
      for (final url in urls) {
        if (!_shouldPreload(url)) continue;
        
        tasks.add(_PreloadTask(
          url: url,
          priority: priority,
          addedAt: DateTime.now(),
          portfolioId: portfolio.noId,
        ));
      }
    }

    if (tasks.isEmpty) {
      debugPrint('[MediaPreload] ℹ️ No new URLs to preload');
      return;
    }

    debugPrint('[MediaPreload] 📋 Adding ${tasks.length} tasks (priority: $priority)');
    
    // Add to queue
    _queue.addAll(tasks);
    
    // Sort by priority
    _queue.sort((a, b) => b.priority.compareTo(a.priority));

    // Start processing if not already running
    if (!_isPreloading) {
      unawaited(_processQueue());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // QUEUE PROCESSING
  // ═══════════════════════════════════════════════════════════
  
  Future<void> _processQueue() async {
    if (_isPreloading) return;
    if (_queue.isEmpty) return;

    _isPreloading = true;
    
    debugPrint('[MediaPreload] ⚙️ Processing queue: ${_queue.length} tasks');

    int batchCount = 0;
    
    while (_queue.isNotEmpty) {
      // Take next batch
      final batch = _queue.take(_maxPerBatch).toList();
      _queue.removeRange(0, batch.length);

      batchCount++;
      debugPrint('[MediaPreload] 📦 Batch $batchCount: ${batch.length} images');

      // Process batch with concurrency limit
      await _processBatchConcurrent(batch);

      // Delay between batches to avoid overwhelming network
      if (_queue.isNotEmpty) {
        await Future.delayed(Duration(milliseconds: _batchDelay));
      }
    }

    _isPreloading = false;
    
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('[MediaPreload] ✅ PRELOAD COMPLETE');
    debugPrint('[MediaPreload]    Batches: $batchCount');
    debugPrint('[MediaPreload]    Preloaded: ${_preloadedUrls.length}');
    debugPrint('[MediaPreload]    Failed: ${_failedUrls.length}');
    debugPrint('═══════════════════════════════════════════════════');
  }

  Future<void> _processBatchConcurrent(List<_PreloadTask> tasks) async {
    final futures = <Future<void>>[];
    
    for (int i = 0; i < tasks.length; i += _maxConcurrent) {
      final chunk = tasks.skip(i).take(_maxConcurrent).toList();
      
      // Process chunk concurrently
      final chunkFutures = chunk.map((task) => _preloadSingle(task));
      futures.addAll(chunkFutures);
      
      // Wait for chunk to complete before starting next
      await Future.wait(chunkFutures, eagerError: false);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SINGLE PRELOAD
  // ═══════════════════════════════════════════════════════════
  
  Future<void> _preloadSingle(_PreloadTask task) async {
    final url = task.url;
    
    if (_loadingUrls.contains(url)) return;
    if (_preloadedUrls.contains(url)) return;

    _loadingUrls.add(url);

    try {
      debugPrint('[MediaPreload]    📥 Loading: ${_shortUrl(url)}');

      await _cacheManager.getSingleFile(url);
      _preloadedUrls.add(url);
      _failedUrls.remove(url);

    } catch (e) {
      final failCount = (_failedUrls[url] ?? 0) + 1;
      _failedUrls[url] = failCount;
      
      debugPrint('[MediaPreload]    ❌ Failed: ${_shortUrl(url)} (attempt $failCount)');
      
      // Retry once for transient errors
      if (failCount == 1 && e.toString().contains('SocketException')) {
        debugPrint('[MediaPreload]    🔄 Will retry later');
        _queue.add(task.copyWith(priority: task.priority - 1));
      }
    } finally {
      _loadingUrls.remove(url);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════
  
  /// Extract all media URLs from portfolio
  List<String> _extractMediaUrls(PortofolioModel portfolio) {
    final urls = <String>[];

    for (final media in portfolio.mediaUrls) {
      if (media.isCached && media.localPath != null) continue;

      // Gunakan idMedia agar cocok dengan URL yang di-render PortofolioCard.
      // Fallback ke url jika idMedia kosong.
      final displayUrl = media.idMedia ?? media.url;
      if (displayUrl != null &&
          displayUrl.isNotEmpty &&
          displayUrl.startsWith('http')) {
        urls.add(displayUrl);
      }

      // Thumbnail video
      if (media.isVideo &&
          media.thumbUrl != null &&
          media.thumbUrl!.isNotEmpty) {
        urls.add(media.thumbUrl!);
      }
    }

    return urls;
  }

  /// Should this URL be preloaded?
  bool _shouldPreload(String url) {
    // Already preloaded
    if (_preloadedUrls.contains(url)) return false;
    
    // Currently loading
    if (_loadingUrls.contains(url)) return false;
    
    // Failed too many times
    if ((_failedUrls[url] ?? 0) >= 2) return false;
    
    // Invalid URL
    if (url.isEmpty || !url.startsWith('http')) return false;
    
    return true;
  }

  /// Shorten URL for logging
  String _shortUrl(String url) {
    if (url.length <= 50) return url;
    return '...${url.substring(url.length - 47)}';
  }

  // ═══════════════════════════════════════════════════════════
  // CACHE MANAGEMENT
  // ═══════════════════════════════════════════════════════════\

  /// Warm Flutter's in-memory image cache secara parallel.
  /// Gunakan ini hanya untuk sejumlah kecil URL agar tidak membebani network.
  Future<void> warmMemoryCache(
    List<String> urls,
    BuildContext context, {
    int maxCount = 5,
  }) async {
    if (!context.mounted) return;
    final targets = urls
        .where((u) => u.isNotEmpty && u.startsWith('http'))
        .take(maxCount)
        .toList();

    await Future.wait(
      targets.map((url) async {
        try {
          if (context.mounted) {
            await precacheImage(CachedNetworkImageProvider(url), context);
          }
        } catch (_) {}
      }),
    );
  }
  
  /// Check if URL is cached
  Future<bool> isCached(String url) async {
    try {
      final fileInfo = await _cacheManager.getFileFromCache(url);
      return fileInfo != null;
    } catch (e) {
      return false;
    }
  }

  /// Clear all caches
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
    _preloadedUrls.clear();
    _failedUrls.clear();
    debugPrint('[MediaPreload] 🗑️ Cache cleared');
  }

  /// Clear specific URL from cache
  Future<void> removeCached(String url) async {
    await _cacheManager.removeFile(url);
    _preloadedUrls.remove(url);
    debugPrint('[MediaPreload] 🗑️ Removed: ${_shortUrl(url)}');
  }

  // ═══════════════════════════════════════════════════════════
  // CONTROL
  // ═══════════════════════════════════════════════════════════
  
  /// Cancel all pending preloads
  void cancelAll() {
    _queue.clear();
    _loadingUrls.clear();
    _isPreloading = false;
    debugPrint('[MediaPreload] 🛑 All preloads cancelled');
  }

  /// Pause preloading
  void pause() {
    _isPreloading = false;
    debugPrint('[MediaPreload] ⏸️ Preloading paused');
  }

  /// Resume preloading
  void resume() {
    if (_queue.isNotEmpty && !_isPreloading) {
      unawaited(_processQueue());
      debugPrint('[MediaPreload] ▶️ Preloading resumed');
    }
  }

  /// Print current stats
  void printStats() {
    final stats = getStats();
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('[MediaPreload] 📊 STATISTICS');
    debugPrint('[MediaPreload]    Queue: ${stats['queueLength']}');
    debugPrint('[MediaPreload]    Loading: ${stats['loadingCount']}');
    debugPrint('[MediaPreload]    Preloaded: ${stats['preloadedCount']}');
    debugPrint('[MediaPreload]    Failed: ${stats['failedCount']}');
    debugPrint('[MediaPreload]    Active: ${stats['isPreloading']}');
    debugPrint('═══════════════════════════════════════════════════');
  }
}

// ═══════════════════════════════════════════════════════════
// PRELOAD TASK
// ═══════════════════════════════════════════════════════════

class _PreloadTask {
  final String url;
  final int priority; // Higher = more important
  final DateTime addedAt;
  final String? portfolioId;

  _PreloadTask({
    required this.url,
    required this.priority,
    required this.addedAt,
    this.portfolioId,
  });

  _PreloadTask copyWith({
    String? url,
    int? priority,
    DateTime? addedAt,
    String? portfolioId,
  }) {
    return _PreloadTask(
      url: url ?? this.url,
      priority: priority ?? this.priority,
      addedAt: addedAt ?? this.addedAt,
      portfolioId: portfolioId ?? this.portfolioId,
    );
  }
}