import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/services/media_preload_service.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';
import 'package:mpjnew/src/data/hive_service.dart/portofolio_local_service.dart';
import 'package:mpjnew/src/data/models/kategori_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/auth/view/user_login.dart';
import 'package:mpjnew/src/features/customer/services/portofolio_service.dart';
import 'package:mpjnew/src/features/customer/view/single_post_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/paket_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:provider/provider.dart';

class PortofolioProvider with ChangeNotifier {
  final PortofolioService portofolioService;

  // ✅ Pakai CustomerPortofolioLocalService (bukan PortofolioLocalService lama)
  // CustomerPortofolioLocalService sudah handle guard hasActiveCustomer
  // sehingga aman dipanggil saat guest mode (saveLiked/saveSaved di-skip)
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

  bool isLikeInProgress(String noId) => _likeInProgress.contains(noId);
  bool isSaveInProgress(String noId) => _saveInProgress.contains(noId);
  bool isPortfolioCached(String noId) =>
      _cachedPortfolios.any((p) => p.noId == noId);
  bool isLiked(String noId) => _portofolioLikelist.any((p) => p.noId == noId);
  bool isSaved(String noId) => _portofolioSaveList.any((p) => p.noId == noId);

  void setKategori(KategoriModel? value) {
    _selectedKategori = value;
    notifyListeners();
  }

