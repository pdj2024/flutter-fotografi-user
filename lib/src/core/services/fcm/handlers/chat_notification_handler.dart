import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';

import '../utils/notification_channel_manager.dart';
import '../utils/notification_helper.dart';

// ─────────────────────────────────────────────────────────────────
// ChatNotificationHandler
//
// Bertanggung jawab untuk:
//   1. Parse payload FCM → ChatModel
//   2. ✅ Tentukan targetStatus (read/received) berdasarkan activeRoomId
//   3. Panggil onMessageReceived → ChatProvider.handleMessageFromFCM
//   4. Panggil onUpdateMessageStatus → ChatProvider.updateMessageStatus
//   5. Tampilkan notifikasi lokal HANYA jika bukan room aktif
//
// Aturan status:
//   - User sedang di room YANG SAMA dengan pesan → status "read", NO notif lokal
//   - User tidak di room ini (atau di halaman lain) → status "received", tampilkan notif lokal
// ─────────────────────────────────────────────────────────────────
class ChatNotificationHandler {
  final FlutterLocalNotificationsPlugin notificationsPlugin;

  /// Getter live — selalu baca nilai terbaru dari FCMService
  final String? Function() getCurrentUserId;
  final String? Function() getActiveRoomId;

  /// Dipanggil setelah status ditentukan, membawa ChatModel + targetStatus
  final void Function(ChatModel message, String targetStatus) onMessageReceived;

  /// Dipanggil untuk update status pesan ke API + Isar
  final Future<void> Function(String messageId, String roomId, String newStatus)
      onUpdateMessageStatus;

  /// Untuk mendapatkan nama pengirim (dipakai di judul notifikasi)
  final String Function(String roomId, String senderId) getSenderName;

  // ── Notif grouping (per sender) ─────────────────────────────────
  final Map<String, List<String>> _messageGroups = {};

  ChatNotificationHandler({
    required this.notificationsPlugin,
    required this.getCurrentUserId,
    required this.getActiveRoomId,
    required this.onMessageReceived,
    required this.onUpdateMessageStatus,
    required this.getSenderName,
  });

  // =========================================
  // ENTRY POINT — dipanggil dari FCMService._handleForegroundMessage
  // =========================================

  Future<void> handleForegroundMessage(RemoteMessage message) async {
    try {
      final detail = NotificationHelper.parseDetail(message.data['detail']);
      if (detail.isEmpty) return;

      final messageId = detail['message_id']?.toString() ?? '';
      final roomId = detail['room_id']?.toString() ?? '';
      final senderId = detail['sender_id']?.toString() ?? '';
      final messageText = detail['message']?.toString() ?? '';
      final jenisPesan = detail['jenis_pesan']?.toString() ?? 'text';
      final sendStatus = detail['send_status']?.toString() ?? 'sent';

      if (messageId.isEmpty) return;

      final currentUserId = getCurrentUserId();
      debugPrint(
          '[ChatHandler] ⏭️ User ID Saat ini ${currentUserId ?? 'null'}');
      final activeRoomId = getActiveRoomId();
      debugPrint('[ChatHandler] ⏭️ active Room Id ${activeRoomId ?? 'null'}');
      final isOwnMessage = senderId == currentUserId;

      // ── 1. Own echo — sendStatus: 'sent' (konfirmasi dari BE) ──────────────
      if (isOwnMessage && sendStatus == 'sent') {
        final chatModel = _parseChatModel(detail, message);
        if (chatModel == null) return;
        onMessageReceived(chatModel, 'sent');
        return;
      }

      // ── 2. Status echo MILIK SENDIRI (received/read dari partner) ─────────
      // BE broadcast FCM ini ke semua peserta termasuk pengirim asli.
      // Update status lokal pesan kita dari 'sent' → 'received'/'read'.
      // Tidak perlu hit API — backend sudah tahu statusnya.
      if (isOwnMessage && sendStatus != 'sent') {
        final chatModel = _parseChatModel(detail, message);
        if (chatModel == null) return;
        onMessageReceived(chatModel, sendStatus);
        debugPrint(
            '[ChatHandler] ✅ Own message echo ($sendStatus), update local status');
        return;
      }

      // ── 3. Parse ChatModel ──────────────────────────────────────────────────
      final chatModel = _parseChatModel(detail, message);
      if (chatModel == null) return;

      // ── 4. Status echo dari orang LAIN (received/read update untuk kita) ───
      // Ini adalah konfirmasi bahwa penerima sudah menerima/membaca pesan kita.
      // Persist dengan status asli dari FCM, tidak perlu panggil API.
      if (sendStatus != 'sent') {
        onMessageReceived(chatModel, sendStatus);
        debugPrint(
            '[ChatHandler] 🔕 Status echo ($sendStatus) dari penerima, persist only');
        return;
      }

      // ── 5. Pesan BARU dari orang lain (sendStatus: 'sent') ─────────────────
      final bool isUserInSameRoom = activeRoomId != null &&
          activeRoomId.isNotEmpty &&
          activeRoomId == roomId;

      final String targetStatus = isUserInSameRoom ? 'read' : 'received';

      final chatModelWithStatus = chatModel.copyWith(sendStatus: targetStatus);
      onMessageReceived(chatModelWithStatus, targetStatus);
      onUpdateMessageStatus(messageId, roomId, targetStatus);

      if (!isUserInSameRoom) {
        await _showLocalNotification(
          messageId: messageId,
          roomId: roomId,
          senderId: senderId,
          messageText: messageText,
          jenisPesan: jenisPesan,
        );
      } else {
        debugPrint('[ChatHandler] 🔕 No notif — user is in same room');
      }
    } catch (e, st) {
      debugPrint('[ChatHandler] ❌ handleForegroundMessage error: $e\n$st');
    }
  }

