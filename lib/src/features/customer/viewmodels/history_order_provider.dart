import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/widget/order_status_flow.dart';

/// ═══════════════════════════════════════════════════════════════
/// HISTORY ORDER PROVIDER — CUSTOMER
/// ═══════════════════════════════════════════════════════════════
class HistoryOrderProvider extends ChangeNotifier {
  final HistoryOrderService _service = HistoryOrderService();

  final Map<String, List<HistoryOrderModel>> _orderHistories = {};
  final Map<String, bool> _loadingStates = {};
  final Map<String, String?> _errors = {};
  final Map<String, String> _orderStatuses = {};
  final Set<String> _trackedOrders = {};
  bool _isInitialized = false;

  void Function(String noOrder, String newStatus)? onOrderStatusChanged;
  void Function(HistoryOrderModel progress)? onProgressReceived;

  bool get isInitialized => _isInitialized;

  List<HistoryOrderModel> getHistoryForOrder(String noOrder) =>
      _orderHistories[noOrder] ?? [];

  bool isLoadingOrder(String noOrder) => _loadingStates[noOrder] ?? false;

  String? getErrorForOrder(String noOrder) => _errors[noOrder];

  String? getCurrentStatus(String noOrder) => _orderStatuses[noOrder];

  int getHistoryCount(String noOrder) =>
      _orderHistories[noOrder]?.length ?? 0;

  HistoryOrderModel? getLatestProgress(String noOrder) {
    final histories = _orderHistories[noOrder];
    if (histories == null || histories.isEmpty) return null;
    return (List<HistoryOrderModel>.from(histories)
          ..sort((a, b) => b.tglProgress.compareTo(a.tglProgress)))
        .first;
  }

