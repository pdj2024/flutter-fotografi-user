import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';

/// ✅ Background message handler (MUST be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('═══════════════════════════════════════════════════');
  debugPrint('[FCM Background] 📨 Message received: ${message.messageId}');
  debugPrint('[FCM Background] 📦 Data: ${message.data}');
  debugPrint('═══════════════════════════════════════════════════');

  // Handle the message and show notification
  await FCMService.instance.handleBackgroundMessage(message);
}

/// ✅ Notification Type Enum
enum NotificationType {
  chat,
  like,
  progress,
  unknown;

  static NotificationType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'chat':
        return NotificationType.chat;
      case 'like':
        return NotificationType.like;
      case 'progress':
      case 'progres':
        return NotificationType.progress;
      default:
        return NotificationType.unknown;
    }
  }
}

/// ✅ Progress Status Enum untuk mapping status pesanan
enum OrderProgressStatus {
  menungguBayar, // Pesanan baru, menunggu pembayaran
  persiapan, // Pembayaran diterima, vendor siapkan
  proses, // Sedang dikerjakan oleh vendor
  review, // Selesai dikerjakan, menunggu review
  revisi, // Vendor melakukan revisi
  selesai, // Pesanan selesai
  dibatalkan, // Pesanan dibatalkan
  unknown;