  // =========================================
  // PARSE CHAT MODEL
  // =========================================

  ChatModel? _parseChatModel(
    Map<String, dynamic> detail,
    RemoteMessage message,
  ) {
    try {
      // Normalisasi key (FCM bisa kirim snake_case atau PascalCase)
      final normalized = <String, dynamic>{
        'Message_Id': detail['message_id'] ?? detail['Message_Id'] ?? '',
        'Room_Id': detail['room_id'] ?? detail['Room_Id'] ?? '',
        'Sender_Id': detail['sender_id'] ?? detail['Sender_Id'] ?? '',
        'Tipe_User': detail['tipe_user'] ?? detail['Tipe_User'] ?? '',
        'Message': detail['message'] ?? detail['Message'] ?? '',
        'Jenis_Pesan': detail['jenis_pesan'] ?? detail['Jenis_Pesan'] ?? 'text',
        'Id_Paket': detail['id_paket'] ?? detail['Id_Paket'],
        'No_Pesanan': detail['no_pesanan'] ?? detail['No_Pesanan'],
        'No_Penawaran': detail['no_penawaran'] ?? detail['No_Penawaran'],
        'Status': detail['status'] ?? 'aktif',
        'Send_Status': detail['send_status'] ?? detail['Send_Status'] ?? 'sent',
        'Room_Type': detail['room_type'] ?? detail['Room_Type'] ?? 'direct',
        'Sent_At': detail['sent_at'] ?? detail['Sent_At'],
        'User_Ids': detail['user_ids'] ?? detail['User_Ids'] ?? [],
        'Receiver_Ids': detail['receiver_ids'] ?? detail['Receiver_Ids'] ?? [],
        'Local_Id': detail['local_id'] ?? detail['Local_Id'],
      };

      return ChatModel.fromJson(normalized);
    } catch (e) {
      debugPrint('[ChatHandler] ⚠️ _parseChatModel error: $e');
      return null;
    }
  }

  // =========================================
  // LOCAL NOTIFICATION
  // =========================================

  Future<void> _showLocalNotification({
    required String messageId,
    required String roomId,
    required String senderId,
    required String messageText,
    required String jenisPesan,
  }) async {
    try {
      // Grouping pesan per sender (agar notif tidak flood)
      _messageGroups[senderId] ??= [];
      _messageGroups[senderId]!.add(messageId);
      final count = _messageGroups[senderId]!.length;

      final senderName = getSenderName(roomId, senderId);
      final displayText = _formatContent(messageText, jenisPesan);

      // Body: "2 pesan baru" jika lebih dari satu, otherwise isi pesan
      final body =
          count > 1 ? '$count pesan baru dari $senderName' : displayText;

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
        autoCancel: true,
        groupKey: 'chat_$senderId',
        setAsGroupSummary: count > 1,
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
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: payload,
      );

      debugPrint('[ChatHandler] 🔔 Notif shown: $senderName — $displayText');
    } catch (e) {
      debugPrint('[ChatHandler] ⚠️ _showLocalNotification: $e');
    }
  }

  // =========================================
  // UTILITIES
  // =========================================

  String _formatContent(String message, String jenisPesan) {
    if (message.isNotEmpty) return message;
    switch (jenisPesan) {
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

  void clearMessagesForSender(String senderId) {
    _messageGroups.remove(senderId);
    debugPrint('[ChatHandler] 🧹 Cleared notif group: $senderId');
  }

  void clearAllMessageGroups() {
    _messageGroups.clear();
    debugPrint('[ChatHandler] 🧹 All notif groups cleared');
  }
}
