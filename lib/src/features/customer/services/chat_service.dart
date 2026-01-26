import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/services/auth_service_instance.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';

/// Konfigurasi untuk ChatService
class ChatServiceConfig {
  final String hubUrl;
  final String role;
  final Future<String?> Function() getToken;
  final int requestTimeout;
  final List<int> retryDelays;

  const ChatServiceConfig({
    required this.hubUrl,
    required this.role,
    required this.getToken,
    this.requestTimeout = 15000,
    this.retryDelays = const [1000, 2000, 5000, 10000, 30000],
  });
}

/// ✅ IMPROVED ChatService with Enhanced Notification Support
///
/// Key improvements:
/// - ✅ Callback untuk mendapatkan sender name dari ChatProvider
/// - ✅ Better notification content formatting
/// - ✅ Proper active room tracking
class ChatService {
  final String controller = 'chat';

  HubConnection? _connection;
  ChatServiceConfig? _config;
  String _currentUserId = '';
  bool _isConnecting = false;

  // Tracking joined rooms/channels
  final Set<String> _joinedRooms = {};
  final Set<String> _joinedUserChannels = {};

  // ✅ Notification plugin
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;

  // ✅ Notification settings
  String? _activeRoomId; // Room yang sedang dibuka user
  bool _showNotifications = true; // Toggle notifikasi

  // ✅ NEW: Callback to get sender name from ChatProvider
  String Function(String roomId, String senderId)? getSenderName;

  // =========================================
  // CALLBACKS
  // =========================================

  Function(ChatModel message)? onMessageReceived;
  Function(String roomId, String roomName, DateTime createdAt)? onRoomCreated;
  Function(bool isConnected, String? error)? onConnectionChanged;
  Function()? onReconnected;

  // =========================================
  // GETTERS
  // =========================================

  bool get isConnected => _connection?.state == HubConnectionState.Connected;
  bool get isConnecting => _isConnecting;
  String get currentUserId => _currentUserId;
  Set<String> get joinedRooms => Set.unmodifiable(_joinedRooms);

  // =========================================
  // INITIALIZATION
  // =========================================