  Future<void> refreshLikePortofolio(BuildContext context) =>
      loadLikedPortofolio(context: context, syncFromApi: true);

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
    } catch (e) {
      debugPrint('❌ [PortofolioProvider] Init error: $e');
    }
  }

  // ═══════════════════════════════════════════════════
  // SELECTED PORTFOLIO
  // ═══════════════════════════════════════════════════

  void setSelectedPortofolio(PortofolioModel? porto) {
    _selectedPortofolio = porto;
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

      // ✅ Sync dari local hanya jika customer sudah login
      // Guest mode: _portofolioLikelist & _portofolioSaveList tetap kosong
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

  Future<void> silentRefreshSelected({String? userId}) async {
    final current = _selectedPortofolio;
    if (current == null) return;

    try {
      final result = await portofolioService.getAll(
        noId: current.noId,
        id_customer: userId,
        status: 'aktif',
        untuk_keperluan: 'home',
      );

      if (result.isNotEmpty) {
        final fresh = result.first;

        // ✅ Hanya update field yang berubah (likes, saves),
        // mediaUrls TIDAK diganti → ImagePost tidak rebuild ulang
        _selectedPortofolio = current.copyWith(
          likes: fresh.likes,
          saves: fresh.saves, // sesuaikan nama field di PortofolioModel
        );

        // Update portofolioList juga hanya field yang berubah
        final idx = _portofolioList.indexWhere((p) => p.noId == current.noId);
        if (idx != -1) {
          final updated = _portofolioList[idx].copyWith(
            likes: fresh.likes,
            saves: fresh.saves,
          );
          _portofolioList = List.of(_portofolioList)..[idx] = updated;
        }

        safeNotify();
      }
    } catch (e) {
      debugPrint('[PortofolioProvider] ⚠️ silentRefreshSelected error: $e');
    }
  }

  // ═══════════════════════════════════════════════════
  // LIKE — optimistic UI + rollback
  // ═══════════════════════════════════════════════════

  Future<void> toggleLike({
    required BuildContext context,
    required PortofolioModel porto,
    bool navigateToPost = true, // ✅ tambah parameter ini
  }) async {
    final userId = context.read<UserProvider>().userId;
    if (userId == null) {
      return context
          .read<NavigationProvider>()
          .navigateToPage(context, UserLogin(), targetTabIndex: 0);
    }
    final noId = porto.noId;
    if (_likeInProgress.contains(noId)) return;

    final wasLiked = isLiked(noId);
    final nowLiked = !wasLiked;

    _likeInProgress.add(noId);
    _updateLikeList(porto, nowLiked);
    safeNotify();

    try {
      if (nowLiked) {
        await portofolioService.likePorto(userId, noId);
        await localService.saveLiked(porto);

        // ✅ Hanya navigate jika diminta (dari card, bukan dari single post)
        if (navigateToPost && context.mounted) {
          setSelectedPortofolio(porto);
          context.read<NavigationProvider>().navigateToPage(
                context,
                const SinglePostPage(),
                hrsLogin: true,
                targetTabIndex: 0,
                targetPage: 'SinglePostPage',
                noIdPortofolio: porto.noId,
              );
        }
      } else {
        await portofolioService.unlikePorto(userId, noId);
        await localService.removeLiked(noId);
      }

      await _syncLikedAndSavedFromLocal();
    } catch (e) {
      debugPrint('[PortofolioProvider] ❌ toggleLike error: $e');
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
  // SAVE — optimistic UI + rollback
  // ═══════════════════════════════════════════════════

  Future<void> toggleSave({
    required BuildContext context,
    required PortofolioModel porto,
    bool navigateToPost = true, // ✅ tambah parameter ini
  }) async {
    final userId = context.read<UserProvider>().userId;
    if (userId == null) {
      return context
          .read<NavigationProvider>()
          .navigateToPage(context, UserLogin(), targetTabIndex: 0);
    }
    final noId = porto.noId;
    if (_saveInProgress.contains(noId)) return;

    final wasSaved = isSaved(noId);
    final nowSaved = !wasSaved;

    _saveInProgress.add(noId);
    _updateSaveList(porto, nowSaved);
    safeNotify();

    try {
      if (nowSaved) {
        await portofolioService.savePorto(userId, noId);
        await localService.saveSaved(porto);

        // ✅ Hanya navigate jika diminta
        if (navigateToPost && context.mounted) {
          setSelectedPortofolio(porto);
          context.read<NavigationProvider>().navigateToPage(
                context,
                const SinglePostPage(),
                hrsLogin: true,
                targetTabIndex: 0,
                targetPage: 'SinglePostPage',
                noIdPortofolio: porto.noId,
              );
        }
      } else {
        await portofolioService.unsavePorto(userId, noId);
        await localService.removeSaved(noId);
      }

      await _syncLikedAndSavedFromLocal();
    } catch (e) {
      debugPrint('[PortofolioProvider] ❌ toggleSave error: $e');
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
  // LOAD LIKED / SAVED LIST
  // ═══════════════════════════════════════════════════

  Future<void> loadLikedPortofolio({
    BuildContext? context,
    bool syncFromApi = true,
  }) async {
    _isLoadingLike = true;
    safeNotify();

    try {
      _portofolioLikelist = await localService.getLikedPortfolios();
      safeNotify();

      if (syncFromApi && context != null) {
        try {
          final userId = context.read<UserProvider>().userId;
          if (userId != null) {
            final apiLiked =
                await portofolioService.getLikesPorto(noId: userId);

            // ✅ syncLiked memanggil saveLiked di dalamnya.
            // Aman karena saveLiked sekarang silent-skip jika belum login.
            await localService.syncLiked(apiLiked);
            _portofolioLikelist = await localService.getLikedPortfolios();
          }
        } catch (e) {
          debugPrint('[PortofolioProvider] ⚠️ syncLiked API failed: $e');
        }
      }
    } catch (e) {
      debugPrint('[PortofolioProvider] ❌ loadLikedPortofolio: $e');
    } finally {
      _isLoadingLike = false;
      safeNotify();
    }
  }

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

            // ✅ syncSaved memanggil saveSaved di dalamnya.
            // Aman karena saveSaved sekarang silent-skip jika belum login.
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
      // Clear progress sets
      _likeInProgress.clear();
      _saveInProgress.clear();

      // ✅ FIX: Clear SEMUA in-memory state yang user-specific
      _portofolioLikelist = []; // ← ini yang menyebabkan bug
      _portofolioSaveList = []; // ← ini juga
      _selectedPortofolio =
          null; // ← agar SinglePostPage tidak tampilkan data lama
      _paketPortofolio = [];

      // ✅ Tidak perlu clear _portofolioList karena itu data publik
      // (feed home — sama untuk semua user, tidak user-specific)

      // Baru clear Hive box (async) setelah in-memory sudah clear
      // Ini memastikan UI langsung tampil kosong tanpa tunggu Hive
      await localService.clearAll();

      safeNotify(); // notify SETELAH semua clear
      debugPrint('[PortofolioProvider] 🧹 Customer data cleared');
    } catch (e) {
      debugPrint('[PortofolioProvider] ❌ clearCustomerData: $e');
    }
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
