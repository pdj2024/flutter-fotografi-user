import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/services/media_preload_service.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';
import 'package:mpjnew/src/data/hive_service.dart/portofolio_local_service.dart';
import 'package:mpjnew/src/data/models/kategori_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/portofolio_service.dart';
import 'package:mpjnew/src/features/customer/viewmodels/kategori_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/paket_provider.dart';
import 'package:provider/provider.dart';

/// ═══════════════════════════════════════════════════════════════
/// UNIFIED PORTOFOLIO PROVIDER - CUSTOMER
///
/// Features:
/// - ✅ Local cache management (like vendor)
/// - ✅ Background image preloading
/// - ✅ Like & Save tracking
/// - ✅ Selected portfolio management
/// - ✅ Smart load with cache-first strategy
/// ═══════════════════════════════════════════════════════════════

class PortofolioProvider with ChangeNotifier {
  final PortofolioService portofolioService;
  final PortofolioLocalService localService;

  // ✅ Preload service instance
  final MediaPreloadService _preloadService = MediaPreloadService();

  bool _disposed = false;

  PortofolioProvider({
    required this.portofolioService,
    PortofolioLocalService? localService,
  }) : localService = localService ?? PortofolioLocalService() {
    _initialize();
  }

  // ═══════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════

  PortofolioModel? _selectedPortofolio;
  List<PortofolioModel> _portofolioList = [];
  List<PortofolioModel> _portofolioSaveList = [];
  List<PortofolioModel> _portofolioLikelist = [];
  List<PortofolioModel> _cachedPortfolios = [];

  // ✅ For selected portfolio's pakets
  List<PaketModel> _paketPortofolio = [];

  bool _isLoadingPorto = true;
  String? _errorPorto;
  bool _isInitialized = false;
  bool _isFromCache = false;

  // ═══════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════

  List<PortofolioModel> get portofolioList => _portofolioList;
  List<PortofolioModel> get portofolioSaveList => _portofolioSaveList;
  List<PortofolioModel> get portofolioLikelist => _portofolioLikelist;
  List<PortofolioModel> get cachedPortfolios => _cachedPortfolios;

  PortofolioModel? get selectedPortofolio => _selectedPortofolio;
  List<PaketModel> get paketPortofolio => _paketPortofolio;

  bool get isLoadingPorto => _isLoadingPorto;
  String? get errorPorto => _errorPorto;
  bool get isInitialized => _isInitialized;
  bool get isFromCache => _isFromCache;

  // ✅ Preload service getter
  MediaPreloadService get preloadService => _preloadService;

  KategoriModel? _selectedKategori;
  List<PaketModel> _selectedPaket = [];

  KategoriModel? get selectedKategori => _selectedKategori;
  List<PaketModel> get selectedPaket => _selectedPaket;

  void setKategori(KategoriModel? value) {
    _selectedKategori = value;
    notifyListeners();
  }

  /// Check if portfolio is in cache
  bool isPortfolioCached(String noId) {
    return _cachedPortfolios.any((p) => p.noId == noId);
  }

  // ═══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════

  @override
  void dispose() {
    _disposed = true;
    // ✅ Cancel pending preloads
    _preloadService.cancelAll();
    super.dispose();
  }

  void safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════

