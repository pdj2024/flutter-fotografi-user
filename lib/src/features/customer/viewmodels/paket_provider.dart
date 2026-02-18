import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/models/ulasan_model.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/services/ulasan_service.dart';

class PaketProvider with ChangeNotifier {
  final PaketService service;
  final UlasanService ulasanService;

  PaketProvider({
    required this.service,
    UlasanService? ulasanService,
  }) : ulasanService = ulasanService ?? UlasanService();

  // ═══════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════

  List<PaketModel> _paketList = [];
  PaketModel? _paket;

  // Map paket_id → list ulasan
  Map<String, List<UlasanModel>> _ulasanByPaket = {};

  bool _isLoading = false;
  bool _isLoadingUlasan = false;
  String? _error;

  // ✅ FIX: Track portfolio ID yang sedang dimuat
  // Digunakan untuk membatalkan hasil load jika portfolio sudah berganti
  String? _loadingForPortfolioId;

  // ═══════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════

  List<PaketModel> get paketList => _paketList;
  PaketModel? get paket => _paket;
  Map<String, List<UlasanModel>> get ulasanByPaket => _ulasanByPaket;

  bool get isLoading => _isLoading;
  bool get isLoadingUlasan => _isLoadingUlasan;
  String? get error => _error;

  /// Get ulasan for specific paket — returns empty list jika tidak ada
  List<UlasanModel> getUlasanForPaket(String paketId) {
    return _ulasanByPaket[paketId] ?? [];
  }

