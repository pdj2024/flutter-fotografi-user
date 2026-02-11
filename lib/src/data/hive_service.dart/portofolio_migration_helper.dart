import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';
import 'package:mpjnew/src/data/hive_service.dart/portofolio_local_service.dart';
import 'package:mpjnew/src/features/customer/services/portofolio_service.dart';

/// ═══════════════════════════════════════════════════════════
/// PORTOFOLIO MIGRATION HELPER
///
/// Handles sync between API and local storage with smart caching
///
/// Strategy:
/// 1. Load cached (top 10) immediately → Fast UI
/// 2. Fetch from API → Get all portfolios
/// 3. Return ALL portfolios (cached + API)
/// 4. Save ONLY top 10 to cache with media download
/// 5. Non-cached portfolios shown but not saved
///
/// Benefits:
/// - Instant load from cache
/// - Full data from API
/// - Smart bandwidth usage (download only top 10 media)
/// ═══════════════════════════════════════════════════════════

class PortofolioMigrationHelper {
  static PortofolioService? _apiService;

  /// Initialize with custom service (for testing)
  static void initialize({PortofolioService? apiService}) {
    _apiService = apiService;
  }

  // ═══════════════════════════════════════════════════════════
  // 🔄 SMART LOAD - Cache First, Then API
  // ═══════════════════════════════════════════════════════════

  /// Smart load strategy:
  /// 1. Load from cache immediately (top 10 with downloaded media)
  /// 2. Fetch from API (all portfolios)
  /// 3. Return combined list (cached items first, then new from API)
  /// 4. Save top 10 to cache with media download
  ///
  /// Returns:
  /// - cached: List of cached portfolios (top 10)
  /// - all: Combined list (cached + API)
  static Future<PortofolioLoadResult> smartLoad({
    required PortofolioLocalService localService,
    required String vendorId,
    PortofolioService? apiService,
    bool forceRefresh = false,
    bool downloadMedia = true,
  }) async {
    try {
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('[PortofolioMigration] 🚀 Smart Load Starting...');
      debugPrint('═══════════════════════════════════════════════════');

      final service = apiService ?? _apiService ?? PortofolioService();

      // ✅ STEP 1: Load from cache (instant, with downloaded media)
      final cachedPortfolios = await localService.getCachedPortfolios();

      debugPrint(
          '[PortofolioMigration] 📦 Cached: ${cachedPortfolios.length} portfolios');

      if (cachedPortfolios.isNotEmpty) {
        debugPrint(
            '[PortofolioMigration]    ✅ Media: Pre-downloaded (instant display)');
      }

      // If not forcing refresh and have cache, can return early for instant UI
      if (!forceRefresh && cachedPortfolios.isNotEmpty) {
        debugPrint(
            '[PortofolioMigration] ⚡ Quick return with cache (API fetch in background)');

        // Return cache immediately
        final quickResult = PortofolioLoadResult(
          cached: cachedPortfolios,
          all: cachedPortfolios,
          fromCache: true,
        );

        // Fetch API in background (don't await)
        _backgroundApiSync(
          localService: localService,
          vendorId: vendorId,
          service: service,
          downloadMedia: downloadMedia,
        );

        return quickResult;
      }

      // ✅ STEP 2: Fetch from API (all portfolios)
      debugPrint('[PortofolioMigration] 🌐 Fetching from API...');

      final apiPortfolios = await service.getAll(
        idVendor: vendorId,
        orderBy: "Tgl_Created",
        orderDir: "DESC",
        status: "aktif",
      );

      debugPrint(
          '[PortofolioMigration] ✅ API: ${apiPortfolios.length} portfolios');

      // ✅ STEP 3: Save top 10 to cache with media download
      if (apiPortfolios.isNotEmpty) {
        debugPrint('[PortofolioMigration] 💾 Caching top 10...');

        await localService.saveTop10(
          apiPortfolios,
          downloadMedia: downloadMedia,
        );

        debugPrint('[PortofolioMigration] ✅ Cache updated with top 10');
      }

      // ✅ STEP 4: Get fresh cached portfolios (with media paths)
      final freshCached = await localService.getCachedPortfolios();

      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('[PortofolioMigration] ✅ Smart Load Complete:');
      debugPrint(
          '[PortofolioMigration]    Cached: ${freshCached.length} (with media)');
      debugPrint('[PortofolioMigration]    Total: ${apiPortfolios.length}');
      debugPrint('═══════════════════════════════════════════════════');

      return PortofolioLoadResult(
        cached: freshCached,
        all: apiPortfolios,
        fromCache: false,
      );
    } catch (e, st) {
      debugPrint('❌ [PortofolioMigration] Smart load failed: $e');
      debugPrint(st.toString());

      // Fallback to cache on error
      final cachedPortfolios = await localService.getCachedPortfolios();

      if (cachedPortfolios.isNotEmpty) {
        debugPrint('[PortofolioMigration] ⚠️ Using cached data (API failed)');

        return PortofolioLoadResult(
          cached: cachedPortfolios,
          all: cachedPortfolios,
          fromCache: true,
          error: e.toString(),
        );
      }

      rethrow;
    }
  }

