import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/data/isar/service/chat_storage_service.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import '../utils/notification_channel_manager.dart';
import '../utils/notification_helper.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CHAT NOTIFICATION HANDLER
//
// Tanggung jawab handler ini:
//   1. Parse ChatModel dari RemoteMessage payload
//   2. Panggil onMessageReceived → FCMService → ChatProvider → ChatStorageService
//   3. Tampilkan notif lokal (hanya jika bukan active room & bukan pesan sendiri)
//
// ✅ FIX BUG 1: currentUserId dan activeRoomId sekarang dibaca live via getter
//    callback (getCurrentUserId / getActiveRoomId), bukan di-pass saat konstruksi.
//    Ini memastikan nilai selalu up-to-date setelah login / room change.
//
// ✅ TIDAK menyimpan pesan ke storage secara langsung.
//    Penyimpanan dihandle oleh ChatStorageService via onMessageReceived callback.
// ═══════════════════════════════════════════════════════════════════════════

class ChatNotificationHandler {
  final FlutterLocalNotificationsPlugin notificationsPlugin;

  // ✅ FIX: Gunakan getter callback, bukan nilai final yang di-set saat konstruksi.
  // Nilai dibaca SAAT pesan datang, bukan saat handler dibuat.
  // Ini mencegah bug di mana currentUserId null karena user belum login
  // saat handler pertama kali dibuat.
  final String? Function() getCurrentUserId;
  final String? Function() getActiveRoomId;

  final Function(ChatModel)? onMessageReceived;
  final String Function(String roomId, String senderId)? getSenderName;

  // ✅ Null di Isar edition — ChatStorageService yang handle status update
  final Future<void> Function(
      String messageId, String roomId, String newStatus)? onUpdateMessageStatus;

  // Track messages by sender for grouped notification (inbox style)
  final Map<String, List<String>> _messagesBySender = {};

  ChatNotificationHandler({
    required this.notificationsPlugin,
    // ✅ FIX: Parameter lama (currentUserId, activeRoomId) diganti dengan getter
    required this.getCurrentUserId,
    required this.getActiveRoomId,
    this.onMessageReceived,
    this.getSenderName,
    this.onUpdateMessageStatus,
  });

  // =========================================
  // FOREGROUND HANDLER
  // =========================================

  Future<void> handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[ChatHandler] 💬 Handling foreground message...');

