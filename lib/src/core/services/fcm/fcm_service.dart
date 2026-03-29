import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mpjnew/src/core/services/fcm/handlers/payment_notification_handler.dart';
import 'package:mpjnew/src/core/services/fcm/handlers/progres_notification_handler.dart';
import 'package:mpjnew/src/core/services/fcm/models/notification_type.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';
import 'package:mpjnew/src/features/customer/services/device_token_service.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';

import 'utils/notification_channel_manager.dart';
import 'utils/notification_helper.dart';
import 'handlers/chat_notification_handler.dart';

class FCMService {
  static final FCMService instance = FCMService._internal();
  factory FCMService() => instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  late ChatNotificationHandler _chatHandler;
  late PaymentNotificationHandler _paymentHandler;
  late ProgressNotificationHandler _progressHandler;

  String? _fcmToken;
  bool _initialized = false;
  String? _currentUserId;
  String? _activeRoomId;

  ChatProvider? _chatProvider;
  HistoryOrderProvider? _historyOrderProvider;
  PesananProvider? _pesananProvider;

  Function(ChatModel)? onChatMessageReceived;
  Function(HistoryOrderModel)? onProgressReceived;
  Function(String roomId)? onNotificationTapped;
  Function(String orderId)? onOrderNotificationTapped;
  String Function(String roomId, String senderId)? getSenderName;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _initialized;

  // =========================================
  // PROVIDER INJECTION
  // =========================================

  void setChatProvider(ChatProvider provider) {
    _chatProvider = provider;
    debugPrint('[FCM] ✅ ChatProvider injected');
    if (_initialized) _rebuildChatHandler();
  }

  void setHistoryOrderProvider(HistoryOrderProvider provider) {
    _historyOrderProvider = provider;
    debugPrint('[FCM] ✅ HistoryOrderProvider injected');
  }

  void setPesananProvider(PesananProvider provider) {
    _pesananProvider = provider;
    debugPrint('[FCM] ✅ PesananProvider injected');
  }

  void clearProviders() {
    _chatProvider = null;
    _historyOrderProvider = null;
    _pesananProvider = null;
    debugPrint('[FCM] 🗑️ Providers cleared');
  }

