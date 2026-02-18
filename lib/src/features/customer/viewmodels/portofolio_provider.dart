import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/services/media_preload_service.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';
import 'package:mpjnew/src/data/hive_service.dart/portofolio_local_service.dart';
import 'package:mpjnew/src/data/models/kategori_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/portofolio_service.dart';
import 'package:mpjnew/src/features/customer/viewmodels/paket_provider.dart';
import 'package:provider/provider.dart';

class PortofolioProvider with ChangeNotifier {
  final PortofolioService portofolioService;
  final PortofolioLocalService localService;
  final MediaPreloadService _preloadService = MediaPreloadService();
  bool _disposed = false;

  PortofolioProvider({
    required this.portofolioService,
    PortofolioLocalService? localService,
  }) : localService = localService ?? PortofolioLocalService() {
    _initialize();
  }

  // ═══════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════

  PortofolioModel? _selectedPortofolio;
  List<PortofolioModel> _portofolioList = [];
  List<PortofolioModel> _portofolioSaveList = [];
  List<PortofolioModel> _portofolioLikelist = [];
  List<PortofolioModel> _cachedPortfolios = [];
  List<PaketModel> _paketPortofolio = [];

  bool _isLoadingPorto = true;
  bool _isLoadingLike = false;
  bool _isLoadingSave = false;
  String? _errorPorto;
  bool _isInitialized = false;
  bool _isFromCache = false;

  KategoriModel? _selectedKategori;
  List<PaketModel> _selectedPaket = [];

  // Guard prevent double tap — tidak pakai debounce agar data realtime
  // ketika user berpindah halaman.
  final Set<String> _likeInProgress = {};
  final Set<String> _saveInProgress = {};

  // ═══════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════

  List<PortofolioModel> get portofolioList => _portofolioList;
  List<PortofolioModel> get portofolioSaveList => _portofolioSaveList;
  List<PortofolioModel> get portofolioLikelist => _portofolioLikelist;
  List<PortofolioModel> get cachedPortfolios => _cachedPortfolios;
  PortofolioModel? get selectedPortofolio => _selectedPortofolio;
  List<PaketModel> get paketPortofolio => _paketPortofolio;
  bool get isLoadingPorto => _isLoadingPorto;
  bool get isLoadingLike => _isLoadingLike;
  bool get isLoadingSave => _isLoadingSave;
  String? get errorPorto => _errorPorto;
  bool get isInitialized => _isInitialized;
  bool get isFromCache => _isFromCache;
  KategoriModel? get selectedKategori => _selectedKategori;
  List<PaketModel> get selectedPaket => _selectedPaket;
  MediaPreloadService get preloadService => _preloadService;

  /// true jika API like sedang berjalan (prevent double tap)
  bool isLikeInProgress(String noId) => _likeInProgress.contains(noId);

  /// true jika API save sedang berjalan (prevent double tap)
  bool isSaveInProgress(String noId) => _saveInProgress.contains(noId);

  bool isPortfolioCached(String noId) =>
      _cachedPortfolios.any((p) => p.noId == noId);

  /// Cek apakah porto di-like, berdasarkan list lokal
  bool isLiked(String noId) => _portofolioLikelist.any((p) => p.noId == noId);

  /// Cek apakah porto di-save, berdasarkan list lokal
  bool isSaved(String noId) => _portofolioSaveList.any((p) => p.noId == noId);

