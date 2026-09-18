import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/cache_manager.dart';
import 'package:mpjnew/src/data/hive_entity/media_url_model.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';
import 'package:mpjnew/src/features/customer/services/local_storage_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// CUSTOMER PORTOFOLIO LOCAL SERVICE
///
/// Menyimpan portofolio yang di-like & di-save oleh customer.
///
/// Dua box terpisah:
/// - customer_liked_porto_box  → portofolio yang di-like
/// - customer_saved_porto_box  → portofolio yang di-save/bookmark
///
/// Tidak menggunakan key prefix karena:
/// - Data ini sangat personal (like/save adalah tindakan user)
/// - Saat logout, seluruh box di-clear (bukan filter by user)
/// - Berbeda dengan vendor yang share satu box multi-vendor
///
/// Lifecycle:
///   Login  → initialize() → load liked/saved
///   Logout → clearAll() (hapus data + media cache)
///   Delete → clearAll() (sama, karena sudah hapus semua)
/// ═══════════════════════════════════════════════════════════════

class PortofolioLocalService {
  static const String _likedBoxName = 'customer_liked_porto_box';
  static const String _savedBoxName = 'customer_saved_porto_box';
  // Feed Home. Terpisah dari liked/saved karena isinya publik (guest pun
  // punya) dan dibuang-tulis ulang tiap fetch, bukan hasil aksi user.
  static const String _feedBoxName = 'customer_feed_porto_box';

  /// Batas item feed yang disimpan — cukup untuk mengisi layar pertama
  /// saat cold start; sisanya menyusul dari network.
  static const int feedCacheLimit = 20;

  Box<PortofolioModel>? _likedBox;
  Box<PortofolioModel>? _savedBox;
  Box<PortofolioModel>? _feedBox;

  // ═══════════════════════════════════════════════════
  // INIT
  // ═══════════════════════════════════════════════════

  Future<void> initialize() async {
    try {
      _likedBox = Hive.isBoxOpen(_likedBoxName)
          ? Hive.box<PortofolioModel>(_likedBoxName)
          : await Hive.openBox<PortofolioModel>(_likedBoxName);

      _savedBox = Hive.isBoxOpen(_savedBoxName)
          ? Hive.box<PortofolioModel>(_savedBoxName)
          : await Hive.openBox<PortofolioModel>(_savedBoxName);

      _feedBox = Hive.isBoxOpen(_feedBoxName)
          ? Hive.box<PortofolioModel>(_feedBoxName)
          : await Hive.openBox<PortofolioModel>(_feedBoxName);

      debugPrint('✅ [CustomerPortoLocal] Initialized');
      debugPrint('   Liked: ${_likedBox!.length} | Saved: ${_savedBox!.length}'
          ' | Feed: ${_feedBox!.length}');
    } catch (e) {
      debugPrint('❌ [CustomerPortoLocal] Init error: $e');
      rethrow;
    }
  }

  Future<void> _ensureReady() async {
    final needsHiveInit = _likedBox == null || !_likedBox!.isOpen ||
        _savedBox == null || !_savedBox!.isOpen ||
        _feedBox == null || !_feedBox!.isOpen;

    await Future.wait([
      if (needsHiveInit) initialize(),
      CacheManager.instance.initialize(),
    ]);
  }

  // ═══════════════════════════════════════════════════
  // LIKE — WRITE
  // ═══════════════════════════════════════════════════

