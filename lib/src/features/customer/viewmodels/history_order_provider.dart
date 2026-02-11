import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';

/// ✅ Provider untuk mengelola state history order dengan FCM
/// Real-time updates via FCM, no SignalR needed
class HistoryOrderProvider extends ChangeNotifier {
  final HistoryOrderService _service = HistoryOrderService();

  // =========================================
  // STATE
  // =========================================

  /// Map untuk menyimpan history per order
  final Map<String, List<HistoryOrderModel>> _orderHistories = {};

  /// Map untuk tracking loading state per order
  final Map<String, bool> _loadingStates = {};

  /// Map untuk tracking error per order
  final Map<String, String?> _errors = {};

  /// Map untuk tracking status per order
  final Map<String, String> _orderStatuses = {};

  /// Set of orders yang sedang ditrack (for filtering FCM)
  final Set<String> _trackedOrders = {};

  bool _isInitialized = false;

  // =========================================
  // CALLBACKS
  // =========================================

  /// Callback when order status changes (for UI updates)
  void Function(String noOrder, String newStatus)? onOrderStatusChanged;

  /// Callback when new progress is received (for analytics, logging, etc)
  void Function(HistoryOrderModel progress)? onProgressReceived;

  // =========================================
  // GETTERS
  // =========================================

  bool get isInitialized => _isInitialized;

  /// Get history untuk order tertentu
  List<HistoryOrderModel> getHistoryForOrder(String noOrder) {
    return _orderHistories[noOrder] ?? [];
  }

  /// Get loading state untuk order tertentu
  bool isLoadingOrder(String noOrder) {
    return _loadingStates[noOrder] ?? false;
  }

  /// Get error untuk order tertentu
  String? getErrorForOrder(String noOrder) {
    return _errors[noOrder];
  }

  /// Get current status untuk order tertentu
  String? getCurrentStatus(String noOrder) {
    return _orderStatuses[noOrder];
  }

  int getHistoryCount(String noOrder) {
    return _orderHistories[noOrder]?.length ?? 0;
  }

  /// Get latest progress untuk order tertentu
  HistoryOrderModel? getLatestProgress(String noOrder) {
    final histories = _orderHistories[noOrder];
    if (histories == null || histories.isEmpty) return null;

    final sorted = List<HistoryOrderModel>.from(histories)
      ..sort((a, b) => b.tglProgress.compareTo(a.tglProgress));

    return sorted.first;
  }

  /// Check if order is being tracked
  bool isOrderTracked(String noOrder) {
    return _trackedOrders.contains(noOrder);
  }

  /// Get all tracked orders
  Set<String> get trackedOrders => Set.unmodifiable(_trackedOrders);

  // =========================================
  // INITIALIZATION
  // =========================================

  /// Initialize provider (no connection needed, just state setup)
  void initialize() {
    if (_isInitialized) {
      debugPrint('[HistoryOrderProvider] ℹ️ Already initialized');
      return;
    }

    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');
    debugPrint('[HistoryOrderProvider] 🚀 INITIALIZING (FCM Mode)');
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');

    _isInitialized = true;

    debugPrint('[HistoryOrderProvider] ✅ Initialized successfully');
    debugPrint('[HistoryOrderProvider] ℹ️ Real-time updates via FCM');
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');
  }

  // =========================================
  // FCM INTEGRATION
  // =========================================

  /// Handle progress update from FCM
  /// Call this from your main FCM handler when progress notification received
  void handleProgressFromFCM(HistoryOrderModel progress) {
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');
    debugPrint('[HistoryOrderProvider] 📨 PROGRESS FROM FCM');
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');
    debugPrint('[HistoryOrderProvider] 📦 Order: ${progress.noOrder}');
    debugPrint(
        '[HistoryOrderProvider] 🔖 Status: ${progress.statusProgressPesanan}');
    debugPrint('[HistoryOrderProvider] 📝 Deskripsi: ${progress.deskripsi}');
    debugPrint('[HistoryOrderProvider] 👤 Sender: ${progress.senderId}');
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');

    // Only process if we're tracking this order
    if (!_trackedOrders.contains(progress.noOrder)) {
      debugPrint('[HistoryOrderProvider] ⏭️ Order not tracked, skipping');
      return;
    }

    _handleNewProgress(progress);
  }

