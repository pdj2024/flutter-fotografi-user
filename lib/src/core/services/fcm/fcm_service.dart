import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mpjnew/src/core/services/fcm/handlers/progres_notification_handler.dart';
import 'package:mpjnew/src/core/services/fcm/models/notification_type.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';
import 'package:mpjnew/src/data/models/ulasan_model.dart';
import 'package:mpjnew/src/features/customer/services/device_token_service.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:provider/provider.dart';

import 'utils/notification_channel_manager.dart';
import 'utils/notification_helper.dart';
import 'handlers/chat_notification_handler.dart';
import 'handlers/like_notification_handler.dart';
import 'handlers/review_notification_handler.dart';

/// Background message handler (MUST be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('═══════════════════════════════════════════════════');
  debugPrint('[FCM Background] 📨 Message: ${message.messageId}');
  debugPrint('[FCM Background] 📦 Data: ${message.data}');
  debugPrint('═══════════════════════════════════════════════════');

  await FCMService.instance.handleBackgroundMessage(message);
}

/// Main FCM Service - Coordinator
class FCMService {
  static final FCMService instance = FCMService._internal();
  factory FCMService() => instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Handlers
  late ChatNotificationHandler _chatHandler;
  late LikeNotificationHandler _likeHandler;
  late ProgressNotificationHandler _progressHandler;
  late ReviewNotificationHandler _reviewHandler;

  // State
  String? _fcmToken;
  bool _initialized = false;
  String? _currentUserId;
  String? _activeRoomId;

  // Callbacks
  Function(ChatModel)? onChatMessageReceived;
  Function(String portofolioId, String userId)? onLikeReceived;
  Function(HistoryOrderModel)? onProgressReceived;
  Function(UlasanModel)? onReviewReceived;
  Function(String roomId)? onNotificationTapped;
  Function(String orderId)? onOrderNotificationTapped;
  String Function(String roomId, String senderId)? getSenderName;

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _initialized;

  BuildContext? _appContext; // Store app context

  void setAppContext(BuildContext context) {
    _appContext = context;
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

      // 1. Request permission
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

      // 2. Initialize local notifications
      await _initializeLocalNotifications();

      // 3. Initialize handlers
      _initializeHandlers();

      // 4. Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('[FCM] 🔑 Token: $_fcmToken');

      if (_fcmToken == null) {
        debugPrint('[FCM] ⚠️ Token is NULL, retrying...');
        await Future.delayed(const Duration(seconds: 2));
        _fcmToken = await _firebaseMessaging.getToken();
        debugPrint('[FCM] 🔄 Retry token: $_fcmToken');
      }

      // 5. Setup message handlers
      _setupMessageHandlers();
      _setupProgressCallback();

      // 6. Setup token refresh listener
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
      debugPrint('[FCM] ❌ Initialization error: $e');
      debugPrint('[FCM] Stack: $st');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    debugPrint('[FCM] 🔔 Setting up local notifications...');

    // Create channels
    await NotificationChannelManager.createAllChannels(_notificationsPlugin);

    // Initialize plugin
    const androidSettings =
        AndroidInitializationSettings('ic_stat_pacific_data_jaya');
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

    debugPrint('[FCM] ✅ Local notifications ready');
  }

