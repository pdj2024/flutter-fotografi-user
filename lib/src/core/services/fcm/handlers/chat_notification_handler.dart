import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import '../utils/notification_channel_manager.dart';
import '../utils/notification_helper.dart';

class ChatNotificationHandler {
  final FlutterLocalNotificationsPlugin notificationsPlugin;
  final String? currentUserId;
  final String? activeRoomId;

  // ✅ Callback untuk update data lokal
  final Function(ChatModel)? onMessageReceived;

  // ✅ Callback untuk get sender name
  final String Function(String roomId, String senderId)? getSenderName;

  // Track messages by sender for grouping
  final Map<String, List<String>> _messagesBySender = {};

  ChatNotificationHandler({
    required this.notificationsPlugin,
    this.currentUserId,
    this.activeRoomId,
    this.onMessageReceived,
    this.getSenderName,
  });

  /// ✅ IMPROVED: Handle chat message in foreground
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[ChatHandler] ═══════════════════════════════════════');
    debugPrint('[ChatHandler] 💬 HANDLING FOREGROUND CHAT MESSAGE');
    debugPrint('[ChatHandler] ═══════════════════════════════════════');

    try {
      final detail = NotificationHelper.parseDetail(message.data['detail']);
      debugPrint('[ChatHandler] Detail: ${message.data['detail']}');

      final chatMessage = ChatModel.fromFCM(detail, currentUserId ?? "");

      debugPrint('[ChatHandler] ✅ Message parsed: ${chatMessage.messageId}');
      debugPrint('[ChatHandler]   Room: ${chatMessage.roomId}');
      debugPrint('[ChatHandler]   Sender: ${chatMessage.senderId}');
      debugPrint('[ChatHandler]   Status: ${chatMessage.sendStatus}');
      debugPrint('[ChatHandler]   Message: ${chatMessage.message}');

      // ✅ Determine context
      final isFromMe = chatMessage.senderId == currentUserId;
      final isActiveRoom = activeRoomId == chatMessage.roomId;

      debugPrint('[ChatHandler]   From me: $isFromMe');
      debugPrint('[ChatHandler]   Active room: $isActiveRoom');

      // ═══════════════════════════════════════════════════════════
      // ✅ IMPROVED LOGIC: Proper handling for all scenarios
      // ═══════════════════════════════════════════════════════════

      if (isFromMe) {
        // ═══════════════════════════════════════════════════════════
        // OWN MESSAGE: Echo from server
        // ═══════════════════════════════════════════════════════════
        debugPrint('[ChatHandler] 📤 Own message detected');
        debugPrint(
            '[ChatHandler]   Action: Pass to ChatProvider for echo replacement');

        // Pass to ChatProvider (will replace local echo)
        onMessageReceived?.call(chatMessage);

        // ✅ NO notification for own messages
        debugPrint('[ChatHandler] 🔕 Skip notification (own message)');
      } else {
        // ═══════════════════════════════════════════════════════════
        // MESSAGE FROM OTHERS
        // ═══════════════════════════════════════════════════════════
        debugPrint('[ChatHandler] 📨 Message from others');

        // ✅ CRITICAL: Pass to ChatProvider FIRST
        // ChatProvider will determine correct status (read/received)
        // based on isActiveRoom
        debugPrint('[ChatHandler]   Action: Pass to ChatProvider');
        onMessageReceived?.call(chatMessage);

        // ✅ Show notification ONLY if NOT in active room
        if (!isActiveRoom) {
          debugPrint('[ChatHandler]   Action: Show notification');
          await showNotification(message);
        } else {
          debugPrint('[ChatHandler] 🔕 Skip notification (active room)');
        }
      }

      debugPrint('[ChatHandler] ═══════════════════════════════════════');
    } catch (e, st) {
      debugPrint('[ChatHandler] ❌ Error: $e');
      debugPrint('[ChatHandler] Stack: $st');
    }
  }

  /// Show chat notification with proper sender grouping
  Future<void> showNotification(RemoteMessage message) async {
    try {
      final detail = NotificationHelper.parseDetail(message.data['detail']);
      final sendStatus = detail['send_status'] as String? ?? '';
      final senderId = detail['sender_id'] as String? ?? '';

      // ✅ CRITICAL: Only show notification for 'sent' status
      // This ensures we don't show notifications for status updates (received/read)
      if (sendStatus != 'sent') {
        debugPrint('[ChatHandler] 🔕 Skip notification (status: $sendStatus)');
        return;
      }

      if (senderId == currentUserId) {
        debugPrint('[ChatHandler] 🔕 Skip notification (same sender)');
        return;
      }

      final roomId = detail['room_id'] as String? ?? '';
      final messageText = detail['message'] as String? ?? '';
      final messageId = detail['message_id'] as String? ?? '';
      final jenisPesan = detail['jenis_pesan'] as String? ?? 'text';

      debugPrint('[ChatHandler] 🔔 Preparing notification...');
      debugPrint('[ChatHandler]   Room: $roomId');
      debugPrint('[ChatHandler]   Sender: $senderId');
      debugPrint('[ChatHandler]   Status: $sendStatus');

      // Skip if from self
      if (senderId == currentUserId) {
        debugPrint('[ChatHandler] 🔕 Skip (own message)');
        return;
      }

      // Skip if active room (double-check)
      if (activeRoomId == roomId) {
        debugPrint('[ChatHandler] 🔕 Skip (active room)');
        return;
      }

      // Get sender name
      String senderName = 'New Message';
      if (getSenderName != null) {
        try {
          senderName = getSenderName!(roomId, senderId);
        } catch (e) {
          debugPrint('[ChatHandler] ⚠️ Error getting sender name: $e');
        }
      }

      // Format message content
      final content = _formatMessageContent(messageText, jenisPesan, detail);

      // Group by sender
      final groupKey = 'sender_$senderId';

      // Add to sender's message list
      _messagesBySender.putIfAbsent(senderId, () => []);
      _messagesBySender[senderId]!.add(content);

      // Keep only last 5 messages
      if (_messagesBySender[senderId]!.length > 5) {
        _messagesBySender[senderId] = _messagesBySender[senderId]!
            .sublist(_messagesBySender[senderId]!.length - 5);
      }

      // Show grouped notification
      await _showGroupedNotification(
        senderId: senderId,
        senderName: senderName,
        groupKey: groupKey,
        messageId: messageId,
        roomId: roomId,
      );

      debugPrint('[ChatHandler] ✅ Notification shown');
    } catch (e, st) {
      debugPrint('[ChatHandler] ❌ Error: $e');
      debugPrint('[ChatHandler] Stack: $st');
    }
  }

  Future<void> _showGroupedNotification({
    required String senderId,
    required String senderName,
    required String groupKey,
    required String messageId,
    required String roomId,
  }) async {
    try {
      final messages = _messagesBySender[senderId] ?? [];
      final messageCount = messages.length;

      // Create InboxStyle
      final inboxStyle = InboxStyleInformation(
        messages,
        contentTitle: senderName,
        summaryText:
            messageCount == 1 ? 'Pesan baru' : '$messageCount pesan baru',
      );

      final androidDetails = AndroidNotificationDetails(
        NotificationChannelManager.chatChannelId,
        'Chat Messages',
        channelDescription: 'Notifications for new chat messages',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: 'ic_stat_pacific_data_jaya',
        enableVibration: true,
        playSound: true,
        groupKey: groupKey,
        setAsGroupSummary: false,
        styleInformation: inboxStyle,
        color: Constants.primaryColor,
        autoCancel: true,
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

      final payload = NotificationHelper.createPayload({
        'type': 'chat',
        'roomId': roomId,
        'messageId': messageId,
        'senderId': senderId,
      });

      // Use same ID for same sender
      final notificationId =
          NotificationHelper.generateNotificationId(senderId);

      await notificationsPlugin.show(
        notificationId,
        senderName,
        messageCount == 1 ? messages.first : '$messageCount pesan baru',
        notificationDetails,
        payload: payload,
      );

      debugPrint('[ChatHandler] ✅ Grouped notification shown');
    } catch (e, st) {
      debugPrint('[ChatHandler] ❌ Error showing notification: $e');
      debugPrint('[ChatHandler] Stack: $st');
    }
  }

  String _formatMessageContent(
    String message,
    String jenisPesan,
    Map<String, dynamic> detail,
  ) {
    if (message.isNotEmpty) {
      return NotificationHelper.truncateText(message);
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

  /// Clear messages for sender
  void clearMessagesForSender(String senderId) {
    _messagesBySender.remove(senderId);
    debugPrint('[ChatHandler] 🗑️ Cleared messages for: $senderId');
  }

  /// Clear all message groups
  void clearAllMessageGroups() {
    _messagesBySender.clear();
    debugPrint('[ChatHandler] 🗑️ Cleared all message groups');
  }
}