  /// Internal handler for new progress
  void _handleNewProgress(HistoryOrderModel progress) {
    final noOrder = progress.noOrder;

    debugPrint(
        '[HistoryOrderProvider] ───────────────────────────────────────');
    debugPrint('[HistoryOrderProvider] 📦 PROCESSING NEW PROGRESS');
    debugPrint('[HistoryOrderProvider] Order: $noOrder');
    debugPrint(
        '[HistoryOrderProvider] Current count: ${_orderHistories[noOrder]?.length ?? 0}');

    // Update history list
    if (_orderHistories.containsKey(noOrder)) {
      // Check if already exists by noId
      final exists =
          _orderHistories[noOrder]!.any((p) => p.noId == progress.noId);

      if (!exists) {
        debugPrint('[HistoryOrderProvider] ➕ Adding new progress');
        _orderHistories[noOrder]!.add(progress);

        // Sort by date descending
        _orderHistories[noOrder]!
            .sort((a, b) => b.tglProgress.compareTo(a.tglProgress));

        debugPrint(
            '[HistoryOrderProvider] ✅ New count: ${_orderHistories[noOrder]!.length}');
      } else {
        debugPrint(
            '[HistoryOrderProvider] ℹ️ Progress already exists, updating');

        // Update existing progress
        final index = _orderHistories[noOrder]!
            .indexWhere((p) => p.noId == progress.noId);
        if (index != -1) {
          _orderHistories[noOrder]![index] = progress;
        }
      }
    } else {
      debugPrint('[HistoryOrderProvider] 🆕 Creating new order history list');
      _orderHistories[noOrder] = [progress];
    }

    // Update current status
    final oldStatus = _orderStatuses[noOrder];
    _orderStatuses[noOrder] = progress.statusProgressPesanan;

    // Notify status change
    if (oldStatus != null && oldStatus != progress.statusProgressPesanan) {
      debugPrint(
          '[HistoryOrderProvider] 🔄 Status changed: $oldStatus → ${progress.statusProgressPesanan}');
      onOrderStatusChanged?.call(noOrder, progress.statusProgressPesanan);
    }

    // Trigger progress received callback
    onProgressReceived?.call(progress);

    debugPrint(
        '[HistoryOrderProvider] ───────────────────────────────────────');

    notifyListeners();
  }

  // =========================================
  // ORDER TRACKING
  // =========================================

  /// Start tracking an order (for FCM filtering)
  Future<void> trackOrder(String noOrder) async {
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');
    debugPrint('[HistoryOrderProvider] 📍 TRACKING ORDER: $noOrder');
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');

    if (_trackedOrders.contains(noOrder)) {
      debugPrint('[HistoryOrderProvider] ℹ️ Already tracking this order');
      return;
    }

    _trackedOrders.add(noOrder);
    debugPrint('[HistoryOrderProvider] ✅ Order added to tracking');
    debugPrint(
        '[HistoryOrderProvider] 📊 Total tracked orders: ${_trackedOrders.length}');

    // Fetch initial data
    await fetchHistoryForOrder(noOrder);

    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');
  }

  /// Track multiple orders
  Future<void> trackOrders(List<String> orderIds) async {
    debugPrint('[HistoryOrderProvider] 📍 Tracking ${orderIds.length} orders');

    for (var i = 0; i < orderIds.length; i++) {
      debugPrint(
          '[HistoryOrderProvider] Processing ${i + 1}/${orderIds.length}: ${orderIds[i]}');
      await trackOrder(orderIds[i]);
    }

    debugPrint('[HistoryOrderProvider] ✅ All orders tracked');
  }

  /// Stop tracking an order
  void untrackOrder(String noOrder) {
    debugPrint('[HistoryOrderProvider] 👋 Untracking order: $noOrder');
    _trackedOrders.remove(noOrder);
    debugPrint('[HistoryOrderProvider] ✅ Order removed from tracking');
  }

  /// Stop tracking all orders
  void untrackAllOrders() {
    debugPrint('[HistoryOrderProvider] 👋 Untracking all orders');
    _trackedOrders.clear();
    debugPrint('[HistoryOrderProvider] ✅ All orders untracked');
  }

