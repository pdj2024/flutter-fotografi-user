import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/cache_manager.dart';
import 'package:mpjnew/src/data/hive_entity/media_url_model.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';

class PortofolioLocalService {
  static const String _likedBoxName = 'customer_liked_porto_box';
  static const String _savedBoxName = 'customer_saved_porto_box';

  Box<PortofolioModel>? _likedBox;
  Box<PortofolioModel>? _savedBox;

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

      debugPrint('✅ [CustomerPortoLocal] Initialized');
      debugPrint('   Liked: ${_likedBox!.length} | Saved: ${_savedBox!.length}');
    } catch (e) {
      debugPrint('❌ [CustomerPortoLocal] Init error: $e');
      rethrow;
    }
  }

  Future<void> _ensureReady() async {
    // Init Hive box lokal + CacheManager secara paralel.
    // CacheManager.initialize() aman dipanggil berkali-kali (lazy + idempotent).
    final needsHiveInit = _likedBox == null || !_likedBox!.isOpen ||
        _savedBox == null || !_savedBox!.isOpen;

    await Future.wait([
      if (needsHiveInit) initialize(),
      CacheManager.instance.initialize(),
    ]);
  }

  // ═══════════════════════════════════════════════════
  // LIKE — WRITE
  // ═══════════════════════════════════════════════════

  /// Simpan portfolio ke liked box.
  /// Otomatis download semua gambar ke lokal (background).
  Future<void> saveLiked(PortofolioModel portfolio) async {
    await _ensureReady();
    try {
      // Merge dengan cache existing agar tidak re-download gambar yang sudah ada
      final existing = _likedBox!.get(portfolio.noId);
      final toSave = existing != null
          ? _mergeMedia(portfolio, existing)
          : portfolio;

      await _likedBox!.put(portfolio.noId, toSave);
      debugPrint('[CustomerPortoLocal] ❤️  saveLiked: ${portfolio.noId}');

      // Download gambar background — tidak block UI
      _downloadMediaBackground(toSave, _likedBox!);
    } catch (e) {
      debugPrint('❌ [CustomerPortoLocal] saveLiked: $e');
      rethrow;
    }
  }

  /// Hapus dari liked box.
  /// Media hanya di-cleanup jika porto tidak ada di saved box juga.
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
  // SAVE — WRITE
  // ═══════════════════════════════════════════════════

  Future<void> saveSaved(PortofolioModel portfolio) async {
    await _ensureReady();
    try {
      final existing = _savedBox!.get(portfolio.noId);
      final toSave = existing != null
          ? _mergeMedia(portfolio, existing)
          : portfolio;

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

      // Jangan hapus media jika masih di-like
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

  /// Semua portfolio yang di-like oleh user, urut terbaru.
  Future<List<PortofolioModel>> getLikedPortfolios() async {
    await _ensureReady();
    try {
      return _likedBox!.values.toList()
        ..sort((a, b) => b.tglCreated.compareTo(a.tglCreated));
    } catch (e) {
      debugPrint('❌ [CustomerPortoLocal] getLiked: $e');
      return [];
    }
  }

  /// Semua portfolio yang di-save oleh user, urut terbaru.
  Future<List<PortofolioModel>> getSavedPortfolios() async {
    await _ensureReady();
    try {
      return _savedBox!.values.toList()
        ..sort((a, b) => b.tglCreated.compareTo(a.tglCreated));
    } catch (e) {
      debugPrint('❌ [CustomerPortoLocal] getSaved: $e');
      return [];
    }
  }

  /// Semua portfolio yang di-cache (liked + saved gabungan, tanpa duplikat).
  /// Berguna untuk keperluan preload atau stats.
  Future<List<PortofolioModel>> getCachedPortfolios() async {
    await _ensureReady();
    try {
      // Gunakan Map agar tidak ada duplikat (porto bisa ada di dua box)
      final map = <String, PortofolioModel>{};

      for (final p in _likedBox!.values) {
        map[p.noId] = p;
      }
      for (final p in _savedBox!.values) {
        // Jika sudah ada dari liked, ambil yang punya lebih banyak media cached
        if (!map.containsKey(p.noId) ||
            p.cachedMedia.length > map[p.noId]!.cachedMedia.length) {
          map[p.noId] = p;
        }
      }

      final list = map.values.toList()
        ..sort((a, b) => b.tglCreated.compareTo(a.tglCreated));

      debugPrint('[CustomerPortoLocal] 📦 getCachedPortfolios: ${list.length} total');
      return list;
    } catch (e) {
      debugPrint('❌ [CustomerPortoLocal] getCachedPortfolios: $e');
      return [];
    }
  }

  /// Cari portfolio by ID — cek liked dulu, lalu saved.
  Future<PortofolioModel?> getPortfolioById(String noId) async {
    await _ensureReady();
    return _likedBox!.get(noId) ?? _savedBox!.get(noId);
  }

  /// Cek status like/save secara async.
  Future<bool> isLiked(String noId) async {
    await _ensureReady();
    return _likedBox!.containsKey(noId);
  }

  Future<bool> isSaved(String noId) async {
    await _ensureReady();
    return _savedBox!.containsKey(noId);
  }

  /// Cek status like/save secara sync (gunakan setelah initialize selesai).
  bool isLikedSync(String noId) => _likedBox?.containsKey(noId) ?? false;
  bool isSavedSync(String noId) => _savedBox?.containsKey(noId) ?? false;

  // ═══════════════════════════════════════════════════
  // DOWNLOAD MEDIA
  // ═══════════════════════════════════════════════════

  /// Download semua gambar dari semua porto yang di-cache (liked + saved).
  /// Panggil ini saat app start atau setelah sync dari API.
  /// Gambar yang sudah ada di lokal di-skip otomatis.
  Future<void> downloadAllMedia() async {
    await _ensureReady();
    final all = await getCachedPortfolios();

    debugPrint('[CustomerPortoLocal] 📥 downloadAllMedia: ${all.length} portfolios');

    int totalDownloaded = 0;
    int totalSkipped = 0;

    for (final porto in all) {
      final isLikedItem = _likedBox!.containsKey(porto.noId);
      final isSavedItem = _savedBox!.containsKey(porto.noId);

      final result = await _doDownloadMedia(porto);
      totalDownloaded += result.downloaded;
      totalSkipped += result.skipped;

      // Update box yang relevan
      if (isLikedItem) await _likedBox!.put(porto.noId, result.updated);
      if (isSavedItem) await _savedBox!.put(porto.noId, result.updated);
    }

    debugPrint('[CustomerPortoLocal] ✅ downloadAllMedia done:');
    debugPrint('   Downloaded: $totalDownloaded | Skipped: $totalSkipped');
  }

  /// Download ulang media untuk satu portfolio spesifik.
  Future<void> downloadMediaForPortfolio(String noId) async {
    await _ensureReady();

    final porto = await getPortfolioById(noId);
    if (porto == null) {
      debugPrint('[CustomerPortoLocal] ⚠️ downloadMedia: porto $noId not found');
      return;
    }

    debugPrint('[CustomerPortoLocal] 📥 downloadMedia: $noId');
    final result = await _doDownloadMedia(porto);

    if (_likedBox!.containsKey(noId)) await _likedBox!.put(noId, result.updated);
    if (_savedBox!.containsKey(noId)) await _savedBox!.put(noId, result.updated);
  }

  // ═══════════════════════════════════════════════════
  // BULK SYNC (dari API)
  // ═══════════════════════════════════════════════════

  /// Sync liked list dari API.
  /// Porto yang tidak ada di API → dihapus dari lokal.
  /// Porto baru → ditambah + download media.
  Future<void> syncLiked(List<PortofolioModel> apiList) async {
    await _ensureReady();
    debugPrint('[CustomerPortoLocal] 🔄 syncLiked (${apiList.length})');

    final localIds = _likedBox!.keys.cast<String>().toSet();
    final apiIds = apiList.map((p) => p.noId).toSet();

    // Hapus yang sudah tidak di-like
    for (final id in localIds.difference(apiIds)) {
      await removeLiked(id);
    }

    // Tambah / update
    for (final porto in apiList) {
      await saveLiked(porto);
    }

    debugPrint('[CustomerPortoLocal] ✅ syncLiked done');
  }

  /// Sync saved list dari API.
  Future<void> syncSaved(List<PortofolioModel> apiList) async {
    await _ensureReady();
    debugPrint('[CustomerPortoLocal] 🔄 syncSaved (${apiList.length})');

    final localIds = _savedBox!.keys.cast<String>().toSet();
    final apiIds = apiList.map((p) => p.noId).toSet();

    for (final id in localIds.difference(apiIds)) {
      await removeSaved(id);
    }

    for (final porto in apiList) {
      await saveSaved(porto);
    }

    debugPrint('[CustomerPortoLocal] ✅ syncSaved done');
  }

  // ═══════════════════════════════════════════════════
  // CLEAR (logout)
  // ═══════════════════════════════════════════════════

  Future<void> clearAll() async {
    await _ensureReady();

    // Cleanup media — hindari double-delete untuk porto yang ada di dua box
    final cleaned = <String>{};
    for (final p in [..._likedBox!.values, ..._savedBox!.values]) {
      if (cleaned.add(p.noId)) await _cleanupMedia(p);
    }

    await _likedBox!.clear();
    await _savedBox!.clear();
    debugPrint('✅ [CustomerPortoLocal] clearAll done');
  }

  // ═══════════════════════════════════════════════════
  // MEDIA HELPERS (private)
  // ═══════════════════════════════════════════════════

  /// Fire-and-forget: download media tanpa block caller.
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

  /// Download semua media untuk sebuah portfolio.
  /// Return [_DownloadResult] berisi porto terupdate + stats.
  Future<_DownloadResult> _doDownloadMedia(PortofolioModel portfolio) async {
    if (portfolio.mediaUrls.isEmpty) {
      return _DownloadResult(updated: portfolio, downloaded: 0, skipped: 0);
    }

    debugPrint('[CustomerPortoLocal] 📥 ${portfolio.noId} — ${portfolio.mediaUrls.length} media');

    final updated = <MediaUrlModel>[];
    int downloaded = 0;
    int skipped = 0;

    for (int i = 0; i < portfolio.mediaUrls.length; i++) {
      final media = portfolio.mediaUrls[i];
      try {
        // Skip jika sudah ada di lokal
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
        updated.add(media); // Tetap pakai original jika gagal
      }

      // Delay kecil agar tidak overload network
      if (i < portfolio.mediaUrls.length - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    final updatedPorto = portfolio.copyWith(
      mediaUrls: updated,
      lastUpdated: DateTime.now(),
    );

    debugPrint('[CustomerPortoLocal]   ✅ downloaded: $downloaded | skipped: $skipped');
    return _DownloadResult(
      updated: updatedPorto,
      downloaded: downloaded,
      skipped: skipped,
    );
  }

  /// Preserve local path dari cache lama agar tidak re-download.
  PortofolioModel _mergeMedia(PortofolioModel newPorto, PortofolioModel existing) {
    if (existing.mediaUrls.isEmpty) return newPorto;

    final merged = newPorto.mediaUrls.map((newMedia) {
      try {
        final ex = existing.mediaUrls.firstWhere(
          (e) => e.idMedia == newMedia.idMedia || e.noIdMedia == newMedia.noIdMedia,
        );
        // Pakai cache lama jika sudah di-download
        return (ex.isCached && ex.localPath != null) ? ex : newMedia;
      } catch (_) {
        return newMedia;
      }
    }).toList();

    return newPorto.copyWith(mediaUrls: merged);
  }

  /// Hapus file media lokal untuk sebuah portfolio.
  Future<void> _cleanupMedia(PortofolioModel portfolio) async {
    for (final media in portfolio.mediaUrls) {
      if (media.isCached && media.localPath != null) {
        try {
          await CacheManager.instance.getCachedPath(
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
    debugPrint('═══════════════════════════════════════');
    debugPrint('📊 CUSTOMER PORTO CACHE STATS');
    debugPrint('   Liked: ${s['liked_count']} | ${s['liked_cached_media']}/${s['liked_media']} media cached');
    debugPrint('   Saved: ${s['saved_count']} | ${s['saved_cached_media']}/${s['saved_media']} media cached');
    debugPrint('═══════════════════════════════════════');
  }
}

// ═══════════════════════════════════════════════════
// INTERNAL — Download result model
// ═══════════════════════════════════════════════════

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