  bool isOrderTracked(String noOrder) => _trackedOrders.contains(noOrder);
  Set<String> get trackedOrders => Set.unmodifiable(_trackedOrders);

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    debugPrint('[HistoryOrderProvider] ✅ Initialized (FCM mode)');
  }

  // =========================================
  // FCM INTEGRATION
  // =========================================

  void handleProgressFromFCM(HistoryOrderModel progress) {
    debugPrint('[HistoryOrderProvider] 📨 FCM'
        ' — order: ${progress.noOrder}'
        ' — status: ${progress.statusProgressPesanan}');
    if (!_trackedOrders.contains(progress.noOrder)) return;
    _handleNewProgress(progress);
  }

  void _handleNewProgress(HistoryOrderModel progress) {
    final noOrder = progress.noOrder;

    if (_orderHistories.containsKey(noOrder)) {
      final exists =
          _orderHistories[noOrder]!.any((p) => p.noId == progress.noId);
      if (!exists) {
        _orderHistories[noOrder]!.add(progress);
        _orderHistories[noOrder]!
            .sort((a, b) => b.tglProgress.compareTo(a.tglProgress));
      } else {
        final idx = _orderHistories[noOrder]!
            .indexWhere((p) => p.noId == progress.noId);
        if (idx != -1) _orderHistories[noOrder]![idx] = progress;
      }
    } else {
      _orderHistories[noOrder] = [progress];
    }

    final oldStatus = _orderStatuses[noOrder];
    _orderStatuses[noOrder] = progress.statusProgressPesanan;

    if (oldStatus != null && oldStatus != progress.statusProgressPesanan) {
      onOrderStatusChanged?.call(noOrder, progress.statusProgressPesanan);
    }

    onProgressReceived?.call(progress);
    notifyListeners();
  }

  // =========================================
  // ORDER TRACKING
  // =========================================

  Future<void> trackOrder(String noOrder) async {
    if (_trackedOrders.contains(noOrder)) return;
    _trackedOrders.add(noOrder);
    await fetchHistoryForOrder(noOrder);
  }

  Future<void> trackOrders(List<String> orderIds) async {
    for (final id in orderIds) {
      await trackOrder(id);
    }
  }

  void untrackOrder(String noOrder) => _trackedOrders.remove(noOrder);
  void untrackAllOrders() => _trackedOrders.clear();

  // =========================================
  // DATA FETCHING
  // =========================================

  Future<void> fetchHistoryForOrder(String noOrder,
      {bool silent = false}) async {
    if (!silent) {
      _loadingStates[noOrder] = true;
      _errors[noOrder] = null;
      notifyListeners();
    }

    try {
      final histories = await _service.getAll(
        noOrder: noOrder,
        status: 'aktif',
        orderBy: 'Tgl_Progress',
        orderDir: 'DESC',
      );
      _orderHistories[noOrder] = histories;
      if (histories.isNotEmpty) {
        _orderStatuses[noOrder] = histories.first.statusProgressPesanan;
      }
      _errors[noOrder] = null;
    } catch (e, st) {
      debugPrint('[HistoryOrderProvider] ❌ Fetch error: $e\n$st');
      _errors[noOrder] = e.toString();
    } finally {
      _loadingStates[noOrder] = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistoriesForOrders(List<String> orderIds) async {
    for (final id in orderIds) {
      await fetchHistoryForOrder(id, silent: true);
    }
    notifyListeners();
  }

  Future<void> refreshHistoryForOrder(String noOrder) =>
      fetchHistoryForOrder(noOrder);

  // =========================================
  // CRUD OPERATIONS
  // =========================================

  Future<bool> createProgress(HistoryOrderModel progress) async {
    try {
      await _service.create(progress);
      return true;
    } catch (e, st) {
      debugPrint('[HistoryOrderProvider] ❌ Create error: $e\n$st');
      _errors[progress.noOrder] = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // createProgressWithStatus — tanpa validasi alur
  // Gunakan untuk: dibatalkan, menunggu bayar, dan status non-linear.
  // ─────────────────────────────────────────────────────────────────
  Future<bool> createProgressWithStatus({
    required String noOrder,
    required String senderId,
    required String status,
    String? customDeskripsi,
  }) async {
    final progress = HistoryOrderService.createHistory(
      noOrder: noOrder,
      senderId: senderId,
      statusProgressPesanan: status,
      customDeskripsi: customDeskripsi,
    );
    return createProgress(progress);
  }

  // ─────────────────────────────────────────────────────────────────
  // createProgressLinear — dengan validasi alur
  // Gunakan untuk semua transisi di alur fotografi:
  //   persiapan → pengerjaan → review → [revisi] → selesai
  //
  // Otomatis menolak jika transisi tidak ada di tabel OrderStatusFlow.
  // ─────────────────────────────────────────────────────────────────
  Future<bool> createProgressLinear({
    required String noOrder,
    required String currentStatus,
    required String newStatus,
    required String senderId,
    String? customDeskripsi,
  }) async {
    if (!OrderStatusFlow.isValid(currentStatus, newStatus)) {
      debugPrint('[HistoryOrderProvider] ❌ Invalid transition:'
          ' $currentStatus → $newStatus');
      return false;
    }

    final progress = HistoryOrderService.createHistory(
      noOrder: noOrder,
      senderId: senderId,
      statusProgressPesanan: newStatus,
      customDeskripsi: customDeskripsi ??
          OrderStatusFlow.defaultDeskripsi(currentStatus, newStatus),
    );

    return createProgress(progress);
  }

  Future<bool> updateProgress(HistoryOrderModel progress) async {
    try {
      await _service.update(progress);
      final noOrder = progress.noOrder;
      if (_orderHistories.containsKey(noOrder)) {
        final idx = _orderHistories[noOrder]!
            .indexWhere((p) => p.noId == progress.noId);
        if (idx != -1) {
          _orderHistories[noOrder]![idx] = progress;
          notifyListeners();
        }
      }
      return true;
    } catch (e, st) {
      debugPrint('[HistoryOrderProvider] ❌ Update error: $e\n$st');
      return false;
    }
  }

  Future<bool> deleteProgress(String noId, String noOrder) async {
    try {
      await _service.delete(noId);
      _orderHistories[noOrder]?.removeWhere((p) => p.noId == noId);
      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrint('[HistoryOrderProvider] ❌ Delete error: $e\n$st');
      return false;
    }
  }

  // =========================================
  // QUICK-CREATE HELPERS
  // =========================================

  Future<bool> createMenungguPembayaran(String noOrder, String senderId) =>
      createProgressWithStatus(
          noOrder: noOrder, senderId: senderId, status: 'menunggu bayar');

  Future<bool> createPersiapan(String noOrder, String senderId) =>
      createProgressWithStatus(
          noOrder: noOrder, senderId: senderId, status: 'persiapan');

  Future<bool> createProses(String noOrder, String senderId) =>
      createProgressWithStatus(
          noOrder: noOrder, senderId: senderId, status: 'proses');

  Future<bool> createReview(String noOrder, String senderId) =>
      createProgressWithStatus(
          noOrder: noOrder, senderId: senderId, status: 'review');

  Future<bool> createRevisi(String noOrder, String senderId,
          {String? catatan}) =>
      createProgressWithStatus(
          noOrder: noOrder,
          senderId: senderId,
          status: 'proses',
          customDeskripsi: catatan != null
              ? 'Customer meminta revisi: $catatan'
              : OrderStatusFlow.defaultDeskripsi('review', 'proses'));

  Future<bool> createSelesai(String noOrder, String senderId) =>
      createProgressWithStatus(
          noOrder: noOrder, senderId: senderId, status: 'selesai');

  Future<bool> createDibatalkan(String noOrder, String senderId,
          {String? alasan}) =>
      createProgressWithStatus(
          noOrder: noOrder,
          senderId: senderId,
          status: 'dibatalkan',
          customDeskripsi: alasan);

  // =========================================
  // UTILITY
  // =========================================

  void clearOrderData(String noOrder) {
    _orderHistories.remove(noOrder);
    _loadingStates.remove(noOrder);
    _errors.remove(noOrder);
    _orderStatuses.remove(noOrder);
    notifyListeners();
  }

  void clearAllData() {
    _orderHistories.clear();
    _loadingStates.clear();
    _errors.clear();
    _orderStatuses.clear();
    notifyListeners();
  }

  String getStatusDescription(String status) =>
      HistoryOrderService.getStatusDescription(status);
  List<String> getAllStatusList() => HistoryOrderService.getAllStatusList();
  String getStatusEmoji(String status) =>
      HistoryOrderService.getStatusEmoji(status);

  @override
  void dispose() {
    _orderHistories.clear();
    _loadingStates.clear();
    _errors.clear();
    _orderStatuses.clear();
    _trackedOrders.clear();
    onOrderStatusChanged = null;
    onProgressReceived = null;
    super.dispose();
  }
}