  /// ✅ Initialize notifications
  Future<void> initNotifications() async {
    if (_notificationsInitialized) return;

    try {
      debugPrint('[ChatService] 🔔 Initializing notifications...');

      // ✅ STEP 1: Request permission (Android 13+)
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.notification.request();

        debugPrint('[ChatService] 📱 Notification permission status: $status');

        if (status.isDenied || status.isPermanentlyDenied) {
          debugPrint('[ChatService] ❌ Notification permission denied');
          debugPrint('[ChatService] ℹ️  User needs to enable it in Settings');
          return; // Don't initialize if permission denied
        }

        debugPrint('[ChatService] ✅ Notification permission granted');
      }

      await createNotificationChannel();

      // ✅ STEP 2: Initialize plugin
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
      debugPrint('[ChatService] ✅ Notifications initialized');
    } catch (e) {
      debugPrint('[ChatService] ❌ Notification init error: $e');
    }
  }

  Future<void> createNotificationChannel() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chat_channel', // id
      'Chat Messages', // name
      description: 'Notifications for new chat messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('[ChatService] ✅ Notification channel created');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[ChatService] 🔔 Notification tapped: ${response.payload}');

    // Parse payload (format: "roomId|messageId")
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      final parts = payload.split('|');
      if (parts.length >= 1) {
        final roomId = parts[0];
        // TODO: Navigate to chat room
        debugPrint('[ChatService] 📱 Should open room: $roomId');
        // You can add navigation logic here or expose via callback
      }
    }
  }

  // =========================================
  // NOTIFICATION METHODS
  // =========================================

  /// ✅ IMPROVED: Show notification with sender name
  Future<void> _showMessageNotification(ChatModel message) async {
    // Don't show if:
    // 1. Notifications disabled
    // 2. Message from self
    // 3. User is viewing this room
    if (!_showNotifications) {
      debugPrint('[ChatService] 🔕 Notifications disabled globally');
      return;
    }

    if (message.senderId == _currentUserId) {
      debugPrint('[ChatService] 🔕 Skip notification (own message)');
      return;
    }

    if (_activeRoomId == message.roomId) {
      debugPrint('[ChatService] 🔕 Skip notification (room is active)');
      return;
    }

    try {
      debugPrint(
          '[ChatService] 🔔 Preparing notification for: ${message.messageId}');

      // ✅ Get sender name from callback or use default
      String senderName = 'New Message';
      if (getSenderName != null) {
        try {
          senderName = getSenderName!(message.roomId, message.senderId);
          debugPrint('[ChatService] 👤 Sender name: $senderName');
        } catch (e) {
          debugPrint('[ChatService] ⚠️ Error getting sender name: $e');
        }
      }

      // ✅ Format message content based on type
      String messageContent;
      if (message.message.isNotEmpty) {
        messageContent = message.message;
      } else if (message.idPaket != null && message.idPaket!.isNotEmpty) {
        messageContent = '📦 Mengirim paket';
      } else if (message.noPenawaran != null &&
          message.noPenawaran!.isNotEmpty) {
        messageContent = '💼 Mengirim penawaran';
      } else if (message.noInvoice != null && message.noInvoice!.isNotEmpty) {
        messageContent = '🧾 Mengirim pesanan';
      } else {
        messageContent = 'Pesan baru';
      }

      // Truncate long messages
      if (messageContent.length > 100) {
        messageContent = '${messageContent.substring(0, 97)}...';
      }

      debugPrint('[ChatService] 📝 Message content: $messageContent');

      // Notification details
      const androidDetails = AndroidNotificationDetails(
        'chat_channel', // channel ID
        'Chat Messages', // channel name
        channelDescription: 'Notifications for new chat messages',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: 'ic_stat_pacific_data_jaya',
        // largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        // ✅ Enable notification actions
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

      // // Show notification
      // await _notificationsPlugin.show(
      //   message.messageId.hashCode, // Unique ID
      //   senderName, // Title
      //   messageContent, // Body
      //   notificationDetails,
      //   payload: '${message.roomId}|${message.messageId}', // For navigation
      // );

      debugPrint('[ChatService] ✅ Notification shown successfully');
    } catch (e) {
      debugPrint('[ChatService] ❌ Show notification error: $e');
    }
  }

  /// ✅ Set active room (suppress notifications for this room)
  void setActiveRoom(String? roomId) {
    if (_activeRoomId != roomId) {
      _activeRoomId = roomId;
      debugPrint('[ChatService] 📱 Active room set: ${roomId ?? "none"}');

      if (roomId != null) {
        debugPrint(
            '[ChatService] 🔕 Notifications suppressed for room: $roomId');
      } else {
        debugPrint('[ChatService] 🔔 Notifications enabled for all rooms');
      }
    }
  }

  /// ✅ Enable/disable notifications globally
  void setNotificationsEnabled(bool enabled) {
    _showNotifications = enabled;
    debugPrint(
        '[ChatService] 🔔 Notifications globally: ${enabled ? 'ENABLED' : 'DISABLED'}');
  }

  // =========================================
  // CONNECTION
  // =========================================

  Future<bool> connect({
    required ChatServiceConfig config,
    required String userId,
  }) async {
    if (_isConnecting) {
      debugPrint('[ChatService] ⏸️ Already connecting, skip');
      return false;
    }

    if (isConnected && _currentUserId == userId) {
      debugPrint('[ChatService] ✅ Already connected for user $userId');
      return true;
    }

    _isConnecting = true;
    _config = config;
    _currentUserId = userId;

    try {
      debugPrint('[ChatService] 🔑 Getting token...');

      final token = await authService.getIdToken();

      if (token == null || token.isEmpty) {
        debugPrint('[ChatService] ❌ No token available');
        onConnectionChanged?.call(false, 'No authentication token');
        return false;
      }

      debugPrint('[ChatService] ✅ Token obtained (length: ${token.length})');

      if (_connection != null) {
        debugPrint('[ChatService] 🔌 Disconnecting existing connection...');
        await disconnect();
      }

      debugPrint('[ChatService] 🔧 Building connection');
      debugPrint('  - Hub URL: ${config.hubUrl}');
      debugPrint('  - Role: ${config.role}');
      debugPrint('  - User ID: $userId');

      _connection = HubConnectionBuilder()
          .withUrl(
            '${config.hubUrl}?role=${config.role}',
            options: HttpConnectionOptions(
              accessTokenFactory: () async {
                debugPrint('[ChatService] 🔑 Token factory called');
                final freshToken = await config.getToken();

                if (freshToken == null || freshToken.isEmpty) {
                  debugPrint(
                      '[ChatService] ⚠️ Token factory returned null/empty');
                  return '';
                }

                debugPrint('[ChatService] ✅ Token refreshed in factory');
                return freshToken;
              },
              requestTimeout: config.requestTimeout,
            ),
          )
          .withAutomaticReconnect(retryDelays: config.retryDelays)
          .build();

      _setupListeners();

      debugPrint('[ChatService] 🚀 Starting connection...');
      await _connection!.start();

      debugPrint('[ChatService] ✅ Connected successfully');
      debugPrint('  - Connection ID: ${_connection!.connectionId}');

      onConnectionChanged?.call(true, null);

      // ✅ Initialize notifications on first connect
      await initNotifications();

      await joinUserChannel(userId);

      return true;
    } catch (e, st) {
      debugPrint('[ChatService] ❌ Connection failed');
      debugPrint('  - Error: $e');
      debugPrint('  - Stack: $st');

      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        debugPrint('[ChatService] 🔒 Authentication error');
        onConnectionChanged?.call(false, 'Authentication failed');
      } else if (e.toString().contains('timeout')) {
        debugPrint('[ChatService] ⏱️ Connection timeout');
        onConnectionChanged?.call(false, 'Connection timeout');
      } else {
        onConnectionChanged?.call(false, e.toString());
      }

      return false;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> disconnect() async {
    try {
      if (_connection != null) {
        debugPrint('[ChatService] 🔌 Disconnecting...');
        await _connection!.stop();
        debugPrint('[ChatService] ✅ Disconnected');
      }
    } catch (e) {
      debugPrint('[ChatService] ❌ Disconnect error: $e');
    } finally {
      _connection = null;
      _resetJoinState();
      onConnectionChanged?.call(false, null);
    }
  }

  void _resetJoinState() {
    _joinedRooms.clear();
    _joinedUserChannels.clear();
  }

  // =========================================
  // LISTENERS SETUP
  // =========================================

  void _setupListeners() {
    if (_connection == null) return;

    _connection!.on('ReceiveMessage', (args) {
      debugPrint(
          '[ChatService] 📨 ReceiveMessage => ${args?.length ?? 0} args');
      if (args == null || args.isEmpty) return;
      _handleReceiveMessage(args);
    });

    _connection!.on('RoomCreated', (args) {
      debugPrint('[ChatService] 🆕 RoomCreated => ${args?.length ?? 0} args');
      if (args == null || args.isEmpty) return;
      _handleRoomCreated(args);
    });

    _connection!.onclose(({error}) {
      debugPrint('[ChatService] 🔌 Connection closed');
      if (error != null) {
        debugPrint('[ChatService] ❌ Close error: $error');
      }
      onConnectionChanged?.call(false, error?.toString());
    });

    _connection!.onreconnecting(({error}) {
      debugPrint('[ChatService] 🔄 Reconnecting...');
      if (error != null) {
        debugPrint('[ChatService] ⚠️ Reconnect reason: $error');
      }
      onConnectionChanged?.call(false, 'reconnecting');
    });

    _connection!.onreconnected(({connectionId}) async {
      debugPrint('[ChatService] ✅ Reconnected');
      debugPrint('  - New connection ID: $connectionId');

      onConnectionChanged?.call(true, null);
      await _rejoinAfterReconnect();
      onReconnected?.call();
    });
  }

  // =========================================
  // EVENT HANDLERS
  // =========================================

  void _handleReceiveMessage(List<Object?> args) {
    try {
      final raw = args[0];
      final data = Helper.parseData(raw);

      debugPrint('[ChatService] 📦 Parsed message data');

      final message = ChatModel.fromSignalR(data, _currentUserId);

      debugPrint('[ChatService] ✅ Message parsed: ${message.messageId}');
      debugPrint('[ChatService] 📍 Room: ${message.roomId}');
      debugPrint('[ChatService] 👤 Sender: ${message.senderId}');

      // ✅ Show notification BEFORE calling callback
      // This ensures notification is shown even if callback takes time
      if (message.senderId != _currentUserId) {
        _showMessageNotification(message);
      }

      // Then trigger the callback
      onMessageReceived?.call(message);
    } catch (e, st) {
      debugPrint('[ChatService] ❌ Parse ReceiveMessage error: $e');
      debugPrint('[ChatService] Stack: $st');
    }
  }

  void _handleRoomCreated(List<Object?> args) {
    try {
      final raw = args[0];
      final data = Helper.parseData(raw);

      final roomId = data['roomId']?.toString() ?? '';
      final roomName = data['roomName']?.toString() ?? '';
      final createdAt = Helper.parseDateTime(data['createdAt']);

      debugPrint('[ChatService] 🆕 Room created: $roomId');

      onRoomCreated?.call(roomId, roomName, createdAt);
    } catch (e, st) {
      debugPrint('[ChatService] ❌ Parse RoomCreated error: $e\n$st');
    }
  }

  // =========================================
  // ROOM MANAGEMENT
  // =========================================

  Future<bool> joinRoom(String roomId) async {
    if (!isConnected) {
      debugPrint('[ChatService] ⚠️ Cannot join: not connected');
      return false;
    }

    if (roomId.isEmpty) return false;

    if (_joinedRooms.contains(roomId)) {
      debugPrint('[ChatService] ℹ️ Already in room: $roomId');
      return true;
    }

    try {
      debugPrint('[ChatService] 🚪 Joining room: $roomId');
      await _connection!.invoke('JoinRoom', args: [roomId]);
      _joinedRooms.add(roomId);
      debugPrint('[ChatService] ✅ Joined room: $roomId');
      return true;
    } catch (e) {
      debugPrint('[ChatService] ❌ Join room error: $e');
      return false;
    }
  }

  Future<void> joinRooms(List<String> roomIds) async {
    debugPrint('[ChatService] 🚪 Joining ${roomIds.length} rooms...');

    for (final roomId in roomIds) {
      if (roomId.isNotEmpty) {
        await joinRoom(roomId);
      }
    }

    debugPrint('[ChatService] ✅ Joined ${_joinedRooms.length} rooms total');
  }

  Future<void> leaveRoom(String roomId) async {
    if (!isConnected) return;

    try {
      debugPrint('[ChatService] 👋 Leaving room: $roomId');
      await _connection!.invoke('LeaveRoom', args: [roomId]);
      _joinedRooms.remove(roomId);
      debugPrint('[ChatService] ✅ Left room: $roomId');
    } catch (e) {
      debugPrint('[ChatService] ❌ Leave room error: $e');
    }
  }

  Future<bool> joinUserChannel(String userId) async {
    if (!isConnected) {
      debugPrint('[ChatService] ⚠️ Cannot join user channel: not connected');
      return false;
    }

    if (_joinedUserChannels.contains(userId)) {
      debugPrint('[ChatService] ℹ️ Already in user channel: $userId');
      return true;
    }

    try {
      debugPrint('[ChatService] 📢 Joining user channel: $userId');
      await _connection!.invoke('JoinUserChannel', args: [userId]);
      _joinedUserChannels.add(userId);
      debugPrint('[ChatService] ✅ Joined user channel: $userId');
      return true;
    } catch (e) {
      debugPrint('[ChatService] ❌ Join user channel error: $e');
      return false;
    }
  }

  Future<void> _rejoinAfterReconnect() async {
    final rooms = List<String>.from(_joinedRooms);
    final channels = List<String>.from(_joinedUserChannels);

    debugPrint('[ChatService] 🔄 Rejoining after reconnect:');
    debugPrint('  - Rooms: ${rooms.length}');
    debugPrint('  - User channels: ${channels.length}');

    _joinedRooms.clear();
    _joinedUserChannels.clear();

    for (final roomId in rooms) {
      await joinRoom(roomId);
    }

    for (final channel in channels) {
      await joinUserChannel(channel);
    }

    debugPrint('[ChatService] ✅ Rejoin completed');
  }

  // =========================================
  // UTILITIES
  // =========================================

  Future<bool> testConnection() async {
    if (!isConnected) {
      debugPrint('[ChatService] ⚠️ Not connected');
      return false;
    }

    try {
      debugPrint('[ChatService] 🧪 Testing connection...');
      await _connection!.invoke('Ping');
      debugPrint('[ChatService] ✅ Connection test passed');
      return true;
    } catch (e) {
      debugPrint('[ChatService] ❌ Connection test failed: $e');
      return false;
    }
  }

  Map<String, dynamic> getDebugInfo() {
    return {
      'isConnected': isConnected,
      'isConnecting': _isConnecting,
      'currentUserId': _currentUserId,
      'connectionId': _connection?.connectionId ?? 'null',
      'state': _connection?.state.toString() ?? 'null',
      'joinedRooms': _joinedRooms.length,
      'joinedChannels': _joinedUserChannels.length,
      'hasConfig': _config != null,
      'notificationsEnabled': _showNotifications,
      'notificationsInitialized': _notificationsInitialized,
      'activeRoomId': _activeRoomId ?? 'none',
      'hasSenderNameCallback': getSenderName != null,
    };
  }

  void printDebugInfo() {
    debugPrint('=== ChatService Debug Info ===');
    final info = getDebugInfo();
    info.forEach((key, value) {
      debugPrint('  $key: $value');
    });
    debugPrint('  Joined rooms: ${_joinedRooms.join(", ")}');
    debugPrint('  Joined channels: ${_joinedUserChannels.join(", ")}');
    debugPrint('===============================');
  }

  void dispose() {
    debugPrint('[ChatService] 🗑️ Disposing...');
    _connection?.stop();
    _connection = null;
    _resetJoinState();
    _activeRoomId = null;
    getSenderName = null;
  }
}
