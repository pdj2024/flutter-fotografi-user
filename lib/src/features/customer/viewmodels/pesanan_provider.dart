import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';

/// ✅ IMPROVED: PesananProvider dengan integrasi HistoryOrderProvider
class PesananProvider with ChangeNotifier {
  final PesananService pesananService;

  PesananProvider({required this.pesananService});

  /// ALL DATA
  List<PesananModel> _allPesanan = [];

  /// FILTERED DATA
  List<PesananModel> _pesananUnpaid = [];
  List<PesananModel> _pesananProgress = [];
  List<PesananModel> _pesananSelesai = [];

  List<PesananModel> get pesananUnpaid => _pesananUnpaid;
  List<PesananModel> get pesananProgress => _pesananProgress;
  List<PesananModel> get pesananSelesai => _pesananSelesai;
  List<PesananModel> get allPesanan => _allPesanan;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorPesanan;
  String? get errorPesanan => _errorPesanan;

  // =========================================
  // LOAD ORDER (1x FETCH)
  // =========================================
  Future<void> loadOrder({
    required String userId,
    String status = 'aktif',
  }) async {
    _isLoading = true;
    _errorPesanan = null;
    notifyListeners();
    debugPrint("📦 [PesananProvider] Memuat pesanan...");

    try {
      /// 🔥 FETCH SEKALI SAJA
      final result = await pesananService.getAll(
        idCustomer: userId,
        status: status,
        orderBy: "Created_At",
        orderDir: "desc",
      );

      _allPesanan = result;
      debugPrint("📦 [PesananProvider] Loaded ${_allPesanan.length} pesanan");

      /// 🔽 FILTER DATA
      _filterPesanan();

      debugPrint("📊 [PesananProvider] Filtered:");
      debugPrint("   - Unpaid: ${_pesananUnpaid.length}");
      debugPrint("   - Progress: ${_pesananProgress.length}");
      debugPrint("   - Selesai: ${_pesananSelesai.length}");
    } catch (e, st) {
      _errorPesanan = "Error memuat pesanan";
      debugPrint("❌ [PesananProvider] Load error: $e");
      debugPrint("Stack: $st");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================
  // ✅ UPDATE ORDER STATUS (Called from HistoryOrderProvider)
  // =========================================
  /// Update status pesanan berdasarkan SignalR update dari HistoryOrder
  void updateOrderStatus(String noOrder, String newStatus) {
    debugPrint("═══════════════════════════════════════");
    debugPrint("[PesananProvider] 📨 UPDATE ORDER STATUS");
    debugPrint("═══════════════════════════════════════");
    debugPrint("[PesananProvider] Order: $noOrder");
    debugPrint("[PesananProvider] New Status: $newStatus");

    // Find pesanan by noBukti (same as noOrder)
    final index = _allPesanan.indexWhere((p) => p.noBukti == noOrder);

    if (index == -1) {
      debugPrint("[PesananProvider] ⚠️ Order not found: $noOrder");
      debugPrint("[PesananProvider] Available orders:");
      for (var p in _allPesanan) {
        debugPrint("   - ${p.noBukti}: ${p.statusProgresPesanan}");
      }
      debugPrint("═══════════════════════════════════════");
      return;
    }

    final pesanan = _allPesanan[index];
    final oldStatus = pesanan.statusProgresPesanan;

    // Check if status actually changed
    if (oldStatus == newStatus) {
      debugPrint("[PesananProvider] ℹ️ Status unchanged: $newStatus");
      debugPrint("═══════════════════════════════════════");
      return;
    }

    debugPrint("[PesananProvider] 🔄 Status change detected:");
    debugPrint("   Old: $oldStatus");
    debugPrint("   New: $newStatus");

    // ✅ Update pesanan with new status
    _allPesanan[index] = pesanan.copyWith(
      statusProgresPesanan: newStatus,
    );

    debugPrint("[PesananProvider] ✅ Updated in _allPesanan");

    // ✅ Re-filter to move to correct list
    final oldListName = _getListName(oldStatus ?? "unknown");
    final newListName = _getListName(newStatus);

    debugPrint("[PesananProvider] 📦 Moving order:");
    debugPrint("   From: $oldListName");
    debugPrint("   To: $newListName");

    _filterPesanan();

    debugPrint("[PesananProvider] ✅ Filtered. New counts:");
    debugPrint("   - Unpaid: ${_pesananUnpaid.length}");
    debugPrint("   - Progress: ${_pesananProgress.length}");
    debugPrint("   - Selesai: ${_pesananSelesai.length}");

    // Notify listeners to update UI
    notifyListeners();

    debugPrint("[PesananProvider] 🔔 Listeners notified");
    debugPrint("═══════════════════════════════════════");
  }

  // =========================================
  // HELPER: Get List Name for Debugging
  // =========================================
  String _getListName(String status) {
    if (status == "menunggu bayar") return "Unpaid";
    if (["persiapan", "proses", "review", "revisi"].contains(status)) {
      return "Progress";
    }
    if (status == "selesai") return "Selesai";
    return "Unknown";
  }

  // =========================================
  // FILTER LOGIC
  // =========================================
  void _filterPesanan() {
    debugPrint("[PesananProvider] 🔽 Filtering ${_allPesanan.length} orders...");

    _pesananUnpaid = _allPesanan.where((pesanan) {
      return pesanan.statusProgresPesanan == "menunggu bayar";
    }).toList();

    _pesananProgress = _allPesanan.where((pesanan) {
      return [
        "persiapan",
        "proses",
        "review",
        "revisi",
      ].contains(pesanan.statusProgresPesanan);
    }).toList();

    _pesananSelesai = _allPesanan.where((pesanan) {
      return pesanan.statusProgresPesanan == "selesai";
    }).toList();

    debugPrint("[PesananProvider] ✅ Filtering complete");
  }

  // =========================================
  // ✅ GET PESANAN BY NO ORDER
  // =========================================
  /// Find pesanan by noBukti/noOrder
  PesananModel? getPesananByNoOrder(String noOrder) {
    try {
      return _allPesanan.firstWhere((p) => p.noBukti == noOrder);
    } catch (e) {
      return null;
    }
  }

  // =========================================
  // ✅ REFRESH SINGLE ORDER
  // =========================================
  /// Refresh data untuk 1 order tertentu dari API
  Future<void> refreshOrder(String noOrder) async {
    debugPrint("[PesananProvider] 🔄 Refreshing order: $noOrder");

    try {
      final result = await pesananService.getAll(
        noBukti: noOrder,
        status: 'aktif',
      );

      if (result.isNotEmpty) {
        final updatedPesanan = result.first;
        final index = _allPesanan.indexWhere((p) => p.noBukti == noOrder);

        if (index != -1) {
          _allPesanan[index] = updatedPesanan;
          _filterPesanan();
          notifyListeners();
          debugPrint("[PesananProvider] ✅ Order refreshed: $noOrder");
        } else {
          // Order baru, tambahkan
          _allPesanan.add(updatedPesanan);
          _filterPesanan();
          notifyListeners();
          debugPrint("[PesananProvider] ➕ New order added: $noOrder");
        }
      }
    } catch (e) {
      debugPrint("[PesananProvider] ❌ Refresh error: $e");
    }
  }

  // =========================================
  // DEBUG
  // =========================================
  void printDebug() {
    debugPrint("=== PesananProvider Debug ===");
    debugPrint("Total orders: ${_allPesanan.length}");
    debugPrint("Unpaid: ${_pesananUnpaid.length}");
    debugPrint("Progress: ${_pesananProgress.length}");
    debugPrint("Selesai: ${_pesananSelesai.length}");
    debugPrint("Loading: $_isLoading");
    debugPrint("Error: $_errorPesanan");
    
    debugPrint("\nAll Orders:");
    for (var p in _allPesanan) {
      debugPrint("  - ${p.noBukti}: ${p.statusProgresPesanan}");
    }
    debugPrint("============================");
  }
}