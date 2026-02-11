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

  // ✅ Map paket_id → list ulasan
  Map<String, List<UlasanModel>> _ulasanByPaket = {};

  bool _isLoading = false;
  bool _isLoadingUlasan = false;
  String? _error;

  // ═══════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════

  List<PaketModel> get paketList => _paketList;
  PaketModel? get paket => _paket;
  Map<String, List<UlasanModel>> get ulasanByPaket => _ulasanByPaket;

  bool get isLoading => _isLoading;
  bool get isLoadingUlasan => _isLoadingUlasan;
  String? get error => _error;

  /// Get ulasan for specific paket
  List<UlasanModel> getUlasanForPaket(String paketId) {
    return _ulasanByPaket[paketId] ?? [];
  }

  /// Check if paket has ulasan loaded
  bool hasUlasanForPaket(String paketId) {
    return _ulasanByPaket.containsKey(paketId);
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

  /// Load pakets by ID list (for portfolio)
  Future<List<PaketModel>> loadPaketsByIds(List<String> paketIds) async {
    if (paketIds.isEmpty) {
      debugPrint('[PaketProvider] ℹ️ No paket IDs to load');
      return [];
    }

    try {
      debugPrint('[PaketProvider] 📥 Loading ${paketIds.length} pakets...');

      final pakets = await service.getAll(
        idList: paketIds,
        status: 'aktif',
      );

      debugPrint('[PaketProvider] ✅ Loaded ${pakets.length} pakets');
      return pakets;
    } catch (e) {
      debugPrint('[PaketProvider] ❌ Error loading pakets: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ULASAN OPERATIONS - OPTIMIZED WITH FOREACH
  // ═══════════════════════════════════════════════════════════

  /// ✅ OPTIMIZED: Load ulasan for each paket individually
  Future<void> loadUlasanForPakets(List<String> paketIds) async {
    if (paketIds.isEmpty) {
      debugPrint('[PaketProvider] ℹ️ No paket IDs for ulasan');
      return;
    }

    _isLoadingUlasan = true;
    notifyListeners();

    try {
      debugPrint(
          '[PaketProvider] 📥 Loading ulasan for ${paketIds.length} pakets...');

      final Map<String, List<UlasanModel>> grouped = {};

      // ✅ Fetch ulasan for each paket individually
      for (var paketId in paketIds) {
        try {
          final ulasanList = await ulasanService.getAll(
            idPaket: paketId, // ✅ One paket at a time
            status: 'aktif',
            orderBy: 'Tgl_Ulasan',
            orderDir: 'DESC',
          );

          grouped[paketId] = ulasanList;

          debugPrint(
              '[PaketProvider]    📦 $paketId: ${ulasanList.length} ulasan');
        } catch (e) {
          debugPrint(
              '[PaketProvider]    ⚠️ Error loading ulasan for $paketId: $e');
          grouped[paketId] = []; // Empty list on error
        }
      }

      _ulasanByPaket = grouped;

      final totalUlasan = grouped.values.fold<int>(
        0,
        (sum, list) => sum + list.length,
      );

      debugPrint('[PaketProvider] ✅ Total ulasan loaded: $totalUlasan');
    } catch (e) {
      debugPrint('[PaketProvider] ❌ Error loading ulasan: $e');
      _error = 'Failed to load ulasan: $e';

      // Initialize empty ulasan for all pakets on error
      _ulasanByPaket = {
        for (var paketId in paketIds) paketId: [],
      };
    } finally {
      _isLoadingUlasan = false;
      notifyListeners();
    }
  }

  /// ✅ OPTIMIZED: Load pakets with their ulasan
  Future<void> loadPaketsWithUlasan({
    required List<String> paketIds,
  }) async {
    if (paketIds.isEmpty) {
      debugPrint('[PaketProvider] ℹ️ No paket IDs provided');
      _paketList = [];
      _ulasanByPaket = {};
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('[PaketProvider] 📥 Loading pakets with ulasan...');
      debugPrint('[PaketProvider]    Paket count: ${paketIds.length}');

      // ✅ STEP 1: Load pakets
      final pakets = await loadPaketsByIds(paketIds);
      _paketList = pakets;

      debugPrint('[PaketProvider] ✅ Pakets loaded: ${pakets.length}');

      // ✅ STEP 2: Load ulasan for each paket
      final Map<String, List<UlasanModel>> grouped = {};

      for (var paketId in paketIds) {
        try {
          debugPrint('[PaketProvider]    📥 Loading ulasan for: $paketId');

          final ulasanList = await ulasanService.getAll(
            idPaket: paketId, // ✅ One paket at a time
            status: 'aktif',
            orderBy: 'Tgl_Ulasan',
            orderDir: 'DESC',
          );

          grouped[paketId] = ulasanList;

          debugPrint(
              '[PaketProvider]       ✅ Found ${ulasanList.length} ulasan');
        } catch (e) {
          debugPrint('[PaketProvider]       ⚠️ Error: $e');
          grouped[paketId] = []; // Empty list on error
        }
      }

      _ulasanByPaket = grouped;

      // ✅ Calculate statistics
      final totalUlasan = grouped.values.fold<int>(
        0,
        (sum, list) => sum + list.length,
      );
      final paketsWithUlasan =
          grouped.entries.where((e) => e.value.isNotEmpty).length;
      final paketsWithoutUlasan =
          grouped.entries.where((e) => e.value.isEmpty).length;

      debugPrint('[PaketProvider] ✅ SUMMARY:');
      debugPrint('[PaketProvider]    Pakets: ${pakets.length}');
      debugPrint('[PaketProvider]    Total ulasan: $totalUlasan');
      debugPrint('[PaketProvider]    Pakets with ulasan: $paketsWithUlasan');
      debugPrint(
          '[PaketProvider]    Pakets without ulasan: $paketsWithoutUlasan');
    } catch (e) {
      debugPrint('[PaketProvider] ❌ Error: $e');
      _error = e.toString();

      // Initialize empty data on error
      _paketList = [];
      _ulasanByPaket = {
        for (var paketId in paketIds) paketId: [],
      };

      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear ulasan data
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
      debugPrint('[PaketProvider] 📥 Fetching pakets from room...');
      debugPrint('[PaketProvider]    Messages: ${messages.length}');

      // Collect paket IDs
      final Set<String> paketIds = {};

      for (final msg in messages) {
        if (msg.idPaket != null && msg.idPaket!.isNotEmpty) {
          paketIds.add(msg.idPaket!);
        }
      }

      debugPrint('[PaketProvider]    Unique paket IDs: ${paketIds.length}');

      if (paketIds.isEmpty) {
        debugPrint('[PaketProvider] ℹ️ No pakets in room');
        return [];
      }

      // Fetch pakets
      final paketList = await service.getAll(idList: paketIds.toList());

      debugPrint('[PaketProvider] ✅ Fetched ${paketList.length} pakets');
      return paketList;
    } catch (e) {
      _error = e.toString();
      debugPrint('[PaketProvider] ❌ Error: $e');
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
      await getAll(); // refresh after create
    } catch (e) {
      _error = e.toString();
      debugPrint('[PaketProvider] ❌ Error create: $e');
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
      await getAll(); // refresh after update
    } catch (e) {
      _error = e.toString();
      debugPrint('[PaketProvider] ❌ Error update: $e');
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
      await getAll(); // refresh after delete
    } catch (e) {
      _error = e.toString();
      debugPrint('[PaketProvider] ❌ Error delete: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
