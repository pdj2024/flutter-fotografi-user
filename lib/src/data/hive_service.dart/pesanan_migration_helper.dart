import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/hive_service.dart/pesanan_local_service.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';

/// ═══════════════════════════════════════════════════════════
/// PESANAN MIGRATION HELPER - Smart Order Cache
///
/// Strategy:
/// - Load from cache first (instant)
/// - Sync with API in background
/// - Cache active orders with their histories
/// - Efficient history management
/// ═══════════════════════════════════════════════════════════

class PesananLoadResult {
  final List<PesananModel> cached;
  final List<PesananModel> all;
  final bool fromCache;
  final Map<String, List<HistoryOrderModel>> histories;

  PesananLoadResult({
    required this.cached,
    required this.all,
    required this.fromCache,
    required this.histories,
  });
}

class PesananMigrationHelper {
  // ═══════════════════════════════════════════════════════════
  // SMART LOAD - Cache First, Then API
  // ═══════════════════════════════════════════════════════════

  /// Load orders with smart cache strategy
  ///
  /// Flow:
  /// 1. Try cache first (instant!)
  /// 2. If cache empty or force refresh, fetch from API
  /// 3. Update cache with API data
  /// 4. Fetch histories for orders
  static Future<PesananLoadResult> smartLoad({
    required PesananLocalService localService,
    required String vendorId,
    required PesananService apiService,
    required HistoryOrderService historyService,
    bool forceRefresh = false,
    String status = 'aktif',
  }) async {
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('[PesananMigration] 📥 SMART LOAD');
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('[PesananMigration] Vendor ID: $vendorId');
    debugPrint('[PesananMigration] Status: $status');
    debugPrint('[PesananMigration] Force refresh: $forceRefresh');

    try {
      List<PesananModel> cachedOrders = [];
      Map<String, List<HistoryOrderModel>> cachedHistories = {};
      bool isFromCache = false;

      // ───────────────────────────────────────────────────────
      // Step 1: Try cache first (if not force refresh)
      // ───────────────────────────────────────────────────────
      if (!forceRefresh) {
        cachedOrders = await localService.getAllOrders();

        if (cachedOrders.isNotEmpty) {
          debugPrint('[PesananMigration] 📦 Cache hit: ${cachedOrders.length} orders');

          // Load histories for cached orders
          for (final order in cachedOrders) {
            final histories = await localService.getHistories(order.noBukti);
            if (histories.isNotEmpty) {
              cachedHistories[order.noBukti] = histories;
            }
          }

          debugPrint('[PesananMigration] 📦 Loaded histories for ${cachedHistories.length} orders');

          isFromCache = true;

          // Return cached data immediately
          // Background sync will happen separately
          return PesananLoadResult(
            cached: cachedOrders,
            all: cachedOrders,
            fromCache: true,
            histories: cachedHistories,
          );
        } else {
          debugPrint('[PesananMigration] ℹ️ Cache empty');
        }
      }

      // ───────────────────────────────────────────────────────
      // Step 2: Fetch from API
      // ───────────────────────────────────────────────────────
      debugPrint('[PesananMigration] 🌐 Fetching from API...');

      final apiOrders = await apiService.getAll(
        status: status,
        idVendor: vendorId,
      );

      debugPrint('[PesananMigration] ✅ API returned ${apiOrders.length} orders');

      if (apiOrders.isEmpty) {
        debugPrint('[PesananMigration] ℹ️ No orders from API');
        return PesananLoadResult(
          cached: cachedOrders,
          all: [],
          fromCache: false,
          histories: cachedHistories,
        );
      }

      // ───────────────────────────────────────────────────────
      // Step 3: Fetch histories for each order
      // ───────────────────────────────────────────────────────
      debugPrint('[PesananMigration] 📥 Fetching histories...');

      final Map<String, List<HistoryOrderModel>> apiHistories = {};

      for (int i = 0; i < apiOrders.length; i++) {
        final order = apiOrders[i];

        try {
          final histories = await historyService.getAll(
            noOrder: order.noBukti,
            status: 'aktif',
            orderBy: 'Tgl_Progress',
            orderDir: 'DESC',
          );

          if (histories.isNotEmpty) {
            apiHistories[order.noBukti] = histories;
            debugPrint('[PesananMigration]    [${i + 1}/${apiOrders.length}] ${order.noBukti}: ${histories.length} histories');
          } else {
            debugPrint('[PesananMigration]    [${i + 1}/${apiOrders.length}] ${order.noBukti}: no histories');
          }
        } catch (e) {
          debugPrint('[PesananMigration]    ⚠️ Error fetching histories for ${order.noBukti}: $e');
        }
      }

      debugPrint('[PesananMigration] ✅ Fetched histories for ${apiHistories.length} orders');

      // ───────────────────────────────────────────────────────
      // Step 4: Save to cache
      // ───────────────────────────────────────────────────────
      debugPrint('[PesananMigration] 💾 Saving to cache...');

      await localService.saveOrders(
        apiOrders,
        historiesMap: apiHistories,
      );

      debugPrint('[PesananMigration] ✅ Cache updated');

      debugPrint('═══════════════════════════════════════════════════');

      return PesananLoadResult(
        cached: apiOrders,
        all: apiOrders,
        fromCache: false,
        histories: apiHistories,
      );
    } catch (e, st) {
      debugPrint('[PesananMigration] ❌ Error: $e');
      debugPrint('[PesananMigration] Stack: $st');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // FORCE SYNC - Always Fetch from API
  // ═══════════════════════════════════════════════════════════

  /// Force sync with API (ignore cache)
  static Future<PesananLoadResult> forceSync({
    required PesananLocalService localService,
    required String vendorId,
    required PesananService apiService,
    required HistoryOrderService historyService,
    String status = 'aktif',
  }) async {
    debugPrint('[PesananMigration] 🔄 Force sync from API');

    return await smartLoad(
      localService: localService,
      vendorId: vendorId,
      apiService: apiService,
      historyService: historyService,
      forceRefresh: true,
      status: status,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // REFRESH SINGLE ORDER
  // ═══════════════════════════════════════════════════════════

  /// Refresh single order and its history
  static Future<Map<String, dynamic>?> refreshSingleOrder({
    required PesananLocalService localService,
    required String noBukti,
    required PesananService apiService,
    required HistoryOrderService historyService,
  }) async {
    debugPrint('[PesananMigration] 🔄 Refreshing order: $noBukti');

    try {
      // Fetch order from API
      final orders = await apiService.getAll(
        noBukti: noBukti,
        status: 'aktif',
      );

      if (orders.isEmpty) {
        debugPrint('[PesananMigration] ⚠️ Order not found: $noBukti');
        return null;
      }

      final order = orders.first;

      // Fetch histories
      final histories = await historyService.getAll(
        noOrder: noBukti,
        status: 'aktif',
        orderBy: 'Tgl_Progress',
        orderDir: 'DESC',
      );

      debugPrint('[PesananMigration] ✅ Fetched: ${histories.length} histories');

      // Save to cache
      await localService.saveOrder(
        order,
        histories: histories,
      );

      debugPrint('[PesananMigration] ✅ Order refreshed');

      return {
        'order': order,
        'histories': histories,
      };
    } catch (e) {
      debugPrint('[PesananMigration] ❌ Refresh error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // UPDATE ORDER STATUS
  // ═══════════════════════════════════════════════════════════

  /// Update order status in cache
  static Future<void> updateOrderStatus({
    required PesananLocalService localService,
    required String noBukti,
    required String newStatus,
  }) async {
    debugPrint('[PesananMigration] 🔄 Updating status: $noBukti → $newStatus');

    try {
      await localService.updateOrderStatus(noBukti, newStatus);
      debugPrint('[PesananMigration] ✅ Status updated in cache');
    } catch (e) {
      debugPrint('[PesananMigration] ❌ Update error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ADD HISTORY TO ORDER
  // ═══════════════════════════════════════════════════════════

  /// Add new history to cached order
  static Future<void> addHistoryToOrder({
    required PesananLocalService localService,
    required String noBukti,
    required HistoryOrderModel history,
  }) async {
    debugPrint('[PesananMigration] ➕ Adding history to: $noBukti');

    try {
      await localService.addHistory(noBukti, history);
      debugPrint('[PesananMigration] ✅ History added to cache');
    } catch (e) {
      debugPrint('[PesananMigration] ❌ Add history error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CLEAR CACHE
  // ═══════════════════════════════════════════════════════════

  /// Clear all cached orders
  static Future<void> clearAllCache({
    required PesananLocalService localService,
  }) async {
    debugPrint('[PesananMigration] 🗑️ Clearing all order cache');

    try {
      await localService.clearAll();
      debugPrint('[PesananMigration] ✅ Cache cleared');
    } catch (e) {
      debugPrint('[PesananMigration] ❌ Clear error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // STATISTICS
  // ═══════════════════════════════════════════════════════════

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats({
    required PesananLocalService localService,
  }) async {
    return await localService.getStats();
  }

  /// Print cache statistics
  static Future<void> printCacheStats({
    required PesananLocalService localService,
  }) async {
    await localService.printStats();
  }
}