  /// Background API sync (don't block UI)
  static Future<void> _backgroundApiSync({
    required PortofolioLocalService localService,
    required String vendorId,
    required PortofolioService service,
    required bool downloadMedia,
  }) async {
    try {
      // Small delay to not compete with UI rendering
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('[PortofolioMigration] 🔄 Background sync starting...');

      final apiPortfolios = await service.getAll(
        idVendor: vendorId,
        orderBy: "Tgl_Created",
        orderDir: "DESC",
        status: "aktif",
      );

      if (apiPortfolios.isNotEmpty) {
        await localService.saveTop10(
          apiPortfolios,
          downloadMedia: downloadMedia,
        );

        debugPrint('[PortofolioMigration] ✅ Background sync complete');
      }
    } catch (e) {
      debugPrint('[PortofolioMigration] ⚠️ Background sync failed: $e');
      // Silent fail - user already has cached data
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔄 SYNC OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Force sync from API (refresh)
  /// Use this for pull-to-refresh
  static Future<List<PortofolioModel>> forceSync({
    required PortofolioLocalService localService,
    required String vendorId,
    PortofolioService? apiService,
    bool downloadMedia = true,
  }) async {
    try {
      debugPrint('[PortofolioMigration] 🔄 Force sync...');

      final service = apiService ?? _apiService ?? PortofolioService();

      // Fetch from API
      final apiPortfolios = await service.getAll(
        idVendor: vendorId,
        orderBy: "Tgl_Created",
        orderDir: "DESC",
        status: "aktif",
      );

      debugPrint(
          '[PortofolioMigration] ✅ Fetched ${apiPortfolios.length} portfolios');

      // Save top 10 to cache
      if (apiPortfolios.isNotEmpty) {
        await localService.saveTop10(
          apiPortfolios,
          downloadMedia: downloadMedia,
        );
      }

      if (apiPortfolios.isEmpty) {
        await localService.clearAll();
      }

      return apiPortfolios;
    } catch (e, st) {
      debugPrint('❌ [PortofolioMigration] Force sync failed: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  /// Refresh media for cached portfolios
  /// Use this when URLs expire
  static Future<void> refreshMedia({
    required PortofolioLocalService localService,
  }) async {
    try {
      debugPrint('[PortofolioMigration] 🔄 Refreshing media...');

      await localService.refreshAllMedia();

      debugPrint('[PortofolioMigration] ✅ Media refreshed');
    } catch (e) {
      debugPrint('❌ [PortofolioMigration] Media refresh failed: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🗑️ CLEANUP
  // ═══════════════════════════════════════════════════════════

  /// Clear all cache (for logout)
  static Future<void> clearAllCache({
    required PortofolioLocalService localService,
  }) async {
    try {
      debugPrint('[PortofolioMigration] 🗑️ Clearing all cache...');

      await localService.clearAll();

      debugPrint('[PortofolioMigration] ✅ Cache cleared');
    } catch (e) {
      debugPrint('❌ [PortofolioMigration] Clear cache failed: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 📊 UTILITIES
  // ═══════════════════════════════════════════════════════════

  /// Check if portfolio is in cache
  static Future<bool> isCached({
    required PortofolioLocalService localService,
    required String portfolioId,
  }) async {
    return await localService.isCached(portfolioId);
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats({
    required PortofolioLocalService localService,
  }) async {
    return await localService.getStats();
  }

  /// Print cache statistics (debug)
  static Future<void> printCacheStats({
    required PortofolioLocalService localService,
  }) async {
    await localService.printStats();
  }

  // ═══════════════════════════════════════════════════════════
  // 🎯 LOAD MORE (Pagination)
  // ═══════════════════════════════════════════════════════════

  /// Load more portfolios (for infinite scroll)
  ///
  /// Note: These additional portfolios are NOT cached
  /// They are display-only and will be lost on app restart
  static Future<List<PortofolioModel>> loadMore({
    required String vendorId,
    required int offset,
    int limit = 10,
    PortofolioService? apiService,
  }) async {
    try {
      debugPrint('[PortofolioMigration] 📥 Loading more...');
      debugPrint('[PortofolioMigration]    Offset: $offset, Limit: $limit');

      final service = apiService ?? _apiService ?? PortofolioService();

      // Fetch additional portfolios from API
      // Note: API might not support offset/limit, so we fetch all and skip
      final allPortfolios = await service.getAll(
        idVendor: vendorId,
        orderBy: "Tgl_Created",
        orderDir: "DESC",
        status: "aktif",
      );

      // Skip first `offset` items and take `limit` items
      if (offset >= allPortfolios.length) {
        debugPrint('[PortofolioMigration] ℹ️ No more portfolios');
        return [];
      }

      final morePortfolios = allPortfolios.skip(offset).take(limit).toList();

      debugPrint(
          '[PortofolioMigration] ✅ Loaded ${morePortfolios.length} more');
      debugPrint('[PortofolioMigration]    ℹ️ NOT cached (display only)');

      return morePortfolios;
    } catch (e, st) {
      debugPrint('❌ [PortofolioMigration] Load more failed: $e');
      debugPrint(st.toString());
      return [];
    }
  }
}

// ═══════════════════════════════════════════════════════════
// RESULT MODEL
// ═══════════════════════════════════════════════════════════

/// Result from smart load operation
class PortofolioLoadResult {
  /// Cached portfolios (top 10 with downloaded media)
  final List<PortofolioModel> cached;

  /// All portfolios (cached + API)
  final List<PortofolioModel> all;

  /// Whether this result came from cache
  final bool fromCache;

  /// Error message if any
  final String? error;

  const PortofolioLoadResult({
    required this.cached,
    required this.all,
    this.fromCache = false,
    this.error,
  });

  /// Check if load was successful
  bool get isSuccess => error == null;

  /// Check if has any data
  bool get hasData => all.isNotEmpty;

  /// Get count of non-cached portfolios
  int get nonCachedCount => all.length - cached.length;

  @override
  String toString() {
    return 'PortofolioLoadResult('
        'cached: ${cached.length}, '
        'all: ${all.length}, '
        'fromCache: $fromCache, '
        'error: $error'
        ')';
  }
}
