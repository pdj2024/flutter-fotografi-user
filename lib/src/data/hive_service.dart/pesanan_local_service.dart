import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';

/// ═══════════════════════════════════════════════════════════════
/// CUSTOMER PESANAN LOCAL SERVICE
///
/// Cache pesanan customer dengan history-nya.
///
/// Dua box:
/// - pesanan_box        → PesananModel (keyed by noBukti)
/// - history_order_box  → List<HistoryOrderModel> per noBukti
///
/// Lifecycle:
///   Login  → initialize()
///   Logout → clearAll() (hapus semua order + history)
///   Delete → clearAll() (sama)
/// ═══════════════════════════════════════════════════════════════

class PesananLocalService {
  static const String _orderBoxName = 'customer_pesanan_box';
  static const String _historyBoxName = 'customer_history_order_box';

  Box<PesananModel>? _orderBox;
  Box<List<dynamic>>? _historyBox;

  // ═══════════════════════════════════════════════════
  // INIT
  // ═══════════════════════════════════════════════════

  Future<void> initialize() async {
    try {
      debugPrint('[CustomerPesananLocal] 🚀 Initializing...');

      _orderBox = Hive.isBoxOpen(_orderBoxName)
          ? Hive.box<PesananModel>(_orderBoxName)
          : await Hive.openBox<PesananModel>(_orderBoxName);

      _historyBox = Hive.isBoxOpen(_historyBoxName)
          ? Hive.box<List<dynamic>>(_historyBoxName)
          : await Hive.openBox<List<dynamic>>(_historyBoxName);

      debugPrint('[CustomerPesananLocal] ✅ Initialized');
      debugPrint(
          '   Orders: ${_orderBox!.length} | Histories: ${_historyBox!.length}');
    } catch (e) {
      debugPrint('[CustomerPesananLocal] ❌ Init error: $e');
      rethrow;
    }
  }

  Future<void> _ensureReady() async {
    if (_orderBox == null ||
        !_orderBox!.isOpen ||
        _historyBox == null ||
        !_historyBox!.isOpen) {
      await initialize();
    }
  }

  // ═══════════════════════════════════════════════════
  // SAVE
  // ═══════════════════════════════════════════════════

  Future<void> saveOrder(
    PesananModel order, {
    List<HistoryOrderModel>? histories,
  }) async {
    await _ensureReady();
    try {
      await _orderBox!.put(order.noBukti, order);

      if (histories != null && histories.isNotEmpty) {
        await saveHistories(order.noBukti, histories);
      }

      debugPrint('[CustomerPesananLocal] 💾 Saved: ${order.noBukti}');
    } catch (e) {
      debugPrint('[CustomerPesananLocal] ❌ saveOrder: $e');
      rethrow;
    }
  }

  Future<void> saveOrders(
    List<PesananModel> orders, {
    Map<String, List<HistoryOrderModel>>? historiesMap,
  }) async {
    await _ensureReady();
    try {
      debugPrint('[CustomerPesananLocal] 💾 Saving ${orders.length} orders...');

      for (final order in orders) {
        await _orderBox!.put(order.noBukti, order);

        if (historiesMap != null && historiesMap.containsKey(order.noBukti)) {
          await saveHistories(order.noBukti, historiesMap[order.noBukti]!);
        }
      }

      debugPrint('[CustomerPesananLocal] ✅ Saved ${orders.length} orders');
    } catch (e) {
      debugPrint('[CustomerPesananLocal] ❌ saveOrders: $e');
      rethrow;
    }
  }

  Future<void> saveHistories(
    String noBukti,
    List<HistoryOrderModel> histories,
  ) async {
    await _ensureReady();
    try {
      final jsonList = histories.map((h) => h.toJson()).toList();
      await _historyBox!.put(noBukti, jsonList);
      debugPrint(
          '[CustomerPesananLocal] 💾 Saved ${histories.length} histories: $noBukti');
    } catch (e) {
      debugPrint('[CustomerPesananLocal] ❌ saveHistories: $e');
      rethrow;
    }
  }

