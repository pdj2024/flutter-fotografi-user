import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mpjnew/src/core/services/fcm_chat_message.dart';

/// ═══════════════════════════════════════════════════════════════
/// FCM CHAT NOTIFICATION HELPER
///
/// Bertanggung jawab hanya untuk menampilkan notifikasi lokal.
/// Tidak ada logika bisnis di sini.
/// ═══════════════════════════════════════════════════════════════
class FcmChatNotificationHelper {
  static const String _chatChannelId = 'chat_messages';
  static const String _chatChannelName = 'Chat Messages';
  static const String _chatChannelDesc = 'Notifications for new chat messages';

  final FlutterLocalNotificationsPlugin _plugin;

  // Grouping: track messages per sender untuk inbox style
  final Map<String, List<String>> _messagesBySender = {};

  FcmChatNotificationHelper(this._plugin);

  // =========================================
  // SETUP
  // =========================================

  static Future<void> createChannel(
      FlutterLocalNotificationsPlugin plugin) async {
    const androidChannel = AndroidNotificationChannel(
      _chatChannelId,
      _chatChannelName,
      description: _chatChannelDesc,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    debugPrint('[ChatNotif] ✅ Channel created');
  }

  static Future<void> initialize(
    FlutterLocalNotificationsPlugin plugin, {
    void Function(String? payload)? onTap,
  }) async {
    await createChannel(plugin);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_pacific_data_jaya'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        onTap?.call(response.payload);
      },
    );

    debugPrint('[ChatNotif] ✅ Initialized');
  }

  // =========================================
  // SHOW NOTIFICATION
  // =========================================

  Future<void> show({
    required FcmChatMessage message,
    required String senderName,
    String? activeRoomId,
    String? currentUserId,
  }) async {
    // Skip jika pesan sendiri
    if (message.senderId == currentUserId) {
      debugPrint('[ChatNotif] 🔕 Skip: own message');
      return;
    }

    // Skip jika sedang di room yang sama
    if (activeRoomId != null && activeRoomId == message.roomId) {
      debugPrint('[ChatNotif] 🔕 Skip: active room');
      return;
    }

    // Skip jika status bukan 'sent' (pesan tidak baru)
    if (message.sendStatus != 'sent') {
      debugPrint('[ChatNotif] 🔕 Skip: status is ${message.sendStatus}');
      return;
    }

    final content = _formatContent(message);
    final groupKey = 'chat_${message.senderId}';

    // Tambah ke grup sender
    _messagesBySender.putIfAbsent(message.senderId, () => []);
    final senderMessages = _messagesBySender[message.senderId]!;
    senderMessages.add(content);

    // Batasi 5 pesan terakhir per sender
    if (senderMessages.length > 5) {
      _messagesBySender[message.senderId] =
          senderMessages.sublist(senderMessages.length - 5);
    }

    await _showGrouped(
      senderId: message.senderId,
      senderName: senderName,
      groupKey: groupKey,
      messageId: message.messageId,
      roomId: message.roomId,
    );
  }

  Future<void> _showGrouped({
    required String senderId,
    required String senderName,
    required String groupKey,
    required String messageId,
    required String roomId,
  }) async {
    try {
      final messages = _messagesBySender[senderId] ?? [];
      final count = messages.length;

      final inboxStyle = InboxStyleInformation(
        messages,
        contentTitle: senderName,
        summaryText: count == 1 ? 'Pesan baru' : '$count pesan baru',
      );

      final androidDetails = AndroidNotificationDetails(
        _chatChannelId,
        _chatChannelName,
        channelDescription: _chatChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        groupKey: groupKey,
        setAsGroupSummary: false,
        styleInformation: inboxStyle,
        autoCancel: true,
        icon: 'ic_stat_pacific_data_jaya',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final payload = jsonEncode({
        'type': 'chat',
        'roomId': roomId,
        'messageId': messageId,
        'senderId': senderId,
      });

      final notifId = _notifId(senderId);

      await _plugin.show(
        notifId,
        senderName,
        count == 1 ? messages.first : '$count pesan baru',
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: payload,
      );

      debugPrint('[ChatNotif] ✅ Shown for sender: $senderId');
    } catch (e) {
      debugPrint('[ChatNotif] ❌ Error: $e');
    }
  }

  // =========================================
  // UTILITIES
  // =========================================

  String _formatContent(FcmChatMessage message) {
    if (message.message.isNotEmpty) {
      return message.message.length > 100
          ? '${message.message.substring(0, 100)}...'
          : message.message;
    }
    switch (message.jenisPesan) {
      case 'paket':
        return '📦 Mengirim paket';
      case 'penawaran':
        return '💼 Mengirim penawaran';
      case 'pesanan':
        return '🧾 Mengirim pesanan';
      case 'image':
        return '🖼️ Mengirim gambar';
      default:
        return 'Pesan baru';
    }
  }

  int _notifId(String senderId) => senderId.hashCode.abs() % 2147483647;

  void clearSender(String senderId) {
    _messagesBySender.remove(senderId);
  }

  void clearAll() {
    _messagesBySender.clear();
  }
}