  void _initializeHandlers() {
    _chatHandler = ChatNotificationHandler(
      notificationsPlugin: _notificationsPlugin,
      currentUserId: _currentUserId,
      activeRoomId: _activeRoomId,
      onMessageReceived: (message) {
        // Pass to ChatProvider
        if (_appContext != null) {
          try {
            final chatProvider = _appContext!.read<ChatProvider>();
            chatProvider.handleMessageFromFCM(message);
          } catch (e) {
            debugPrint('[FCM] ⚠️ Error passing to ChatProvider: $e');
          }
        }

        // Also trigger app-level callback
        onChatMessageReceived?.call(message);
      },
      getSenderName: (roomId, senderId) {
        if (_appContext != null) {
          try {
            final chatProvider = _appContext!.read<ChatProvider>();
            return chatProvider.getSenderName(roomId, senderId);
          } catch (e) {
            debugPrint('[FCM] ⚠️ Error getting sender name: $e');
            return 'Unknown User';
          }
        }
        return 'Pesan baru';
      },
    );

    _likeHandler = LikeNotificationHandler(
      notificationsPlugin: _notificationsPlugin,
      onLikeReceived: (portofolioId, userId) =>
          onLikeReceived?.call(portofolioId, userId),
    );

    _progressHandler = ProgressNotificationHandler(
      notificationsPlugin: _notificationsPlugin,
      onProgressReceived: (data) => onProgressReceived?.call(data),
    );

    // _reviewHandler = ReviewNotificationHandler(
    //   notificationsPlugin: _notificationsPlugin,
    //   onReviewReceived: (data) => onReviewReceived?.call(data),
    // );

    debugPrint('[FCM] ✅ Handlers initialized');
  }