  // =========================================
  // INITIALIZATION
  // =========================================

  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('[FCM] ⏸️ Already initialized');
      return;
    }

    try {
      debugPrint('[FCM] 🚀 Initializing...');

      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[FCM] 📱 Permission: ${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] ❌ Permission denied');
        return;
      }

      await _initializeLocalNotifications();
      _initializeHandlers();

      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('[FCM] 🔑 Token: $_fcmToken');

      if (_fcmToken == null) {
        debugPrint('[FCM] ⚠️ Token null, retrying in 2s...');
        await Future.delayed(const Duration(seconds: 2));
        _fcmToken = await _firebaseMessaging.getToken();
        debugPrint('[FCM] 🔄 Retry token: $_fcmToken');
      }

      _setupMessageListeners();

      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        debugPrint('[FCM] 🔄 Token refreshed: $newToken');
        _fcmToken = newToken;
        if (_currentUserId != null) {
          await _sendTokenToBackend(newToken, _currentUserId!);
        }
      });

      _initialized = true;
      debugPrint('[FCM] ✅ Initialization complete');
    } catch (e, st) {
      debugPrint('[FCM] ❌ Initialization error: $e\n$st');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    await NotificationChannelManager.createAllChannels(_notificationsPlugin);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_pacific_data_jaya'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      debugPrint('[FCM] 📱 Android notif permission granted: $granted');
    }

    debugPrint('[FCM] ✅ Local notifications ready');
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    debugPrint('[FCM] 👆 Background local notif tapped: ${response.payload}');
  }

  void _initializeHandlers() {
    _chatHandler = _buildChatHandler();

    _progressHandler = ProgressNotificationHandler(
      notificationsPlugin: _notificationsPlugin,
      onProgressReceived: (progressData) {
        debugPrint('[FCM] 📊 Progress: ${progressData.noOrder}');
        _historyOrderProvider?.handleProgressFromFCM(progressData);
        onProgressReceived?.call(progressData);
      },
    );

    _paymentHandler = PaymentNotificationHandler(
      notificationsPlugin: _notificationsPlugin,
      onPaymentReceived: (pesanan) {
        _pesananProvider?.handlePaymentFromFCM(pesanan);
        debugPrint('[FCM] ✅ PesananProvider updated (payment)');
      },
    );

    debugPrint('[FCM] ✅ Handlers initialized');
  }

  // ✅ Factory method — hindari duplikasi kode antara _initializeHandlers dan _rebuildChatHandler
  ChatNotificationHandler _buildChatHandler() {
    return ChatNotificationHandler(
      notificationsPlugin: _notificationsPlugin,
      getCurrentUserId: () => _currentUserId,
      getActiveRoomId: () => _activeRoomId,

      // ✅ Signature berubah: sekarang membawa (ChatModel message, String targetStatus)
      //    targetStatus sudah ditentukan oleh ChatNotificationHandler berdasarkan
      //    perbandingan activeRoomId vs message.roomId
      onMessageReceived: (ChatModel message, String targetStatus) {
        debugPrint('[FCM] 💬 onMessageReceived: ${message.messageId} '
            'room=${message.roomId} status=$targetStatus');

        if (_chatProvider != null) {
          // message sudah di-inject targetStatus oleh ChatNotificationHandler
          // ChatProvider.handleMessageFromFCM menyimpan ke Isar dengan status ini
          _chatProvider!.handleMessageFromFCM(message);
          debugPrint('[FCM] ✅ → ChatProvider ($targetStatus)');
        } else {
          debugPrint('[FCM] ⚠️ ChatProvider null, pakai callback fallback');
          onChatMessageReceived?.call(message);
        }
      },

      getSenderName: (roomId, senderId) {
        if (_chatProvider != null) {
          return _chatProvider!.getSenderName(roomId, senderId);
        }
        return getSenderName?.call(roomId, senderId) ?? 'Pesan baru';
      },

      onUpdateMessageStatus: (messageId, roomId, newStatus) async {
        debugPrint('[FCM] 🔄 updateMessageStatus: $messageId → $newStatus');
        if (_chatProvider != null) {
          await _chatProvider!.updateMessageStatus(messageId, newStatus);
        } else {
          debugPrint('[FCM] ⚠️ ChatProvider null — skip: $messageId');
        }
      },
    );
  }

  void _rebuildChatHandler() {
    _chatHandler = _buildChatHandler();
    debugPrint('[FCM] 🔄 ChatHandler rebuilt');
  }

  // =========================================
  // MESSAGE LISTENERS
  // =========================================

  void _setupMessageListeners() {
    debugPrint('[FCM] 📡 Setting up listeners...');
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('[FCM] 🚀 App launched from terminated via notification');
        _handleMessageOpenedApp(message);
      }
    });
    debugPrint('[FCM] ✅ Listeners ready');
  }

  // =========================================
  // FOREGROUND HANDLER
  // =========================================

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] ☀️ Foreground: ${message.messageId} | activeRoom: $_activeRoomId');

    try {
      final type = NotificationType.fromString(message.data['type']);
      debugPrint('[FCM] Type: $type');

      switch (type) {
        case NotificationType.chat:
          // ✅ ChatNotificationHandler menentukan read/received
          //    berdasarkan _activeRoomId vs roomId di payload
          await _chatHandler.handleForegroundMessage(message);
          break;
        case NotificationType.payment:
          await _paymentHandler.handleMessage(message);
          break;
        case NotificationType.progress:
          await _progressHandler.handleMessage(message);
          break;
        case NotificationType.like:
        case NotificationType.review:
          debugPrint('[FCM] ℹ️ $type — not handled in customer app');
          break;
        default:
          debugPrint('[FCM] ⚠️ Unknown type: ${message.data['type']}');
      }
    } catch (e, st) {
      debugPrint('[FCM] ❌ Foreground error: $e\n$st');
    }
  }

  // =========================================
  // NOTIFICATION TAP
  // =========================================

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] 👆 Notification tap (background/terminated)');
    final type = NotificationType.fromString(message.data['type']);
    final detail = NotificationHelper.parseDetail(message.data['detail']);

    switch (type) {
      case NotificationType.chat:
        final roomId = detail['room_id'] as String?;
        if (roomId != null) onNotificationTapped?.call(roomId);
        break;
      case NotificationType.progress:
        final orderId = detail['no_order'] as String?;
        if (orderId != null) onOrderNotificationTapped?.call(orderId);
        break;
      default:
        debugPrint('[FCM] ℹ️ Tap ignored for type: $type');
    }
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    debugPrint('[FCM] 👆 Local notification tapped: ${response.payload}');
    final payload = NotificationHelper.parsePayload(response.payload);
    if (payload == null) return;

    final type = NotificationType.fromString(payload['type']);
    switch (type) {
      case NotificationType.chat:
        final roomId = payload['roomId'] as String?;
        if (roomId != null) onNotificationTapped?.call(roomId);
        break;
      case NotificationType.progress:
        final orderId = payload['orderId'] as String?;
        if (orderId != null) onOrderNotificationTapped?.call(orderId);
        break;
      default:
        break;
    }
  }

  // =========================================
  // TOKEN MANAGEMENT
  // =========================================

  Future<void> registerToken(String userId) async {
    try {
      debugPrint('[FCM] 📤 Registering token for: $userId');
      _currentUserId = userId;
      _fcmToken ??= await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        await _sendTokenToBackend(_fcmToken!, userId);
        debugPrint('[FCM] ✅ Token registered: ${_fcmToken!.substring(0, 20)}...');
      } else {
        debugPrint('[FCM] ⚠️ FCM token null saat registerToken');
      }
    } catch (e) {
      debugPrint('[FCM] ❌ registerToken error: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token, String userId) async {
    try {
      final deviceTokenService = DeviceTokenService();
      await deviceTokenService.addDeviceToken(userId, token);
      debugPrint('[FCM] ✅ Token sent to backend');
    } catch (e) {
      debugPrint('[FCM] ❌ _sendTokenToBackend error: $e');
    }
  }

  Future<void> unregisterToken(String userId) async {
    try {
      debugPrint('[FCM] 📤 Unregistering token for: $userId');
      final token = _fcmToken ?? await _firebaseMessaging.getToken();
      if (token != null) {
        final deviceTokenService = DeviceTokenService();
        await deviceTokenService.removeDeviceToken(userId, token);
        debugPrint('[FCM] ✅ Token unregistered');
      }
      _currentUserId = null;
      _fcmToken = null;
    } catch (e) {
      debugPrint('[FCM] ❌ unregisterToken error: $e');
    }
  }

  // =========================================
  // ACTIVE ROOM
  // ✅ Kunci dari logika read/received
  // =========================================

  /// Set room yang sedang aktif dibuka user.
  ///
  /// Dipanggil dari:
  ///   - RoomChatPage._initializeChat()  → setActiveRoom(roomId)
  ///   - RoomChatPage.dispose()          → setActiveRoom(null)
  ///   - ChatListPage (via disposeRoom)  → setActiveRoom(null)
  ///
  /// Efek langsung pada FCM yang masuk:
  ///   - roomId SAMA → targetStatus='read', tidak tampilkan notif lokal
  ///   - roomId BEDA atau null → targetStatus='received', tampilkan notif lokal
  void setActiveRoom(String? roomId) {
    if (_activeRoomId == roomId) return;
    _activeRoomId = roomId;
    debugPrint('[FCM] 🏠 Active room: ${roomId ?? "(none)"}');
  }

  // =========================================
  // UTILITIES
  // =========================================

  void clearMessagesForSender(String senderId) {
    _chatHandler.clearMessagesForSender(senderId);
  }

  void clearAllMessageGroups() {
    _chatHandler.clearAllMessageGroups();
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('[FCM] ✅ Subscribed: $topic');
    } catch (e) {
      debugPrint('[FCM] ❌ subscribeToTopic error: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('[FCM] ✅ Unsubscribed: $topic');
    } catch (e) {
      debugPrint('[FCM] ❌ unsubscribeFromTopic error: $e');
    }
  }

  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      debugPrint('[FCM] ✅ Token deleted');
    } catch (e) {
      debugPrint('[FCM] ❌ deleteToken error: $e');
    }
  }

  void dispose() {
    onChatMessageReceived = null;
    onProgressReceived = null;
    onNotificationTapped = null;
    onOrderNotificationTapped = null;
    getSenderName = null;
    _currentUserId = null;
    _activeRoomId = null;
    clearProviders();
    debugPrint('[FCM] 🗑️ Disposed');
  }
}