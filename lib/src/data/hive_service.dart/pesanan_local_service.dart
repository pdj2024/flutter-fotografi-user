import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';

/// ═══════════════════════════════════════════════════════════
/// PESANAN LOCAL SERVICE - Order Cache with History
///
/// Strategy:
/// - Cache active orders with their histories
/// - Separate storage for orders and histories
/// - Fast lookup by order ID
/// - Efficient history tracking per order
/// ═══════════════════════════════════════════════════════════

class PesananLocalService {
  static const String _orderBoxName = 'pesanan_box';
  static const String _historyBoxName = 'history_order_box';

  Box<PesananModel>? _orderBox;
  Box<List<dynamic>>? _historyBox; // Stores list of history per order

  /// Initialize Hive boxes
  Future<void> initialize() async {
    try {
      debugPrint('[PesananLocal] 🚀 Initializing...');

      // Open order box
      if (!Hive.isBoxOpen(_orderBoxName)) {
        _orderBox = await Hive.openBox<PesananModel>(_orderBoxName);
        debugPrint('[PesananLocal] ✅ Order box opened: ${_orderBox!.length} orders');
      } else {
        _orderBox = Hive.box<PesananModel>(_orderBoxName);
        debugPrint('[PesananLocal] ✅ Order box already open: ${_orderBox!.length} orders');
      }

      // Open history box
      if (!Hive.isBoxOpen(_historyBoxName)) {
        _historyBox = await Hive.openBox<List<dynamic>>(_historyBoxName);
        debugPrint('[PesananLocal] ✅ History box opened: ${_historyBox!.length} orders');
      } else {
        _historyBox = Hive.box<List<dynamic>>(_historyBoxName);
        debugPrint('[PesananLocal] ✅ History box already open: ${_historyBox!.length} orders');
      }

      debugPrint('[PesananLocal] ✅ Initialization complete');
    } catch (e) {
      debugPrint('[PesananLocal] ❌ Error opening boxes: $e');
      rethrow;
    }
  }