    try {
      final type = message.data['type'] as String? ?? '';
      debugPrint('[ChatHandler] type: $type');

      // ── Chat message ─────────────────────────────────────────────────────
      final detail = NotificationHelper.parseDetail(message.data['detail']);
      final chatMessage = ChatModel.fromFCM(detail, getCurrentUserId() ?? '');

      final currentUserId = getCurrentUserId();
      final activeRoomId = getActiveRoomId();

      debugPrint('[ChatHandler] ✅ Parsed: ${chatMessage.messageId}');
      debugPrint('[ChatHandler]   Room: ${chatMessage.roomId}');
      debugPrint('[ChatHandler]   Sender: ${chatMessage.senderId}');
      debugPrint('[ChatHandler]   Status: ${chatMessage.sendStatus}');
      debugPrint('[ChatHandler]   CurrentUser: $currentUserId');
      debugPrint('[ChatHandler]   ActiveRoom: $activeRoomId');

      final isStatusEcho = chatMessage.sendStatus == 'received' ||
          chatMessage.sendStatus == 'read';
      final isOwnSender =
          currentUserId != null && chatMessage.senderId == currentUserId;
      final hasLocalId = chatMessage.localId != null &&
          chatMessage.localId!.startsWith('local-');
      final isFromMe = isOwnSender || isStatusEcho || hasLocalId;
      final isActiveRoom =
          activeRoomId != null && activeRoomId == chatMessage.roomId;

      debugPrint('[ChatHandler]   isOwnSender=$isOwnSender'
          ' isStatusEcho=$isStatusEcho'
          ' hasLocalId=$hasLocalId'
          ' isActiveRoom=$isActiveRoom'
          ' isFromMe=$isFromMe');

      // ── Step 1: Persist ke Isar ──────────────────────────────────────────
      await ChatStorageService.instance.persistForegroundMessage(chatMessage);

      if (!isFromMe) {
        // ── Step 2: Update status ke server ─────────────────────────────────
        // ✅ FIX: lakukan ini SEBELUM notif dan SEBELUM onMessageReceived
        // agar tidak ada kondisi race yang menyebabkan step ini terlewat
        final targetStatus = isActiveRoom ? 'read' : 'received';

        debugPrint('[ChatHandler] 🔄 Attempting status update: '
            '${chatMessage.messageId} → $targetStatus');
        debugPrint('[ChatHandler]   onUpdateMessageStatus is null: '
            '${onUpdateMessageStatus == null}');

        if (chatMessage.sendStatus != targetStatus) {
          if (onUpdateMessageStatus != null) {
            await onUpdateMessageStatus!.call(
              chatMessage.messageId,
              chatMessage.roomId,
              targetStatus,
            );
            debugPrint('[ChatHandler] ✅ Status update called: $targetStatus');
          } else {
            debugPrint('[ChatHandler] ❌ onUpdateMessageStatus is NULL — '
                'status tidak dikirim ke server!');
          }
        } else {
          debugPrint(
              '[ChatHandler] ℹ️ Status sudah $targetStatus, skip update');
        }

        // ── Step 3: Callback ke provider (untuk UI update) ──────────────────
        onMessageReceived?.call(chatMessage);

        // ── Step 4: Tampilkan notif lokal ────────────────────────────────────
        if (!isActiveRoom) {
          await showNotification(message);
        } else {
          debugPrint('[ChatHandler] 🔕 Skip notif (active room)');
        }
      } else {
        // Own echo — hanya callback ke provider
        onMessageReceived?.call(chatMessage);
        debugPrint('[ChatHandler] 🔕 Skip notif — isFromMe=$isFromMe');
      }
    } catch (e, st) {
      debugPrint('[ChatHandler] ❌ Error: $e\n$st');
    }
  }

  // =========================================
  // SHOW NOTIFICATION
  // =========================================

  /// Tampilkan notif lokal dengan grouping per sender (inbox style).
  Future<void> showNotification(RemoteMessage message) async {
    try {
      final detail = NotificationHelper.parseDetail(message.data['detail']);

      final sendStatus = detail['send_status'] as String? ?? '';

      // ✅ FIX: Guard tambahan — hanya tampil untuk status 'sent'
      // Status received/read adalah echo konfirmasi, bukan pesan baru
      if (sendStatus != 'sent') {
        debugPrint('[ChatHandler] 🔕 Skip notif (status: $sendStatus)');
        return;
      }

      final roomId = detail['room_id'] as String? ?? '';
      final senderId = detail['sender_id'] as String? ?? '';
      final messageText = detail['message'] as String? ?? '';
      final messageId = detail['message_id'] as String? ?? '';
      final jenisPesan = detail['jenis_pesan'] as String? ?? 'text';

      // ✅ FIX: Baca live saat akan tampil notif
      final currentUserId = getCurrentUserId();
      final activeRoomId = getActiveRoomId();

      // Guard: pesan sendiri
      if (senderId == currentUserId) {
        debugPrint(
            '[ChatHandler] 🔕 Skip notif (own message): sender=$senderId');
        return;
      }

      // Guard: room aktif
      if (activeRoomId != null && activeRoomId == roomId) {
        debugPrint('[ChatHandler] 🔕 Skip (active room)');
        return;
      }

      if (messageId.isEmpty || roomId.isEmpty) {
        debugPrint('[ChatHandler] ⚠️ Missing messageId/roomId');
        return;
      }

      // Resolve sender name
      String senderName = 'Pesan baru';
      if (getSenderName != null) {
        try {
          senderName = getSenderName!(roomId, senderId);
        } catch (e) {
          debugPrint('[ChatHandler] ⚠️ getSenderName error: $e');
        }
      }

      final content = _formatMessageContent(messageText, jenisPesan);

      // Accumulate messages per sender untuk inbox style
      _messagesBySender.putIfAbsent(senderId, () => []);
      _messagesBySender[senderId]!.add(content);

      // Batasi 5 pesan terakhir per sender
      if (_messagesBySender[senderId]!.length > 5) {
        _messagesBySender[senderId] = _messagesBySender[senderId]!.sublist(
          _messagesBySender[senderId]!.length - 5,
        );
      }

      await _showGroupedNotification(
        senderId: senderId,
        senderName: senderName,
        groupKey: 'sender_$senderId',
        messageId: messageId,
        roomId: roomId,
      );

      debugPrint('[ChatHandler] ✅ Notification shown');
    } catch (e, st) {
      debugPrint('[ChatHandler] ❌ showNotification error: $e\n$st');
    }
  }

  Future<void> _showGroupedNotification({
    required String senderId,
    required String senderName,
    required String groupKey,
    required String messageId,
    required String roomId,
  }) async {
    final messages = _messagesBySender[senderId] ?? [];
    final count = messages.length;

    final inboxStyle = InboxStyleInformation(
      messages,
      contentTitle: senderName,
      summaryText: count == 1 ? 'Pesan baru' : '$count pesan baru',
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

    final payload = NotificationHelper.createPayload({
      'type': 'chat',
      'roomId': roomId,
      'messageId': messageId,
      'senderId': senderId,
    });

    await notificationsPlugin.show(
      NotificationHelper.generateNotificationId(senderId),
      senderName,
      count == 1 ? messages.first : '$count pesan baru',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  // =========================================
  // UTILITIES
  // =========================================

  String _formatMessageContent(String message, String jenisPesan) {
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

  void clearMessagesForSender(String senderId) {
    _messagesBySender.remove(senderId);
    debugPrint('[ChatHandler] 🗑️ Cleared: $senderId');
  }

  void clearAllMessageGroups() {
    _messagesBySender.clear();
    debugPrint('[ChatHandler] 🗑️ Cleared all groups');
  }
}