  void _setupMessageHandlers() {
    debugPrint('[FCM] 📡 Setting up message handlers...');

    // Foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Terminated
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });

    debugPrint('[FCM] ✅ Message handlers ready');
  }

  void _setupProgressCallback() {
    _progressHandler = ProgressNotificationHandler(
      notificationsPlugin: _notificationsPlugin,
      onProgressReceived: (progressData) {
        debugPrint('═══════════════════════════════════════════════════');
        debugPrint('[FCM] 📊 PROGRESS CALLBACK TRIGGERED');
        debugPrint('═══════════════════════════════════════════════════');
        debugPrint('[FCM]   Order: ${progressData.noOrder}');
        debugPrint('[FCM]   Status: ${progressData.statusProgressPesanan}');

        // ✅ STEP 1: Pass to HistoryOrderProvider
        if (_appContext != null) {
          try {
            final historyProvider = _appContext!.read<HistoryOrderProvider>();

            // Update provider dengan data baru
            historyProvider.handleProgressFromFCM(progressData);

            debugPrint('[FCM] ✅ HistoryOrderProvider updated');
          } catch (e) {
            debugPrint('[FCM] ⚠️ Error passing to HistoryOrderProvider: $e');
          }
        }

        // ✅ STEP 2: Trigger app-level callback if set
        onProgressReceived?.call(progressData);

        debugPrint('═══════════════════════════════════════════════════');
      },
    );
  }

  // =========================================
  // TOKEN MANAGEMENT
  // =========================================

  Future<void> registerToken(String userId) async {
    try {
      debugPrint('[FCM] 📤 Registering token for: $userId');
      _currentUserId = userId;

      if (_fcmToken == null) {
        _fcmToken = await _firebaseMessaging.getToken();
      }

      if (_fcmToken != null) {
        await _sendTokenToBackend(_fcmToken!, userId);
      }
    } catch (e) {
      debugPrint('[FCM] ❌ Register token error: $e');
    }
  }

  Future<void> unregisterToken(String userId, String token) async {
    try {
      debugPrint('[FCM] 📤 Unregistering token...');
      // TODO: Call backend to remove token
      _currentUserId = null;
      DeviceTokenService deviceTokenService = DeviceTokenService();
      await deviceTokenService.addDeviceToken(userId, token);
      debugPrint('[FCM] ✅ Token unregistered');
    } catch (e) {
      debugPrint('[FCM] ❌ Unregister token error: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token, String userId) async {
    try {
      debugPrint('[FCM] 📤 Sending token to backend');
      // TODO: Implement API call
      DeviceTokenService deviceTokenService = DeviceTokenService();
      await deviceTokenService.addDeviceToken(userId, token);
      debugPrint('[FCM] ✅ Token sent successfully');
    } catch (e) {
      debugPrint('[FCM] ❌ Send token error: $e');
    }
  }

  // =========================================
  // MESSAGE HANDLERS
  // =========================================

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM Foreground] 🔄 Processing message...');

    try {
      final type = NotificationType.fromString(message.data['type']);
      debugPrint('[FCM Foreground] Type: $type');

      switch (type) {
        case NotificationType.chat:
          await _chatHandler.handleForegroundMessage(message);
          break;
        case NotificationType.like:
          await _likeHandler.handleMessage(message);
          break;
        case NotificationType.progress:
          await _progressHandler.handleMessage(message);
          break;
        case NotificationType.review:
          await _reviewHandler.handleMessage(message);
          break;
        default:
          debugPrint(
              '[FCM Foreground] ⚠️ Unknown type: ${message.data['type']}');
      }
    } catch (e, st) {
      debugPrint('[FCM Foreground] ❌ Error: $e');
      debugPrint('[FCM Foreground] Stack: $st');
    }
  }

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('[FCM Background] 🔄 Processing message...');

    try {
      final type = NotificationType.fromString(message.data['type']);

      // ✅ PERBAIKAN: Inisialisasi handler secara lokal untuk background
      // karena background handler berjalan di isolate terpisah
      final FlutterLocalNotificationsPlugin localPlugin =
          FlutterLocalNotificationsPlugin();

      // Setup channels jika belum
      await NotificationChannelManager.createAllChannels(localPlugin);

      switch (type) {
        case NotificationType.chat:
          // ✅ Create temporary handler for background
          final chatHandler = ChatNotificationHandler(
            notificationsPlugin: localPlugin,
            currentUserId: null, // No user context in background
            activeRoomId: null,
            onMessageReceived: null,
            getSenderName: null,
          );
          await chatHandler.showNotification(message);
          break;

        case NotificationType.like:
          final likeHandler = LikeNotificationHandler(
            notificationsPlugin: localPlugin,
            onLikeReceived: null,
          );
          await likeHandler.showNotification(message);
          break;

        case NotificationType.progress:
          final progressHandler = ProgressNotificationHandler(
            notificationsPlugin: localPlugin,
            onProgressReceived: null,
          );
          final progressData = progressHandler.parseProgressData(message);
          if (progressData != null) {
            await progressHandler.showNotification(message, progressData);
          }
          ;
          break;

        case NotificationType.review:
          // final reviewHandler = ReviewNotificationHandler(
          //   notificationsPlugin: localPlugin,
          //   onReviewReceived: null,
          // );
          // final ulasanData = reviewHandler.parseUlasanData(message);

          // if (ulasanData != null) {
          //   await reviewHandler.showNotification(message, ulasanData);
          // }
          break;

        default:
          debugPrint('[FCM Background] ⚠️ Unknown type');
      }
    } catch (e, st) {
      debugPrint('[FCM Background] ❌ Error: $e');
      debugPrint('[FCM Background] Stack: $st');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] 👆 Notification tapped');

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

  void _onNotificationTapped(NotificationResponse response) {
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
  // UTILITIES
  // =========================================

  void setActiveRoom(String? roomId) {
    if (_activeRoomId != roomId) {
      _activeRoomId = roomId;

      // Update chat handler dengan active room baru
      _initializeHandlers();
    }
  }

  void clearMessagesForSender(String senderId) {
    _chatHandler.clearMessagesForSender(senderId);
  }

  void clearAllMessageGroups() {
    _chatHandler.clearAllMessageGroups();
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('[FCM] ✅ Subscribed to: $topic');
    } catch (e) {
      debugPrint('[FCM] ❌ Subscribe error: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('[FCM] ✅ Unsubscribed from: $topic');
    } catch (e) {
      debugPrint('[FCM] ❌ Unsubscribe error: $e');
    }
  }

  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      debugPrint('[FCM] ✅ Token deleted');
    } catch (e) {
      debugPrint('[FCM] ❌ Delete token error: $e');
    }
  }

  void dispose() {
    debugPrint('[FCM] 🗑️ Disposing...');
    onChatMessageReceived = null;
    onLikeReceived = null;
    onProgressReceived = null;
    onReviewReceived = null;
    onNotificationTapped = null;
    onOrderNotificationTapped = null;
    getSenderName = null;
    _currentUserId = null;
    _activeRoomId = null;
  }
}