  /// Ensure boxes are ready
  Future<void> _ensureBoxReady() async {
    if (_orderBox == null || !_orderBox!.isOpen ||
        _historyBox == null || !_historyBox!.isOpen) {
      await initialize();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 📥 SAVE OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Save single order with its history
  Future<void> saveOrder(
    PesananModel order, {
    List<HistoryOrderModel>? histories,
  }) async {
    await _ensureBoxReady();

    try {
      debugPrint('[PesananLocal] 💾 Saving order: ${order.noBukti}');

      // Save order
      await _orderBox!.put(order.noBukti, order);

      // Save histories if provided
      if (histories != null && histories.isNotEmpty) {
        await saveHistories(order.noBukti, histories);
      }

      debugPrint('[PesananLocal] ✅ Order saved');
      debugPrint('[PesananLocal]    Histories: ${histories?.length ?? 0}');
    } catch (e) {
      debugPrint('[PesananLocal] ❌ Error saving order: $e');
      rethrow;
    }
  }

  /// Save multiple orders with their histories
  Future<void> saveOrders(
    List<PesananModel> orders, {
    Map<String, List<HistoryOrderModel>>? historiesMap,
  }) async {
    await _ensureBoxReady();

    try {
      debugPrint('[PesananLocal] 💾 Saving ${orders.length} orders...');

      int savedCount = 0;
      int historySavedCount = 0;

      for (final order in orders) {
        // Save order
        await _orderBox!.put(order.noBukti, order);
        savedCount++;

        // Save histories if available
        if (historiesMap != null && historiesMap.containsKey(order.noBukti)) {
          final histories = historiesMap[order.noBukti]!;
          await saveHistories(order.noBukti, histories);
          historySavedCount += histories.length;
        }
      }

      debugPrint('[PesananLocal] ✅ Save complete:');
      debugPrint('[PesananLocal]    Orders: $savedCount');
      debugPrint('[PesananLocal]    Histories: $historySavedCount');
    } catch (e) {
      debugPrint('[PesananLocal] ❌ Error saving orders: $e');
      rethrow;
    }
  }

  /// Save histories for specific order
  Future<void> saveHistories(
    String noBukti,
    List<HistoryOrderModel> histories,
  ) async {
    await _ensureBoxReady();

    try {
      // Convert to JSON for storage
      final historyJsonList = histories.map((h) => h.toJson()).toList();

      // Save to box
      await _historyBox!.put(noBukti, historyJsonList);

      debugPrint('[PesananLocal] 💾 Saved ${histories.length} histories for: $noBukti');
    } catch (e) {
      debugPrint('[PesananLocal] ❌ Error saving histories: $e');
      rethrow;
    }
  }

  /// Add single history to existing order
  Future<void> addHistory(
    String noBukti,
    HistoryOrderModel history,
  ) async {
    await _ensureBoxReady();

    try {
      // Get existing histories
      final existing = await getHistories(noBukti);

      // Check if already exists
      final alreadyExists = existing.any((h) => h.noId == history.noId);

      if (alreadyExists) {
        debugPrint('[PesananLocal] ℹ️ History already exists: ${history.noId}');
        return;
      }

      // Add new history
      existing.add(history);

      // Sort by date descending
      existing.sort((a, b) => b.tglProgress.compareTo(a.tglProgress));

      // Save back
      await saveHistories(noBukti, existing);

      debugPrint('[PesananLocal] ✅ Added history for: $noBukti');
    } catch (e) {
      debugPrint('[PesananLocal] ❌ Error adding history: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 📤 READ OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Get all cached orders
  Future<List<PesananModel>> getAllOrders() async {
    await _ensureBoxReady();

    try {
      final orders = _orderBox!.values.toList();

      debugPrint('[PesananLocal] 📦 Retrieved ${orders.length} orders');
      return orders;
    } catch (e) {
      debugPrint('[PesananLocal] ❌ Error getting orders: $e');
      return [];
    }
  }

  /// Get orders by status
  Future<List<PesananModel>> getOrdersByStatus(String statusProgress) async {
    await _ensureBoxReady();

    try {
      final orders = _orderBox!.values
          .where((o) => o.statusProgresPesanan == statusProgress)
          .toList();

      debugPrint('[PesananLocal] 📦 Found ${orders.length} orders with status: $statusProgress');
      return orders;
    } catch (e) {
      debugPrint('[PesananLocal] ❌ Error getting orders by status: $e');
      return [];
    }
  }

  /// Get single order by noBukti
  Future<PesananModel?> getOrder(String noBukti) async {
    await _ensureBoxReady();

    try {
      final order = _orderBox!.get(noBukti);

      if (order != null) {
        debugPrint('[PesananLocal] 📦 Found order: $noBukti');
      } else {
        debugPrint('[PesananLocal] ⚠️ Order not found: $noBukti');
      }

      return order;
    } catch (e) {
      debugPrint('[PesananLocal] ❌ Error getting order: $e');
      return null;
    }
  }

  /// Get histories for specific order
  Future<List<HistoryOrderModel>> getHistories(String noBukti) async {
    await _ensureBoxReady();

    try {
      final historyJsonList = _historyBox!.get(noBukti);

      if (historyJsonList == null || historyJsonList.isEmpty) {
        debugPrint('[PesananLocal] ℹ️ No histories for: $noBukti');
        return [];
      }

      // Convert from JSON
      final histories = historyJsonList
          .map((json) {
            try {
              return HistoryOrderModel.fromJson(Map<String, dynamic>.from(json));
            } catch (e) {
              debugPrint('[PesananLocal] ⚠️ Error parsing history: $e');
              return null;
            }
          })
          .whereType<HistoryOrderModel>()
          .toList();

      debugPrint('[PesananLocal] 📦 Retrieved ${histories.length} histories for: $noBukti');
      return histories;
    } catch (e) {
      debugPrint('[PesananLocal] ❌ Error getting histories: $e');
      return [];
    }
  }

  /// Get order with its histories
  Future<Map<String, dynamic>?> getOrderWithHistories(String noBukti) async {
    await _ensureBoxReady();

    try {
      final order = await getOrder(noBukti);
      if (order == null) return null;

      final histories = await getHistories(noBukti);

      return {
        'order': order,
        'histories': histories,
      };
    } catch (e) {
      debugPrint('[PesananLocal] ❌ Error getting order with histories: $e');
      return null;
    }
  }

  /// Check if order is cached
  Future<bool> isCached(String noBukti) async {
    await _ensureBoxReady();
    return _orderBox!.containsKey(noBukti);
  }

  /// Get all cached order IDs
  Future<List<String>> getCachedOrderIds() async {
    await _ensureBoxReady();

    try {
      return _orderBox!.keys.cast<String>().toList();
    } catch (e) {
      debugPrint('[PesananLocal] ❌ Error getting cached IDs: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✏️ UPDATE OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Update order
  Future<void> updateOrder(PesananModel order) async {
    await _ensureBoxReady();

    try {
      if (_orderBox!.containsKey(order.noBukti)) {
        await _orderBox!.put(order.noBukti, order);
        debugPrint('[PesananLocal] ✅ Updated order: ${order.noBukti}');
      } else {
        debugPrint('[PesananLocal] ⚠️ Order not in cache: ${order.noBukti}');
      }
    } catch (e) {
      debugPrint('[PesananLocal] ❌ Error updating order: $e');
      rethrow;
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String noBukti, String newStatus) async {
    await _ensureBoxReady();

    try {
      final order = await getOrder(noBukti);

      if (order != null) {
        final updatedOrder = order.copyWith(
          statusProgresPesanan: newStatus,
        );

        await _orderBox!.put(noBukti, updatedOrder);
        debugPrint('[PesananLocal] ✅ Updated status for: $noBukti');
        debugPrint('[PesananLocal]    New status: $newStatus');
      } else {
        debugPrint('[PesananLocal] ⚠️ Order not found: $noBukti');
      }
    } catch (e) {
      debugPrint('[PesananLocal] ❌ Error updating status: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🗑️ DELETE OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Delete order and its histories
  Future<void> deleteOrder(String noBukti) async {
    await _ensureBoxReady();

    try {
      debugPrint('[PesananLocal] 🗑️ Deleting order: $noBukti');

      // Delete order
      await _orderBox!.delete(noBukti);

      // Delete histories
      await _historyBox!.delete(noBukti);

      debugPrint('[PesananLocal] ✅ Order deleted');
    } catch (e) {
      debugPrint('[PesananLocal] ❌ Error deleting order: $e');
      rethrow;
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    await _ensureBoxReady();

    try {
      debugPrint('[PesananLocal] 🗑️ Clearing all cache...');

      await _orderBox!.clear();
      await _historyBox!.clear();

      debugPrint('[PesananLocal] ✅ All cache cleared');
    } catch (e) {
      debugPrint('[PesananLocal] ❌ Error clearing cache: $e');
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
      final orders = await getAllOrders();

      int progressCount = 0;
      int selesaiCount = 0;
      int totalHistories = 0;

      for (final order in orders) {
        // Count by status
        if (['persiapan', 'proses', 'review', 'revisi']
            .contains(order.statusProgresPesanan)) {
          progressCount++;
        } else if (order.statusProgresPesanan == 'selesai') {
          selesaiCount++;
        }

        // Count histories
        final histories = await getHistories(order.noBukti);
        totalHistories += histories.length;
      }

      return {
        'total_orders': orders.length,
        'progress_orders': progressCount,
        'selesai_orders': selesaiCount,
        'total_histories': totalHistories,
      };
    } catch (e) {
      debugPrint('[PesananLocal] ❌ Error getting stats: $e');
      return {};
    }
  }

  /// Print cache statistics
  Future<void> printStats() async {
    final stats = await getStats();

    debugPrint('═══════════════════════════════════════');
    debugPrint('📊 PESANAN CACHE STATS');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Total orders: ${stats['total_orders']}');
    debugPrint('In progress: ${stats['progress_orders']}');
    debugPrint('Completed: ${stats['selesai_orders']}');
    debugPrint('Total histories: ${stats['total_histories']}');
    debugPrint('═══════════════════════════════════════');
  }

  // ═══════════════════════════════════════════════════════════
  // 🔧 UTILITY
  // ═══════════════════════════════════════════════════════════

  /// Get count of cached orders
  Future<int> getCount() async {
    await _ensureBoxReady();
    return _orderBox!.length;
  }

  /// Close boxes (cleanup)
  Future<void> close() async {
    if (_orderBox?.isOpen ?? false) {
      await _orderBox!.close();
    }
    if (_historyBox?.isOpen ?? false) {
      await _historyBox!.close();
    }
    debugPrint('[PesananLocal] ✅ Boxes closed');
  }
}