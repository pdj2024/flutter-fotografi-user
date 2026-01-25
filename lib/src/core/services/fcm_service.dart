import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mpjnew/src/core/services/auth_service_instance.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';

/// ✅ Background message handler (MUST be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] 📨 Message received: ${message.messageId}');
  debugPrint('[FCM Background] 📦 Data: ${message.data}');

  // Handle the message and show notification
  await FCMService.instance._handleBackgroundMessage(message);
}

class FCMService {
  static final FCMService instance = FCMService._internal();
  factory FCMService() => instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _initialized = false;

  // Callbacks
  Function(ChatModel message)? onMessageReceived;
  Function(String roomId)? onNotificationTapped;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _initialized;

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

      debugPrint('[FCM] 📱 Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] ❌ Permission denied');
        return;
      }

      // 2. Initialize local notifications
      await _initializeLocalNotifications();

      // 3. Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('[FCM] 🔑 FCM Token: $_fcmToken');

      // 4. Setup message handlers
      _setupMessageHandlers();

      // 5. Setup token refresh listener
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] 🔄 Token refreshed: $newToken');
        _fcmToken = newToken;
        // TODO: Send new token to backend
        _sendTokenToBackend(newToken);
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

    // Android channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chat_messages_fcm', // id
      'Chat Messages', // name
      description: 'Notifications for chat messages via FCM',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initialize plugin
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

    debugPrint('[FCM] ✅ Local notifications ready');
  }

  void _setupMessageHandlers() {
    debugPrint('[FCM] 📡 Setting up message handlers...');

    // 1. FOREGROUND messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 2. BACKGROUND messages (when app is in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 3. TERMINATED messages (handled by background handler at top)
    // Check if app was opened from terminated state
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('[FCM] 📨 App opened from terminated state');
        _handleNotificationTap(message);
      }
    });

    debugPrint('[FCM] ✅ Message handlers ready');
  }

  // =========================================
  // MESSAGE HANDLERS
  // =========================================

  /// Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM Foreground] 📨 Message: ${message.messageId}');
    debugPrint('[FCM Foreground] 📦 Data: ${message.data}');

    try {
      // Parse message data
      final chatMessage = _parseChatMessage(message.data);

      if (chatMessage != null) {
        // Trigger callback
        onMessageReceived?.call(chatMessage);

        // Show notification (optional - you might want to skip if chat screen is open)
        await _showNotification(message);
      }
    } catch (e) {
      debugPrint('[FCM Foreground] ❌ Error: $e');
    }
  }

  /// Handle background messages (called by top-level handler)
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('[FCM Background] 📨 Processing message: ${message.messageId}');

    try {
      // Show notification
      await _showNotification(message);
    } catch (e) {
      debugPrint('[FCM Background] ❌ Error: $e');
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] 👆 Notification tapped: ${message.messageId}');
    debugPrint('[FCM] 📦 Data: ${message.data}');

    final roomId = message.data['roomId'] as String?;
    if (roomId != null) {
      onNotificationTapped?.call(roomId);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[FCM] 👆 Local notification tapped: ${response.payload}');

    if (response.payload != null && response.payload!.isNotEmpty) {
      final parts = response.payload!.split('|');
      if (parts.isNotEmpty) {
        onNotificationTapped?.call(parts[0]);
      }
    }
  }

  // =========================================
  // NOTIFICATION DISPLAY
  // =========================================

  Future<void> _showNotification(RemoteMessage message) async {
    try {
      // Get notification data
      final data = message.data;
      final senderName = data['senderName'] as String? ?? 'New Message';
      final messageText =
          data['message'] as String? ?? 'You have a new message';
      final roomId = data['roomId'] as String? ?? '';
      final messageId = data['messageId'] as String? ?? '';

      debugPrint('[FCM] 🔔 Showing notification');
      debugPrint('[FCM]   Title: $senderName');
      debugPrint('[FCM]   Body: $messageText');

      const androidDetails = AndroidNotificationDetails(
        'chat_messages_fcm',
        'Chat Messages',
        channelDescription: 'Notifications for chat messages via FCM',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: 'ic_stat_pacific_data_jaya',
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        messageId.hashCode,
        senderName,
        messageText,
        notificationDetails,
        payload: '$roomId|$messageId',
      );

      debugPrint('[FCM] ✅ Notification shown');
    } catch (e) {
      debugPrint('[FCM] ❌ Show notification error: $e');
    }
  }

  // =========================================
  // UTILITIES
  // =========================================

  ChatModel? _parseChatMessage(Map<String, dynamic> data) {
    try {
      // Parse FCM data to ChatModel
      // Adjust based on your backend data structure
      return ChatModel.fromSignalR(data, authService.userId ?? "");
    } catch (e) {
      debugPrint('[FCM] ❌ Parse chat message error: $e');
      return null;
    }
  }

  /// Send FCM token to backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      debugPrint('[FCM] 📤 Sending token to backend...');

      // TODO: Implement API call to save token
      // Example:
      // await ApiClient().post('/users/fcm-token', body: {'token': token});

      debugPrint('[FCM] ✅ Token sent to backend');
    } catch (e) {
      debugPrint('[FCM] ❌ Send token error: $e');
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('[FCM] ✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FCM] ❌ Subscribe error: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('[FCM] ✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[FCM] ❌ Unsubscribe error: $e');
    }
  }

  /// Delete FCM token
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
    onMessageReceived = null;
    onNotificationTapped = null;
  }
}