  void setKategori(KategoriModel? value) {
    _selectedKategori = value;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  // REFRESH ALIASES (untuk bottom navigation tab refresh)
  // ═══════════════════════════════════════════════════

  /// Alias untuk loadLikedPortofolio — dipanggil saat tab profile di-tap
  /// dari bottom navigation agar nama method konsisten dengan pattern refresh.
  Future<void> refreshLikePortofolio(BuildContext context) =>
      loadLikedPortofolio(context: context, syncFromApi: true);

  /// Alias untuk loadSavedPortofolio — dipanggil saat tab profile di-tap.
  Future<void> refreshSavePortofolio(BuildContext context) =>
      loadSavedPortofolio(context: context, syncFromApi: true);

  // ═══════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════

  @override
  void dispose() {
    _disposed = true;
    _preloadService.cancelAll();
    super.dispose();
  }

  void safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _initialize() async {
    try {
      await localService.initialize();
      _isInitialized = true;
      debugPrint('✅ [PortofolioProvider] Initialized');
    } catch (e) {
      debugPrint('❌ [PortofolioProvider] Init error: $e');
    }
  }

  // ═══════════════════════════════════════════════════
  // SELECTED PORTFOLIO
  // ═══════════════════════════════════════════════════

  void setSelectedPortofolio(PortofolioModel? porto) {
    _selectedPortofolio = porto;
    if (porto != null) {
      _preloadService.preloadPortfolio(porto, highPriority: true);
    }
    notifyListeners();
  }

  Future<PortofolioModel?> getPortfolioById(String noId) async {
    try {
      final cached = await localService.getPortfolioById(noId);
      if (cached != null) return cached;
      try {
        return _portofolioList.firstWhere((p) => p.noId == noId);
      } catch (_) {}
      final list = await portofolioService.getAll(noId: noId);
      return list.isNotEmpty ? list.first : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> setPaketPortofolio({
    required List<String> idPaket,
    required PaketProvider paketProvider,
  }) async {
    _paketPortofolio = paketProvider.paketList
        .where((p) => idPaket.contains(p.no_id) && p.status == 'aktif')
        .toList();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  // LOAD ALL (home feed)
  // ═══════════════════════════════════════════════════

  Future<void> loadPortofolio(
    BuildContext context, {
    String status = 'aktif',
    String untukKeperluan = 'home',
    bool preloadImages = true,
    bool forceRefresh = false,
  }) async {
    _isLoadingPorto = true;
    _errorPorto = null;
    safeNotify();

    try {
      final userProvider = context.read<UserProvider>();
      final userId =
          userProvider.role == 'customer' ? userProvider.userId : null;

      // Load liked/saved dari Hive terlebih dahulu
      await _syncLikedAndSavedFromLocal();

      if (!forceRefresh && _isInitialized) {
        try {
          final cached = await localService.getCachedPortfolios();
          if (cached.isNotEmpty) {
            _cachedPortfolios = cached;
            _portofolioList = cached;
            _isFromCache = true;
            safeNotify();
          }
        } catch (_) {}
      }

      final result = await portofolioService.getAll(
        id_customer: userId,
        status: status,
        untuk_keperluan: untukKeperluan,
        orderBy: 'Tgl_Created',
        orderDir: 'desc',
      );

      _portofolioList = result;
      _isFromCache = false;

      if (result.length >= 10) {
        _saveToCacheInBackground(result.take(10).toList());
      }
      if (preloadImages && result.isNotEmpty) {
        _preloadService.preloadPortfolios(result, priorityCount: 10);
      }
    } catch (e) {
      debugPrint('[PortofolioProvider] ❌ loadPortofolio: $e');
      _errorPorto = 'Error memuat portofolio';
    } finally {
      _isLoadingPorto = false;
      safeNotify();
    }
  }

  // ═══════════════════════════════════════════════════
  // LIKE — Langsung API (tanpa debounce), optimistic UI + rollback
  // ═══════════════════════════════════════════════════

  /// Toggle like pada portfolio.
  ///
  /// Flow:
  /// 1. Guard — abaikan jika API masih berjalan (prevent double tap).
  /// 2. Optimistic UI — update list lokal langsung agar UI responsif.
  /// 3. API call — langsung, tanpa debounce, data realtime.
  /// 4. Local Hive — simpan/hapus + download media background.
  /// 5. Rollback — kembalikan ke state sebelumnya jika API gagal.
  Future<void> toggleLike({
    required BuildContext context,
    required PortofolioModel porto,
  }) async {
    final noId = porto.noId;

    // ── 1. Guard ──────────────────────────────────────
    if (_likeInProgress.contains(noId)) return;

    final wasLiked = isLiked(noId);
    final nowLiked = !wasLiked;

    // ── 2. Optimistic UI ──────────────────────────────
    _likeInProgress.add(noId);
    _updateLikeList(porto, nowLiked);
    safeNotify();

    try {
      final userId = context.read<UserProvider>().userId;
      if (userId == null) throw Exception('User belum login');

      debugPrint(
          '[PortofolioProvider] ${nowLiked ? '❤️' : '💔'} toggleLike: $noId');

      // ── 3. API call ───────────────────────────────
      if (nowLiked) {
        await portofolioService.likePorto(userId, noId);
        // ── 4a. Simpan ke Hive + download media background ──
        await localService.saveLiked(porto);
      } else {
        await portofolioService.unlikePorto(userId, noId);
        // ── 4b. Hapus dari Hive ──────────────────────
        await localService.removeLiked(noId);
      }

      // Sync ulang dari Hive agar list akurat
      await _syncLikedAndSavedFromLocal();
    } catch (e) {
      debugPrint('[PortofolioProvider] ❌ toggleLike error: $e');
      // ── 5. Rollback ───────────────────────────────
      _updateLikeList(porto, wasLiked);
    } finally {
      _likeInProgress.remove(noId);
      safeNotify();
    }
  }

  void _updateLikeList(PortofolioModel porto, bool liked) {
    if (liked) {
      if (!_portofolioLikelist.any((p) => p.noId == porto.noId)) {
        _portofolioLikelist = [porto, ..._portofolioLikelist];
      }
    } else {
      _portofolioLikelist =
          _portofolioLikelist.where((p) => p.noId != porto.noId).toList();
    }
  }

  // ═══════════════════════════════════════════════════
  // SAVE — Langsung API (tanpa debounce), optimistic UI + rollback
  // ═══════════════════════════════════════════════════

  Future<void> toggleSave({
    required BuildContext context,
    required PortofolioModel porto,
  }) async {
    final noId = porto.noId;

    // ── 1. Guard ──────────────────────────────────────
    if (_saveInProgress.contains(noId)) return;

    final wasSaved = isSaved(noId);
    final nowSaved = !wasSaved;

    // ── 2. Optimistic UI ──────────────────────────────
    _saveInProgress.add(noId);
    _updateSaveList(porto, nowSaved);
    safeNotify();

    try {
      final userId = context.read<UserProvider>().userId;
      if (userId == null) throw Exception('User belum login');

      debugPrint(
          '[PortofolioProvider] ${nowSaved ? '🔖' : '🗑️'} toggleSave: $noId');

      // ── 3. API call ───────────────────────────────
      if (nowSaved) {
        await portofolioService.savePorto(userId, noId);
        // ── 4a. Simpan ke Hive + download media background ──
        await localService.saveSaved(porto);
      } else {
        await portofolioService.unsavePorto(userId, noId);
        // ── 4b. Hapus dari Hive ──────────────────────
        await localService.removeSaved(noId);
      }

      await _syncLikedAndSavedFromLocal();
    } catch (e) {
      debugPrint('[PortofolioProvider] ❌ toggleSave error: $e');
      // ── 5. Rollback ───────────────────────────────
      _updateSaveList(porto, wasSaved);
    } finally {
      _saveInProgress.remove(noId);
      safeNotify();
    }
  }

  void _updateSaveList(PortofolioModel porto, bool saved) {
    if (saved) {
      if (!_portofolioSaveList.any((p) => p.noId == porto.noId)) {
        _portofolioSaveList = [porto, ..._portofolioSaveList];
      }
    } else {
      _portofolioSaveList =
          _portofolioSaveList.where((p) => p.noId != porto.noId).toList();
    }
  }

  // ═══════════════════════════════════════════════════
  // LOAD LIKED LIST (untuk halaman Liked)
  // ═══════════════════════════════════════════════════

  Future<void> loadLikedPortofolio({
    BuildContext? context,
    bool syncFromApi = true,
  }) async {
    _isLoadingLike = true;
    safeNotify();

    try {
      // Load dari local dulu (cepat, offline-first)
      _portofolioLikelist = await localService.getLikedPortfolios();
      safeNotify();

      // Sync dari API untuk pastikan konsistensi
      if (syncFromApi && context != null) {
        try {
          final userId = context.read<UserProvider>().userId;
          if (userId != null) {
            final apiLiked =
                await portofolioService.getLikesPorto(noId: userId);
            await localService.syncLiked(apiLiked);
            _portofolioLikelist = await localService.getLikedPortfolios();
          }
        } catch (e) {
          debugPrint('[PortofolioProvider] ⚠️ syncLiked API failed: $e');
          // Tetap pakai data lokal
        }
      }
    } catch (e) {
      debugPrint('[PortofolioProvider] ❌ loadLikedPortofolio: $e');
    } finally {
      _isLoadingLike = false;
      safeNotify();
    }
  }

  // ═══════════════════════════════════════════════════
  // LOAD SAVED LIST (untuk halaman Saved)
  // ═══════════════════════════════════════════════════

  Future<void> loadSavedPortofolio({
    BuildContext? context,
    bool syncFromApi = true,
  }) async {
    _isLoadingSave = true;
    safeNotify();

    try {
      _portofolioSaveList = await localService.getSavedPortfolios();
      safeNotify();

      if (syncFromApi && context != null) {
        try {
          final userId = context.read<UserProvider>().userId;
          if (userId != null) {
            final apiSaved =
                await portofolioService.getSavesPorto(noId: userId);
            await localService.syncSaved(apiSaved);
            _portofolioSaveList = await localService.getSavedPortfolios();
          }
        } catch (e) {
          debugPrint('[PortofolioProvider] ⚠️ syncSaved API failed: $e');
        }
      }
    } catch (e) {
      debugPrint('[PortofolioProvider] ❌ loadSavedPortofolio: $e');
    } finally {
      _isLoadingSave = false;
      safeNotify();
    }
  }

  // ═══════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════

  Future<void> _syncLikedAndSavedFromLocal() async {
    try {
      final liked = await localService.getLikedPortfolios();
      final saved = await localService.getSavedPortfolios();
      _portofolioLikelist = liked;
      _portofolioSaveList = saved;
      debugPrint(
          '[PortofolioProvider] 🔄 syncLocal: liked=${liked.length} saved=${saved.length}');
    } catch (e) {
      debugPrint('[PortofolioProvider] ❌ syncLocal error: $e');
    }
  }

  Future<void> _saveToCacheInBackground(
      List<PortofolioModel> portfolios) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _cachedPortfolios = await localService.getCachedPortfolios();
      safeNotify();
    } catch (_) {}
  }

  Future<void> refreshSinglePortofolio(
    BuildContext context, {
    required PaketProvider paketProvider,
  }) async {
    _isLoadingPorto = true;
    _errorPorto = null;
    notifyListeners();
    try {
      final oldId = selectedPortofolio?.noId;
      await loadPortofolio(context);
      final fresh = portofolioList.firstWhere((p) => p.noId == oldId);
      setSelectedPortofolio(fresh);
      await setPaketPortofolio(
          idPaket: fresh.idPaket.toList(), paketProvider: paketProvider);
    } catch (e) {
      _errorPorto = 'Gagal refresh portofolio';
    } finally {
      _isLoadingPorto = false;
      notifyListeners();
    }
  }

  Future<void> refresh(BuildContext context) async =>
      loadPortofolio(context, forceRefresh: true);

  Future<void> clearCache() async {
    try {
      await localService.clearAll();
      _cachedPortfolios = [];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> clearCustomerData() async {
    try {
      _likeInProgress.clear();
      _saveInProgress.clear();
      await localService.clearAll();
      _portofolioLikelist = [];
      _portofolioSaveList = [];
      notifyListeners();
    } catch (_) {}
  }

  void setSelectedPaket(List<PaketModel> p) {
    _selectedPaket = p;
    notifyListeners();
  }

  Future<void> preloadPortfolio(PortofolioModel p) =>
      _preloadService.preloadPortfolio(p, highPriority: true);
  Map<String, dynamic> getPreloadStats() => _preloadService.getStats();
  Future<void> clearImageCache() => _preloadService.clearCache();
  void cancelPreloads() => _preloadService.cancelAll();
  void pausePreloads() => _preloadService.pause();
  void resumePreloads() => _preloadService.resume();
  Future<Map<String, dynamic>> getCacheStats() => localService.getStats();
  Future<void> printCacheStats() => localService.printStats();
}