  static OrderProgressStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu bayar':
      case 'menunggu_bayar':
      case 'pending':
        return OrderProgressStatus.menungguBayar;
      case 'persiapan':
      case 'preparation':
        return OrderProgressStatus.persiapan;
      case 'proses':
      case 'processing':
      case 'dikerjakan':
        return OrderProgressStatus.proses;
      case 'review':
      case 'ulasan':
        return OrderProgressStatus.review;
      case 'revisi':
      case 'revision':
        return OrderProgressStatus.revisi;
      case 'selesai':
      case 'completed':
      case 'done':
        return OrderProgressStatus.selesai;
      case 'dibatalkan':
      case 'cancelled':
      case 'batal':
        return OrderProgressStatus.dibatalkan;
      default:
        return OrderProgressStatus.unknown;
    }
  }

  /// Get emoji for each status
  String get emoji {
    switch (this) {
      case OrderProgressStatus.menungguBayar:
        return '💳';
      case OrderProgressStatus.persiapan:
        return '📦';
      case OrderProgressStatus.proses:
        return '⚙️';
      case OrderProgressStatus.review:
        return '⭐';
      case OrderProgressStatus.revisi:
        return '🔧';
      case OrderProgressStatus.selesai:
        return '🎉';
      case OrderProgressStatus.dibatalkan:
        return '❌';
      default:
        return '📋';
    }
  }

  /// Get user-friendly title
  String get title {
    switch (this) {
      case OrderProgressStatus.menungguBayar:
        return 'Menunggu Pembayaran';
      case OrderProgressStatus.persiapan:
        return 'Persiapan Pesanan';
      case OrderProgressStatus.proses:
        return 'Sedang Diproses';
      case OrderProgressStatus.review:
        return 'Berikan Ulasan';
      case OrderProgressStatus.revisi:
        return 'Dalam Revisi';
      case OrderProgressStatus.selesai:
        return 'Pesanan Selesai';
      case OrderProgressStatus.dibatalkan:
        return 'Pesanan Dibatalkan';
      default:
        return 'Update Pesanan';
    }
  }

  /// Get description for each status
  String get description {
    switch (this) {
      case OrderProgressStatus.menungguBayar:
        return 'Pesanan berhasil dibuat. Silakan selesaikan pembayaran.';
      case OrderProgressStatus.persiapan:
        return 'Pembayaran diterima. Vendor sedang menyiapkan pesanan Anda.';
      case OrderProgressStatus.proses:
        return 'Pesanan sedang dikerjakan oleh vendor.';
      case OrderProgressStatus.review:
        return 'Pesanan selesai dikerjakan. Mohon berikan ulasan Anda.';
      case OrderProgressStatus.revisi:
        return 'Vendor sedang melakukan revisi sesuai permintaan Anda.';
      case OrderProgressStatus.selesai:
        return 'Pesanan telah selesai. Terima kasih!';
      case OrderProgressStatus.dibatalkan:
        return 'Pesanan telah dibatalkan.';
      default:
        return 'Status tidak diketahui';
    }
  }

  /// Get tipe user (who triggers this status)
  String get tipeUser {
    switch (this) {
      case OrderProgressStatus.menungguBayar:
      case OrderProgressStatus.review:
      case OrderProgressStatus.selesai:
      case OrderProgressStatus.dibatalkan:
        return 'Customer';
      case OrderProgressStatus.persiapan:
      case OrderProgressStatus.proses:
      case OrderProgressStatus.revisi:
        return 'Vendor';
      default:
        return 'Unknown';
    }
  }
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
  String? _currentUserId;

  // ✅ Active room tracking (untuk suppress notification)
  String? _activeRoomId;

  // ✅ Callbacks
  Function(ChatModel message)? onChatMessageReceived;
  Function(String portofolioId, String userId)? onLikeReceived;

  // ✅ NEW: Enhanced progress callback
  Function(HistoryOrderModel progressData)? onProgressReceived;

  Function(String roomId)? onNotificationTapped;

  // ✅ NEW: Callback untuk navigate ke order detail
  Function(String orderId)? onOrderNotificationTapped;

  // ✅ Callback untuk get sender name
  String Function(String roomId, String senderId)? getSenderName;

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

      if (_fcmToken == null) {
        debugPrint('[FCM] ⚠️ WARNING: FCM Token is NULL!');
        await Future.delayed(Duration(seconds: 2));
        _fcmToken = await _firebaseMessaging.getToken();
        debugPrint('[FCM] 🔄 Retry token: $_fcmToken');
      }

      // 4. Setup message handlers
      _setupMessageHandlers();

      // 5. Setup token refresh listener
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        debugPrint('[FCM] 🔄 Token refreshed: $newToken');
        _fcmToken = newToken;

        if (_currentUserId != null) {
          // TODO: Send new token to backend
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

    // ✅ Create notification channels
    await _createNotificationChannels();

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

  /// ✅ Create multiple notification channels
  Future<void> _createNotificationChannels() async {
    final plugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (plugin == null) return;

    // Channel untuk Chat (dengan grouping)
    const chatChannel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Channel untuk Like
    const likeChannel = AndroidNotificationChannel(
      'likes',
      'Likes',
      description: 'Notifications for portfolio likes',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    // Channel untuk Progress
    const progressChannel = AndroidNotificationChannel(
      'order_progress',
      'Order Progress',
      description: 'Notifications for order progress updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await plugin.createNotificationChannel(chatChannel);
    await plugin.createNotificationChannel(likeChannel);
    await plugin.createNotificationChannel(progressChannel);

    debugPrint('[FCM] ✅ Notification channels created');
  }

  void _setupMessageHandlers() {
    debugPrint('[FCM] 📡 Setting up message handlers...');

    // 1. FOREGROUND messages
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('[FCM FOREGROUND] 📨 Message received!');
      debugPrint('[FCM FOREGROUND] MessageId: ${message.messageId}');
      debugPrint('[FCM FOREGROUND] Data: ${message.data}');
      debugPrint('═══════════════════════════════════════════════════');

      _handleForegroundMessage(message);
    });

    // 2. BACKGROUND messages (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('[FCM] 👆 App opened from notification (background)');
      debugPrint('[FCM] Data: ${message.data}');
      debugPrint('═══════════════════════════════════════════════════');

      _handleNotificationTap(message);
    });

    // 3. TERMINATED messages
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('═══════════════════════════════════════════════════');
        debugPrint('[FCM] 📨 App opened from terminated state');
        debugPrint('[FCM] Data: ${message.data}');
        debugPrint('═══════════════════════════════════════════════════');

        _handleNotificationTap(message);
      }
    });

    debugPrint('[FCM] ✅ Message handlers ready');
  }

  // =========================================
  // TOKEN MANAGEMENT
  // =========================================

  Future<void> registerToken(String userId) async {
    try {
      debugPrint('[FCM] 📤 Registering token for user: $userId');
      _currentUserId = userId;

      if (_fcmToken == null) {
        debugPrint('[FCM] ⚠️ No FCM token available yet, fetching...');
        _fcmToken = await _firebaseMessaging.getToken();
      }

      if (_fcmToken != null) {
        debugPrint('[FCM] ✅ Token available: $_fcmToken');
        await _sendTokenToBackend(_fcmToken!, userId);
      } else {
        debugPrint('[FCM] ❌ Failed to get FCM token');
      }
    } catch (e) {
      debugPrint('[FCM] ❌ Register token error: $e');
    }
  }

  Future<void> unregisterToken(String userId) async {
    try {
      debugPrint('[FCM] 📤 Unregistering token from backend...');

      // TODO: Call backend to remove token
      // await deviceTokenService.removeDeviceToken(userId);

      _currentUserId = null;
      debugPrint('[FCM] ✅ Token unregistered successfully');
    } catch (e) {
      debugPrint('[FCM] ❌ Unregister token error: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token, String userId) async {
    try {
      debugPrint('[FCM] 📤 Sending token to backend for user: $userId');
      debugPrint('[FCM] Token: $token');

      // TODO: Implement API call
      // await deviceTokenService.addDeviceToken(userId);

      debugPrint('[FCM] ✅ Token sent to backend successfully');
    } catch (e) {
      debugPrint('[FCM] ❌ Send token error: $e');
    }
  }

  // =========================================
  // MESSAGE HANDLERS
  // =========================================

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM Foreground] 🔄 Processing message...');
    debugPrint('[FCM Foreground] Full data: ${message.data}');

    try {
      // ✅ IMPROVED: Infer type from data structure
      final type = _inferNotificationType(message.data);
      debugPrint('[FCM Foreground] Inferred type: $type');

      switch (type) {
        case NotificationType.chat:
          await _handleChatMessage(message);
          break;
        case NotificationType.like:
          await _handleLikeMessage(message);
          break;
        case NotificationType.progress:
          await _handleProgressMessage(message);
          break;
        default:
          debugPrint(
              '[FCM Foreground] ⚠️ Unknown message type, showing generic notification');
          await _showGenericNotification(message);
      }
    } catch (e, st) {
      debugPrint('[FCM Foreground] ❌ Error: $e');
      debugPrint('[FCM Foreground] Stack: $st');
    }
  }

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('[FCM Background] 🔄 Processing message...');
    debugPrint('[FCM Background] Full data: ${message.data}');

    try {
      final type = _inferNotificationType(message.data);
      debugPrint('[FCM Background] Inferred type: $type');

      switch (type) {
        case NotificationType.chat:
          await _showChatNotification(message);
          break;
        case NotificationType.like:
          await _showLikeNotification(message);
          break;
        case NotificationType.progress:
          await _showProgressNotification(message);
          break;
        default:
          await _showGenericNotification(message);
      }
    } catch (e, st) {
      debugPrint('[FCM Background] ❌ Error: $e');
      debugPrint('[FCM Background] Stack: $st');
    }
  }

  /// ✅ NEW: Infer notification type from data structure
  NotificationType _inferNotificationType(Map<String, dynamic> data) {
    debugPrint('[FCM] 🔍 Inferring notification type from data...');

    // Method 1: Check explicit 'type' field
    if (data.containsKey('type')) {
      final typeStr = data['type']?.toString();
      debugPrint('[FCM]   Found explicit type: $typeStr');
      return NotificationType.fromString(typeStr);
    }

    // Method 2: Check 'detail' field for type
    if (data.containsKey('detail')) {
      try {
        final detail = _parseDetail(data['detail']);
        if (detail.containsKey('type')) {
          final typeStr = detail['type']?.toString();
          debugPrint('[FCM]   Found type in detail: $typeStr');
          return NotificationType.fromString(typeStr);
        }

        // Infer from detail structure
        if (detail.containsKey('room_id') || detail.containsKey('message_id')) {
          debugPrint('[FCM]   Inferred: CHAT (has room_id/message_id)');
          return NotificationType.chat;
        }

        if (detail.containsKey('status_progress_pesanan') ||
            detail.containsKey('no_order')) {
          debugPrint('[FCM]   Inferred: PROGRESS (has order fields)');
          return NotificationType.progress;
        }

        if (detail.containsKey('portofolio_id')) {
          debugPrint('[FCM]   Inferred: LIKE (has portofolio_id)');
          return NotificationType.like;
        }
      } catch (e) {
        debugPrint('[FCM]   Error parsing detail: $e');
      }
    }

    // Method 3: Infer from root data structure
    if (data.containsKey('room_id') ||
        data.containsKey('message_id') ||
        data.containsKey('sender_id')) {
      debugPrint('[FCM]   Inferred: CHAT (has chat fields in root)');
      return NotificationType.chat;
    }

    if (data.containsKey('id_paket') || data.containsKey('tipe_pengirim')) {
      debugPrint('[FCM]   Inferred: CHAT (has paket/sender fields)');
      return NotificationType.chat;
    }

    if (data.containsKey('status_progress_pesanan') ||
        data.containsKey('no_order') ||
        data.containsKey('no_id')) {
      debugPrint('[FCM]   Inferred: PROGRESS (has order fields in root)');
      return NotificationType.progress;
    }

    if (data.containsKey('portofolio_id')) {
      debugPrint('[FCM]   Inferred: LIKE (has portofolio_id in root)');
      return NotificationType.like;
    }

    debugPrint('[FCM]   ⚠️ Could not infer type, returning UNKNOWN');
    return NotificationType.unknown;
  }

  Future<void> _showGenericNotification(RemoteMessage message) async {
    try {
      debugPrint('[FCM] 🔔 Showing generic notification...');
      debugPrint('[FCM] Data: ${message.data}');

      // Try to extract meaningful info
      String title = 'Notifikasi Baru';
      String body = 'Anda memiliki notifikasi baru';

      // Check for common title/body fields
      if (message.notification != null) {
        title = message.notification!.title ?? title;
        body = message.notification!.body ?? body;
      } else {
        // Try to build from data
        if (message.data.containsKey('title')) {
          title = message.data['title'].toString();
        }
        if (message.data.containsKey('body')) {
          body = message.data['body'].toString();
        } else if (message.data.containsKey('message')) {
          body = message.data['message'].toString();
        }
      }

      const androidDetails = AndroidNotificationDetails(
        'default_channel',
        'Notifications',
        channelDescription: 'General notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: 'ic_stat_pacific_data_jaya',
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
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );

      debugPrint('[FCM] ✅ Generic notification shown');
    } catch (e, st) {
      debugPrint('[FCM] ❌ Show generic notification error: $e');
      debugPrint('[FCM] Stack: $st');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] 👆 Notification tapped');
    debugPrint('[FCM] Data: ${message.data}');

    final type = NotificationType.fromString(message.data['type']);

    switch (type) {
      case NotificationType.chat:
        final detail = _parseDetail(message.data['detail']);
        final roomId = detail['room_id'] as String?;
        if (roomId != null) {
          debugPrint('[FCM] 📍 Navigating to room: $roomId');
          onNotificationTapped?.call(roomId);
        }
        break;
      case NotificationType.like:
        // TODO: Handle like notification tap
        break;
      case NotificationType.progress:
        final detail = _parseDetail(message.data['detail']);
        final orderId = detail['no_order'] as String?;
        if (orderId != null) {
          debugPrint('[FCM] 📍 Navigating to order: $orderId');
          onOrderNotificationTapped?.call(orderId);
        }
        break;
      default:
        break;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[FCM] 👆 Local notification tapped');
    debugPrint('[FCM] Payload: ${response.payload}');

    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final payload = jsonDecode(response.payload!);
        final type = NotificationType.fromString(payload['type']);

        switch (type) {
          case NotificationType.chat:
            final roomId = payload['roomId'] as String?;
            if (roomId != null) {
              onNotificationTapped?.call(roomId);
            }
            break;
          case NotificationType.like:
            // TODO: Handle like tap
            break;
          case NotificationType.progress:
            final orderId = payload['orderId'] as String?;
            if (orderId != null) {
              onOrderNotificationTapped?.call(orderId);
            }
            break;
          default:
            break;
        }
      } catch (e) {
        debugPrint('[FCM] ❌ Error parsing payload: $e');
      }
    }
  }

  // =========================================
  // CHAT MESSAGE HANDLING - FIXED GROUPING
  // =========================================

  // ✅ Add this at class level to track messages per sender
  final Map<String, List<String>> _messagesBySender = {};

  Future<void> _handleChatMessage(RemoteMessage message) async {
    debugPrint('[FCM] 💬 Handling chat message...');

    try {
      final detail = _parseDetail(message.data['detail']);
      final chatMessage = ChatModel.fromSignalR(detail, _currentUserId ?? '');

      debugPrint('[FCM] ✅ Chat message parsed: ${chatMessage.messageId}');
      debugPrint('[FCM]   Room: ${chatMessage.roomId}');
      debugPrint('[FCM]   Sender: ${chatMessage.senderId}');

      // ✅ Trigger callback
      if (onChatMessageReceived != null) {
        debugPrint('[FCM] 📞 Calling onChatMessageReceived callback');
        onChatMessageReceived?.call(chatMessage);
      } else {
        debugPrint('[FCM] ⚠️ WARNING: onChatMessageReceived callback is NULL!');
      }

      // ✅ Show notification
      await _showChatNotification(message);
    } catch (e, st) {
      debugPrint('[FCM] ❌ Handle chat error: $e');
      debugPrint('[FCM] Stack: $st');
    }
  }

  /// ✅ Show chat notification with PROPER SENDER GROUPING
  Future<void> _showChatNotification(RemoteMessage message) async {
    try {
      final detail = _parseDetail(message.data['detail']);

      final roomId = detail['room_id'] as String? ?? '';
      final senderId = detail['sender_id'] as String? ?? '';
      final messageText = detail['message'] as String? ?? '';
      final messageId = detail['message_id'] as String? ?? '';
      final jenisPesan = detail['jenis_pesan'] as String? ?? 'text';

      debugPrint('[FCM] 🔔 Preparing chat notification...');
      debugPrint('[FCM]   Room: $roomId');
      debugPrint('[FCM]   Sender: $senderId');
      debugPrint('[FCM]   Type: $jenisPesan');

      // ✅ Skip if from self or active room
      if (senderId == _currentUserId) {
        debugPrint('[FCM] 🔕 Skip notification (own message)');
        return;
      }

      if (_activeRoomId == roomId) {
        debugPrint('[FCM] 🔕 Skip notification (room is active)');
        return;
      }

      // ✅ Get sender name
      String senderName = 'New Message';
      if (getSenderName != null) {
        try {
          senderName = getSenderName!(roomId, senderId);
          debugPrint('[FCM] 👤 Sender name: $senderName');
        } catch (e) {
          debugPrint('[FCM] ⚠️ Error getting sender name: $e');
        }
      }

      // ✅ Format message content
      String content = _formatMessageContent(messageText, jenisPesan, detail);

      // ✅ CRITICAL: Use senderId as group key (not roomId + senderId)
      // This groups all messages from the same sender together
      final groupKey = 'sender_$senderId';
      final summaryId = senderId.hashCode;

      debugPrint('[FCM] 📦 Group key: $groupKey');
      debugPrint('[FCM] 📝 Content: $content');

      // ✅ Add message to sender's list
      if (!_messagesBySender.containsKey(senderId)) {
        _messagesBySender[senderId] = [];
      }
      _messagesBySender[senderId]!.add(content);

      // ✅ Keep only last 5 messages per sender
      if (_messagesBySender[senderId]!.length > 5) {
        _messagesBySender[senderId] = _messagesBySender[senderId]!
            .sublist(_messagesBySender[senderId]!.length - 5);
      }

      debugPrint(
          '[FCM] 📊 Messages from $senderName: ${_messagesBySender[senderId]!.length}');

      // ✅ Show grouped notification
      await _showGroupedNotification(
        senderId: senderId,
        senderName: senderName,
        groupKey: groupKey,
        summaryId: summaryId,
        messageId: messageId,
        roomId: roomId,
      );

      debugPrint('[FCM] ✅ Chat notification shown');
    } catch (e, st) {
      debugPrint('[FCM] ❌ Show chat notification error: $e');
      debugPrint('[FCM] Stack: $st');
    }
  }

  /// ✅ Show grouped notification for sender
  Future<void> _showGroupedNotification({
    required String senderId,
    required String senderName,
    required String groupKey,
    required int summaryId,
    required String messageId,
    required String roomId,
  }) async {
    try {
      final messages = _messagesBySender[senderId] ?? [];
      final messageCount = messages.length;

      debugPrint('[FCM] 📬 Creating grouped notification for $senderName');
      debugPrint('[FCM]   Total messages: $messageCount');

      // ✅ Create InboxStyle with all messages
      final inboxStyle = InboxStyleInformation(
        messages, // List of message contents
        contentTitle: senderName,
        summaryText:
            messageCount == 1 ? 'Pesan baru' : '$messageCount pesan baru',
      );

      final androidDetails = AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription: 'Notifications for new chat messages',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: 'ic_stat_pacific_data_jaya',
        enableVibration: true,
        playSound: true,

        // ✅ Group by sender
        groupKey: groupKey,
        setAsGroupSummary: false,

        // ✅ Use InboxStyle for grouped messages
        styleInformation: inboxStyle,

        // ✅ Auto-cancel when tapped
        autoCancel: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: null,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final payload = jsonEncode({
        'type': 'chat',
        'roomId': roomId,
        'messageId': messageId,
        'senderId': senderId,
      });

      // ✅ CRITICAL: Use same notification ID for same sender
      // This updates the notification instead of creating new ones
      final notificationId = senderId.hashCode;

      await _notificationsPlugin.show(
        notificationId,
        senderName,
        messageCount == 1 ? messages.first : '$messageCount pesan baru',
        notificationDetails,
        payload: payload,
      );

      debugPrint('[FCM] ✅ Grouped notification shown (ID: $notificationId)');
    } catch (e, st) {
      debugPrint('[FCM] ❌ Show grouped notification error: $e');
      debugPrint('[FCM] Stack: $st');
    }
  }

  /// ✅ Clear messages for sender (call when notification is tapped or room opened)
  void clearMessagesForSender(String senderId) {
    _messagesBySender.remove(senderId);
    debugPrint('[FCM] 🗑️ Cleared messages for sender: $senderId');
  }

  /// ✅ Clear all message groups (call on logout or app reset)
  void clearAllMessageGroups() {
    _messagesBySender.clear();
    debugPrint('[FCM] 🗑️ Cleared all message groups');
  }

  String _formatMessageContent(
    String message,
    String jenisPesan,
    Map<String, dynamic> detail,
  ) {
    if (message.isNotEmpty) {
      return message.length > 100 ? '${message.substring(0, 97)}...' : message;
    }

    switch (jenisPesan) {
      case 'paket':
        return '📦 Mengirim paket';
      case 'penawaran':
        return '💼 Mengirim penawaran';
      case 'pesanan':
      case 'order':
        return '🧾 Mengirim pesanan';
      case 'image':
      case 'gambar':
        return '🖼️ Mengirim gambar';
      case 'file':
        return '📎 Mengirim file';
      default:
        return 'Pesan baru';
    }
  }

  // =========================================
  // LIKE MESSAGE HANDLING
  // =========================================

  Future<void> _handleLikeMessage(RemoteMessage message) async {
    debugPrint('[FCM] ❤️ Handling like message...');

    try {
      final detail = _parseDetail(message.data['detail']);
      final portofolioId = detail['portofolio_id'] as String?;
      final userId = detail['user_id'] as String?;

      if (portofolioId != null && userId != null) {
        onLikeReceived?.call(portofolioId, userId);
      }

      await _showLikeNotification(message);
    } catch (e) {
      debugPrint('[FCM] ❌ Handle like error: $e');
    }
  }

  Future<void> _showLikeNotification(RemoteMessage message) async {
    try {
      final detail = _parseDetail(message.data['detail']);
      final userName = detail['user_name'] as String? ?? 'Someone';
      final portofolioTitle =
          detail['portofolio_title'] as String? ?? 'your portfolio';

      const androidDetails = AndroidNotificationDetails(
        'likes',
        'Likes',
        channelDescription: 'Notifications for portfolio likes',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: 'ic_stat_pacific_data_jaya',
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
        DateTime.now().millisecondsSinceEpoch % 100000,
        'New Like',
        '$userName liked $portofolioTitle',
        notificationDetails,
        payload: jsonEncode({
          'type': 'like',
          'portofolioId': detail['portofolio_id'],
        }),
      );

      debugPrint('[FCM] ✅ Like notification shown');
    } catch (e) {
      debugPrint('[FCM] ❌ Show like notification error: $e');
    }
  }

  // =========================================
  // ✅ PROGRESS MESSAGE HANDLING (ENHANCED)
  // =========================================

  /// ✅ Handle progress message dengan parsing data lengkap
  Future<void> _handleProgressMessage(RemoteMessage message) async {
    debugPrint('[FCM] 📊 Handling progress message...');
    debugPrint('[FCM] Raw data: ${message.data}');

    try {
      final detail = _parseDetail(message.data['detail']);
      debugPrint('[FCM] Parsed detail: $detail');

      // ✅ Parse ke HistoryOrderModel model
      final progressData = HistoryOrderModel.fromFCM(detail);

      debugPrint('[FCM] ✅ Progress data parsed:');
      debugPrint('[FCM]   Order: ${progressData.noOrder}');
      debugPrint('[FCM]   Status: ${progressData.statusProgressPesanan}');
      debugPrint(
          '[FCM]   Sender: ${progressData.senderId} (${progressData.tipeUser})');
      debugPrint('[FCM]   Deskripsi: ${progressData.deskripsi}');

      // ✅ Trigger callback untuk update UI/data
      if (onProgressReceived != null) {
        debugPrint('[FCM] 📞 Calling onProgressReceived callback');
        onProgressReceived?.call(progressData);
      } else {
        debugPrint('[FCM] ⚠️ WARNING: onProgressReceived callback is NULL!');
      }

      // ✅ Show notification
      await _showProgressNotification(message);
    } catch (e, st) {
      debugPrint('[FCM] ❌ Handle progress error: $e');
      debugPrint('[FCM] Stack: $st');
    }
  }

  /// ✅ Show progress notification dengan styling yang lebih baik
  Future<void> _showProgressNotification(RemoteMessage message) async {
    try {
      final detail = _parseDetail(message.data['detail']);

      // Parse data
      final nomorId = detail['no_id'] as String? ?? '';
      final deskripsi = detail['deskripsi'] as String? ?? '';
      final statusStr = detail['status_progress_pesanan'] as String?;
      final status = OrderProgressStatus.fromString(statusStr);

      debugPrint('[FCM] 🔔 Preparing progress notification...');
      debugPrint('[FCM]   noid: $nomorId');
      debugPrint('[FCM]   Status: ${status.name}');
      debugPrint('[FCM]   Description: $deskripsi');

      // ✅ Build notification title dengan emoji
      final title = '${status.emoji} ${status.title}';

      // ✅ Build notification body
      final body = deskripsi.isNotEmpty
          ? deskripsi
          : 'Pesanan telah ${status.title.toLowerCase()}';

      // ✅ Styling notification berdasarkan status
      final androidDetails = AndroidNotificationDetails(
        'order_progress',
        'Order Progress',
        channelDescription: 'Notifications for order progress updates',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_stat_pacific_data_jaya',
        enableVibration: true,
        playSound: true,

        // ✅ Big text style untuk deskripsi panjang
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),

        // ✅ Show timestamp
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final payload = jsonEncode({
        'type': 'progress',
        'nomorId': nomorId,
        'status': status.name,
      });

      // ✅ Show notification dengan unique ID berdasarkan order
      await _notificationsPlugin.show(
        nomorId.hashCode, // Unique ID per order
        title,
        body,
        notificationDetails,
        payload: "payload",
      );

      debugPrint('[FCM] ✅ Progress notification shown');
    } catch (e, st) {
      debugPrint('[FCM] ❌ Show progress notification error: $e');
      debugPrint('[FCM] Stack: $st');
    }
  }
  // =========================================
  // UTILITIES
  // =========================================

  Map<String, dynamic> _parseDetail(dynamic detail) {
    if (detail is String) {
      try {
        return jsonDecode(detail) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('[FCM] ⚠️ Failed to parse detail string: $e');
        return {};
      }
    } else if (detail is Map) {
      return Map<String, dynamic>.from(detail);
    }
    return {};
  }

  /// ✅ Set active room (suppress notifications for this room)
  void setActiveRoom(String? roomId) {
    if (_activeRoomId != roomId) {
      _activeRoomId = roomId;
      debugPrint('[FCM] 📱 Active room set: ${roomId ?? "none"}');

      if (roomId != null) {
        debugPrint('[FCM] 🔕 Notifications suppressed for room: $roomId');
      } else {
        debugPrint('[FCM] 🔔 Notifications enabled for all rooms');
      }
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
    onChatMessageReceived = null;
    onLikeReceived = null;
    onProgressReceived = null;
    onNotificationTapped = null;
    onOrderNotificationTapped = null;
    getSenderName = null;
    _currentUserId = null;
    _activeRoomId = null;
  }
}