  bool hasUlasanForPaket(String paketId) {
    return _ulasanByPaket.containsKey(paketId);
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ FIX: CLEAR FOR PORTFOLIO
  // Harus dipanggil SEBELUM load porto baru agar data lama
  // tidak pernah terlihat di porto yang salah
  // ═══════════════════════════════════════════════════════════

  /// Reset state untuk porto baru.
  /// [portfolioId] null = force clear tanpa set target baru (untuk refresh)
  void clearForPortfolio(String? portfolioId) {
    debugPrint('[PaketProvider] 🗑️ Clearing for portfolio: $portfolioId');

    _paketList = [];
    _ulasanByPaket = {};
    _error = null;
    _loadingForPortfolioId = portfolioId;

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  // PAKET OPERATIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> getAll({
    String? no_id,
    String? nama_paket,
    String? id_media,
    String? status,
    String? orderBy,
    String? orderDir,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _paketList = await service.getAll(
        noId: no_id,
        namaPaket: nama_paket,
        idVendor: id_media,
        status: status,
        orderBy: orderBy,
        orderDir: orderDir,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('[PaketProvider] ❌ Error getAll: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<PaketModel>> loadPaketsByIds(List<String> paketIds) async {
    if (paketIds.isEmpty) return [];

    try {
      debugPrint('[PaketProvider] 📥 Loading ${paketIds.length} pakets by IDs...');
      final pakets = await service.getAll(idList: paketIds, status: 'aktif');
      debugPrint('[PaketProvider] ✅ Loaded ${pakets.length} pakets');
      return pakets;
    } catch (e) {
      debugPrint('[PaketProvider] ❌ Error loading pakets: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ FIXED: LOAD PAKETS WITH ULASAN
  // Menerima portfolioId untuk memastikan hasil load masih relevan
  // ═══════════════════════════════════════════════════════════

  Future<void> loadPaketsWithUlasan({
    required List<String> paketIds,
    String? portfolioId, // ✅ FIX: tambah parameter ini
    String? vendorId,
  }) async {
    if (paketIds.isEmpty) {
      _paketList = [];
      _ulasanByPaket = {};
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('[PaketProvider] ═══════════════════════════════════');
      debugPrint('[PaketProvider] 📥 loadPaketsWithUlasan');
      debugPrint('[PaketProvider]    Portfolio: $portfolioId');
      debugPrint('[PaketProvider]    Paket IDs: $paketIds');

      // ✅ Step 1: Load pakets
      final pakets = await loadPaketsByIds(paketIds);

      // ✅ FIX: Batalkan jika portfolio sudah berganti saat await
      if (portfolioId != null && portfolioId != _loadingForPortfolioId) {
        debugPrint('[PaketProvider] ⚠️ Portfolio changed during load, discarding results');
        debugPrint('[PaketProvider]    Expected: $portfolioId');
        debugPrint('[PaketProvider]    Current:  $_loadingForPortfolioId');
        return;
      }

      _paketList = pakets;
      notifyListeners(); // Tampilkan paket dulu, ulasan menyusul

      debugPrint('[PaketProvider] ✅ Pakets ready: ${pakets.length}');

      // ✅ Step 2: Load ulasan per paket SATU PER SATU
      // Ulasan harus di-fetch berdasarkan paket_id spesifik,
      // bukan semua sekaligus, agar tidak tercampur
      final Map<String, List<UlasanModel>> grouped = {};

      final ulasanList = await ulasanService.getAll(
        idVendor: vendorId,
        status: 'aktif',
        orderBy: 'Tgl_Ulasan',
        orderDir: 'DESC',
      );

      for (final ulasan in ulasanList) {
        grouped[ulasan.idPaket] ??= [];
        grouped[ulasan.idPaket]!.add(ulasan);
      }

      // for (final paketId in paketIds) {
      //   // ✅ FIX: Check tiap iterasi apakah portfolio masih sama
      //   if (portfolioId != null && portfolioId != _loadingForPortfolioId) {
      //     debugPrint('[PaketProvider] ⚠️ Portfolio changed mid-loop, stopping');
      //     return;
      //   }

      //   try {
      //     debugPrint('[PaketProvider]    📝 Fetching ulasan for paket: $paketId');

      //     final ulasanList = await ulasanService.getAll(
      //       idPaket: paketId,
      //       status: 'aktif',
      //       orderBy: 'Tgl_Ulasan',
      //       orderDir: 'DESC',
      //     );

      //     grouped[paketId] = ulasanList;

      //     debugPrint('[PaketProvider]       ✅ $paketId → ${ulasanList.length} ulasan');
      //   } catch (e) {
      //     debugPrint('[PaketProvider]       ⚠️ Error for $paketId: $e');
      //     grouped[paketId] = []; // empty, jangan pakai data paket lain!
      //   }
      // }

      // ✅ FIX: Final check sebelum commit ke state
      if (portfolioId != null && portfolioId != _loadingForPortfolioId) {
        debugPrint('[PaketProvider] ⚠️ Portfolio changed before commit, discarding');
        return;
      }

      _ulasanByPaket = grouped;

      // Summary
      final totalUlasan = grouped.values.fold(0, (s, l) => s + l.length);
      final withUlasan = grouped.values.where((l) => l.isNotEmpty).length;
      final withoutUlasan = grouped.values.where((l) => l.isEmpty).length;

      debugPrint('[PaketProvider] ✅ DONE for portfolio $portfolioId:');
      debugPrint('[PaketProvider]    Pakets: ${pakets.length}');
      debugPrint('[PaketProvider]    Total ulasan: $totalUlasan');
      debugPrint('[PaketProvider]    With ulasan: $withUlasan');
      debugPrint('[PaketProvider]    Without ulasan: $withoutUlasan');
      debugPrint('[PaketProvider] ═══════════════════════════════════');
    } catch (e) {
      debugPrint('[PaketProvider] ❌ Error: $e');
      _error = e.toString();
      _paketList = [];
      _ulasanByPaket = {for (var id in paketIds) id: []};
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUlasanForPakets(List<String> paketIds) async {
    if (paketIds.isEmpty) return;

    _isLoadingUlasan = true;
    notifyListeners();

    try {
      final Map<String, List<UlasanModel>> grouped = {};

      for (final paketId in paketIds) {
        try {
          final ulasanList = await ulasanService.getAll(
            idPaket: paketId,
            status: 'aktif',
            orderBy: 'Tgl_Ulasan',
            orderDir: 'DESC',
          );
          grouped[paketId] = ulasanList;
        } catch (e) {
          grouped[paketId] = [];
        }
      }

      _ulasanByPaket = grouped;
    } catch (e) {
      _error = 'Failed to load ulasan: $e';
      _ulasanByPaket = {for (var id in paketIds) id: []};
    } finally {
      _isLoadingUlasan = false;
      notifyListeners();
    }
  }

  void clearUlasan() {
    _ulasanByPaket.clear();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  // CHAT ROOM OPERATIONS
  // ═══════════════════════════════════════════════════════════

  Future<List<PaketModel>> fetchPaketFromRoom(List<ChatModel> messages) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Set<String> paketIds = {};
      for (final msg in messages) {
        if (msg.idPaket != null && msg.idPaket!.isNotEmpty) {
          paketIds.add(msg.idPaket!);
        }
      }

      if (paketIds.isEmpty) return [];

      final paketList = await service.getAll(idList: paketIds.toList());
      return paketList;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CRUD OPERATIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> create(PaketModel model) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await service.create(model);
      await getAll();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> update(PaketModel model) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await service.update(model);
      await getAll();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> delete(String noId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await service.delete(noId);
      await getAll();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}