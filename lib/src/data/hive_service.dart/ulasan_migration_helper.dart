import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/hive_service.dart/ulasan_local_service.dart';
import 'package:mpjnew/src/features/customer/services/ulasan_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// ULASAN MIGRATION HELPER
/// 
/// Handles:
/// - Initial sync from API to local storage
/// - Data integrity checks
/// - Migration operations
/// - Health monitoring
/// ═══════════════════════════════════════════════════════════════

class UlasanMigrationHelper {
  static final UlasanService _apiService = UlasanService();

  /// ═══════════════════════════════════════════════════════════
  /// CHECK IF INITIAL SYNC IS NEEDED
  /// ═══════════════════════════════════════════════════════════

  static Future<bool> needsInitialSync({
    required UlasanLocalService localService,
    required String vendorId,
  }) async {
    try {
      debugPrint('🔍 [UlasanMigration] Checking if initial sync needed...');

      // Check if local storage is empty
      final count = await localService.getCountByVendor(vendorId);
      
      if (count == 0) {
        debugPrint('✅ [UlasanMigration] Initial sync needed: No local data');
        return true;
      }

      debugPrint('ℹ️ [UlasanMigration] Local storage has $count ulasan');
      return false;
    } catch (e) {
      debugPrint('❌ [UlasanMigration] Error checking sync need: $e');
      return true; // If error, safer to sync
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// PERFORM INITIAL SYNC
  /// ═══════════════════════════════════════════════════════════

  static Future<bool> performInitialSync({
    required UlasanLocalService localService,
    required String vendorId,
  }) async {
    try {
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('[UlasanMigration] 🔄 PERFORMING INITIAL SYNC');
      debugPrint('═══════════════════════════════════════════════════');

      // Fetch all active ulasan for this vendor from API
      final apiUlasan = await _apiService.getAll(
        idVendor: vendorId,
        status: 'aktif',
        orderBy: 'Tgl_Ulasan',
        orderDir: 'DESC',
      );

      debugPrint('[UlasanMigration] ✅ Fetched ${apiUlasan.length} ulasan from API');

      if (apiUlasan.isEmpty) {
        debugPrint('[UlasanMigration] ℹ️ No ulasan to sync');
        return true;
      }

      // Save to local storage
      await localService.syncForVendor(vendorId, apiUlasan);

      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('[UlasanMigration] ✅ INITIAL SYNC COMPLETE');
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('Total synced: ${apiUlasan.length} ulasan');
      debugPrint('═══════════════════════════════════════════════════');

      return true;
    } catch (e, st) {
      debugPrint('❌ [UlasanMigration] Initial sync failed: $e');
      debugPrint(st.toString());
      return false;
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// VERIFY DATA INTEGRITY
  /// ═══════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> verifyDataIntegrity({
    required UlasanLocalService localService,
    required String vendorId,
  }) async {
    try {
      debugPrint('🔍 [UlasanMigration] Verifying data integrity...');

      final allUlasan = await localService.getUlasanByVendor(vendorId);

      // Check for duplicates
      final uniqueIds = allUlasan.map((u) => u.noId).toSet();
      final hasDuplicates = uniqueIds.length != allUlasan.length;

      // Check for invalid data
      final invalidUlasan = allUlasan.where((u) {
        return u.noId.isEmpty ||
               u.rating < 1 ||
               u.rating > 5 ||
               u.isiUlasan.isEmpty;
      }).toList();

      // Check rating distribution
      final ratingDistribution = <int, int>{};
      for (var ulasan in allUlasan) {
        ratingDistribution[ulasan.rating] = 
            (ratingDistribution[ulasan.rating] ?? 0) + 1;
      }

      // Check balasan status
      final withBalasan = allUlasan.where((u) => u.adaBalasan == true).length;
      final needReply = allUlasan.length - withBalasan;

      final result = {
        'total': allUlasan.length,
        'unique_ids': uniqueIds.length,
        'has_duplicates': hasDuplicates,
        'invalid_count': invalidUlasan.length,
        'invalid_items': invalidUlasan.map((u) => u.noId).toList(),
        'rating_distribution': ratingDistribution,
        'with_balasan': withBalasan,
        'need_reply': needReply,
        'is_healthy': !hasDuplicates && invalidUlasan.isEmpty,
      };

      debugPrint('✅ [UlasanMigration] Integrity check complete:');
      debugPrint('   Total: ${result['total']}');
      debugPrint('   Duplicates: ${result['has_duplicates']}');
      debugPrint('   Invalid: ${result['invalid_count']}');
      debugPrint('   With balasan: ${result['with_balasan']}');
      debugPrint('   Need reply: ${result['need_reply']}');
      debugPrint('   Health: ${result['is_healthy'] as bool ? 'HEALTHY ✅' : 'ISSUES FOUND ⚠️'}');

      return result;
    } catch (e) {
      debugPrint('❌ [UlasanMigration] Integrity check failed: $e');
      return {
        'error': e.toString(),
        'is_healthy': false,
      };
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// CLEANUP INVALID DATA
  /// ═══════════════════════════════════════════════════════════

  static Future<int> cleanupInvalidData({
    required UlasanLocalService localService,
    required String vendorId,
  }) async {
    try {
      debugPrint('🧹 [UlasanMigration] Cleaning up invalid data...');

      final allUlasan = await localService.getUlasanByVendor(vendorId);
      int cleanedCount = 0;

      for (var ulasan in allUlasan) {
        bool isInvalid = false;

        // Check for invalid data
        if (ulasan.noId.isEmpty) {
          isInvalid = true;
          debugPrint('   ⚠️ Invalid: Empty noId');
        }

        if (ulasan.rating < 1 || ulasan.rating > 5) {
          isInvalid = true;
          debugPrint('   ⚠️ Invalid: Rating out of range (${ulasan.rating})');
        }

        if (ulasan.isiUlasan.isEmpty) {
          isInvalid = true;
          debugPrint('   ⚠️ Invalid: Empty review content');
        }

        if (isInvalid) {
          await localService.deleteUlasan(ulasan.noId);
          cleanedCount++;
        }
      }

      debugPrint('✅ [UlasanMigration] Cleanup complete: Removed $cleanedCount invalid items');
      return cleanedCount;
    } catch (e) {
      debugPrint('❌ [UlasanMigration] Cleanup failed: $e');
      return 0;
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// REMOVE DUPLICATES
  /// ═══════════════════════════════════════════════════════════

  static Future<int> removeDuplicates({
    required UlasanLocalService localService,
    required String vendorId,
  }) async {
    try {
      debugPrint('🧹 [UlasanMigration] Removing duplicates...');

      final allUlasan = await localService.getUlasanByVendor(vendorId);
      final seen = <String>{};
      int removedCount = 0;

      for (var ulasan in allUlasan) {
        if (seen.contains(ulasan.noId)) {
          // Duplicate found, keep the one with latest date
          await localService.deleteUlasan(ulasan.noId);
          removedCount++;
          debugPrint('   🗑️ Removed duplicate: ${ulasan.noId}');
        } else {
          seen.add(ulasan.noId);
        }
      }

      debugPrint('✅ [UlasanMigration] Removed $removedCount duplicates');
      return removedCount;
    } catch (e) {
      debugPrint('❌ [UlasanMigration] Remove duplicates failed: $e');
      return 0;
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// RUN FULL MIGRATION
  /// ═══════════════════════════════════════════════════════════

  static Future<bool> runFullMigration({
    required UlasanLocalService localService,
    required String vendorId,
  }) async {
    try {
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('[UlasanMigration] 🚀 RUNNING FULL MIGRATION');
      debugPrint('═══════════════════════════════════════════════════');

      // STEP 1: Verify current data
      final integrity = await verifyDataIntegrity(
        localService: localService,
        vendorId: vendorId,
      );

      // STEP 2: Cleanup if needed
      if (!integrity['is_healthy']) {
        debugPrint('[UlasanMigration] ⚠️ Data issues found, cleaning up...');
        
        await cleanupInvalidData(
          localService: localService,
          vendorId: vendorId,
        );
        
        await removeDuplicates(
          localService: localService,
          vendorId: vendorId,
        );
      }

      // STEP 3: Check if initial sync is needed
      final needsSync = await needsInitialSync(
        localService: localService,
        vendorId: vendorId,
      );

      // STEP 4: Perform initial sync if needed
      if (needsSync) {
        final syncSuccess = await performInitialSync(
          localService: localService,
          vendorId: vendorId,
        );

        if (!syncSuccess) {
          debugPrint('❌ [UlasanMigration] Initial sync failed');
          return false;
        }
      } else {
        debugPrint('[UlasanMigration] ℹ️ Initial sync not needed');
      }

      // STEP 5: Final integrity check
      final finalIntegrity = await verifyDataIntegrity(
        localService: localService,
        vendorId: vendorId,
      );

      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('[UlasanMigration] ✅ MIGRATION COMPLETE');
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('Final status: ${finalIntegrity['is_healthy'] ? 'HEALTHY ✅' : 'NEEDS ATTENTION ⚠️'}');
      debugPrint('Total ulasan: ${finalIntegrity['total']}');
      debugPrint('═══════════════════════════════════════════════════');

      return finalIntegrity['is_healthy'];
    } catch (e, st) {
      debugPrint('❌ [UlasanMigration] Migration failed: $e');
      debugPrint(st.toString());
      return false;
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// GET HEALTH STATUS
  /// ═══════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getHealthStatus({
    required UlasanLocalService localService,
    required String vendorId,
  }) async {
    try {
      final integrity = await verifyDataIntegrity(
        localService: localService,
        vendorId: vendorId,
      );

      final statistics = await localService.getStatistics(vendorId: vendorId);

      return {
        'is_healthy': integrity['is_healthy'],
        'total_ulasan': integrity['total'],
        'average_rating': statistics['average_rating'],
        'rating_distribution': statistics['rating_distribution'],
        'reply_rate': statistics['reply_rate'],
        'need_reply': statistics['need_reply'],
        'has_duplicates': integrity['has_duplicates'],
        'invalid_count': integrity['invalid_count'],
      };
    } catch (e) {
      debugPrint('❌ [UlasanMigration] Get health status failed: $e');
      return {
        'is_healthy': false,
        'error': e.toString(),
      };
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// SYNC ULASAN FOR SPECIFIC PAKET
  /// ═══════════════════════════════════════════════════════════

  static Future<bool> syncUlasanForPaket({
    required UlasanLocalService localService,
    required String paketId,
    UlasanService? apiService,
  }) async {
    try {
      debugPrint('[UlasanMigration] 🔄 Syncing ulasan for paket: $paketId');

      final service = apiService ?? _apiService;

      // Fetch ulasan for this paket from API
      final apiUlasan = await service.getAll(
        idPaket: paketId,
        status: 'aktif',
        orderBy: 'Tgl_Ulasan',
        orderDir: 'DESC',
      );

      // Sync to local storage
      await localService.syncForPaket(paketId, apiUlasan);

      debugPrint('[UlasanMigration] ✅ Synced ${apiUlasan.length} ulasan for paket: $paketId');
      return true;
    } catch (e) {
      debugPrint('[UlasanMigration] ❌ Sync failed for paket: $paketId - $e');
      return false;
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// EXPORT DIAGNOSTICS
  /// ═══════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> exportDiagnostics({
    required UlasanLocalService localService,
    required String vendorId,
  }) async {
    try {
      final health = await getHealthStatus(
        localService: localService,
        vendorId: vendorId,
      );

      final allUlasan = await localService.getUlasanByVendor(vendorId);

      // Group by paket
      final byPaket = <String, int>{};
      for (var ulasan in allUlasan) {
        final paketIds = ulasan.idPaket.split(',').map((id) => id.trim()).toList();
        for (var paketId in paketIds) {
          byPaket[paketId] = (byPaket[paketId] ?? 0) + 1;
        }
      }

      // Recent ulasan
      final recent = allUlasan.take(10).map((u) => {
        'id': u.noId,
        'rating': u.rating,
        'date': u.tglUlasan.toIso8601String(),
        'has_reply': u.adaBalasan ?? false,
      }).toList();

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'vendor_id': vendorId,
        'health': health,
        'ulasan_by_paket': byPaket,
        'recent_ulasan': recent,
        'total_pakets_with_ulasan': byPaket.length,
      };
    } catch (e) {
      debugPrint('❌ [UlasanMigration] Export diagnostics failed: $e');
      return {
        'error': e.toString(),
      };
    }
  }
}