  // =========================================
  // DATA FETCHING
  // =========================================

  /// Fetch history untuk order tertentu dari API
  Future<void> fetchHistoryForOrder(String noOrder,
      {bool silent = false}) async {
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');
    debugPrint('[HistoryOrderProvider] 📥 FETCHING HISTORY: $noOrder');
    debugPrint('[HistoryOrderProvider] Silent mode: $silent');
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');

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

      debugPrint('[HistoryOrderProvider] ✅ Fetched ${histories.length} items');

      _orderHistories[noOrder] = histories;

      // Update current status
      if (histories.isNotEmpty) {
        _orderStatuses[noOrder] = histories.first.statusProgressPesanan;
        debugPrint(
            '[HistoryOrderProvider] 📊 Status: ${histories.first.statusProgressPesanan}');
      }

      _errors[noOrder] = null;
    } catch (e, st) {
      debugPrint('[HistoryOrderProvider] ❌ ERROR: $e');
      debugPrint('[HistoryOrderProvider] Stack: $st');

      _errors[noOrder] = e.toString();

    } finally {
      _loadingStates[noOrder] = false;
      notifyListeners();
      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');
    }
  }

  /// Fetch histories untuk multiple orders
  Future<void> fetchHistoriesForOrders(List<String> orderIds) async {
    debugPrint(
        '[HistoryOrderProvider] 📥 Fetching ${orderIds.length} order histories');

    for (var i = 0; i < orderIds.length; i++) {
      debugPrint(
          '[HistoryOrderProvider] Fetching ${i + 1}/${orderIds.length}: ${orderIds[i]}');
      await fetchHistoryForOrder(orderIds[i], silent: true);
    }

    notifyListeners();
    debugPrint('[HistoryOrderProvider] ✅ All histories fetched');
  }

  /// Refresh history for order (force fetch from API)
  Future<void> refreshHistoryForOrder(String noOrder) async {
    debugPrint('[HistoryOrderProvider] 🔄 Refreshing history for: $noOrder');
    await fetchHistoryForOrder(noOrder);
  }

  // =========================================
  // CRUD OPERATIONS
  // =========================================

  /// Create progress baru
  /// Backend will send FCM notification automatically
  Future<bool> createProgress(HistoryOrderModel progress) async {
    try {
      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderProvider] 📤 CREATING PROGRESS');
      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderProvider] Order: ${progress.noOrder}');
      debugPrint(
          '[HistoryOrderProvider] Status: ${progress.statusProgressPesanan}');

      final created = await _service.create(progress);

      debugPrint('[HistoryOrderProvider] ✅ Created with ID: $created');
      debugPrint('[HistoryOrderProvider] ℹ️ FCM notification sent by backend');

      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');
      return true;
    } catch (e, st) {
      debugPrint('[HistoryOrderProvider] ❌ CREATE ERROR: $e');
      debugPrint('[HistoryOrderProvider] Stack: $st');

      _errors[progress.noOrder] = e.toString();
      notifyListeners();

      return false;
    }
  }

  /// Create progress dengan status tertentu
  Future<bool> createProgressWithStatus({
    required String noOrder,
    required String senderId,
    required String status,
    String? customDeskripsi,
  }) async {
    debugPrint('[HistoryOrderProvider] 🔧 Creating progress: $status');

    final progress = HistoryOrderService.createHistory(
      noOrder: noOrder,
      senderId: senderId,
      statusProgressPesanan: status,
      customDeskripsi: customDeskripsi,
    );

    return await createProgress(progress);
  }

  /// Update progress
  Future<bool> updateProgress(HistoryOrderModel progress) async {
    try {
      debugPrint('[HistoryOrderProvider] 📝 Updating: ${progress.noId}');

      await _service.update(progress);

      // Update local state
      final noOrder = progress.noOrder;
      if (_orderHistories.containsKey(noOrder)) {
        final index = _orderHistories[noOrder]!
            .indexWhere((p) => p.noId == progress.noId);

        if (index != -1) {
          _orderHistories[noOrder]![index] = progress;
          debugPrint('[HistoryOrderProvider] ✅ Local state updated');
          notifyListeners();
        }
      }

      return true;
    } catch (e, st) {
      debugPrint('[HistoryOrderProvider] ❌ Update error: $e');

      return false;
    }
  }

  /// Delete progress
  Future<bool> deleteProgress(String noId, String noOrder) async {
    try {
      debugPrint('[HistoryOrderProvider] 🗑️ Deleting: $noId');

      await _service.delete(noId);

      // Update local state
      if (_orderHistories.containsKey(noOrder)) {
        _orderHistories[noOrder]!.removeWhere((p) => p.noId == noId);
        debugPrint('[HistoryOrderProvider] ✅ Removed from local state');
        notifyListeners();
      }

      return true;
    } catch (e, st) {
      debugPrint('[HistoryOrderProvider] ❌ Delete error: $e');


      return false;
    }
  }

  // =========================================
  // HELPER METHODS - QUICK CREATE
  // =========================================

  Future<bool> createMenungguPembayaran(String noOrder, String senderId) async {
    final progress = HistoryOrderService.createMenungguPembayaran(
      noOrder: noOrder,
      senderId: senderId,
    );
    return await createProgress(progress);
  }

  Future<bool> createPersiapan(String noOrder, String senderId) async {
    final progress = HistoryOrderService.createPersiapan(
      noOrder: noOrder,
      senderId: senderId,
    );
    return await createProgress(progress);
  }

  Future<bool> createProses(String noOrder, String senderId) async {
    final progress = HistoryOrderService.createProses(
      noOrder: noOrder,
      senderId: senderId,
    );
    return await createProgress(progress);
  }

  Future<bool> createReview(String noOrder, String senderId) async {
    final progress = HistoryOrderService.createReview(
      noOrder: noOrder,
      senderId: senderId,
    );
    return await createProgress(progress);
  }

  Future<bool> createRevisi(String noOrder, String senderId) async {
    final progress = HistoryOrderService.createRevisi(
      noOrder: noOrder,
      senderId: senderId,
    );
    return await createProgress(progress);
  }

  Future<bool> createSelesai(String noOrder, String senderId) async {
    final progress = HistoryOrderService.createSelesai(
      noOrder: noOrder,
      senderId: senderId,
    );
    return await createProgress(progress);
  }

  Future<bool> createDibatalkan(String noOrder, String senderId,
      {String? alasan}) async {
    final progress = HistoryOrderService.createDibatalkan(
      noOrder: noOrder,
      senderId: senderId,
      customDeskripsi: alasan,
    );
    return await createProgress(progress);
  }

  // =========================================
  // UTILITY METHODS
  // =========================================

  /// Clear data untuk order tertentu
  void clearOrderData(String noOrder) {
    debugPrint('[HistoryOrderProvider] 🧹 Clearing data for: $noOrder');
    _orderHistories.remove(noOrder);
    _loadingStates.remove(noOrder);
    _errors.remove(noOrder);
    _orderStatuses.remove(noOrder);
    notifyListeners();
  }

  /// Clear semua data
  void clearAllData() {
    debugPrint('[HistoryOrderProvider] 🧹 Clearing all data');
    _orderHistories.clear();
    _loadingStates.clear();
    _errors.clear();
    _orderStatuses.clear();
    notifyListeners();
  }

  /// Get status description
  String getStatusDescription(String status) {
    return HistoryOrderService.getStatusDescription(status);
  }

  /// Get all status list
  List<String> getAllStatusList() {
    return HistoryOrderService.getAllStatusList();
  }

  /// Get status emoji
  String getStatusEmoji(String status) {
    return HistoryOrderService.getStatusEmoji(status);
  }

  // =========================================
  // DISPOSE
  // =========================================

  @override
  void dispose() {
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');
    debugPrint('[HistoryOrderProvider] 🔌 DISPOSING');
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');

    _orderHistories.clear();
    _loadingStates.clear();
    _errors.clear();
    _orderStatuses.clear();
    _trackedOrders.clear();

    onOrderStatusChanged = null;
    onProgressReceived = null;

    debugPrint('[HistoryOrderProvider] ✅ Disposed');
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');

    super.dispose();
  }
}