  Future<void> saveLiked(PortofolioModel portfolio) async {
    await _ensureReady();

    // Guard: silent skip jika belum login (guest mode).
    // Tidak throw karena syncLiked() bisa dipanggil sebelum setActiveCustomer().
    if (!LocalStorageService.instance.hasActiveCustomer) {
      debugPrint('[CustomerPortoLocal] ⚠️ saveLiked skipped: no active customer');
      return;
    }

    try {
      final existing = _likedBox!.get(portfolio.noId);
      final toSave = (existing != null
              ? _mergeMedia(portfolio, existing)
              : portfolio)
          .copyWith(likedAt: DateTime.now());

      await _likedBox!.put(portfolio.noId, toSave);
      debugPrint('[CustomerPortoLocal] ❤️  saveLiked: ${portfolio.noId}');

      _downloadMediaBackground(toSave, _likedBox!);
    } catch (e) {
      debugPrint('❌ [CustomerPortoLocal] saveLiked: $e');
      rethrow;
    }
  }

  Future<void> removeLiked(String noId) async {
    await _ensureReady();
    try {
      final p = _likedBox!.get(noId);
      if (p == null) return;

      // Jangan hapus media jika masih di-save
      final isAlsoSaved = _savedBox!.containsKey(noId);
      if (!isAlsoSaved) await _cleanupMedia(p);

      await _likedBox!.delete(noId);
      debugPrint('[CustomerPortoLocal] 💔 removeLiked: $noId');
    } catch (e) {
      debugPrint('❌ [CustomerPortoLocal] removeLiked: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // SAVE / BOOKMARK — WRITE
  // ═══════════════════════════════════════════════════

  Future<void> saveSaved(PortofolioModel portfolio) async {
    await _ensureReady();
    // Guard: silent skip jika belum login (guest mode).
    if (!LocalStorageService.instance.hasActiveCustomer) {
      debugPrint('[CustomerPortoLocal] ⚠️ saveSaved skipped: no active customer');
      return;
    }

    try {
      final existing = _savedBox!.get(portfolio.noId);
      final toSave = (existing != null
              ? _mergeMedia(portfolio, existing)
              : portfolio)
          .copyWith(savedAt: DateTime.now());

      await _savedBox!.put(portfolio.noId, toSave);
      debugPrint('[CustomerPortoLocal] 🔖 saveSaved: ${portfolio.noId}');

      _downloadMediaBackground(toSave, _savedBox!);
    } catch (e) {
      debugPrint('❌ [CustomerPortoLocal] saveSaved: $e');
      rethrow;
    }
  }

  Future<void> removeSaved(String noId) async {
    await _ensureReady();
    try {
      final p = _savedBox!.get(noId);
      if (p == null) return;

      final isAlsoLiked = _likedBox!.containsKey(noId);
      if (!isAlsoLiked) await _cleanupMedia(p);

      await _savedBox!.delete(noId);
      debugPrint('[CustomerPortoLocal] 🗑️  removeSaved: $noId');
    } catch (e) {
      debugPrint('❌ [CustomerPortoLocal] removeSaved: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════
  // READ
  // ═══════════════════════════════════════════════════

  Future<List<PortofolioModel>> getLikedPortfolios() async {
    await _ensureReady();
    try {
      return _likedBox!.values.toList()
        ..sort((a, b) =>
            (b.likedAt ?? b.tglCreated).compareTo(a.likedAt ?? a.tglCreated));
    } catch (e) {
      debugPrint('❌ [CustomerPortoLocal] getLiked: $e');
      return [];
    }
  }

  Future<List<PortofolioModel>> getSavedPortfolios() async {
    await _ensureReady();
    try {
      return _savedBox!.values.toList()
        ..sort((a, b) =>
            (b.savedAt ?? b.tglCreated).compareTo(a.savedAt ?? a.tglCreated));
    } catch (e) {
      debugPrint('❌ [CustomerPortoLocal] getSaved: $e');
      return [];
    }
  }

  /// Semua portofolio yang di-cache (liked + saved, tanpa duplikat).
  Future<List<PortofolioModel>> getCachedPortfolios() async {
    await _ensureReady();
    try {
      final map = <String, PortofolioModel>{};

      for (final p in _likedBox!.values) {
        map[p.noId] = p;
      }
      for (final p in _savedBox!.values) {
        if (!map.containsKey(p.noId) ||
            p.cachedMedia.length > map[p.noId]!.cachedMedia.length) {
          map[p.noId] = p;
        }
      }

      final list = map.values.toList()
        ..sort((a, b) => b.tglCreated.compareTo(a.tglCreated));

      debugPrint('[CustomerPortoLocal] 📦 getCached: ${list.length} total');
      return list;
    } catch (e) {
      debugPrint('❌ [CustomerPortoLocal] getCachedPortfolios: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════
  // FEED HOME — cache agar cold start tidak menunggu network
  // ═══════════════════════════════════════════════════

  /// Simpan sebagian feed Home ke disk.
  Future<void> saveFeed(List<PortofolioModel> portfolios) async {
    await _ensureReady();
    try {
      final slice = portfolios.take(feedCacheLimit).toList();
      await _feedBox!.clear();
      await _feedBox!.putAll({for (final p in slice) p.noId: p});
      debugPrint('[CustomerPortoLocal] 💾 Feed cached: ${slice.length}');
    } catch (e) {
      debugPrint('❌ [CustomerPortoLocal] saveFeed: $e');
    }
  }

  /// Feed Home dari disk. Diurutkan ulang dengan kunci yang sama seperti
  /// permintaan API (Tgl_Created desc) karena Hive tidak menjamin urutan.
  Future<List<PortofolioModel>> getFeed() async {
    await _ensureReady();
    try {
      final list = _feedBox!.values.toList()
        ..sort((a, b) => b.tglCreated.compareTo(a.tglCreated));
      debugPrint('[CustomerPortoLocal] 📦 Feed from disk: ${list.length}');
      return list;
    } catch (e) {
      debugPrint('❌ [CustomerPortoLocal] getFeed: $e');
      return [];
    }
  }

  Future<PortofolioModel?> getPortfolioById(String noId) async {
    await _ensureReady();
    return _likedBox!.get(noId) ?? _savedBox!.get(noId);
  }

  Future<bool> isLiked(String noId) async {
    await _ensureReady();
    return _likedBox!.containsKey(noId);
  }

  Future<bool> isSaved(String noId) async {
    await _ensureReady();
    return _savedBox!.containsKey(noId);
  }

  /// Sync (gunakan setelah initialize selesai)
  bool isLikedSync(String noId) => _likedBox?.containsKey(noId) ?? false;
  bool isSavedSync(String noId) => _savedBox?.containsKey(noId) ?? false;

  /// Status like + save sekaligus dalam satu call
  Future<({bool liked, bool saved})> getStatus(String noId) async {
    await _ensureReady();
    return (
      liked: _likedBox!.containsKey(noId),
      saved: _savedBox!.containsKey(noId),
    );
  }

  // ═══════════════════════════════════════════════════
  // BULK SYNC (dari API)
  // ═══════════════════════════════════════════════════

  /// Sync liked list dari API.
  /// Porto yang tidak ada di API → dihapus dari lokal.
  /// likedAt di-assign berdasarkan posisi di API (index 0 = paling baru liked).
  Future<void> syncLiked(List<PortofolioModel> apiList) async {
    await _ensureReady();
    debugPrint('[CustomerPortoLocal] 🔄 syncLiked (${apiList.length})');

    final localIds = _likedBox!.keys.cast<String>().toSet();
    final apiIds = apiList.map((p) => p.noId).toSet();

    // Hapus yang sudah tidak di-like
    for (final id in localIds.difference(apiIds)) {
      await removeLiked(id);
    }

    // Simpan dengan likedAt berdasarkan posisi API
    // API urut dari terlama → terbaru, jadi index terakhir = paling baru liked
    final baseTime = DateTime.now();
    final total = apiList.length;
    for (int i = 0; i < total; i++) {
      final existing = _likedBox!.get(apiList[i].noId);
      final porto = (existing != null
              ? _mergeMedia(apiList[i], existing)
              : apiList[i])
          .copyWith(likedAt: baseTime.subtract(Duration(seconds: total - 1 - i)));
      await _likedBox!.put(porto.noId, porto);
    }

    debugPrint('[CustomerPortoLocal] ✅ syncLiked done');
  }

  /// Sync saved list dari API.
  /// savedAt di-assign berdasarkan posisi di API (index 0 = paling baru saved).
  Future<void> syncSaved(List<PortofolioModel> apiList) async {
    await _ensureReady();
    debugPrint('[CustomerPortoLocal] 🔄 syncSaved (${apiList.length})');

    final localIds = _savedBox!.keys.cast<String>().toSet();
    final apiIds = apiList.map((p) => p.noId).toSet();

    for (final id in localIds.difference(apiIds)) {
      await removeSaved(id);
    }

    // Simpan dengan savedAt berdasarkan posisi API
    // API urut dari terlama → terbaru, jadi index terakhir = paling baru saved
    final baseTime = DateTime.now();
    final total = apiList.length;
    for (int i = 0; i < total; i++) {
      final existing = _savedBox!.get(apiList[i].noId);
      final porto = (existing != null
              ? _mergeMedia(apiList[i], existing)
              : apiList[i])
          .copyWith(savedAt: baseTime.subtract(Duration(seconds: total - 1 - i)));
      await _savedBox!.put(porto.noId, porto);
    }

    debugPrint('[CustomerPortoLocal] ✅ syncSaved done');
  }

  // ═══════════════════════════════════════════════════
  // DOWNLOAD MEDIA
  // ═══════════════════════════════════════════════════

  Future<void> downloadAllMedia() async {
    await _ensureReady();
    final all = await getCachedPortfolios();

    debugPrint('[CustomerPortoLocal] 📥 downloadAllMedia: ${all.length} porto');

    int totalDownloaded = 0;
    int totalSkipped = 0;

    for (final porto in all) {
      final isLikedItem = _likedBox!.containsKey(porto.noId);
      final isSavedItem = _savedBox!.containsKey(porto.noId);

      final result = await _doDownloadMedia(porto);
      totalDownloaded += result.downloaded;
      totalSkipped += result.skipped;

      if (isLikedItem) await _likedBox!.put(porto.noId, result.updated);
      if (isSavedItem) await _savedBox!.put(porto.noId, result.updated);
    }

    debugPrint('[CustomerPortoLocal] ✅ Done: $totalDownloaded dl / $totalSkipped skip');
  }

  Future<void> downloadMediaForPortfolio(String noId) async {
    await _ensureReady();

    final porto = await getPortfolioById(noId);
    if (porto == null) return;

    final result = await _doDownloadMedia(porto);

    if (_likedBox!.containsKey(noId)) await _likedBox!.put(noId, result.updated);
    if (_savedBox!.containsKey(noId)) await _savedBox!.put(noId, result.updated);
  }

  // ═══════════════════════════════════════════════════
  // CLEAR
  // ═══════════════════════════════════════════════════

  /// Clear semua data liked + saved + media cache.
  /// Dipanggil saat logout atau hapus akun.
  Future<void> clearAll() async {
    await _ensureReady();

    debugPrint('[CustomerPortoLocal] 🗑️ Clearing all...');

    // Cleanup media — hindari double-delete untuk porto yang ada di dua box
    final cleaned = <String>{};
    for (final p in [..._likedBox!.values, ..._savedBox!.values]) {
      if (cleaned.add(p.noId)) await _cleanupMedia(p);
    }

    await _likedBox!.clear();
    await _savedBox!.clear();
    await _feedBox!.clear();

    debugPrint('[CustomerPortoLocal] ✅ clearAll done');
  }

  // ═══════════════════════════════════════════════════
  // MEDIA HELPERS (private)
  // ═══════════════════════════════════════════════════

  void _downloadMediaBackground(
    PortofolioModel portfolio,
    Box<PortofolioModel> box,
  ) {
    _doDownloadMedia(portfolio).then((result) {
      box.put(portfolio.noId, result.updated);
    }).catchError((e) {
      debugPrint('[CustomerPortoLocal] ⚠️ bg download error: $e');
    });
  }

  Future<_DownloadResult> _doDownloadMedia(PortofolioModel portfolio) async {
    if (portfolio.mediaUrls.isEmpty) {
      return _DownloadResult(updated: portfolio, downloaded: 0, skipped: 0);
    }

    final updated = <MediaUrlModel>[];
    int downloaded = 0;
    int skipped = 0;

    for (int i = 0; i < portfolio.mediaUrls.length; i++) {
      final media = portfolio.mediaUrls[i];
      try {
        if (media.isCached && media.localPath != null) {
          updated.add(media);
          skipped++;
          continue;
        }

        final cached = await CacheManager.instance.cacheMedia(
          media,
          priority: CachePriority.high,
        );
        updated.add(cached);
        if (cached.isCached) downloaded++;
      } catch (e) {
        debugPrint('[CustomerPortoLocal]   ⚠️ media[$i] error: $e');
        updated.add(media);
      }

      if (i < portfolio.mediaUrls.length - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return _DownloadResult(
      updated: portfolio.copyWith(
        mediaUrls: updated,
        lastUpdated: DateTime.now(),
      ),
      downloaded: downloaded,
      skipped: skipped,
    );
  }

  PortofolioModel _mergeMedia(
      PortofolioModel newPorto, PortofolioModel existing) {
    if (existing.mediaUrls.isEmpty) return newPorto;

    final merged = newPorto.mediaUrls.map((newMedia) {
      try {
        final ex = existing.mediaUrls.firstWhere(
          (e) =>
              e.idMedia == newMedia.idMedia ||
              e.noIdMedia == newMedia.noIdMedia,
        );
        return (ex.isCached && ex.localPath != null) ? ex : newMedia;
      } catch (_) {
        return newMedia;
      }
    }).toList();

    return newPorto.copyWith(mediaUrls: merged);
  }

  Future<void> _cleanupMedia(PortofolioModel portfolio) async {
    for (final media in portfolio.mediaUrls) {
      if (media.isCached && media.localPath != null) {
        try {
          await CacheManager.instance.evict(
            media.idMedia ?? media.noIdMedia ?? '',
          );
        } catch (_) {}
      }
    }
  }

  // ═══════════════════════════════════════════════════
  // STATS
  // ═══════════════════════════════════════════════════

  Future<Map<String, dynamic>> getStats() async {
    await _ensureReady();

    final liked = _likedBox!.values.toList();
    final saved = _savedBox!.values.toList();

    int lM = 0, lC = 0, sM = 0, sC = 0;
    for (final p in liked) {
      lM += p.mediaUrls.length;
      lC += p.cachedMedia.length;
    }
    for (final p in saved) {
      sM += p.mediaUrls.length;
      sC += p.cachedMedia.length;
    }

    return {
      'liked_count': liked.length,
      'liked_media': lM,
      'liked_cached_media': lC,
      'saved_count': saved.length,
      'saved_media': sM,
      'saved_cached_media': sC,
    };
  }

  Future<void> printStats() async {
    final s = await getStats();
    debugPrint('📊 PORTO CACHE:');
    debugPrint('   Liked: ${s['liked_count']} porto | ${s['liked_cached_media']}/${s['liked_media']} media');
    debugPrint('   Saved: ${s['saved_count']} porto | ${s['saved_cached_media']}/${s['saved_media']} media');
  }
}

// ─────────────────────────────────────────────────────────────

class _DownloadResult {
  final PortofolioModel updated;
  final int downloaded;
  final int skipped;

  const _DownloadResult({
    required this.updated,
    required this.downloaded,
    required this.skipped,
  });
}