  Future<void> _initialize() async {
    try {
      debugPrint('🔧 [PortofolioProvider] Initializing...');

      // Initialize local service
      await localService.initialize();

      _isInitialized = true;
      debugPrint('✅ [PortofolioProvider] Initialized');
    } catch (e, stackTrace) {
      debugPrint('❌ [PortofolioProvider] Initialization error: $e');
      debugPrint('Stack: $stackTrace');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SELECTED PORTFOLIO MANAGEMENT
  // ═══════════════════════════════════════════════════════════

  void setSelectedPortofolio(PortofolioModel? porto) {
    _selectedPortofolio = porto;

    // ✅ Preload selected portfolio images with high priority
    if (porto != null) {
      _preloadService.preloadPortfolio(porto, highPriority: true);
    }

    notifyListeners();
  }

  /// Get portfolio by ID (cache-first)
  Future<PortofolioModel?> getPortfolioById(String noId) async {
    try {
      // Priority 1: Check cache
      final cached = await localService.getPortfolioById(noId);
      if (cached != null) {
        debugPrint('[PortofolioProvider] 📦 Using cached portfolio: $noId');
        return cached;
      }

      // Priority 2: Check in-memory list
      try {
        final fromList = _portofolioList.firstWhere((p) => p.noId == noId);
        debugPrint('[PortofolioProvider] 📋 Using portfolio from list: $noId');
        return fromList;
      } catch (e) {
        // Not found in list
      }

      // Priority 3: Fetch from API
      debugPrint('[PortofolioProvider] 🌐 Fetching portfolio from API: $noId');
      final portfolios = await portofolioService.getAll(noId: noId);

      if (portfolios.isNotEmpty) {
        return portfolios.first;
      }

      return null;
    } catch (e) {
      debugPrint('[PortofolioProvider] ❌ Error getting portfolio: $e');
      return null;
    }
  }

  /// Set pakets for selected portfolio
  Future<void> setPaketPortofolio({
    required List<String> idPaket,
    required PaketProvider paketProvider,
  }) async {
    final allPaketVendor = paketProvider.paketList;

    _paketPortofolio = allPaketVendor
        .where(
          (paket) => idPaket.contains(paket.no_id) && paket.status == 'aktif',
        )
        .toList();

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  // LOAD OPERATIONS - Smart Cache Strategy
  // ═══════════════════════════════════════════════════════════

  /// Load portfolios with smart cache strategy & preloading
  Future<void> loadPortofolio(
    BuildContext context, {
    String status = 'aktif',
    String untukKeperluan = 'home',
    bool preloadImages = true,
    bool forceRefresh = false,
  }) async {
    _isLoadingPorto = true;
    _errorPorto = null;
    debugPrint("═══════════════════════════════════════════════════");
    debugPrint("[PortofolioProvider] 📥 Loading portfolios...");
    safeNotify();

    try {
      final userProvider = context.read<UserProvider>();
      final role = userProvider.role;
      final userId = role == 'customer' ? userProvider.userId : null;

      debugPrint("[PortofolioProvider] User ID: $userId");

      // ✅ STRATEGY 1: Try cache first (if not force refresh)
      if (!forceRefresh && _isInitialized) {
        try {
          final cached = await localService.getCachedPortfolios();

          if (cached.isNotEmpty) {
            debugPrint(
                "[PortofolioProvider] 📦 Found ${cached.length} cached portfolios");

            _cachedPortfolios = cached;
            _portofolioList = cached;
            _isFromCache = true;

            // Filter likes & saves from cache
            if (userProvider.customer != null) {
              _filterLikesAndSaves(userProvider, cached);
            }

            // Show cached data immediately
            safeNotify();

            debugPrint(
                "[PortofolioProvider] ✅ Cache loaded, fetching updates in background...");
          }
        } catch (e) {
          debugPrint("[PortofolioProvider] ⚠️ Cache load failed: $e");
        }
      }

      // ✅ STRATEGY 2: Fetch from API (background or foreground)
      final result = await portofolioService.getAll(
        id_customer: userId,
        status: status,
        untuk_keperluan: untukKeperluan,
        orderBy: 'Tgl_Created',
        orderDir: 'desc',
      );

      _portofolioList = result;
      _isFromCache = false;

      debugPrint(
          "[PortofolioProvider] ✅ Loaded ${result.length} portfolios from API");

      // ✅ Filter likes & saves
      if (userProvider.customer != null) {
        _filterLikesAndSaves(userProvider, result);
      }

      // ✅ Save top 10 to cache in background
      if (result.length >= 10) {
        _saveToCacheInBackground(result.take(10).toList());
      }

      // ✅ START PRELOADING IMAGES IN BACKGROUND
      if (preloadImages && result.isNotEmpty) {
        debugPrint(
            "[PortofolioProvider] 🚀 Starting background image preload...");

        _preloadService
            .preloadPortfolios(
          result,
          priorityCount: 10, // First 10 portfolios get priority
        )
            .then((_) {
          debugPrint("[PortofolioProvider] ✅ Background preload completed");
          _preloadService.printStats();
        }).catchError((e) {
          debugPrint("[PortofolioProvider] ⚠️ Preload error: $e");
        });
      }
    } catch (e) {
      debugPrint("[PortofolioProvider] ❌ Error loading portfolios: $e");
      _errorPorto = "Error memuat portofolio";
    } finally {
      _isLoadingPorto = false;
      debugPrint("[PortofolioProvider] ✅ Load complete");
      debugPrint("═══════════════════════════════════════════════════");
      safeNotify();
    }
  }

  /// Helper: Filter likes and saves
  void _filterLikesAndSaves(
      UserProvider userProvider, List<PortofolioModel> portfolios) {
    final portoMap = {
      for (final porto in portfolios) porto.noId: porto,
    };

    final likes = userProvider.customer!.likes;
    final saves = userProvider.customer!.saves;

    _portofolioLikelist = likes.reversed
        .where((id) => portoMap.containsKey(id))
        .map((id) => portoMap[id]!)
        .toList();

    _portofolioSaveList = saves.reversed
        .where((id) => portoMap.containsKey(id))
        .map((id) => portoMap[id]!)
        .toList();

    debugPrint("[PortofolioProvider]    Likes: ${_portofolioLikelist.length}");
    debugPrint("[PortofolioProvider]    Saves: ${_portofolioSaveList.length}");
  }

  /// Helper: Save to cache in background
  Future<void> _saveToCacheInBackground(
      List<PortofolioModel> portfolios) async {
    try {
      debugPrint(
          "[PortofolioProvider] 💾 Saving ${portfolios.length} portfolios to cache...");

      // Small delay to not block UI
      await Future.delayed(const Duration(milliseconds: 500));

      await localService.saveTop10(
        portfolios,
        downloadMedia: true, // Download media in background
      );

      _cachedPortfolios = await localService.getCachedPortfolios();

      debugPrint("[PortofolioProvider] ✅ Cache saved");
      safeNotify();
    } catch (e) {
      debugPrint("[PortofolioProvider] ⚠️ Cache save failed: $e");
    }
  }

  /// Load liked portfolios
  Future<void> loadLikePortofolio(
    BuildContext context, {
    bool preloadImages = true,
  }) async {
    _isLoadingPorto = true;
    _errorPorto = null;
    debugPrint("[PortofolioProvider] 📥 Loading liked portfolios...");
    safeNotify();

    try {
      final userProvider = context.read<UserProvider>();
      final role = userProvider.role;
      final userId = role == 'customer' ? userProvider.userId : null;

      final result = await portofolioService.getAll(
        id_customer: userId,
        status: "aktif",
      );

      final userLiked = result
          .where((porto) => userProvider.customer!.likes.contains(porto.noId))
          .toList();

      _portofolioLikelist = userLiked;

      debugPrint(
          "[PortofolioProvider] ✅ Loaded ${userLiked.length} liked portfolios");

      // ✅ Preload liked portfolios
      if (preloadImages && userLiked.isNotEmpty) {
        _preloadService.preloadPortfolios(userLiked);
      }
    } catch (e) {
      debugPrint("[PortofolioProvider] ❌ Error loading liked portfolios: $e");
      _errorPorto = "Error memuat portofolio";
    } finally {
      _isLoadingPorto = false;
      safeNotify();
    }
  }

  /// Load saved portfolios
  Future<void> loadSavePortofolio(
    BuildContext context, {
    bool preloadImages = true,
  }) async {
    _isLoadingPorto = true;
    _errorPorto = null;
    debugPrint("[PortofolioProvider] 📥 Loading saved portfolios...");
    safeNotify();

    try {
      final userProvider = context.read<UserProvider>();
      final role = userProvider.role;
      final userId = role == 'customer' ? userProvider.userId : null;

      final result = await portofolioService.getAll(
        id_customer: userId,
        status: "aktif",
      );

      final userSaved = result
          .where((porto) => userProvider.customer!.saves.contains(porto.noId))
          .toList();

      _portofolioSaveList = userSaved;

      debugPrint(
          "[PortofolioProvider] ✅ Loaded ${userSaved.length} saved portfolios");

      // ✅ Preload saved portfolios
      if (preloadImages && userSaved.isNotEmpty) {
        _preloadService.preloadPortfolios(userSaved);
      }
    } catch (e) {
      debugPrint("[PortofolioProvider] ❌ Error loading saved portfolios: $e");
      _errorPorto = "Error memuat portofolio";
    } finally {
      _isLoadingPorto = false;
      safeNotify();
    }
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
      debugPrint('[PortofolioProvider] 🔄 Refreshing: $oldId');

      await loadPortofolio(context);

      final freshPorto = portofolioList.firstWhere((p) => p.noId == oldId);
      setSelectedPortofolio(freshPorto);

      await setPaketPortofolio(
        idPaket: freshPorto.idPaket.toList(),
        paketProvider: paketProvider,
      );

      debugPrint('[PortofolioProvider] ✅ Portfolio refreshed');
    } catch (e, stackTrace) {
      _errorPorto = "Gagal refresh portofolio";
    } finally {
      _isLoadingPorto = false;
      notifyListeners();
    }
  }

  /// Refresh data portofolio (pull-to-refresh)
  Future<void> refresh(BuildContext context) async {
    await loadPortofolio(context, forceRefresh: true);
  }

  // ═══════════════════════════════════════════════════════════
  // PRELOAD CONTROL METHODS
  // ═══════════════════════════════════════════════════════════

  /// Preload specific portfolio (for detail view)
  Future<void> preloadPortfolio(PortofolioModel portfolio) async {
    await _preloadService.preloadPortfolio(portfolio, highPriority: true);
  }

  /// Get preload statistics
  Map<String, dynamic> getPreloadStats() {
    return _preloadService.getStats();
  }

  /// Clear image cache
  Future<void> clearImageCache() async {
    await _preloadService.clearCache();
    debugPrint("[PortofolioProvider] 🗑️ Image cache cleared");
  }

  /// Cancel all pending preloads
  void cancelPreloads() {
    _preloadService.cancelAll();
  }

  /// Pause preloading (to save battery/data)
  void pausePreloads() {
    _preloadService.pause();
  }

  /// Resume preloading
  void resumePreloads() {
    _preloadService.resume();
  }

  // ═══════════════════════════════════════════════════════════
  // CACHE MANAGEMENT
  // ═══════════════════════════════════════════════════════════

  /// Clear all cache
  Future<void> clearCache() async {
    try {
      debugPrint('[PortofolioProvider] 🗑️ Clearing cache...');

      await localService.clearAll();
      _cachedPortfolios = [];

      debugPrint('[PortofolioProvider] ✅ Cache cleared');
      notifyListeners();
    } catch (e) {
      debugPrint('[PortofolioProvider] ❌ Clear cache failed: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    return await localService.getStats();
  }

  /// Print cache statistics
  Future<void> printCacheStats() async {
    await localService.printStats();
  }
}
