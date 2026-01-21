import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';

/// ✅ IMPROVED: ChatBackgroundService dengan AuthService integration
class ChatBackgroundService {
  static const String _serviceName = 'chat_background_service';
  static const int _foregroundNotificationId = 888;

  // Hive box name untuk room info (untuk nama pengirim)
  static const String _roomsBoxName = 'chat_rooms';

  // =========================================
  // PUBLIC API
  // =========================================

  /// ✅ Initialize background service
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Configure notifications for foreground service
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chat_background_service',
      'Chat Background Service',
      description: 'Keeps chat connection alive',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    await notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Configure service
    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: false,
        autoStartOnBoot: false,
        notificationChannelId: 'chat_background_service',
        initialNotificationTitle: 'Chat Service',
        initialNotificationContent: 'Initializing...',
        foregroundServiceNotificationId: _foregroundNotificationId,
      ),
    );

    debugPrint('[ChatBackgroundService] ✅ Initialized');
  }

  /// ✅ Start background service (no userId needed - read from AuthService)
  static Future<void> start() async {
    final service = FlutterBackgroundService();

    // Check if user logged in
    final userId = await _getUserIdFromAuth();
    if (userId == null) {
      debugPrint('[ChatBackgroundService] ❌ No user logged in');
      return;
    }

    // Stop existing service first
    if (await service.isRunning()) {
      await stop();
      await Future.delayed(Duration(milliseconds: 500));
    }

    // Start service
    await service.startService();

    // Trigger connection
    service.invoke('connect');

    debugPrint('[ChatBackgroundService] ✅ Started for user: $userId');
  }

  /// ✅ Stop background service
  static Future<void> stop() async {
    final service = FlutterBackgroundService();

    if (await service.isRunning()) {
      service.invoke('stopService');
      debugPrint('[ChatBackgroundService] 🛑 Stopped');
    }
  }

  /// ✅ Check if service is running
  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  // =========================================
  // HELPER: Get User ID from AuthService
  // =========================================

  /// ✅ Read userId from Hive (AuthService storage)
  static Future<String?> _getUserIdFromAuth() async {
    try {
      // Open auth box
      final box = await Hive.openBox('auth_box');
      final userId = box.get('user_id');

      debugPrint('[ChatBackgroundService] 📝 User ID from auth: $userId');
      return userId;
    } catch (e) {
      debugPrint('[ChatBackgroundService] ❌ Error reading user ID: $e');
      return null;
    }
  }

  /// ✅ Read token from Hive (AuthService storage)
  static Future<String?> _getTokenFromAuth() async {
    try {
      final box = await Hive.openBox('auth_box');
      final token = box.get('id_token');

      if (token != null) {
        debugPrint(
            '[ChatBackgroundService] ✅ Token found (length: ${token.length})');
      } else {
        debugPrint('[ChatBackgroundService] ⚠️ No token in storage');
      }

      return token;
    } catch (e) {
      debugPrint('[ChatBackgroundService] ❌ Error reading token: $e');
      return null;
    }
  }

  // =========================================
  // SERVICE ENTRY POINTS
  // =========================================

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    debugPrint('[ChatBackgroundService] 🚀 Service started');

    // ✅ Initialize Hive in isolate
    await Hive.initFlutter();

    String? userId;
    String? hubUrl = "${Constants.baseUrlHub}/api/chathub";
    HubConnection? connection;
    Timer? heartbeatTimer;
    Box? roomsBox;

    // FlutterLocalNotificationsPlugin
    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    // Initialize notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await notifications.initialize(initSettings);

    // Android-specific setup
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    // =========================================
    // CONNECT COMMAND
    // =========================================
    service.on('connect').listen((event) async {
      debugPrint('[ChatBackgroundService] 🔌 Connect command received');

      try {
        // ✅ Get userId from AuthService storage
        userId = await _getUserIdFromAuth();
        if (userId == null) {
          debugPrint('[ChatBackgroundService] ❌ No user ID found');
          _updateNotification(
            service,
            notifications,
            'Chat Service',
            'Error: Not logged in',
          );
          return;
        }

        debugPrint('[ChatBackgroundService] 👤 User ID: $userId');

        // ✅ Get token from AuthService storage
        final token = await _getTokenFromAuth();
        if (token == null) {
          debugPrint('[ChatBackgroundService] ❌ No token found');
          _updateNotification(
            service,
            notifications,
            'Chat Service',
            'Error: No authentication token',
          );
          return;
        }

        // ✅ Open rooms box for sender names
        try {
          roomsBox = await Hive.openBox(_roomsBoxName);
          debugPrint('[ChatBackgroundService] 📦 Rooms box opened');
        } catch (e) {
          debugPrint('[ChatBackgroundService] ⚠️ Could not open rooms box: $e');
        }

        // Build SignalR connection
        connection = HubConnectionBuilder()
            .withUrl(
          '$hubUrl?role=${Constants.customer}',
          options: HttpConnectionOptions(
            accessTokenFactory: () async {
              // ✅ Always get fresh token from storage
              final freshToken = await _getTokenFromAuth();
              return freshToken ?? token;
            },
            requestTimeout: 15000,
          ),
        )
            .withAutomaticReconnect(
                retryDelays: [1000, 2000, 5000, 10000, 30000]).build();

        // Setup message handler
        connection!.on('ReceiveMessage', (args) {
          if (args != null && args.isNotEmpty) {
            _handleBackgroundMessage(
              args[0],
              notifications,
              userId!,
              roomsBox,
            );
          }
        });

        // Setup reconnection handler
        connection!.onreconnected(({connectionId}) {
          debugPrint('[ChatBackgroundService] 🔄 Reconnected');
          _updateNotification(
            service,
            notifications,
            'Chat Connected',
            'Receiving messages',
          );

          // Rejoin user channel
          connection!.invoke('JoinUserChannel', args: [_getUserIdFromAuth()]);
        });

        // Connect
        debugPrint('[ChatBackgroundService] 🔌 Connecting to SignalR...');
        await connection!.start();

        // Join user channel
        await connection!
            .invoke('JoinUserChannel', args: [_getUserIdFromAuth()]);

        debugPrint('[ChatBackgroundService] ✅ Connected to SignalR');
        debugPrint(
            '[ChatBackgroundService] 📡 Connection ID: ${connection!.connectionId}');

        // Update foreground notification
        _updateNotification(
          service,
          notifications,
          'Chat Connected',
          'Receiving messages in background',
        );

        // Start heartbeat
        heartbeatTimer?.cancel();
        heartbeatTimer = Timer.periodic(
          Duration(seconds: 30),
          (_) => _sendHeartbeat(connection),
        );
      } catch (e, stackTrace) {
        debugPrint('[ChatBackgroundService] ❌ Connection error: $e');
        debugPrint('[ChatBackgroundService] Stack: $stackTrace');

        _updateNotification(
          service,
          notifications,
          'Chat Service',
          'Connection error',
        );
      }
    });

    // =========================================
    // STOP COMMAND
    // =========================================
    service.on('stopService').listen((event) async {
      debugPrint('[ChatBackgroundService] 🛑 Stop command received');

      heartbeatTimer?.cancel();

      try {
        await connection?.stop();
        debugPrint('[ChatBackgroundService] ✅ SignalR disconnected');
      } catch (e) {
        debugPrint('[ChatBackgroundService] ⚠️ Disconnect error: $e');
      }

      try {
        await roomsBox?.close();
      } catch (e) {
        debugPrint('[ChatBackgroundService] ⚠️ Box close error: $e');
      }

      await service.stopSelf();
      debugPrint('[ChatBackgroundService] ✅ Service stopped');
    });

    // Keep service alive
    Timer.periodic(Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (!await service.isForegroundService()) {
          timer.cancel();
        }
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  // =========================================
  // MESSAGE HANDLING
  // =========================================

  static void _handleBackgroundMessage(
    dynamic messageData,
    FlutterLocalNotificationsPlugin notifications,
    String currentUserId,
    Box? roomsBox,
  ) {
    try {
      debugPrint('[ChatBackgroundService] 📨 Message received');

      // Parse message
      final data = messageData as Map<String, dynamic>;
      final senderId = data['senderId']?.toString() ?? '';
      final message = data['message']?.toString() ?? '';
      final roomId = data['roomId']?.toString() ?? '';
      final jenisPesan = data['jenisPesan']?.toString() ?? 'text';

      // Don't notify own messages
      if (senderId == currentUserId) {
        debugPrint('[ChatBackgroundService] 🔕 Skip own message');
        return;
      }

      // ✅ Get sender name from room info (Hive)
      String senderName = 'New Message';
      if (roomsBox != null && roomId.isNotEmpty) {
        try {
          final roomData = roomsBox.get(roomId);
          if (roomData != null) {
            // RoomChatEntity structure: has usernameLawan field
            senderName = roomData.usernameLawan ?? 'Unknown User';
            debugPrint('[ChatBackgroundService] 👤 Sender: $senderName');
          }
        } catch (e) {
          debugPrint(
              '[ChatBackgroundService] ⚠️ Error getting sender name: $e');
        }
      }

      // Format message content
      String messageContent;
      if (message.isNotEmpty) {
        messageContent = message;
      } else if (jenisPesan == 'paket') {
        messageContent = '📦 Mengirim paket';
      } else if (jenisPesan == 'penawaran') {
        messageContent = '💼 Mengirim penawaran';
      } else if (jenisPesan == 'pesanan') {
        messageContent = '🧾 Mengirim pesanan';
      } else {
        messageContent = 'Pesan baru';
      }

      // Truncate long messages
      if (messageContent.length > 100) {
        messageContent = '${messageContent.substring(0, 97)}...';
      }

      debugPrint('[ChatBackgroundService] 📝 Message: $messageContent');

      // Show notification
      _showMessageNotification(
        notifications,
        senderName,
        messageContent,
        roomId,
      );
    } catch (e, stackTrace) {
      debugPrint('[ChatBackgroundService] ❌ Handle message error: $e');
      debugPrint('[ChatBackgroundService] Stack: $stackTrace');
    }
  }

  static Future<void> _showMessageNotification(
    FlutterLocalNotificationsPlugin notifications,
    String title,
    String body,
    String roomId,
  ) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription: 'Notifications for new chat messages',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_stat_pacific_data_jaya',
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

      await notifications.show(
        notificationId,
        title,
        body,
        details,
        payload: roomId, // For navigation when tapped
      );

      debugPrint('[ChatBackgroundService] ✅ Notification shown');
    } catch (e) {
      debugPrint('[ChatBackgroundService] ❌ Show notification error: $e');
    }
  }

  static void _updateNotification(
    ServiceInstance service,
    FlutterLocalNotificationsPlugin notifications,
    String title,
    String content,
  ) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: title,
        content: content,
      );
    }
  }

  static void _sendHeartbeat(HubConnection? connection) {
    if (connection != null &&
        connection.state == HubConnectionState.Connected) {
      try {
        connection.invoke('Ping');
        debugPrint('[ChatBackgroundService] 💓 Heartbeat sent');
      } catch (e) {
        debugPrint('[ChatBackgroundService] ❌ Heartbeat failed: $e');
      }
    }
  }
}
