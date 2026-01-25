import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/core/services/auth_service_instance.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';

/// ✅ IMPROVED: HistoryOrderService dengan notifikasi yang berfungsi
class HistoryOrderServiceConfig {
  final String hubUrl;
  final String role;
  final Future<String?> Function() getToken;
  final int requestTimeout;
  final List<int> retryDelays;

  const HistoryOrderServiceConfig({
    required this.hubUrl,
    required this.role,
    required this.getToken,
    this.requestTimeout = 15000,
    this.retryDelays = const [1000, 2000, 5000, 10000, 30000],
  });
}

class HistoryOrderService {
  final String entity = 'Orderprogress';
  final String controller = 'orderprogress';

  final ApiClient _client = apiClient;

  // ✅ Notification plugin
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;

  // ✅ Notification settings
  String? _activeOrderId; // Order yang sedang dibuka user
  bool _showNotifications = true;

  // SignalR Connection
  HubConnection? _hubConnection;
  HistoryOrderServiceConfig? _config;
  String _currentUserId = '';
  bool _isConnecting = false;

  final Set<String> _joinedOrders = {};

  // Callbacks
  Function(HistoryOrderModel progress)? onProgressReceived;
  Function(bool isConnected, String? error)? onConnectionChanged;
  Function()? onReconnected;

  // Getters
  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;
  bool get isConnecting => _isConnecting;
  String get currentUserId => _currentUserId;
  Set<String> get joinedOrders => Set.unmodifiable(_joinedOrders);

  // =========================================
  // ✅ NOTIFICATION INITIALIZATION
  // =========================================

  /// Initialize notifications (call this early, e.g., in splash screen)
  Future<void> initNotifications() async {
    if (_notificationsInitialized) {
      debugPrint('[HistoryOrderService] ℹ️ Notifications already initialized');
      return;
    }

    try {
      debugPrint('[HistoryOrderService] 🔔 Initializing notifications...');

      // ✅ STEP 1: Request permission (Android 13+)
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.notification.request();

        debugPrint('[HistoryOrderService] 📱 Permission status: $status');

        if (status.isDenied || status.isPermanentlyDenied) {
          debugPrint('[HistoryOrderService] ❌ Permission denied');
          return;
        }

        debugPrint('[HistoryOrderService] ✅ Permission granted');
      }

      // ✅ STEP 2: Create notification channel
      await _createNotificationChannel();

      // ✅ STEP 3: Initialize plugin
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // iOS permission
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }

      _notificationsInitialized = true;
      debugPrint('[HistoryOrderService] ✅ Notifications initialized');
    } catch (e) {
      debugPrint('[HistoryOrderService] ❌ Notification init error: $e');
    }
  }

  /// Create notification channel (Android)
  Future<void> _createNotificationChannel() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'history_order_channel',
      'Pembaruan Pesanan',
      description: 'Notifikasi untuk pembaruan status pesanan Anda',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('[HistoryOrderService] ✅ Notification channel created');
  }

  // =========================================
  // ✅ SHOW NOTIFICATION (IMPROVED)
  // =========================================

  /// Set active order (suppress notifications for this order)
  void setActiveOrder(String? orderId) {
    if (_activeOrderId != orderId) {
      _activeOrderId = orderId;
      debugPrint(
          '[HistoryOrderService] 📱 Active order set: ${orderId ?? "none"}');

      if (orderId != null) {
        debugPrint(
            '[HistoryOrderService] 🔕 Notifications suppressed for: $orderId');
      } else {
        debugPrint(
            '[HistoryOrderService] 🔔 Notifications enabled for all orders');
      }
    }
  }

  /// Enable/disable notifications globally
  void setNotificationsEnabled(bool enabled) {
    _showNotifications = enabled;
    debugPrint(
        '[HistoryOrderService] 🔔 Notifications: ${enabled ? 'ENABLED' : 'DISABLED'}');
  }

  // =========================================
  // CONNECTION
  // =========================================

  Future<bool> connect({
    required HistoryOrderServiceConfig config,
    required String userId,
  }) async {
    debugPrint('[HistoryOrderService] ═══════════════════════════════════════');
    debugPrint('[HistoryOrderService] 🔌 CONNECTING TO SIGNALR');
    debugPrint('[HistoryOrderService] ═══════════════════════════════════════');

    if (_isConnecting) {
      debugPrint('[HistoryOrderService] ⏸️ Already connecting');
      return false;
    }

    if (isConnected && _currentUserId == userId) {
      debugPrint('[HistoryOrderService] ✅ Already connected for user $userId');
      return true;
    }

    _isConnecting = true;
    _config = config;
    _currentUserId = userId;

    try {
      debugPrint('[HistoryOrderService] 👤 User ID: $userId');
      debugPrint('[HistoryOrderService] 🌐 Hub URL: ${config.hubUrl}');

      final token = await authService.getIdToken();
      if (token == null || token.isEmpty) {
        debugPrint('[HistoryOrderService] ❌ No token available');
        return false;
      }

      if (_hubConnection != null) {
        await disconnect();
      }

      final fullUrl = '${config.hubUrl}?role=${config.role}';

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            fullUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token,
              requestTimeout: config.requestTimeout,
            ),
          )
          .withAutomaticReconnect(retryDelays: config.retryDelays)
          .build();

      _setupListeners();

      await _hubConnection!.start();

      debugPrint('[HistoryOrderService] ✅ CONNECTED');
      debugPrint(
          '[HistoryOrderService] Connection ID: ${_hubConnection!.connectionId}');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');

      onConnectionChanged?.call(true, null);

      return true;
    } catch (e, st) {
      debugPrint('[HistoryOrderService] ❌ CONNECTION FAILED: $e');
      debugPrint('Stack: $st');
      onConnectionChanged?.call(false, e.toString());
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> disconnect() async {
    try {
      if (_hubConnection != null) {
        debugPrint('[HistoryOrderService] 🔌 Disconnecting...');
        await _hubConnection!.stop();
        debugPrint('[HistoryOrderService] ✅ Disconnected');
      }
    } catch (e) {
      debugPrint('[HistoryOrderService] ❌ Disconnect error: $e');
    } finally {
      _hubConnection = null;
      _joinedOrders.clear();
      onConnectionChanged?.call(false, null);
    }
  }

  // =========================================
  // EVENT LISTENERS
  // =========================================

  void _setupListeners() {
    if (_hubConnection == null) return;

    debugPrint('[HistoryOrderService] 🎧 Setting up SignalR listeners...');

    _hubConnection!.on('ProgressPesananUpdated', (args) {
      debugPrint('[HistoryOrderService] 📨 ProgressPesananUpdated received');

      if (args == null || args.isEmpty) {
        debugPrint('[HistoryOrderService] ⚠️ Empty args');
        return;
      }

      _handleProgressReceived(args);
    });

    _hubConnection!.onclose(({error}) {
      debugPrint('[HistoryOrderService] 🔌 Connection closed');
      if (error != null) debugPrint('   Error: $error');
      onConnectionChanged?.call(false, error?.toString());
    });

    _hubConnection!.onreconnecting(({error}) {
      debugPrint('[HistoryOrderService] 🔄 Reconnecting...');
      if (error != null) debugPrint('   Reason: $error');
      onConnectionChanged?.call(false, 'reconnecting');
    });

    _hubConnection!.onreconnected(({connectionId}) async {
      debugPrint('[HistoryOrderService] ✅ Reconnected');
      debugPrint('   New ID: $connectionId');
      onConnectionChanged?.call(true, null);
      await _rejoinAfterReconnect();
      onReconnected?.call();
    });

    debugPrint('[HistoryOrderService] ✅ Listeners setup complete');
  }

  // =========================================
  // ✅ HANDLE PROGRESS (WITH NOTIFICATION)
  // =========================================

  // Tambahkan di bagian _handleProgressReceived, setelah callback

  void _handleProgressReceived(List<Object?> args) {
    try {
      debugPrint(
          '[HistoryOrderService] ───────────────────────────────────────');
      debugPrint('[HistoryOrderService] 🔍 PARSING PROGRESS DATA');

      final raw = args[0];
      final data = _parseData(raw);

      // Map dari C# backend ke Dart model
      final progress = HistoryOrderModel(
        noId: data['no_Id']?.toString() ?? '',
        noOrder: data['no_Order']?.toString() ?? '',
        tglProgress: _parseDateTime(data['tgl_Progress']),
        deskripsi: data['deskripsi']?.toString() ?? '',
        senderId: data['sender_Id']?.toString() ?? '',
        tipeUser: data['tipe_User']?.toString() ?? '',
        namaSender: '',
        status: data['status']?.toString() ?? '',
        statusProgressPesanan: data['status_Progress']?.toString() ?? '',
      );

      debugPrint('[HistoryOrderService] ✅ PROGRESS MODEL CREATED');
      debugPrint('[HistoryOrderService] No Order: ${progress.noOrder}');
      debugPrint(
          '[HistoryOrderService] Status: ${progress.statusProgressPesanan}');

      // ✅ Call callback FIRST
      debugPrint(
          '[HistoryOrderService] 📢 Calling onProgressReceived callback...');
      onProgressReceived?.call(progress);

      // ✅ THEN show notification
      debugPrint(
          '[HistoryOrderService] 🔔 Checking if should show notification...');
      _showMessageNotification(progress);

      debugPrint('[HistoryOrderService] ✅ Callback and notification handled');
    } catch (e, st) {
      debugPrint('[HistoryOrderService] ❌ PARSE PROGRESS ERROR');
      debugPrint('[HistoryOrderService] Error: $e');
      debugPrint('[HistoryOrderService] Stack: $st');
    }
  }

// ✅ IMPROVED: Show notification untuk history order
  Future<void> _showMessageNotification(HistoryOrderModel historyOrder) async {
    try {
      // Check if notifications initialized
      if (!_notificationsInitialized) {
        debugPrint(
            '[HistoryOrderService] ⚠️ Notifications not initialized, initializing now...');
        await initNotifications();

        if (!_notificationsInitialized) {
          debugPrint(
              '[HistoryOrderService] ❌ Failed to initialize notifications');
          return;
        }
      }

      // Don't show if notifications disabled
      if (!_showNotifications) {
        debugPrint('[HistoryOrderService] 🔕 Notifications disabled globally');
        return;
      }

      // Don't show own updates (optional - bisa dikomentari jika mau notif semua)
      if (historyOrder.senderId == _currentUserId) {
        debugPrint('[HistoryOrderService] 🔕 Skip notification (own update)');
        return;
      }

      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] 🔔 SHOWING NOTIFICATION');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');

      // ✅ Build notification title based on status
      String notificationTitle =
          _getNotificationTitle(historyOrder.statusProgressPesanan);
      debugPrint('[HistoryOrderService] 📌 Title: $notificationTitle');

      // ✅ Build notification body
      String notificationBody = historyOrder.deskripsi.isNotEmpty
          ? historyOrder.deskripsi
          : HistoryOrderService.getStatusDescription(
              historyOrder.statusProgressPesanan);

      // Truncate if too long
      if (notificationBody.length > 100) {
        notificationBody = '${notificationBody.substring(0, 97)}...';
      }

      debugPrint('[HistoryOrderService] 📝 Body: $notificationBody');
      debugPrint('[HistoryOrderService] 📦 Order: ${historyOrder.noOrder}');

      // ✅ Notification details
      final androidDetails = AndroidNotificationDetails(
        'history_order_channel', // Must match channel ID
        'Progress Pesanan',
        channelDescription: 'Notifikasi untuk update progress pesanan',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: 'ic_stat_pacific_data_jaya', // Pastikan icon ini ada
        enableVibration: true,
        playSound: true,
        // ✅ Add actions for user interaction
        styleInformation: BigTextStyleInformation(
          notificationBody,
          contentTitle: notificationTitle,
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        subtitle: 'Update Pesanan',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // ✅ Generate unique notification ID from order number
      final notificationId = historyOrder.noOrder.hashCode;

      // Show notification
      await _notificationsPlugin.show(
        notificationId,
        notificationTitle,
        notificationBody,
        notificationDetails,
        payload: historyOrder.noOrder, // For navigation when tapped
      );

      debugPrint('[HistoryOrderService] ✅ Notification shown successfully');
      debugPrint('[HistoryOrderService] ID: $notificationId');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
    } catch (e, st) {
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] ❌ SHOW NOTIFICATION ERROR');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] Error: $e');
      debugPrint('[HistoryOrderService] Stack: $st');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
    }
  }

