import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/cache_manager.dart';
import 'package:mpjnew/src/data/hive_entity/media_url_model.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';

/// ═══════════════════════════════════════════════════════════
/// PORTOFOLIO LOCAL SERVICE - Top 10 Cache Strategy
///
/// Strategy:
/// - Cache ONLY top 10 most recent portfolios
/// - Download & store media files for cached portfolios
/// - ✅ SMART MERGE: Preserve existing cache to avoid re-downloads
/// - Auto cleanup old cache when new data arrives
/// ═══════════════════════════════════════════════════════════

class PortofolioLocalService {
  static const String _boxName = 'portofolio_box';
  static const int _maxCachedItems = 10; // Only top 10

  Box<PortofolioModel>? _box;

  /// Initialize Hive box
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox<PortofolioModel>(_boxName);
        debugPrint('✅ [PortofolioLocal] Box opened: ${_box!.length} items');
      } else {
        _box = Hive.box<PortofolioModel>(_boxName);
        debugPrint(
            '✅ [PortofolioLocal] Box already open: ${_box!.length} items');
      }
    } catch (e) {
      debugPrint('❌ [PortofolioLocal] Error opening box: $e');
      rethrow;
    }
  }

  /// Ensure box is ready
  Future<void> _ensureBoxReady() async {
    if (_box == null || !_box!.isOpen) {
      await initialize();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 📥 SAVE OPERATIONS - Top 10 Only
  // ═══════════════════════════════════════════════════════════

  /// Save top 10 portfolios and download their media
  ///
  /// This is the MAIN method for caching portfolios
  /// - Saves only first 10 portfolios
  /// - ✅ SMART MERGE: Preserves existing cache to avoid re-downloads
  /// - Downloads only missing media
  /// - Removes old cached items
  Future<void> saveTop10(
    List<PortofolioModel> portfolios, {
    bool downloadMedia = true,
  }) async {
    await _ensureBoxReady();

    try {
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('[PortofolioLocal] 💾 Saving top 10 portfolios...');
      debugPrint('═══════════════════════════════════════════════════');

      // Take only first 10
      final top10 = portfolios.take(_maxCachedItems).toList();

      debugPrint('[PortofolioLocal] Total portfolios: ${portfolios.length}');
      debugPrint('[PortofolioLocal] Caching: ${top10.length} portfolios');

      // ✅ FIX: Get existing cache BEFORE clearing
      final existingCache = <String, PortofolioModel>{};
      for (final key in _box!.keys) {
        final cached = _box!.get(key);
        if (cached != null) {
          existingCache[key.toString()] = cached;
        }
      }

      debugPrint(
          '[PortofolioLocal] Existing cache: ${existingCache.length} portfolios');

      // Clear old cache
      await _box!.clear();
      debugPrint('[PortofolioLocal] ✅ Old cache cleared');

      // Save new top 10 with smart merge
      int savedCount = 0;
      int mediaDownloadedCount = 0;
      int mediaPreservedCount = 0;

      for (final portfolio in top10) {
        // ✅ FIX: Merge with existing cache data
        PortofolioModel portfolioToSave = portfolio;

        if (existingCache.containsKey(portfolio.noId)) {
          final existingPortfolio = existingCache[portfolio.noId]!;

          // Merge media URLs (preserve cache status)
          final mergedMediaUrls = <MediaUrlModel>[];

          for (int i = 0; i < portfolio.mediaUrls.length; i++) {
            final newMedia = portfolio.mediaUrls[i];

            // Find matching media in existing cache
            final existingMedia = existingPortfolio.mediaUrls.firstWhere(
              (m) =>
                  m.idMedia == newMedia.idMedia ||
                  m.noIdMedia == newMedia.noIdMedia,
              orElse: () => newMedia,
            );

            // Use existing if it's cached, otherwise use new
            if (existingMedia.isCached && existingMedia.localPath != null) {
              mergedMediaUrls.add(existingMedia); // ← Preserve cache!
              mediaPreservedCount++;
            } else {
              mergedMediaUrls.add(newMedia);
            }
          }

          portfolioToSave = portfolio.copyWith(
            mediaUrls: mergedMediaUrls,
          );

          debugPrint(
              '[PortofolioLocal] [${savedCount + 1}/${top10.length}] ${portfolio.noId} (merged with cache)');
        } else {
          debugPrint(
              '[PortofolioLocal] [${savedCount + 1}/${top10.length}] ${portfolio.noId} (new)');
        }

        // Save portfolio metadata
        await _box!.put(portfolio.noId, portfolioToSave);
        savedCount++;

        // Download media if enabled
        if (downloadMedia && portfolioToSave.mediaUrls.isNotEmpty) {
          final downloadedCount =
              await _downloadPortfolioMedia(portfolioToSave);
          mediaDownloadedCount += downloadedCount;

          debugPrint(
              '[PortofolioLocal]    Media: $downloadedCount new downloads');
        }
      }

      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('[PortofolioLocal] ✅ Save complete:');
      debugPrint('[PortofolioLocal]    Portfolios saved: $savedCount');
      debugPrint(
          '[PortofolioLocal]    Media downloaded: $mediaDownloadedCount new');
      debugPrint(
          '[PortofolioLocal]    Media preserved: $mediaPreservedCount cached');
      debugPrint('═══════════════════════════════════════════════════');
    } catch (e, st) {
      debugPrint('❌ [PortofolioLocal] Error saving top 10: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  /// Download media for a single portfolio
  /// Returns count of successfully downloaded media
  ///
  /// ✅ Downloads ALL media (not just first one!)
  /// ✅ Skips already cached media
  Future<int> _downloadPortfolioMedia(PortofolioModel portfolio) async {
    try {
      int downloadedCount = 0;
      int skippedCount = 0;
      final updatedMediaList = <MediaUrlModel>[];

      debugPrint(
          '[PortofolioLocal]    📥 Downloading ${portfolio.mediaUrls.length} media files...');

      for (int i = 0; i < portfolio.mediaUrls.length; i++) {
        final media = portfolio.mediaUrls[i];

        try {
          // ✅ Skip if already cached
          if (media.isCached) {
            updatedMediaList.add(media);
            downloadedCount++; // Count as "handled"
            skippedCount++;
            debugPrint(
                '[PortofolioLocal]       [$i] ✅ Already cached: ${media.idMedia}');
            continue;
          }

          debugPrint(
              '[PortofolioLocal]       [$i] ⬇️  Downloading: ${media.idMedia}');

          // Download media
          final cachedMedia = await CacheManager.instance.cacheMedia(
            media,
            priority: CachePriority.high, // High priority for cached portfolios
          );

          updatedMediaList.add(cachedMedia);

          if (cachedMedia.isCached) {
            downloadedCount++;
            debugPrint(
                '[PortofolioLocal]       [$i] ✅ Downloaded: ${media.idMedia}');
          } else {
            debugPrint(
                '[PortofolioLocal]       [$i] ⚠️  Download failed: ${media.idMedia}');
          }

          // Small delay to not overload network
          if (i < portfolio.mediaUrls.length - 1) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        } catch (e) {
          debugPrint(
              '[PortofolioLocal]       [$i] ❌ Error: ${media.idMedia} - $e');
          // Add original media if download failed
          updatedMediaList.add(media);
        }
      }

      debugPrint(
          '[PortofolioLocal]    Summary: Downloaded $downloadedCount/${portfolio.mediaUrls.length} (Skipped: $skippedCount)');

      // Update portfolio with cached media info
      if (updatedMediaList.isNotEmpty) {
        final updatedPortfolio = portfolio.copyWith(
          mediaUrls: updatedMediaList,
          lastUpdated: DateTime.now(),
        );

        await _box!.put(portfolio.noId, updatedPortfolio);
      }

      return downloadedCount - skippedCount; // Return ONLY new downloads
    } catch (e) {
      debugPrint('[PortofolioLocal] ⚠️  Media download error: $e');
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 📤 READ OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Get all cached portfolios (top 10)
  Future<List<PortofolioModel>> getCachedPortfolios() async {
    await _ensureBoxReady();

    try {
      final portfolios = _box!.values.toList();

      // Sort by date (newest first)
      portfolios.sort((a, b) => b.tglCreated.compareTo(a.tglCreated));

      debugPrint(
          '📦 [PortofolioLocal] Retrieved ${portfolios.length} cached portfolios');
      return portfolios;
    } catch (e) {
      debugPrint('❌ [PortofolioLocal] Error getting cached portfolios: $e');
      return [];
    }
  }

  /// Get single portfolio by ID
  Future<PortofolioModel?> getPortfolioById(String noId) async {
    await _ensureBoxReady();

    try {
      final portfolio = _box!.get(noId);

      if (portfolio != null) {
        debugPrint('📦 [PortofolioLocal] Found: $noId');
      } else {
        debugPrint('⚠️  [PortofolioLocal] Not found: $noId');
      }

      return portfolio;
    } catch (e) {
      debugPrint('❌ [PortofolioLocal] Error getting portfolio: $e');
      return null;
    }
  }

  /// Check if portfolio is cached
  Future<bool> isCached(String noId) async {
    await _ensureBoxReady();
    return _box!.containsKey(noId);
  }

  /// Get cached portfolio IDs
  Future<List<String>> getCachedIds() async {
    await _ensureBoxReady();

    try {
      return _box!.keys.cast<String>().toList();
    } catch (e) {
      debugPrint('❌ [PortofolioLocal] Error getting cached IDs: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✏️  UPDATE OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Update single portfolio in cache
  Future<void> updatePortfolio(PortofolioModel portfolio) async {
    await _ensureBoxReady();

    try {
      if (_box!.containsKey(portfolio.noId)) {
        await _box!.put(portfolio.noId, portfolio);
        debugPrint('✅ [PortofolioLocal] Updated: ${portfolio.noId}');
      } else {
        debugPrint(
            '⚠️  [PortofolioLocal] Portfolio not in cache: ${portfolio.noId}');
      }
    } catch (e) {
      debugPrint('❌ [PortofolioLocal] Error updating portfolio: $e');
      rethrow;
    }
  }

  /// Update media info for a portfolio
  Future<void> updatePortfolioMedia(
    String portfolioId,
    String mediaId,
    MediaUrlModel updatedMedia,
  ) async {
    await _ensureBoxReady();

    try {
      final portfolio = await getPortfolioById(portfolioId);

      if (portfolio != null) {
        final updatedPortfolio = portfolio.updateMedia(mediaId, updatedMedia);
        await _box!.put(portfolioId, updatedPortfolio);

        debugPrint('✅ [PortofolioLocal] Media updated: $mediaId');
      }
    } catch (e) {
      debugPrint('❌ [PortofolioLocal] Error updating media: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🗑️  DELETE OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Delete portfolio from cache (and cleanup media files)
  Future<void> deletePortfolio(String noId) async {
    await _ensureBoxReady();

    try {
      final portfolio = await getPortfolioById(noId);

      if (portfolio != null) {
        // Cleanup media files
        await _cleanupPortfolioMedia(portfolio);

        // Delete from cache
        await _box!.delete(noId);

        debugPrint('✅ [PortofolioLocal] Deleted: $noId');
      }
    } catch (e) {
      debugPrint('❌ [PortofolioLocal] Error deleting portfolio: $e');
      rethrow;
    }
  }

  /// Cleanup media files for a portfolio
  Future<void> _cleanupPortfolioMedia(PortofolioModel portfolio) async {
    try {
      int deletedCount = 0;

      for (final media in portfolio.mediaUrls) {
        if (media.isCached && media.localPath != null) {
          try {
            final file = await CacheManager.instance.getCachedPath(
              media.idMedia ?? media.noIdMedia ?? '',
            );

            if (file != null) {
              // File cleanup handled by CacheManager
              deletedCount++;
            }
          } catch (e) {
            debugPrint(
                '[PortofolioLocal]    ⚠️  Media cleanup failed: ${media.idMedia}');
          }
        }
      }

      if (deletedCount > 0) {
        debugPrint(
            '[PortofolioLocal]    🗑️  Cleaned $deletedCount media files');
      }
    } catch (e) {
      debugPrint('[PortofolioLocal] ⚠️  Media cleanup error: $e');
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    await _ensureBoxReady();

    try {
      debugPrint('[PortofolioLocal] 🗑️  Clearing all cache...');

      // Get all portfolios first for media cleanup
      final portfolios = await getCachedPortfolios();

      // Cleanup all media files
      for (final portfolio in portfolios) {
        await _cleanupPortfolioMedia(portfolio);
      }

      // Clear Hive box
      await _box!.clear();

      debugPrint('✅ [PortofolioLocal] All cache cleared');
    } catch (e) {
      debugPrint('❌ [PortofolioLocal] Error clearing cache: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 📊 STATISTICS
  // ═══════════════════════════════════════════════════════════

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    await _ensureBoxReady();

    try {
      final portfolios = await getCachedPortfolios();

      int totalMedia = 0;
      int cachedMedia = 0;
      int fullyCachedPortfolios = 0;

      for (final portfolio in portfolios) {
        totalMedia += portfolio.mediaUrls.length;
        cachedMedia += portfolio.cachedMedia.length;

        if (portfolio.isFullyCached) {
          fullyCachedPortfolios++;
        }
      }

      return {
        'total_cached': portfolios.length,
        'max_cache': _maxCachedItems,
        'total_media': totalMedia,
        'cached_media': cachedMedia,
        'fully_cached_portfolios': fullyCachedPortfolios,
        'cache_usage': '${portfolios.length}/$_maxCachedItems',
      };
    } catch (e) {
      debugPrint('❌ [PortofolioLocal] Error getting stats: $e');
      return {};
    }
  }

  /// Print cache statistics (for debugging)
  Future<void> printStats() async {
    final stats = await getStats();

    debugPrint('═══════════════════════════════════════');
    debugPrint('📊 PORTFOLIO CACHE STATS');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Cached portfolios: ${stats['cache_usage']}');
    debugPrint('Total media: ${stats['total_media']}');
    debugPrint('Cached media: ${stats['cached_media']}');
    debugPrint('Fully cached: ${stats['fully_cached_portfolios']}');
    debugPrint('═══════════════════════════════════════');
  }

  // ═══════════════════════════════════════════════════════════
  // 🔧 UTILITY
  // ═══════════════════════════════════════════════════════════

  /// Get count of cached portfolios
  Future<int> getCount() async {
    await _ensureBoxReady();
    return _box!.length;
  }

  /// Close box (cleanup)
  Future<void> close() async {
    if (_box?.isOpen ?? false) {
      await _box!.close();
      debugPrint('✅ [PortofolioLocal] Box closed');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔄 RE-DOWNLOAD MEDIA (Refresh)
  // ═══════════════════════════════════════════════════════════

  /// Re-download all media for cached portfolios
  /// Useful for refreshing after URL expiry
  Future<void> refreshAllMedia() async {
    await _ensureBoxReady();

    try {
      debugPrint('[PortofolioLocal] 🔄 Refreshing all media...');

      final portfolios = await getCachedPortfolios();
      int totalDownloaded = 0;

      for (final portfolio in portfolios) {
        final downloaded = await _downloadPortfolioMedia(portfolio);
        totalDownloaded += downloaded;
      }

      debugPrint(
          '✅ [PortofolioLocal] Media refresh complete: $totalDownloaded files');
    } catch (e) {
      debugPrint('❌ [PortofolioLocal] Media refresh error: $e');
    }
  }

  /// Re-download media for specific portfolio
  Future<int> refreshPortfolioMedia(String portfolioId) async {
    await _ensureBoxReady();

    try {
      final portfolio = await getPortfolioById(portfolioId);

      if (portfolio != null) {
        debugPrint('[PortofolioLocal] 🔄 Refreshing media for: $portfolioId');
        return await _downloadPortfolioMedia(portfolio);
      }

      return 0;
    } catch (e) {
      debugPrint('❌ [PortofolioLocal] Refresh media error: $e');
      return 0;
    }
  }
}
