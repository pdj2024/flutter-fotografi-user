import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mpjnew/src/core/services/fcm/handlers/payment_notification_handler.dart';
import 'package:mpjnew/src/core/services/fcm/handlers/progres_notification_handler.dart';
import 'package:mpjnew/src/core/services/fcm/models/notification_type.dart';
import 'package:mpjnew/src/data/isar/service/chat_storage_service.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';
import 'package:mpjnew/src/features/customer/services/device_token_service.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';

import 'utils/notification_channel_manager.dart';
import 'utils/notification_helper.dart';
import 'handlers/chat_notification_handler.dart';

// ─────────────────────────────────────────────────────────────────
// TOP-LEVEL BACKGROUND HANDLER
//
// Wajib top-level (bukan method) karena dijalankan di background isolate.
// Daftarkan di main.dart:
//   FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
//
// Background isolate TIDAK bisa akses Provider/Isar secara langsung.
// Chat message → ChatStorageService.enqueueBackgroundMessage()
//   → SharedPreferences queue → diproses saat app resume via drainBackgroundQueue()
// ─────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  debugPrint('[FCM] 🌙 Background: ${message.messageId}');

  try {
    final type = message.data['type']?.toString() ?? '';

    if (type == 'chat') {
      // Enqueue ke SharedPreferences — aman dari background isolate
      await ChatStorageService.enqueueBackgroundMessage(message);

      // Tampilkan notifikasi lokal (opsional, bisa juga pakai FCM notification payload)
      await _showBackgroundChatNotification(message);
    }

    // Tipe lain (progress, payment) tidak dihandle di background
    // karena butuh Provider yang tidak tersedia di isolate
  } catch (e) {
    debugPrint('[FCM] ❌ Background error: $e');
  }
}

Future<void> _showBackgroundChatNotification(RemoteMessage message) async {
  try {
    final detail = NotificationHelper.parseDetail(message.data['detail']);
    if (detail.isEmpty) return;

    final senderId = detail['sender_id']?.toString() ?? '';
    final messageText = detail['message']?.toString() ?? 'Pesan baru';
    final senderName = detail['sender_name']?.toString() ?? 'Pesan baru';
    final roomId = detail['room_id']?.toString() ?? '';

    if (roomId.isEmpty || senderId.isEmpty) return;

    final plugin = FlutterLocalNotificationsPlugin();
    await NotificationChannelManager.createAllChannels(plugin);

    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat',
      channelDescription: 'Notifikasi pesan chat',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await plugin.show(
      roomId.hashCode,
      senderName,
      messageText,
      details,
      payload: jsonEncode({'type': 'chat', 'roomId': roomId}),
    );
  } catch (e) {
    debugPrint('[FCM] ⚠️ _showBackgroundChatNotification: $e');
  }
}

// ─────────────────────────────────────────────────────────────────
// FCM SERVICE — Singleton Orchestrator
//
// Menghubungkan Firebase Messaging dengan:
//   - ChatProvider (Isar-based, offline-first)
//   - HistoryOrderProvider
//   - PesananProvider
//
//    Semua chat message lewat ChatNotificationHandler → ChatProvider → Isar.
// ─────────────────────────────────────────────────────────────────
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

  // ── Provider references ───────────────────────────────────────
  ChatProvider? _chatProvider;
  HistoryOrderProvider? _historyOrderProvider;
  PesananProvider? _pesananProvider;

  // ── Callbacks untuk navigasi ──────────────────────────────────
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
        debugPrint('[FCM] ⚠️ Token null, retrying...');
        await Future.delayed(const Duration(seconds: 2));
        _fcmToken = await _firebaseMessaging.getToken();
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
    );

    debugPrint('[FCM] ✅ Local notifications ready');
  }

  void _initializeHandlers() {
    _chatHandler = ChatNotificationHandler(
      notificationsPlugin: _notificationsPlugin,
      getCurrentUserId: () => _currentUserId,
      getActiveRoomId: () => _activeRoomId,
      onMessageReceived: (message) {
        // ✅ SATU JALUR: selalu lewat ChatProvider → ChatStorageService → Isar
        // Tidak ada FcmChatProvider lagi
        if (_chatProvider != null) {
          _chatProvider!.handleMessageFromFCM(message);
          debugPrint('[FCM] ✅ Chat → ChatProvider.handleMessageFromFCM');
        } else {
          // Fallback jika ChatProvider belum diinjeksi
          debugPrint('[FCM] ⚠️ ChatProvider belum diinjeksi, pakai callback');
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
        // ✅ Update status pesan via ChatProvider → ChatSyncService
        // Ini penting agar vendor bisa lihat status received/read
        debugPrint('[FCM] 🔄 Update status: $messageId → $newStatus');
        if (_chatProvider != null) {
          await _chatProvider!.updateMessageStatus(messageId, newStatus);
        } else {
          debugPrint('[FCM] ⚠️ ChatProvider null, skip status update');
        }
      },
    );

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

  void _rebuildChatHandler() {
    _chatHandler = ChatNotificationHandler(
      notificationsPlugin: _notificationsPlugin,
      getCurrentUserId: () => _currentUserId,
      getActiveRoomId: () => _activeRoomId,
      onMessageReceived: (message) {
        if (_chatProvider != null) {
          _chatProvider!.handleMessageFromFCM(message);
        } else {
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
        if (_chatProvider != null) {
          await _chatProvider!.updateMessageStatus(messageId, newStatus);
        }
      },
    );
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
      if (message != null) _handleMessageOpenedApp(message);
    });
    debugPrint('[FCM] ✅ Listeners ready');
  }

  // =========================================
  // FOREGROUND HANDLER
  // =========================================

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] ☀️ Foreground: ${message.messageId}');

    try {
      final type = NotificationType.fromString(message.data['type']);
      debugPrint('[FCM] Type: $type');

      switch (type) {
        case NotificationType.chat:
          // ✅ Delegasi ke ChatNotificationHandler
          // Handler akan parse payload → ChatModel → ChatProvider.handleMessageFromFCM
          // → ChatStorageService → Isar → stream → UI (otomatis)
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
    debugPrint('[FCM] 👆 Notification tap (from background)');
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
        break;
    }
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    debugPrint('[FCM] 👆 Local notification tapped');
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

  // =========================================
  // ACTIVE ROOM
  // =========================================

  void setActiveRoom(String? roomId) {
    if (_activeRoomId == roomId) return;
    _activeRoomId = roomId;
    debugPrint('[FCM] 🏠 Active room: $roomId');
    // getCurrentUserId/getActiveRoomId adalah live getter → tidak perlu rebuild handler
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