// ✅ NEW: Helper to get notification title based on status
  String _getNotificationTitle(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu bayar':
        return '⏳ Menunggu Pembayaran';
      case 'persiapan':
        return '📋 Sedang Dipersiapkan';
      case 'proses':
        return '⚙️ Sedang Dikerjakan';
      case 'review':
        return '👀 Menunggu Review';
      case 'revisi':
        return '🔄 Sedang Direvisi';
      case 'selesai':
        return '✅ Pesanan Selesai';
      case 'dibatalkan':
        return '❌ Pesanan Dibatalkan';
      default:
        return '📦 Update Pesanan';
    }
  }

// ✅ IMPROVED: Create notification channel with proper config
  Future<void> createNotificationChannel() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'history_order_channel', // ✅ ID yang sama dengan di androidDetails
      'Progress Pesanan',
      description: 'Notifikasi untuk update progress pesanan',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint(
        '[HistoryOrderService] ✅ Notification channel created: ${channel.id}');
  }

// ✅ IMPROVED: Handle notification tap to navigate to order
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[HistoryOrderService] ═══════════════════════════════════════');
    debugPrint('[HistoryOrderService] 🔔 NOTIFICATION TAPPED');
    debugPrint('[HistoryOrderService] ═══════════════════════════════════════');

    final payload = response.payload;
    debugPrint('[HistoryOrderService] Payload: $payload');

    if (payload != null && payload.isNotEmpty) {
      debugPrint('[HistoryOrderService] 📱 Order ID: $payload');

      // TODO: Add navigation logic here
      // Example:
      // navigatorKey.currentState?.pushNamed(
      //   '/order-detail',
      //   arguments: payload,
      // );

      debugPrint('[HistoryOrderService] ℹ️ Navigation not implemented yet');
      debugPrint('[HistoryOrderService] 💡 Implement navigation in your app');
    }

    debugPrint('[HistoryOrderService] ═══════════════════════════════════════');
  }

  // =========================================
  // ORDER GROUP MANAGEMENT
  // =========================================

  Future<bool> joinOrder(String noOrder) async {
    if (!isConnected || noOrder.isEmpty) return false;
    if (_joinedOrders.contains(noOrder)) return true;

    try {
      debugPrint('[HistoryOrderService] 📦 Joining order: $noOrder');

      await _hubConnection!.invoke('JoinOrder', args: [noOrder]);
      _joinedOrders.add(noOrder);

      debugPrint('[HistoryOrderService] ✅ Joined order: $noOrder');
      return true;
    } catch (e) {
      debugPrint('[HistoryOrderService] ❌ Join error: $e');
      return false;
    }
  }

  Future<void> joinOrders(List<String> orderIds) async {
    for (final orderId in orderIds) {
      if (orderId.isNotEmpty) {
        await joinOrder(orderId);
      }
    }
  }

  Future<void> leaveOrder(String noOrder) async {
    if (!isConnected) return;

    try {
      await _hubConnection!.invoke('LeaveOrder', args: [noOrder]);
      _joinedOrders.remove(noOrder);
      debugPrint('[HistoryOrderService] ✅ Left order: $noOrder');
    } catch (e) {
      debugPrint('[HistoryOrderService] ❌ Leave error: $e');
    }
  }

  Future<void> _rejoinAfterReconnect() async {
    final orders = List<String>.from(_joinedOrders);
    _joinedOrders.clear();

    debugPrint('[HistoryOrderService] 🔄 Rejoining ${orders.length} orders...');

    for (final orderId in orders) {
      await joinOrder(orderId);
    }
  }

  // =========================================
  // API METHODS (unchanged)
  // =========================================

  Future<List<HistoryOrderModel>> getAll({
    String? noid,
    String? senderId,
    String? deskripsi,
    String? noOrder,
    String? status,
    String? orderBy,
    String? orderDir,
  }) async {
    try {
      final queryParams = {
        if (noid != null) 'no_id': noid,
        if (senderId != null) 'sender_id': senderId,
        if (status != null) 'status': status,
        if (noOrder != null) 'no_order': noOrder,
        if (deskripsi != null) 'deskripsi': deskripsi,
        if (orderBy != null) 'orderby': orderBy,
        if (orderDir != null) 'orderdir': orderDir,
      };

      final response = await _client.get(
        '/$controller/getAll',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['Data'];

        if (data is List) {
          return (data as List)
              .map((item) {
                try {
                  return HistoryOrderModel.fromJson(item);
                } catch (e) {
                  return null;
                }
              })
              .whereType<HistoryOrderModel>()
              .toList();
        }
        return [];
      } else if (response.statusCode == 204) {
        return [];
      } else {
        throw Exception('Failed to load $entity (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error loading $entity: $e');
    }
  }

  Future<void> create(HistoryOrderModel model) async {
    final response = await apiClient.post(
      '/$controller/create',
      body: jsonEncode(model.toJsonCreate()),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create progress');
    }
  }

  Future<void> update(HistoryOrderModel model) async {
    final response = await apiClient.put(
      '/$controller/update',
      queryParameters: {'no_id': model.noId},
      body: jsonEncode(model.toJson()),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update $entity');
    }
  }

  Future<void> delete(String noId) async {
    final response = await apiClient.delete(
      '/$controller/delete',
      queryParameters: {'no_id': noId},
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete $entity');
    }
  }

  // =========================================
  // UTILITIES
  // =========================================

  Map<String, dynamic> _parseData(dynamic obj) {
    if (obj is Map) {
      return obj.map((k, v) => MapEntry(k.toString(), v));
    }
    if (obj is String) {
      try {
        final decoded = jsonDecode(obj);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } catch (e) {
        // Ignore
      }
    }
    return {};
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value.toLocal();
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (e) {
      return DateTime.now();
    }
  }

  void dispose() {
    debugPrint('[HistoryOrderService] 🔌 Disposing...');
    _hubConnection?.stop();
    _hubConnection = null;
    _joinedOrders.clear();
    onProgressReceived = null;
    onConnectionChanged = null;
    onReconnected = null;
  }

  // =========================================
  // HELPER METHODS (unchanged)
  // =========================================

  static HistoryOrderModel createMenungguPembayaran({
    required String noOrder,
    required String senderId,
  }) {
    return HistoryOrderModel(
      noId: '',
      noOrder: noOrder,
      tglProgress: DateTime.now(),
      deskripsi: 'Pesanan berhasil dibuat',
      senderId: senderId,
      tipeUser: 'Customer',
      namaSender: '',
      status: 'Aktif',
      statusProgressPesanan: 'menunggu bayar',
    );
  }

  static HistoryOrderModel createPersiapan({
    required String noOrder,
    required String senderId,
  }) {
    return HistoryOrderModel(
      noId: '',
      noOrder: noOrder,
      tglProgress: DateTime.now(),
      deskripsi: 'Pembayaran diterima',
      senderId: senderId,
      tipeUser: 'Customer',
      namaSender: '',
      status: 'Aktif',
      statusProgressPesanan: 'persiapan',
    );
  }

  static HistoryOrderModel createProses({
    required String noOrder,
    required String senderId,
  }) {
    return HistoryOrderModel(
      noId: '',
      noOrder: noOrder,
      tglProgress: DateTime.now(),
      deskripsi: 'Pesanan sedang dikerjakan oleh vendor',
      senderId: senderId,
      tipeUser: 'Vendor',
      namaSender: '',
      status: 'Aktif',
      statusProgressPesanan: 'proses',
    );
  }

  static HistoryOrderModel createReview({
    required String noOrder,
    required String senderId,
  }) {
    return HistoryOrderModel(
      noId: '',
      noOrder: noOrder,
      tglProgress: DateTime.now(),
      deskripsi: 'Pesanan selesai dikerjakan, mohon berikan ulasan',
      senderId: senderId,
      tipeUser: 'Customer',
      namaSender: '',
      status: 'Aktif',
      statusProgressPesanan: 'review',
    );
  }

  static HistoryOrderModel createRevisi({
    required String noOrder,
    required String senderId,
  }) {
    return HistoryOrderModel(
      noId: '',
      noOrder: noOrder,
      tglProgress: DateTime.now(),
      deskripsi: 'Vendor sedang melakukan revisi',
      senderId: senderId,
      tipeUser: 'Vendor',
      namaSender: '',
      status: 'Aktif',
      statusProgressPesanan: 'revisi',
    );
  }

  static HistoryOrderModel createSelesai({
    required String noOrder,
    required String senderId,
  }) {
    return HistoryOrderModel(
      noId: '',
      noOrder: noOrder,
      tglProgress: DateTime.now(),
      deskripsi: 'Pesanan telah selesai',
      senderId: senderId,
      tipeUser: 'Customer',
      namaSender: '',
      status: 'Aktif',
      statusProgressPesanan: 'selesai',
    );
  }

  static HistoryOrderModel createDibatalkan({
    required String noOrder,
    required String senderId,
    String? customDeskripsi,
  }) {
    return HistoryOrderModel(
      noId: '',
      noOrder: noOrder,
      tglProgress: DateTime.now(),
      deskripsi: customDeskripsi ?? 'Pesanan telah dibatalkan',
      senderId: senderId,
      tipeUser: 'Customer',
      namaSender: '',
      status: 'Aktif',
      statusProgressPesanan: 'dibatalkan',
    );
  }

  static List<String> getAllStatusList() {
    return [
      'menunggu bayar',
      'persiapan',
      'proses',
      'review',
      'revisi',
      'selesai',
      'dibatalkan',
    ];
  }

  static String getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu bayar':
        return 'Pesanan berhasil dibuat. Silakan selesaikan pembayaran.';
      case 'persiapan':
        return 'Pembayaran diterima. Vendor sedang menyiapkan pesanan Anda.';
      case 'proses':
        return 'Pesanan sedang dikerjakan oleh vendor.';
      case 'review':
        return 'Pesanan selesai dikerjakan. Mohon berikan ulasan Anda.';
      case 'revisi':
        return 'Vendor sedang melakukan revisi sesuai permintaan Anda.';
      case 'selesai':
        return 'Pesanan telah selesai. Terima kasih!';
      case 'dibatalkan':
        return 'Pesanan telah dibatalkan.';
      default:
        return 'Status tidak diketahui';
    }
  }

  static String getTipeUserByStatus(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu bayar':
      case 'review':
      case 'selesai':
        return 'Customer';
      case 'persiapan':
      case 'proses':
      case 'revisi':
        return 'Vendor';
      case 'dibatalkan':
        return 'Customer';
      default:
        return 'Unknown';
    }
  }

  static HistoryOrderModel createHistory({
    required String noOrder,
    required String senderId,
    required String statusProgressPesanan,
    String? customDeskripsi,
    String? customTipeUser,
  }) {
    return HistoryOrderModel(
      noId: '',
      noOrder: noOrder,
      tglProgress: DateTime.now(),
      deskripsi: customDeskripsi ?? getStatusDescription(statusProgressPesanan),
      senderId: senderId,
      tipeUser: customTipeUser ?? getTipeUserByStatus(statusProgressPesanan),
      namaSender: '',
      status: 'Aktif',
      statusProgressPesanan: statusProgressPesanan,
    );
  }
}
