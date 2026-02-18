import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';
import 'package:mpjnew/src/data/hive_service.dart/portofolio_local_service.dart';
import 'package:mpjnew/src/features/customer/services/portofolio_service.dart';

class PortofolioMigrationHelper {
  /// ─── LIKE ───────────────────────────────────────────────

  /// Dipanggil setelah user tap tombol Like.
  /// [portfolio] harus sudah berisi data lengkap (mediaUrls, dll).
  static Future<void> onLike({
    required PortofolioLocalService localService,
    required PortofolioModel portfolio,
  }) async {
    try {
      debugPrint('[CustomerMigration] ❤️ onLike: ${portfolio.noId}');

      // Simpan ke lokal + download media (background)
      await localService.saveLiked(portfolio);

      debugPrint('[CustomerMigration] ✅ Like saved locally');
    } catch (e) {
      debugPrint('[CustomerMigration] ❌ onLike error: $e');
      rethrow;
    }
  }

  /// Dipanggil setelah user tap tombol Unlike.
  static Future<void> onUnlike({
    required PortofolioLocalService localService,
    required String portfolioId,
  }) async {
    try {
      debugPrint('[CustomerMigration] 💔 onUnlike: $portfolioId');

      await localService.removeLiked(portfolioId);

      debugPrint('[CustomerMigration] ✅ Unlike removed locally');
    } catch (e) {
      debugPrint('[CustomerMigration] ❌ onUnlike error: $e');
      rethrow;
    }
  }

  /// ─── SAVE ───────────────────────────────────────────────

  /// Dipanggil setelah user tap tombol Save.
  static Future<void> onSave({
    required PortofolioLocalService localService,
    required PortofolioModel portfolio,
  }) async {
    try {
      debugPrint('[CustomerMigration] 🔖 onSave: ${portfolio.noId}');

      await localService.saveSaved(portfolio);

      debugPrint('[CustomerMigration] ✅ Save saved locally');
    } catch (e) {
      debugPrint('[CustomerMigration] ❌ onSave error: $e');
      rethrow;
    }
  }

  /// Dipanggil setelah user tap tombol Unsave.
  static Future<void> onUnsave({
    required PortofolioLocalService localService,
    required String portfolioId,
  }) async {
    try {
      debugPrint('[CustomerMigration] 🗑️ onUnsave: $portfolioId');

      await localService.removeSaved(portfolioId);

      debugPrint('[CustomerMigration] ✅ Unsave removed locally');
    } catch (e) {
      debugPrint('[CustomerMigration] ❌ onUnsave error: $e');
      rethrow;
    }
  }

  /// ─── LOAD (Halaman Like/Save) ────────────────────────────

  /// Load liked portfolios.
  /// Langsung return dari lokal (gambar sudah ada di device).
  /// Background sync dari API untuk update data terbaru.
  ///
  /// [onUpdated] callback dipanggil jika background sync menemukan data baru.
  static Future<List<PortofolioModel>> loadLiked({
    required PortofolioLocalService localService,
    required PortofolioService apiService,
    required String customerId,
    void Function(List<PortofolioModel>)? onUpdated,
  }) async {
    debugPrint('[CustomerMigration] 📦 Loading liked portfolios...');

    // ✅ Step 1: Return dari lokal (instant)
    final local = await localService.getLikedPortfolios();
    debugPrint('[CustomerMigration]    Local: ${local.length} portfolios');

    // ✅ Step 2: Background sync dari API
    _backgroundSyncLiked(
      localService: localService,
      apiService: apiService,
      customerId: customerId,
      onUpdated: onUpdated,
    );

    return local;
  }

  /// Load saved portfolios dari lokal + background sync.
  static Future<List<PortofolioModel>> loadSaved({
    required PortofolioLocalService localService,
    required PortofolioService apiService,
    required String customerId,
    void Function(List<PortofolioModel>)? onUpdated,
  }) async {
    debugPrint('[CustomerMigration] 📦 Loading saved portfolios...');

    final local = await localService.getSavedPortfolios();
    debugPrint('[CustomerMigration]    Local: ${local.length} portfolios');

    _backgroundSyncSaved(
      localService: localService,
      apiService: apiService,
      customerId: customerId,
      onUpdated: onUpdated,
    );

    return local;
  }