  Future<void> addHistory(String noBukti, HistoryOrderModel history) async {
    await _ensureReady();
    try {
      final existing = await getHistories(noBukti);
      if (existing.any((h) => h.noId == history.noId)) return;

      existing.add(history);
      existing.sort((a, b) => b.tglProgress.compareTo(a.tglProgress));
      await saveHistories(noBukti, existing);

      debugPrint('[CustomerPesananLocal] ✅ Added history: $noBukti');
    } catch (e) {
      debugPrint('[CustomerPesananLocal] ❌ addHistory: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // READ
  // ═══════════════════════════════════════════════════

  Future<List<PesananModel>> getAllOrders() async {
    await _ensureReady();
    try {
      return _orderBox!.values.toList();
    } catch (e) {
      debugPrint('[CustomerPesananLocal] ❌ getAllOrders: $e');
      return [];
    }
  }

  Future<List<PesananModel>> getOrdersByStatus(String status) async {
    await _ensureReady();
    try {
      return _orderBox!.values
          .where((o) => o.statusProgresPesanan == status)
          .toList();
    } catch (e) {
      debugPrint('[CustomerPesananLocal] ❌ getOrdersByStatus: $e');
      return [];
    }
  }

  Future<PesananModel?> getOrder(String noBukti) async {
    await _ensureReady();
    try {
      return _orderBox!.get(noBukti);
    } catch (e) {
      debugPrint('[CustomerPesananLocal] ❌ getOrder: $e');
      return null;
    }
  }

  Future<List<HistoryOrderModel>> getHistories(String noBukti) async {
    await _ensureReady();
    try {
      final jsonList = _historyBox!.get(noBukti);
      if (jsonList == null || jsonList.isEmpty) return [];

      return jsonList
          .map((json) {
            try {
              return HistoryOrderModel.fromJson(
                  Map<String, dynamic>.from(json));
            } catch (_) {
              return null;
            }
          })
          .whereType<HistoryOrderModel>()
          .toList();
    } catch (e) {
      debugPrint('[CustomerPesananLocal] ❌ getHistories: $e');
      return [];
    }
  }

  Future<bool> isCached(String noBukti) async {
    await _ensureReady();
    return _orderBox!.containsKey(noBukti);
  }

  // ═══════════════════════════════════════════════════
  // UPDATE
  // ═══════════════════════════════════════════════════

  Future<void> updateOrder(PesananModel order) async {
    await _ensureReady();
    try {
      if (_orderBox!.containsKey(order.noBukti)) {
        await _orderBox!.put(order.noBukti, order);
        debugPrint('[CustomerPesananLocal] ✅ Updated: ${order.noBukti}');
      }
    } catch (e) {
      debugPrint('[CustomerPesananLocal] ❌ updateOrder: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String noBukti, String newStatus) async {
    await _ensureReady();
    try {
      final order = await getOrder(noBukti);
      if (order != null) {
        await _orderBox!.put(
          noBukti,
          order.copyWith(statusProgresPesanan: newStatus),
        );
        debugPrint(
            '[CustomerPesananLocal] ✅ Status updated: $noBukti → $newStatus');
      }
    } catch (e) {
      debugPrint('[CustomerPesananLocal] ❌ updateOrderStatus: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // DELETE
  // ═══════════════════════════════════════════════════

  Future<void> deleteOrder(String noBukti) async {
    await _ensureReady();
    try {
      await _orderBox!.delete(noBukti);
      await _historyBox!.delete(noBukti);
      debugPrint('[CustomerPesananLocal] ✅ Deleted: $noBukti');
    } catch (e) {
      debugPrint('[CustomerPesananLocal] ❌ deleteOrder: $e');
      rethrow;
    }
  }

  /// Clear semua data. Dipanggil saat logout atau hapus akun.
  Future<void> clearAll() async {
    await _ensureReady();
    try {
      debugPrint('[CustomerPesananLocal] 🗑️ Clearing all...');
      await _orderBox!.clear();
      await _historyBox!.clear();
      debugPrint('[CustomerPesananLocal] ✅ clearAll done');
    } catch (e) {
      debugPrint('[CustomerPesananLocal] ❌ clearAll: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // STATS
  // ═══════════════════════════════════════════════════

  Future<Map<String, dynamic>> getStats() async {
    await _ensureReady();
    try {
      final orders = await getAllOrders();

      int progressCount = 0;
      int selesaiCount = 0;
      int totalHistories = 0;

      final progressStatuses = {'persiapan', 'proses', 'review', 'revisi'};

      for (final order in orders) {
        if (progressStatuses.contains(order.statusProgresPesanan)) {
          progressCount++;
        } else if (order.statusProgresPesanan == 'selesai') {
          selesaiCount++;
        }

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
      debugPrint('[CustomerPesananLocal] ❌ getStats: $e');
      return {};
    }
  }

  Future<void> printStats() async {
    final s = await getStats();
    debugPrint('📊 PESANAN CACHE:');
    debugPrint(
        '   Total: ${s['total_orders']} | Progress: ${s['progress_orders']} | Selesai: ${s['selesai_orders']}');
    debugPrint('   Total histories: ${s['total_histories']}');
  }

  Future<int> getCount() async {
    await _ensureReady();
    return _orderBox!.length;
  }

  Future<void> close() async {
    if (_orderBox?.isOpen ?? false) await _orderBox!.close();
    if (_historyBox?.isOpen ?? false) await _historyBox!.close();
    debugPrint('[CustomerPesananLocal] ✅ Boxes closed');
  }
}
