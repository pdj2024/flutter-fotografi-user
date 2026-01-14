import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';

/// Provider untuk mengelola state history order dengan SignalR standalone
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

  bool _isInitialized = false;
  bool _isConnected = false;
  String? _connectionError;

  // 🔧 Flag untuk mencegah notifikasi saat build
  bool _isBuildingWidget = false;

  // =========================================
  // GETTERS
  // =========================================

  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  String? get connectionError => _connectionError;

  /// Get history untuk order tertentu
  List<HistoryOrderModel> getHistoryForOrder(String noOrder) {
    debugPrint('[HistoryOrderProvider] 🔍 Getting history for order: $noOrder');
    final history = _orderHistories[noOrder] ?? [];
    debugPrint(
        '[HistoryOrderProvider] 📊 Found ${history.length} history items');
    return history;
  }

  /// Get loading state untuk order tertentu
  bool isLoadingOrder(String noOrder) {
    final isLoading = _loadingStates[noOrder] ?? false;
    debugPrint(
        '[HistoryOrderProvider] ⏳ Loading state for $noOrder: $isLoading');
    return isLoading;
  }

  /// Get error untuk order tertentu
  String? getErrorForOrder(String noOrder) {
    return _errors[noOrder];
  }

  /// Get current status untuk order tertentu
  String? getCurrentStatus(String noOrder) {
    return _orderStatuses[noOrder];
  }

  /// Get latest progress untuk order tertentu
  HistoryOrderModel? getLatestProgress(String noOrder) {
    final histories = _orderHistories[noOrder];
    if (histories == null || histories.isEmpty) {
      debugPrint(
          '[HistoryOrderProvider] ℹ️ No history found for order: $noOrder');
      return null;
    }

    final sorted = List<HistoryOrderModel>.from(histories)
      ..sort((a, b) => b.tglProgress.compareTo(a.tglProgress));

    debugPrint(
        '[HistoryOrderProvider] 📌 Latest progress for $noOrder: ${sorted.first.statusProgressPesanan}');
    return sorted.first;
  }

  /// Get all joined orders
  Set<String> get joinedOrders => _service.joinedOrders;

  // =========================================
  // INITIALIZATION
  // =========================================

  /// Initialize provider dengan standalone connection
  Future<bool> initialize({
    required HistoryOrderServiceConfig config,
    required String userId,
  }) async {
    if (_isInitialized) {
      debugPrint('[HistoryOrderProvider] ℹ️ Already initialized');
      return _isConnected;
    }

    debugPrint(
        '[HistoryOrderProvider] 🔧 Initializing with standalone connection...');
    debugPrint('[HistoryOrderProvider] 👤 User ID: $userId');
    debugPrint('[HistoryOrderProvider] 🌐 Hub URL: ${config.hubUrl}');
    debugPrint('[HistoryOrderProvider] 👥 Role: ${config.role}');

    try {
      // Connect to SignalR
      debugPrint('[HistoryOrderProvider] 📡 Attempting SignalR connection...');
      final connected = await _service.connect(
        config: config,
        userId: userId,
      );

      if (connected) {
        debugPrint('[HistoryOrderProvider] ✅ SignalR connection established');

        // Setup callbacks
        _setupCallbacks();

        _isInitialized = true;
        _isConnected = true;
        _connectionError = null;

        debugPrint('[HistoryOrderProvider] ✅ Initialized successfully');

        // Safe notify after initialization
        _safeNotify();
        return true;
      } else {
        _connectionError = 'Failed to connect to SignalR';
        debugPrint('[HistoryOrderProvider] ❌ Connection failed');
        _safeNotify();
        return false;
      }
    } catch (e, st) {
      _connectionError = e.toString();
      debugPrint('[HistoryOrderProvider] ❌ Initialization error: $e');
      debugPrint('[HistoryOrderProvider] Stack trace: $st');
      _safeNotify();
      return false;
    }
  }

  /// Setup callbacks dari service
  void _setupCallbacks() {
    debugPrint('[HistoryOrderProvider] 🔧 Setting up SignalR callbacks...');

    // ✅ Callback untuk progress baru (ProgressPesananUpdated dari backend)
    _service.onProgressReceived = (progress) {
      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');
      debugPrint(
          '[HistoryOrderProvider] 📨 NEW PROGRESS RECEIVED FROM SIGNALR');
      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderProvider] 📦 Order: ${progress.noOrder}');
      debugPrint(
          '[HistoryOrderProvider] 🔖 Status: ${progress.statusProgressPesanan}');
      debugPrint('[HistoryOrderProvider] 📝 Deskripsi: ${progress.deskripsi}');
      debugPrint('[HistoryOrderProvider] 🆔 No ID: ${progress.noId}');
      debugPrint('[HistoryOrderProvider] 👤 Sender: ${progress.senderId}');
      debugPrint('[HistoryOrderProvider] 📅 Tanggal: ${progress.tglProgress}');
      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');

      _handleNewProgress(progress);
    };

    // ✅ Callback untuk connection state
    _service.onConnectionChanged = (isConnected, error) {
      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderProvider] 🔌 CONNECTION STATE CHANGED');
      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderProvider] Connected: $isConnected');
      if (error != null) {
        debugPrint('[HistoryOrderProvider] ⚠️ Error: $error');
      }
      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');

      _isConnected = isConnected;
      _connectionError = error;
      _safeNotify();
    };

    // ✅ Callback untuk reconnection
    _service.onReconnected = () {
      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderProvider] 🔄 RECONNECTED SUCCESSFULLY');
      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');

      _isConnected = true;
      _connectionError = null;
      _safeNotify();
    };

    debugPrint('[HistoryOrderProvider] ✅ Callbacks setup complete');
  }

  // =========================================
  // SIGNALR HANDLERS
  // =========================================

  /// Handle progress baru dari SignalR (ProgressPesananUpdated event)
  void _handleNewProgress(HistoryOrderModel progress) {
    final noOrder = progress.noOrder;

    debugPrint(
        '[HistoryOrderProvider] ───────────────────────────────────────');
    debugPrint('[HistoryOrderProvider] 📦 PROCESSING NEW PROGRESS');
    debugPrint('[HistoryOrderProvider] Order: $noOrder');
    debugPrint(
        '[HistoryOrderProvider] Current histories count: ${_orderHistories[noOrder]?.length ?? 0}');

    // Update list
    if (_orderHistories.containsKey(noOrder)) {
      // Check if already exists by noId
      final exists =
          _orderHistories[noOrder]!.any((p) => p.noId == progress.noId);

      if (!exists) {
        debugPrint(
            '[HistoryOrderProvider] ➕ Adding new progress to existing order');
        _orderHistories[noOrder]!.add(progress);

        // Sort by date descending (newest first)
        _orderHistories[noOrder]!
            .sort((a, b) => b.tglProgress.compareTo(a.tglProgress));

        debugPrint(
            '[HistoryOrderProvider] ✅ New count: ${_orderHistories[noOrder]!.length}');
      } else {
        debugPrint(
            '[HistoryOrderProvider] ℹ️ Progress already exists (No ID: ${progress.noId}), skipping');
      }
    } else {
      debugPrint('[HistoryOrderProvider] 🆕 Creating new order history list');
      _orderHistories[noOrder] = [progress];
      debugPrint('[HistoryOrderProvider] ✅ Created with 1 item');
    }

    // Update current status
    final oldStatus = _orderStatuses[noOrder];
    _orderStatuses[noOrder] = progress.statusProgressPesanan;

    if (oldStatus != null && oldStatus != progress.statusProgressPesanan) {
      debugPrint(
          '[HistoryOrderProvider] 🔄 Status changed: $oldStatus → ${progress.statusProgressPesanan}');
    } else {
      debugPrint(
          '[HistoryOrderProvider] 📊 Status set to: ${progress.statusProgressPesanan}');
    }

    debugPrint(
        '[HistoryOrderProvider] ───────────────────────────────────────');

    _safeNotify();
  }

  // =========================================
  // ORDER MANAGEMENT
  // =========================================

  /// Join order untuk real-time updates
  Future<bool> joinOrder(String noOrder) async {
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');
    debugPrint('[HistoryOrderProvider] 📦 JOINING ORDER: $noOrder');
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');

    if (!_isConnected) {
      debugPrint(
          '[HistoryOrderProvider] ⚠️ Cannot join: not connected to SignalR');
      debugPrint('[HistoryOrderProvider] Connection state: $_isConnected');
      return false;
    }

    debugPrint(
        '[HistoryOrderProvider] 📡 Sending JoinOrder request to SignalR...');
    final success = await _service.joinOrder(noOrder);

    if (success) {
      debugPrint(
          '[HistoryOrderProvider] ✅ Successfully joined order: $noOrder');
      debugPrint('[HistoryOrderProvider] 📥 Fetching initial data...');

      // Fetch initial data - gunakan silent mode untuk menghindari notifikasi ganda
      await fetchHistoryForOrder(noOrder, silent: false);

      debugPrint('[HistoryOrderProvider] ✅ Join order complete');
    } else {
      debugPrint('[HistoryOrderProvider] ❌ Failed to join order: $noOrder');
    }

    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');

    return success;
  }

  /// Join multiple orders
  Future<void> joinOrders(List<String> orderIds) async {
    debugPrint('[HistoryOrderProvider] 📦 Joining ${orderIds.length} orders');
    debugPrint('[HistoryOrderProvider] Orders: ${orderIds.join(", ")}');

    for (var i = 0; i < orderIds.length; i++) {
      debugPrint(
          '[HistoryOrderProvider] Processing order ${i + 1}/${orderIds.length}: ${orderIds[i]}');
      await joinOrder(orderIds[i]);
    }

    debugPrint('[HistoryOrderProvider] ✅ All orders joined');
  }

  /// Leave order group
  Future<void> leaveOrder(String noOrder) async {
    debugPrint('[HistoryOrderProvider] 👋 Leaving order: $noOrder');
    await _service.leaveOrder(noOrder);
    debugPrint('[HistoryOrderProvider] ✅ Left order: $noOrder');
  }

  // =========================================
  // DATA FETCHING
  // =========================================

  /// Fetch history untuk order tertentu
  Future<void> fetchHistoryForOrder(String noOrder,
      {bool silent = false}) async {
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');
    debugPrint(
        '[HistoryOrderProvider] 📥 FETCHING HISTORY FOR ORDER: $noOrder');
    debugPrint('[HistoryOrderProvider] Silent mode: $silent');
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');

    if (!silent) {
      _loadingStates[noOrder] = true;
      _errors[noOrder] = null;
      debugPrint('[HistoryOrderProvider] ⏳ Loading state set to true');

      // Safe notify - schedule after current frame
      _safeNotify();
    }

    try {
      debugPrint('[HistoryOrderProvider] 🌐 Calling API getAll...');
      debugPrint('[HistoryOrderProvider] Parameters:');
      debugPrint('[HistoryOrderProvider]   - noOrder: $noOrder');
      debugPrint('[HistoryOrderProvider]   - status: Aktif');
      debugPrint('[HistoryOrderProvider]   - orderBy: Tgl_Progress');
      debugPrint('[HistoryOrderProvider]   - orderDir: DESC');

      final histories = await _service.getAll(
        noOrder: noOrder,
        status: 'aktif',
        orderBy: 'Tgl_Progress',
        orderDir: 'DESC',
      );

      debugPrint(
          '[HistoryOrderProvider] ───────────────────────────────────────');
      debugPrint('[HistoryOrderProvider] ✅ API Response received');
      debugPrint('[HistoryOrderProvider] Total items: ${histories.length}');

      if (histories.isNotEmpty) {
        debugPrint('[HistoryOrderProvider] History items:');
        for (var i = 0; i < histories.length; i++) {
          final h = histories[i];
          debugPrint(
              '[HistoryOrderProvider]   ${i + 1}. ${h.statusProgressPesanan} - ${h.deskripsi} (${h.tglProgress})');
        }
      } else {
        debugPrint('[HistoryOrderProvider] ⚠️ No history items found');
      }

      _orderHistories[noOrder] = histories;

      // Update current status
      if (histories.isNotEmpty) {
        _orderStatuses[noOrder] = histories.first.statusProgressPesanan;
        debugPrint(
            '[HistoryOrderProvider] 📊 Current status updated to: ${histories.first.statusProgressPesanan}');
      } else {
        debugPrint(
            '[HistoryOrderProvider] ℹ️ No status to update (empty history)');
      }

      _errors[noOrder] = null;
      debugPrint('[HistoryOrderProvider] ✅ Fetch completed successfully');
    } catch (e, st) {
      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderProvider] ❌ ERROR FETCHING HISTORY');
      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderProvider] Error: $e');
      debugPrint('[HistoryOrderProvider] Stack trace: $st');
      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');

      _errors[noOrder] = e.toString();
    } finally {
      _loadingStates[noOrder] = false;
      debugPrint('[HistoryOrderProvider] ⏳ Loading state set to false');

      // Safe notify - schedule after current frame
      _safeNotify();

      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');
    }
  }

  /// Fetch histories untuk multiple orders
  Future<void> fetchHistoriesForOrders(List<String> orderIds) async {
    debugPrint(
        '[HistoryOrderProvider] 📥 Fetching histories for ${orderIds.length} orders');

    for (var i = 0; i < orderIds.length; i++) {
      debugPrint(
          '[HistoryOrderProvider] Fetching ${i + 1}/${orderIds.length}: ${orderIds[i]}');
      await fetchHistoryForOrder(orderIds[i], silent: true);
    }

    _safeNotify();
    debugPrint('[HistoryOrderProvider] ✅ All histories fetched');
  }

  // =========================================
  // CRUD OPERATIONS
  // =========================================

  /// Create progress baru
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
      debugPrint('[HistoryOrderProvider] Deskripsi: ${progress.deskripsi}');
      debugPrint('[HistoryOrderProvider] Sender: ${progress.senderId}');

      await _service.create(progress);

      // Optimistically update local state
      // Backend akan broadcast ProgressPesananUpdated yang akan trigger _handleNewProgress
      debugPrint(
          '[HistoryOrderProvider] 📦 Optimistically updating local state...');
      _handleNewProgress(progress);

      debugPrint('[HistoryOrderProvider] ✅ Progress created successfully');
      debugPrint(
          '[HistoryOrderProvider] ℹ️ Waiting for SignalR broadcast confirmation...');
      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');

      return true;
    } catch (e, st) {
      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderProvider] ❌ CREATE ERROR');
      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderProvider] Error: $e');
      debugPrint('[HistoryOrderProvider] Stack trace: $st');
      debugPrint(
          '[HistoryOrderProvider] ═══════════════════════════════════════');

      _errors[progress.noOrder] = e.toString();
      _safeNotify();
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
    debugPrint(
        '[HistoryOrderProvider] 🔧 Creating progress with status: $status');

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
      debugPrint(
          '[HistoryOrderProvider] 📝 Updating progress: ${progress.noId}');

      await _service.update(progress);

      // Update local state
      final noOrder = progress.noOrder;
      if (_orderHistories.containsKey(noOrder)) {
        final index = _orderHistories[noOrder]!
            .indexWhere((p) => p.noId == progress.noId);

        if (index != -1) {
          _orderHistories[noOrder]![index] = progress;
          debugPrint('[HistoryOrderProvider] ✅ Local state updated');
          _safeNotify();
        }
      }

      debugPrint('[HistoryOrderProvider] ✅ Progress updated successfully');
      return true;
    } catch (e) {
      debugPrint('[HistoryOrderProvider] ❌ Update error: $e');
      return false;
    }
  }

  /// Delete progress
  Future<bool> deleteProgress(String noId, String noOrder) async {
    try {
      debugPrint('[HistoryOrderProvider] 🗑️ Deleting progress: $noId');

      await _service.delete(noId);

      // Update local state
      if (_orderHistories.containsKey(noOrder)) {
        _orderHistories[noOrder]!.removeWhere((p) => p.noId == noId);
        debugPrint('[HistoryOrderProvider] ✅ Removed from local state');
        _safeNotify();
      }

      debugPrint('[HistoryOrderProvider] ✅ Progress deleted successfully');
      return true;
    } catch (e) {
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
  // RECONNECTION HANDLING
  // =========================================

  /// Reconnect to SignalR
  Future<bool> reconnect({
    required HistoryOrderServiceConfig config,
    required String userId,
  }) async {
    debugPrint('[HistoryOrderProvider] 🔄 Attempting to reconnect...');

    await _service.disconnect();
    _isInitialized = false;

    return await initialize(config: config, userId: userId);
  }

  // =========================================
  // UTILITY METHODS
  // =========================================

  /// Clear data untuk order tertentu
  void clearOrderData(String noOrder) {
    debugPrint('[HistoryOrderProvider] 🧹 Clearing data for order: $noOrder');
    _orderHistories.remove(noOrder);
    _loadingStates.remove(noOrder);
    _errors.remove(noOrder);
    _orderStatuses.remove(noOrder);
    _safeNotify();
  }

  /// Clear semua data
  void clearAllData() {
    debugPrint('[HistoryOrderProvider] 🧹 Clearing all order data');
    _orderHistories.clear();
    _loadingStates.clear();
    _errors.clear();
    _orderStatuses.clear();
    _safeNotify();
  }

  /// Get status description
  String getStatusDescription(String status) {
    return HistoryOrderService.getStatusDescription(status);
  }

  /// Get all status list
  List<String> getAllStatusList() {
    return HistoryOrderService.getAllStatusList();
  }

  // =========================================
  // SAFE NOTIFICATION
  // =========================================

  /// Notify listeners dengan aman (mencegah error saat build)
  void _safeNotify() {
    if (_isBuildingWidget) {
      debugPrint(
          '[HistoryOrderProvider] ⚠️ Skipping notify during widget build');
      return;
    }

    // Schedule notification setelah frame selesai
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isBuildingWidget) {
        try {
          notifyListeners();
          debugPrint('[HistoryOrderProvider] 🔔 Listeners notified');
        } catch (e) {
          debugPrint('[HistoryOrderProvider] ⚠️ Error notifying listeners: $e');
        }
      }
    });
  }

  /// Set build flag (panggil sebelum build dimulai)
  void setBuildingWidget(bool isBuilding) {
    _isBuildingWidget = isBuilding;
  }

  // =========================================
  // DISPOSE
  // =========================================

  @override
  void dispose() {
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');
    debugPrint('[HistoryOrderProvider] 🔌 DISPOSING PROVIDER');
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');

    _service.dispose();
    _orderHistories.clear();
    _loadingStates.clear();
    _errors.clear();
    _orderStatuses.clear();

    debugPrint('[HistoryOrderProvider] ✅ Provider disposed');
    debugPrint(
        '[HistoryOrderProvider] ═══════════════════════════════════════');

    super.dispose();
  }
}