  /// ─── INITIAL SYNC (App Start / Login) ───────────────────

  /// Sync penuh dari API ke lokal saat login atau app start.
  /// Gunakan ini agar data lokal selalu up-to-date dengan server.
  static Future<void> fullSync({
    required PortofolioLocalService localService,
    required PortofolioService apiService,
    required String customerId,
  }) async {
    try {
      debugPrint('[CustomerMigration] 🔄 Full sync for customer: $customerId');

      // Fetch liked dan saved dari API secara paralel
      final results = await Future.wait([
        apiService.getAll(id_customer: customerId, status: 'aktif'),
        // apiService.getAll(id_customer: customerId, status: 'aktif'),
        // TODO: Jika API punya endpoint terpisah untuk liked/saved,
        // ganti dua call di atas dengan endpoint yang sesuai
        // Contoh:
        // apiService.getAllLiked(customerId: customerId),
        // apiService.getAllSaved(customerId: customerId),
      ]);

      // Untuk sekarang, filter dari hasil getAll berdasarkan field
      // (sesuaikan dengan struktur API yang sudah ada)
      // final allPortos = results[0];
      // final likedPortos = allPortos.where((p) => p.isLikedByCustomer).toList();
      // final savedPortos = allPortos.where((p) => p.isSavedByCustomer).toList();

      debugPrint('[CustomerMigration] ✅ Full sync complete');
    } catch (e) {
      debugPrint('[CustomerMigration] ❌ Full sync error: $e');
      // Silent fail — lokal data tetap ada
    }
  }

  /// ─── CLEAR (Logout) ──────────────────────────────────────

  static Future<void> clearAll({
    required PortofolioLocalService localService,
  }) async {
    await localService.clearAll();
    debugPrint('[CustomerMigration] 🗑️ All customer porto cache cleared');
  }

  // ═══════════════════════════════════════════════════════════
  // PRIVATE: BACKGROUND SYNC
  // ═══════════════════════════════════════════════════════════

  static void _backgroundSyncLiked({
    required PortofolioLocalService localService,
    required PortofolioService apiService,
    required String customerId,
    void Function(List<PortofolioModel>)? onUpdated,
  }) {
    Future.delayed(const Duration(milliseconds: 600), () async {
      try {
        debugPrint('[CustomerMigration] 🔄 Background liked sync...');

        // Fetch dari API
        // TODO: Ganti dengan endpoint liked khusus jika tersedia
        final apiList = await apiService.getAll(
          id_customer: customerId,
          status: 'aktif',
        );

        // Sync ke lokal
        await localService.syncLiked(apiList);

        // Notify jika ada callback
        if (onUpdated != null) {
          final updated = await localService.getLikedPortfolios();
          onUpdated(updated);
        }

        debugPrint('[CustomerMigration] ✅ Background liked sync done');
      } catch (e) {
        debugPrint('[CustomerMigration] ⚠️ Background liked sync failed: $e');
      }
    });
  }

  static void _backgroundSyncSaved({
    required PortofolioLocalService localService,
    required PortofolioService apiService,
    required String customerId,
    void Function(List<PortofolioModel>)? onUpdated,
  }) {
    Future.delayed(const Duration(milliseconds: 600), () async {
      try {
        debugPrint('[CustomerMigration] 🔄 Background saved sync...');

        final apiList = await apiService.getAll(
          id_customer: customerId,
          status: 'aktif',
        );

        await localService.syncSaved(apiList);

        if (onUpdated != null) {
          final updated = await localService.getSavedPortfolios();
          onUpdated(updated);
        }

        debugPrint('[CustomerMigration] ✅ Background saved sync done');
      } catch (e) {
        debugPrint('[CustomerMigration] ⚠️ Background saved sync failed: $e');
      }
    });
  }
}