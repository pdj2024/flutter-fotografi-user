import 'package:hive/hive.dart';
import 'package:mpjnew/src/data/models/ulasan_model.dart';

/// ✨ ULASAN LOCAL SERVICE - HIVE OPERATIONS
/// Mengelola penyimpanan dan pengambilan data ulasan dari Hive
///
/// Strategy:
/// - Cache ulasan untuk fast loading
/// - Integrated dengan paket (1 paket → many ulasan)
/// - Auto-sync bersamaan dengan paket
/// - Support filtering by vendor & paket
/// - Efficient query dengan indexing
class UlasanLocalService {
  static const String _boxName = 'ulasan_box';

  Box<UlasanModel>? _box;

  /// Initialize Hive box
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox<UlasanModel>(_boxName);
        print('✅ [UlasanLocal] Box opened: ${_box!.length} items');
      } else {
        _box = Hive.box<UlasanModel>(_boxName);
        print('✅ [UlasanLocal] Box already open: ${_box!.length} items');
      }
    } catch (e) {
      print('❌ [UlasanLocal] Error opening box: $e');
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
  // 📥 CREATE / SAVE OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Save single ulasan to local storage
  Future<void> saveUlasan(UlasanModel ulasan) async {
    await _ensureBoxReady();

    try {
      await _box!.put(ulasan.noId, ulasan);
      print('✅ [UlasanLocal] Saved: ${ulasan.noId} (${ulasan.rating}⭐)');
    } catch (e) {
      print('❌ [UlasanLocal] Error saving ulasan: $e');
      rethrow;
    }
  }

  /// Save multiple ulasan (batch operation)
  Future<void> saveUlasanList(List<UlasanModel> ulasanList) async {
    await _ensureBoxReady();

    try {
      final Map<String, UlasanModel> ulasanMap = {
        for (var ulasan in ulasanList) ulasan.noId: ulasan
      };

      await _box!.putAll(ulasanMap);
      print('✅ [UlasanLocal] Saved ${ulasanList.length} ulasan');
    } catch (e) {
      print('❌ [UlasanLocal] Error saving ulasan list: $e');
      rethrow;
    }
  }

  /// Replace all data (full sync)
  Future<void> replaceAll(List<UlasanModel> ulasanList) async {
    await _ensureBoxReady();

    try {
      await _box!.clear();
      await saveUlasanList(ulasanList);
      print('✅ [UlasanLocal] Replaced all data: ${ulasanList.length} items');
    } catch (e) {
      print('❌ [UlasanLocal] Error replacing data: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 📤 READ OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Get all ulasan from local storage
  Future<List<UlasanModel>> getAllUlasan() async {
    await _ensureBoxReady();

    try {
      final ulasan = _box!.values.toList();
      print('📦 [UlasanLocal] Retrieved ${ulasan.length} ulasan');
      return ulasan;
    } catch (e) {
      print('❌ [UlasanLocal] Error getting all ulasan: $e');
      return [];
    }
  }

  /// Get ulasan by ID
  Future<UlasanModel?> getUlasanById(String noId) async {
    await _ensureBoxReady();

    try {
      final ulasan = _box!.get(noId);
      if (ulasan != null) {
        print('📦 [UlasanLocal] Found: $noId (${ulasan.rating}⭐)');
      } else {
        print('⚠️ [UlasanLocal] Not found: $noId');
      }
      return ulasan;
    } catch (e) {
      print('❌ [UlasanLocal] Error getting ulasan: $e');
      return null;
    }
  }

  /// Get ulasan by vendor ID
  Future<List<UlasanModel>> getUlasanByVendor(String vendorId) async {
    await _ensureBoxReady();

    try {
      final ulasan = _box!.values
          .where((u) =>
              u.idVendor == vendorId && u.status.toLowerCase() == 'aktif')
          .toList();

      print(
          '📦 [UlasanLocal] Found ${ulasan.length} ulasan for vendor: $vendorId');
      return ulasan;
    } catch (e) {
      print('❌ [UlasanLocal] Error getting ulasan by vendor: $e');
      return [];
    }
  }

  /// ✅ CRITICAL: Get ulasan by paket ID
  /// This is the main method used for displaying reviews per package
  Future<List<UlasanModel>> getUlasanByPaket(String paketId) async {
    await _ensureBoxReady();

    try {
      final ulasan = _box!.values.where((u) {
        // Check if paketId contains the ID (support comma-separated IDs)
        if (u.idPaket.isEmpty) return false;

        final paketIds = u.idPaket.split(',').map((id) => id.trim()).toList();
        return paketIds.contains(paketId) && u.status.toLowerCase() == 'aktif';
      }).toList();

      // Sort by date descending (newest first)
      ulasan.sort((a, b) => b.tglUlasan.compareTo(a.tglUlasan));

      print(
          '📦 [UlasanLocal] Found ${ulasan.length} ulasan for paket: $paketId');
      return ulasan;
    } catch (e) {
      print('❌ [UlasanLocal] Error getting ulasan by paket: $e');
      return [];
    }
  }

  /// Get ulasan by multiple paket IDs (efficient bulk query)
  Future<Map<String, List<UlasanModel>>> getUlasanByPaketIds(
    List<String> paketIds,
  ) async {
    await _ensureBoxReady();

    try {
      final Map<String, List<UlasanModel>> result = {};

      // Initialize empty lists for each paket
      for (var paketId in paketIds) {
        result[paketId] = [];
      }

      // Group ulasan by paket
      for (var ulasan in _box!.values) {
        if (ulasan.status.toLowerCase() != 'aktif') continue;
        if (ulasan.idPaket.isEmpty) continue;

        final ulasanPaketIds =
            ulasan.idPaket.split(',').map((id) => id.trim()).toList();

        for (var paketId in paketIds) {
          if (ulasanPaketIds.contains(paketId)) {
            result[paketId]!.add(ulasan);
          }
        }
      }

      // Sort each list by date
      for (var entry in result.entries) {
        entry.value.sort((a, b) => b.tglUlasan.compareTo(a.tglUlasan));
      }

      print('📦 [UlasanLocal] Grouped ulasan for ${paketIds.length} pakets');
      return result;
    } catch (e) {
      print('❌ [UlasanLocal] Error getting ulasan by paket IDs: $e');
      return {};
    }
  }

  /// Get ulasan by order ID
  Future<List<UlasanModel>> getUlasanByOrder(String orderId) async {
    await _ensureBoxReady();

    try {
      final ulasan = _box!.values.where((u) => u.noOrder == orderId).toList();

      print(
          '📦 [UlasanLocal] Found ${ulasan.length} ulasan for order: $orderId');
      return ulasan;
    } catch (e) {
      print('❌ [UlasanLocal] Error getting ulasan by order: $e');
      return [];
    }
  }

  /// Get ulasan by customer ID
  Future<List<UlasanModel>> getUlasanByCustomer(String customerId) async {
    await _ensureBoxReady();

    try {
      final ulasan = _box!.values
          .where((u) =>
              u.idCustomer == customerId && u.status.toLowerCase() == 'aktif')
          .toList();

      print(
          '📦 [UlasanLocal] Found ${ulasan.length} ulasan from customer: $customerId');
      return ulasan;
    } catch (e) {
      print('❌ [UlasanLocal] Error getting ulasan by customer: $e');
      return [];
    }
  }

  /// Get ulasan by rating
  Future<List<UlasanModel>> getUlasanByRating({
    required int minRating,
    int? maxRating,
    String? vendorId,
  }) async {
    await _ensureBoxReady();

    try {
      final ulasan = _box!.values.where((u) {
        if (u.status.toLowerCase() != 'aktif') return false;
        if (u.rating < minRating) return false;
        if (maxRating != null && u.rating > maxRating) return false;
        if (vendorId != null && u.idVendor != vendorId) return false;
        return true;
      }).toList();

      print(
          '📦 [UlasanLocal] Found ${ulasan.length} ulasan with rating $minRating-${maxRating ?? 5}');
      return ulasan;
    } catch (e) {
      print('❌ [UlasanLocal] Error getting ulasan by rating: $e');
      return [];
    }
  }

  /// Get ulasan with balasan (replied reviews)
  Future<List<UlasanModel>> getUlasanWithBalasan({String? vendorId}) async {
    await _ensureBoxReady();

    try {
      final ulasan = _box!.values.where((u) {
        if (u.status.toLowerCase() != 'aktif') return false;
        if (u.adaBalasan != true) return false;
        if (vendorId != null && u.idVendor != vendorId) return false;
        return true;
      }).toList();

      print('📦 [UlasanLocal] Found ${ulasan.length} ulasan with balasan');
      return ulasan;
    } catch (e) {
      print('❌ [UlasanLocal] Error getting ulasan with balasan: $e');
      return [];
    }
  }

  /// Get ulasan without balasan (need reply)
  Future<List<UlasanModel>> getUlasanNeedReply({String? vendorId}) async {
    await _ensureBoxReady();

    try {
      final ulasan = _box!.values.where((u) {
        if (u.status.toLowerCase() != 'aktif') return false;
        if (u.adaBalasan == true) return false;
        if (vendorId != null && u.idVendor != vendorId) return false;
        return true;
      }).toList();

      // Sort by date ascending (oldest first - need reply urgently)
      ulasan.sort((a, b) => a.tglUlasan.compareTo(b.tglUlasan));

      print('📦 [UlasanLocal] Found ${ulasan.length} ulasan need reply');
      return ulasan;
    } catch (e) {
      print('❌ [UlasanLocal] Error getting ulasan need reply: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✏️ UPDATE OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Update ulasan in local storage
  Future<void> updateUlasan(UlasanModel ulasan) async {
    await _ensureBoxReady();

    try {
      if (_box!.containsKey(ulasan.noId)) {
        await _box!.put(ulasan.noId, ulasan);
        print('✅ [UlasanLocal] Updated: ${ulasan.noId}');
      } else {
        print(
            '⚠️ [UlasanLocal] Ulasan not found, creating new: ${ulasan.noId}');
        await saveUlasan(ulasan);
      }
    } catch (e) {
      print('❌ [UlasanLocal] Error updating ulasan: $e');
      rethrow;
    }
  }

  /// Add balasan to ulasan
  Future<void> addBalasan(
    String ulasanId,
    String isiBalasan,
  ) async {
    await _ensureBoxReady();

    try {
      final ulasan = await getUlasanById(ulasanId);
      if (ulasan != null) {
        final updated = ulasan.copyWith(
          adaBalasan: true,
          isiBalasan: isiBalasan,
          tglBalasan: DateTime.now(),
        );
        await updateUlasan(updated);
        print('✅ [UlasanLocal] Added balasan to: $ulasanId');
      } else {
        print(
            '⚠️ [UlasanLocal] Cannot add balasan, ulasan not found: $ulasanId');
      }
    } catch (e) {
      print('❌ [UlasanLocal] Error adding balasan: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🗑️ DELETE OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Delete ulasan from local storage (hard delete)
  Future<void> deleteUlasan(String noId) async {
    await _ensureBoxReady();

    try {
      await _box!.delete(noId);
      print('✅ [UlasanLocal] Deleted: $noId');
    } catch (e) {
      print('❌ [UlasanLocal] Error deleting ulasan: $e');
      rethrow;
    }
  }

  /// Delete ulasan by paket (when paket is deleted)
  Future<void> deleteUlasanByPaket(String paketId) async {
    await _ensureBoxReady();

    try {
      final ulasanToDelete = await getUlasanByPaket(paketId);

      for (var ulasan in ulasanToDelete) {
        await _box!.delete(ulasan.noId);
      }

      print(
          '✅ [UlasanLocal] Deleted ${ulasanToDelete.length} ulasan for paket: $paketId');
    } catch (e) {
      print('❌ [UlasanLocal] Error deleting ulasan by paket: $e');
      rethrow;
    }
  }

  /// Delete ulasan by vendor
  Future<void> deleteUlasanByVendor(String vendorId) async {
    await _ensureBoxReady();

    try {
      final ulasanToDelete = await getUlasanByVendor(vendorId);

      for (var ulasan in ulasanToDelete) {
        await _box!.delete(ulasan.noId);
      }

      print(
          '✅ [UlasanLocal] Deleted ${ulasanToDelete.length} ulasan for vendor: $vendorId');
    } catch (e) {
      print('❌ [UlasanLocal] Error deleting ulasan by vendor: $e');
      rethrow;
    }
  }

  /// Clear all ulasan
  Future<void> clearAll() async {
    await _ensureBoxReady();

    try {
      await _box!.clear();
      print('✅ [UlasanLocal] Cleared all ulasan');
    } catch (e) {
      print('❌ [UlasanLocal] Error clearing ulasan: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 📊 STATISTICS & ANALYTICS
  // ═══════════════════════════════════════════════════════════

  /// Get statistics by vendor
  Future<Map<String, dynamic>> getStatistics({String? vendorId}) async {
    await _ensureBoxReady();

    try {
      final ulasanList = vendorId != null
          ? await getUlasanByVendor(vendorId)
          : _box!.values
              .where((u) => u.status.toLowerCase() == 'aktif')
              .toList();

      if (ulasanList.isEmpty) {
        return {
          'total': 0,
          'average_rating': 0.0,
          'rating_distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
          'with_balasan': 0,
          'need_reply': 0,
        };
      }

      // Calculate statistics
      final totalRating = ulasanList.fold<int>(0, (sum, u) => sum + u.rating);
      final averageRating = totalRating / ulasanList.length;

      final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (var ulasan in ulasanList) {
        ratingDistribution[ulasan.rating] =
            (ratingDistribution[ulasan.rating] ?? 0) + 1;
      }

      final withBalasan = ulasanList.where((u) => u.adaBalasan == true).length;
      final needReply = ulasanList.where((u) => u.adaBalasan != true).length;

      return {
        'total': ulasanList.length,
        'average_rating': double.parse(averageRating.toStringAsFixed(1)),
        'rating_distribution': ratingDistribution,
        'with_balasan': withBalasan,
        'need_reply': needReply,
        'reply_rate': withBalasan / ulasanList.length * 100,
      };
    } catch (e) {
      print('❌ [UlasanLocal] Error getting statistics: $e');
      return {};
    }
  }

  /// Get statistics by paket
  Future<Map<String, dynamic>> getStatisticsByPaket(String paketId) async {
    try {
      final ulasanList = await getUlasanByPaket(paketId);

      if (ulasanList.isEmpty) {
        return {
          'total': 0,
          'average_rating': 0.0,
          'rating_distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final totalRating = ulasanList.fold<int>(0, (sum, u) => sum + u.rating);
      final averageRating = totalRating / ulasanList.length;

      final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (var ulasan in ulasanList) {
        ratingDistribution[ulasan.rating] =
            (ratingDistribution[ulasan.rating] ?? 0) + 1;
      }

      return {
        'total': ulasanList.length,
        'average_rating': double.parse(averageRating.toStringAsFixed(1)),
        'rating_distribution': ratingDistribution,
      };
    } catch (e) {
      print('❌ [UlasanLocal] Error getting paket statistics: $e');
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 📊 UTILITY OPERATIONS
  // ═══════════════════════════════════════════════════════════

  /// Check if ulasan exists
  Future<bool> exists(String noId) async {
    await _ensureBoxReady();
    return _box!.containsKey(noId);
  }

  /// Get count of ulasan
  Future<int> getCount() async {
    await _ensureBoxReady();
    return _box!.length;
  }

  /// Get count by vendor
  Future<int> getCountByVendor(String vendorId) async {
    final ulasan = await getUlasanByVendor(vendorId);
    return ulasan.length;
  }

  /// Get count by paket
  Future<int> getCountByPaket(String paketId) async {
    final ulasan = await getUlasanByPaket(paketId);
    return ulasan.length;
  }

  /// Close box (cleanup)
  Future<void> close() async {
    if (_box?.isOpen ?? false) {
      await _box!.close();
      print('✅ [UlasanLocal] Box closed');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔄 SYNC OPERATIONS (Integrated with Paket)
  // ═══════════════════════════════════════════════════════════

  /// Sync ulasan for specific vendor (called when paket sync happens)
  /// ✅ Always updates existing ulasan to ensure complete data (names, etc.)
  Future<void> syncForVendor(String vendorId, List<UlasanModel> apiData) async {
    await _ensureBoxReady();

    try {
      print('🔄 [UlasanLocal] Syncing ulasan for vendor: $vendorId');

      // Get current local ulasan for this vendor
      final localUlasan = await getUlasanByVendor(vendorId);
      final localIds = localUlasan.map((u) => u.noId).toSet();
      final apiIds = apiData.map((u) => u.noId).toSet();

      // Delete ulasan that no longer exist in API
      final toDelete = localIds.difference(apiIds);
      for (var id in toDelete) {
        await _box!.delete(id);
        print('   🗑️ Deleted: $id (not in API)');
      }

      // ✅ ALWAYS update/add ulasan from API to ensure complete data
      // This is important because FCM data may not have complete info (names, etc.)
      int updated = 0;
      int added = 0;

      for (var ulasan in apiData) {
        final isExisting = localIds.contains(ulasan.noId);
        await _box!.put(ulasan.noId, ulasan);

        if (isExisting) {
          updated++;
          // Only log first few to avoid spam
          if (updated <= 3) {
            print('   🔄 Updated: ${ulasan.noId}');
          }
        } else {
          added++;
          if (added <= 3) {
            print('   ➕ Added: ${ulasan.noId}');
          }
        }
      }

      print('✅ [UlasanLocal] Vendor sync complete:');
      print('   Total: ${apiData.length} items');
      print('   Updated: $updated items (with complete data)');
      print('   Added: $added items');
      print('   Deleted: ${toDelete.length} items');
    } catch (e) {
      print('❌ [UlasanLocal] Error syncing: $e');
      rethrow;
    }
  }

  /// Sync ulasan for specific paket
  /// ✅ Always updates existing ulasan to ensure complete data (names, etc.)
  Future<void> syncForPaket(String paketId, List<UlasanModel> apiData) async {
    await _ensureBoxReady();

    try {
      print('🔄 [UlasanLocal] Syncing ulasan for paket: $paketId');

      // Get current local ulasan for this paket
      final localUlasan = await getUlasanByPaket(paketId);
      final localIds = localUlasan.map((u) => u.noId).toSet();
      final apiIds = apiData.map((u) => u.noId).toSet();

      // Delete ulasan that no longer exist in API
      final toDelete = localIds.difference(apiIds);
      for (var id in toDelete) {
        await _box!.delete(id);
        print('   🗑️ Deleted: $id (not in API)');
      }

      // ✅ ALWAYS update/add ulasan from API to ensure complete data
      // This is important because FCM data may not have complete info (names, etc.)
      int updated = 0;
      int added = 0;

      for (var ulasan in apiData) {
        final isExisting = localIds.contains(ulasan.noId);
        await _box!.put(ulasan.noId, ulasan);

        if (isExisting) {
          updated++;
          print('   🔄 Updated: ${ulasan.noId} (refreshed from API)');
        } else {
          added++;
          print('   ➕ Added: ${ulasan.noId} (new from API)');
        }
      }

      print('✅ [UlasanLocal] Paket sync complete:');
      print('   Total: ${apiData.length} items');
      print('   Updated: $updated items');
      print('   Added: $added items');
      print('   Deleted: ${toDelete.length} items');
    } catch (e) {
      print('❌ [UlasanLocal] Error syncing paket: $e');
      rethrow;
    }
  }
}
