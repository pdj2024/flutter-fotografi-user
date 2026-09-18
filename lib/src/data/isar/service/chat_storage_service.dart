import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/isar/data/chat_message_entity.dart';
import 'package:mpjnew/src/data/isar/data/room_chat_entity.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_isar_service.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mpjnew/src/features/customer/view/chat/data/service/chat_api_service.dart';

const _kBgQueueKey = 'chat_bg_queue';
const _kActiveRoomKey = 'chat_active_room_id';
const _kPendingRoomFetchKey = 'chat_pending_room_fetch';

class ChatStorageService {
  static final ChatStorageService instance = ChatStorageService._internal();
  factory ChatStorageService() => instance;
  ChatStorageService._internal();

  final ChatIsarService _isar = ChatIsarService.instance;
  String? currentUserId;
  String? _activeRoomId;
  void Function(String roomId)? onRoomResolved;

  void setCurrentUser(String userId) {
    currentUserId = userId;
    debugPrint('[ChatStorage] 👤 Current user: $userId');
  }

  void setActiveRoom(String? roomId) {
    _activeRoomId = roomId;
    debugPrint('[ChatStorage] 🏠 Active room: $roomId');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FOREGROUND: FCM → Isar
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> persistForegroundMessage(ChatModel chatModel) async {
    try {
      if (chatModel.messageId.isEmpty) {
        debugPrint('[ChatStorage] ⚠️ Invalid: empty messageId');
        return false;
      }

      final isOwnMessage = chatModel.senderId == currentUserId;

      if (chatModel.roomId.isEmpty && !isOwnMessage) {
        debugPrint(
            '[ChatStorage] ⚠️ Invalid: empty roomId for incoming message');
        return false;
      }

      debugPrint('[ChatStorage] 📨 persist: ${chatModel.messageId}'
          ' sender=${chatModel.senderId} me=$currentUserId'
          ' roomId="${chatModel.roomId.isEmpty ? "(first msg)" : chatModel.roomId}"'
          ' status=${chatModel.sendStatus}');

      if (isOwnMessage) {
        return await _handleOwnEcho(chatModel);
      }

      final existsByMessageId = await _isar.messageExists(chatModel.messageId);
      if (existsByMessageId) {
        await _isar.updateMessageStatusIfHigher(
            chatModel.messageId, chatModel.sendStatus, _statusPriority);
        return false;
      }

      final localEcho = await _findMatchingLocalEcho(chatModel);
      if (localEcho != null) {
        return await _replaceLocalEcho(
          localMessageId: localEcho.messageId,
          serverMessage: chatModel,
        );
      }

      return await _handleIncoming(chatModel);
    } catch (e, st) {
      debugPrint('[ChatStorage] ❌ persistForegroundMessage: $e\n$st');
      return false;
    }
  }

  static const _statusPriority = {'sent': 1, 'received': 2, 'read': 3};

  Future<bool> _handleOwnEcho(ChatModel chatModel) async {
    final incomingStatus = chatModel.sendStatus;

    if (chatModel.localId != null &&
        chatModel.localId!.isNotEmpty &&
        chatModel.localId!.startsWith('local-')) {
      final localEntity = await _isar.getMessageByLocalId(chatModel.localId!);

      if (localEntity != null) {
        debugPrint('[ChatStorage] ✅ Own echo matched by localId: '
            '${chatModel.localId} → ${chatModel.messageId}');

        if (localEntity.roomId.isEmpty ||
            localEntity.roomId.startsWith('temp-')) {
          return await _handleFirstMessageEcho(
            localEntity: localEntity,
            serverMessage: chatModel,
          );
        }

        return await _replaceLocalEcho(
          localMessageId: chatModel.localId!,
          serverMessage: chatModel,
        );
      }

      debugPrint(
          '[ChatStorage] ⚠️ localId not found in Isar: ${chatModel.localId}');
    }

    if (chatModel.roomId.isNotEmpty) {
      final echoByContent = await _isar.findLocalEchoByContent(
        roomId: chatModel.roomId,
        message: chatModel.message,
        sentAt: chatModel.sentAt,
      );

      if (echoByContent != null) {
        debugPrint('[ChatStorage] ✅ Own echo matched by content+time '
            '(roomId): ${echoByContent.messageId}');

        if (echoByContent.roomId.isEmpty ||
            echoByContent.roomId.startsWith('temp-')) {
          return await _handleFirstMessageEcho(
            localEntity: echoByContent,
            serverMessage: chatModel,
          );
        }

        return await _replaceLocalEcho(
          localMessageId: echoByContent.messageId,
          serverMessage: chatModel,
        );
      }
    }

    final echoNoRoom = await _isar.findLocalEchoByContentNoRoom(
      message: chatModel.message,
      sentAt: chatModel.sentAt,
      senderId: chatModel.senderId,
    );

    if (echoNoRoom != null) {
      debugPrint('[ChatStorage] ✅ Own echo matched by content+time '
          '(no room filter): ${echoNoRoom.messageId} '
          'roomId="${echoNoRoom.roomId}"');

      if (echoNoRoom.roomId.isEmpty || echoNoRoom.roomId.startsWith('temp-')) {
        return await _handleFirstMessageEcho(
          localEntity: echoNoRoom,
          serverMessage: chatModel,
        );
      }

      return await _replaceLocalEcho(
        localMessageId: echoNoRoom.messageId,
        serverMessage: chatModel,
      );
    }

    final alreadyExists = await _isar.messageExists(chatModel.messageId);
    if (alreadyExists) {
      await _isar.updateMessageStatusIfHigher(
        chatModel.messageId,
        incomingStatus,
        _statusPriority,
      );
      debugPrint('[ChatStorage] ⏭️ Own echo duplicate: ${chatModel.messageId}');
      return false;
    }

    debugPrint('[ChatStorage] ℹ️ Own echo: no local match found, '
        'saving as new: ${chatModel.messageId}');
    await _isar.saveMessage(ChatMessageEntity.fromChatModel(chatModel));
    await _updateRoomLastMessage(chatModel);
    return true;
  }

  Future<bool> _handleFirstMessageEcho({
    required ChatMessageEntity localEntity,
    required ChatModel serverMessage,
  }) async {
    final roomId = serverMessage.roomId;

    debugPrint('[ChatStorage] 🆕 First message echo: '
        'localId=${localEntity.messageId} '
        'roomId=$roomId '
        'messageId=${serverMessage.messageId}');

    if (roomId.isEmpty || roomId.startsWith('temp-')) {
      debugPrint('[ChatStorage] ⚠️ Server roomId tidak valid, skip');
      return false;
    }

    // ── 1. Buat room baru di Isar jika belum ada ──────────────────────
    // Catatan: ChatSyncService._handleNewRoomFromApi() mungkin sudah buat
    // room ini lebih awal (dari response API). Jika sudah ada, skip.
    final roomExists = await _isar.getRoomById(roomId);
    if (roomExists == null) {
      final idLawan = serverMessage.userIds
          .firstWhere((id) => id != currentUserId, orElse: () => '');

      final newRoom = RoomChatEntity()
        ..roomId = roomId
        ..roomType = serverMessage.roomType
        ..idLawan = idLawan
        ..lastMessage = chatPreviewText(
          jenis: serverMessage.resolvedJenisPesan,
          message: serverMessage.message,
        )
        ..lastMessageAt = serverMessage.sentAt
        ..unread = 0
        ..countStatusReceived = 0
        ..listIdMessageReceived = []
        ..countStatusSent = 0
        ..listIdMessageSent = []
        ..userIds = serverMessage.userIds;

      await _isar.saveRoom(newRoom);
      debugPrint('[ChatStorage] ✅ Room baru: $roomId (idLawan: $idLawan)');

      await _enqueuePendingRoomFetch(roomId);
    } else {
      debugPrint(
          '[ChatStorage] ℹ️ Room sudah ada (dari API response): $roomId');
    }

    // ── 1b. Hapus temp room jika ada ──────────────────────────────────
    if (localEntity.roomId.startsWith('temp-')) {
      await _isar.deleteRoom(localEntity.roomId);
      debugPrint('[ChatStorage] 🗑️ Temp room deleted: ${localEntity.roomId}');
    }

    // ── 2. Replace local echo ─────────────────────────────────────────
    await _isar.replaceLocalMessage(
      localId: localEntity.messageId,
      serverEntity: ChatMessageEntity.fromChatModel(serverMessage),
    );

    // ── 3. Update lastMessage room ─────────────────────────────────────
    await _updateRoomLastMessage(serverMessage);

    // ── 4. Notify RoomChatProvider ─────────────────────────────────────
    // Jika ChatSyncService sudah call onRoomResolved() lebih awal (dari
    // response API), callback ini sudah di-null-kan. Jadi call ini
    // hanya efektif jika FCM datang lebih dulu dari response API.
    if (onRoomResolved != null) {
      debugPrint('[ChatStorage] 📣 onRoomResolved($roomId) via FCM echo');
      onRoomResolved!(roomId);
    }

    debugPrint('[ChatStorage] ✅ First message handled: '
        '${localEntity.messageId} → ${serverMessage.messageId}');
    return true;
  }

  Future<bool> _replaceLocalEcho({
    required String localMessageId,
    required ChatModel serverMessage,
  }) async {
    await _isar.replaceLocalMessage(
      localId: localMessageId,
      serverEntity: ChatMessageEntity.fromChatModel(serverMessage),
    );
    await _updateRoomLastMessage(serverMessage);
    debugPrint('[ChatStorage] ✅ Local echo replaced: '
        '$localMessageId → ${serverMessage.messageId}');
    return true;
  }

  Future<ChatMessageEntity?> _findMatchingLocalEcho(ChatModel chatModel) async {
    final result = await _isar.findLocalEchoByContent(
      roomId: chatModel.roomId,
      message: chatModel.message,
      sentAt: chatModel.sentAt,
    );
    if (result != null) return result;

    if (chatModel.roomId.isNotEmpty && chatModel.senderId == currentUserId) {
      return await _isar.findLocalEchoByContentNoRoom(
        message: chatModel.message,
        sentAt: chatModel.sentAt,
        senderId: chatModel.senderId,
      );
    }
    return null;
  }

  Future<bool> _handleIncoming(ChatModel chatModel) async {
    final exists = await _isar.messageExists(chatModel.messageId);
    if (exists) {
      await _isar.updateMessageStatus(
          chatModel.messageId, chatModel.sendStatus);
      debugPrint('[ChatStorage] ⏭️ Incoming dup → ${chatModel.sendStatus}');
      return false;
    }

    final roomExists = await _isar.getRoomById(chatModel.roomId);
    final isNewRoom = roomExists == null;

    if (isNewRoom) {
      final minimalRoom = RoomChatEntity()
        ..roomId = chatModel.roomId
        ..roomType = 'direct'
        ..idLawan = chatModel.senderId
        ..lastMessage = chatPreviewText(
          jenis: chatModel.resolvedJenisPesan,
          message: chatModel.message,
        )
        ..lastMessageAt = chatModel.sentAt
        ..unread = 0
        ..countStatusReceived = 0
        ..listIdMessageReceived = []
        ..countStatusSent = 0
        ..listIdMessageSent = []
        ..userIds = [];
      await _isar.saveRoom(minimalRoom);
    }

    final bool isUserInSameRoom = _activeRoomId != null &&
        _activeRoomId!.isNotEmpty &&
        _activeRoomId == chatModel.roomId;

    // Status sudah ditentukan oleh FCM handler sebelum memanggil _handleIncoming:
    //   Scenario 5 (pesan baru): chatModel.sendStatus sudah 'read' atau 'received'
    //   Scenario 4 (status echo): chatModel.sendStatus = 'received' → jangan di-override ke 'read'
    // Override isUserInSameRoom di sini menyebabkan race condition: status echo 'received'
    // ter-override menjadi 'read' ketika user sedang di room.
    final String targetStatus = chatModel.sendStatus;

    await _isar.saveMessage(ChatMessageEntity.fromChatModel(chatModel));
    await _updateRoomLastMessage(chatModel);

    if (targetStatus != 'read') {
      await _incrementRoomReceived(chatModel);
    } else {
      debugPrint(
          '[ChatStorage] 👁️ User in room, skip unread increment: ${chatModel.roomId}');
    }
    // HTTP update untuk pesan baru (Scenario 5) sudah dipanggil via onUpdateMessageStatus
    // di FCM handler. Status echo (Scenario 4) tidak memerlukan HTTP update di sini.

    if (isNewRoom) {
      await _enqueuePendingRoomFetch(chatModel.roomId);
      debugPrint(
          '[ChatStorage] 🆕 New room (foreground) — queued: ${chatModel.roomId}');
    }

    debugPrint(
        '[ChatStorage] 💬 Incoming saved (status=$targetStatus): ${chatModel.messageId}');
    return true;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PENDING ROOM FETCH
  // ═══════════════════════════════════════════════════════════════════════════

  /// Private — dipakai internal oleh ChatStorageService
  static Future<void> _enqueuePendingRoomFetch(String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_kPendingRoomFetchKey) ?? [];
      if (!existing.contains(roomId)) {
        existing.add(roomId);
        await prefs.setStringList(_kPendingRoomFetchKey, existing);
        debugPrint('[ChatStorage] 📋 Pending room enqueued: $roomId');
      }
    } catch (e) {
      debugPrint('[ChatStorage] ⚠️ _enqueuePendingRoomFetch: $e');
    }
  }

  /// ✅ Public wrapper — dipakai oleh ChatSyncService setelah room baru
  /// dibuat dari response API (bukan dari FCM).
  ///
  /// Diperlukan karena _enqueuePendingRoomFetch adalah static private
  /// dan ChatSyncService berada di file berbeda.
  static Future<void> enqueuePendingRoomFetchPublic(String roomId) =>
      _enqueuePendingRoomFetch(roomId);

  static Future<List<String>> getPendingRoomFetchIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_kPendingRoomFetchKey) ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearPendingRoomFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPendingRoomFetchKey);
    } catch (_) {}
  }

  Future<void> drainPendingRoomFetch({required String userId}) async {
    try {
      final pendingIds = await getPendingRoomFetchIds();
      if (pendingIds.isEmpty) return;

      debugPrint(
          '[ChatStorage] 🔄 Draining ${pendingIds.length} pending rooms: $pendingIds');

      final rooms = await _fetchRoomsViaApiClient(userId: userId);

      if (rooms.isEmpty) {
        debugPrint(
            '[ChatStorage] ⚠️ drainPendingRoomFetch: rooms empty, retry later');
        return;
      }

      await persistRoomsFromApi(rooms, replace: false);
      debugPrint('[ChatStorage] ✅ Rooms upserted: ${rooms.length}');

      for (final roomId in pendingIds) {
        await _fetchAndSaveMessages(roomId: roomId);
      }

      await clearPendingRoomFetch();

      debugPrint(
          '[ChatStorage] ✅ Pending room fetch complete (${pendingIds.length} rooms)');
    } catch (e, st) {
      debugPrint('[ChatStorage] ❌ drainPendingRoomFetch: $e\n$st');
    }
  }

  Future<List<RoomChatModel>> _fetchRoomsViaApiClient(
      {required String userId}) async {
    try {
      final response = await apiClient.get(
        '/chat/getRooms',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode != 200) {
        debugPrint(
            '[ChatStorage] ⚠️ _fetchRoomsViaApiClient: ${response.statusCode}');
        return [];
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = body['Data'] as List<dynamic>? ?? [];

      return raw
          .whereType<Map<String, dynamic>>()
          .map((e) => RoomChatModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('[ChatStorage] ⚠️ _fetchRoomsViaApiClient: $e');
      return [];
    }
  }

  Future<void> _fetchAndSaveMessages({required String roomId}) async {
    try {
      final response = await apiClient.get(
        '/chat/getAll',
        queryParameters: {
          'room_id': roomId,
          'status': 'aktif',
          'orderBy': 'Sent_at',
          'orderDir': 'desc',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
            '[ChatStorage] ⚠️ _fetchAndSaveMessages $roomId: ${response.statusCode}');
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = body['Data'] as List<dynamic>? ?? [];

      final messages = raw
          .whereType<Map<String, dynamic>>()
          .map((e) => ChatModel.fromJson(e))
          .toList();

      if (messages.isEmpty) {
        debugPrint('[ChatStorage] ℹ️ No messages for room: $roomId');
        return;
      }

      await _isar.saveAllMessages(
        messages.map((m) => ChatMessageEntity.fromChatModel(m)).toList(),
      );

      debugPrint(
          '[ChatStorage] 💾 Messages saved for new room: $roomId (${messages.length})');
    } catch (e) {
      debugPrint('[ChatStorage] ⚠️ _fetchAndSaveMessages $roomId: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKGROUND: FCM → SharedPreferences Queue → Isar (saat app resume)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<bool> enqueueBackgroundMessage(RemoteMessage message) async {
    try {
      final detail = _parseDetail(message.data['detail']);
      if (detail.isEmpty) return false;

      final messageId = detail['message_id']?.toString() ?? '';
      final roomId = detail['room_id']?.toString() ?? '';
      final sendStatus = detail['send_status']?.toString() ?? 'sent';

      if (messageId.isEmpty || roomId.isEmpty) return false;

      await _incrementRoomUnreadCount(roomId, detail);

      if (sendStatus != 'sent') {
        debugPrint(
            '[ChatStorage] ℹ️ Skip bg enqueue (echo: $sendStatus): $messageId');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kBgQueueKey) ?? [];

      final isDuplicate = raw.any((item) {
        try {
          return (jsonDecode(item) as Map<String, dynamic>)['message_id'] ==
              messageId;
        } catch (_) {
          return false;
        }
      });
      if (isDuplicate) return false;

      raw.add(jsonEncode(
          {...detail, '_queued_at': DateTime.now().toIso8601String()}));
      final trimmed = raw.length > 100 ? raw.sublist(raw.length - 100) : raw;
      await prefs.setStringList(_kBgQueueKey, trimmed);

      debugPrint('[ChatStorage] 📦 Enqueued: $messageId (${trimmed.length})');

      // Simpan pesan ke SQLite langsung agar Room Chat bisa tampilkan segera
      // tanpa menunggu drainBackgroundQueue. Status 'received' — bukan 'sent'.
      try {
        final db = ChatIsarService.instance;
        if (!db.isInitialized) await db.initialize();
        final alreadyExists = await db.messageExists(messageId);
        if (!alreadyExists) {
          final chatModel = ChatModel.fromJson(_normalizeDetailKeys(detail));
          final msgWithStatus = chatModel.copyWith(sendStatus: 'received');
          await db.saveMessage(ChatMessageEntity.fromChatModel(msgWithStatus));
          debugPrint('[ChatStorage] 💾 BG message saved to SQLite: $messageId');
        }
      } catch (e) {
        debugPrint('[ChatStorage] ⚠️ BG SQLite save failed: $e');
        // SharedPrefs queue tetap ada sebagai fallback
      }

      unawaited(
          _updateStatusViaHttp(messageId: messageId, newStatus: 'received'));
      return true;
    } catch (e, st) {
      debugPrint('[ChatStorage] ❌ enqueueBackgroundMessage: $e\n$st');
      return false;
    }
  }

  static Future<void> _incrementRoomUnreadCount(
    String roomId,
    Map<String, dynamic> detail,
  ) async {
    try {
      final isar = ChatIsarService.instance;
      if (!isar.isInitialized) await isar.initialize();

      final prefs = await SharedPreferences.getInstance();
      final activeRoomId = prefs.getString(_kActiveRoomKey);
      final isUserInSameRoom = activeRoomId != null &&
          activeRoomId.isNotEmpty &&
          activeRoomId == roomId;

      final messageId = detail['message_id']?.toString() ?? '';
      final messageText = detail['message']?.toString() ?? '';
      final sentAt = DateTime.tryParse(detail['sent_at']?.toString() ?? '') ??
          DateTime.now();
      // Resolusi tipe lewat ChatModel: field jenis_pesan mentah sering "text"
      // padahal tipe aslinya ada di no_penawaran / no_invoice / id_paket.
      final preview = chatPreviewText(
        jenis: ChatModel.fromJson(_normalizeDetailKeys(detail))
            .resolvedJenisPesan,
        message: messageText,
      );

      final existing = await isar.getRoomById(roomId);

      if (existing != null) {
        if (messageId.isNotEmpty &&
            existing.listIdMessageReceived.contains(messageId)) {
          debugPrint('[ChatStorage] ⏭️ Duplicate: $messageId');
          return;
        }

        if (!isUserInSameRoom) {
          final newList = messageId.isNotEmpty
              ? [...existing.listIdMessageReceived, messageId]
              : existing.listIdMessageReceived;

          final updated = existing.copyWith(
            lastMessage: preview,
            lastMessageAt: sentAt,
            countStatusReceived: newList.length,
            listIdMessageReceived: newList,
          );
          await isar.saveRoom(updated);
          debugPrint(
              '[ChatStorage] 🔴 BG unread +1: $roomId (total: ${newList.length})');
        } else {
          final updated = existing.copyWith(
            lastMessage: preview,
            lastMessageAt: sentAt,
          );
          await isar.saveRoom(updated);
          debugPrint(
              '[ChatStorage] 👁️ BG skip unread (user in room when minimized): $roomId');
          // Status 'read' hanya di-set saat user benar-benar membuka room (drainQueue)
          // Jangan panggil _updateStatusViaHttp('read') di sini — activeRoomId di SharedPrefs
          // bisa stale jika app di-force close saat di room.
        }
      } else {
        final unreadCount = isUserInSameRoom ? 0 : 1;
        final receivedList =
            (isUserInSameRoom || messageId.isEmpty) ? <String>[] : [messageId];

        final newRoom = RoomChatEntity()
          ..roomId = roomId
          ..roomType = detail['room_type']?.toString() ?? 'direct'
          ..idLawan = detail['sender_id']?.toString() ?? ''
          ..lastMessage = preview
          ..lastMessageAt = sentAt
          ..unread = unreadCount
          ..countStatusReceived = receivedList.length
          ..listIdMessageReceived = receivedList
          ..countStatusSent = 0
          ..listIdMessageSent = []
          ..userIds = [];

        await isar.saveRoom(newRoom);

        final pendingIds = prefs.getStringList(_kPendingRoomFetchKey) ?? [];
        if (!pendingIds.contains(roomId)) {
          pendingIds.add(roomId);
          await prefs.setStringList(_kPendingRoomFetchKey, pendingIds);
          debugPrint('[ChatStorage] 📋 BG new room queued: $roomId');
        }

        debugPrint(
            '[ChatStorage] 🔴 BG minimal room created: $roomId (unread: $unreadCount)');
      }
    } catch (e) {
      debugPrint('[ChatStorage] ⚠️ _incrementRoomUnreadCount: $e');
    }
  }

  Future<int> drainBackgroundQueue({String? activeRoomId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kBgQueueKey) ?? [];
      if (raw.isEmpty) return 0;

      debugPrint('[ChatStorage] 📬 Draining ${raw.length} messages...');

      final effectiveActiveRoom =
          activeRoomId ?? prefs.getString(_kActiveRoomKey);
      debugPrint('[ChatStorage] 🏠 Active room: $effectiveActiveRoom');

      if (activeRoomId != null) {
        final room = await _isar.getRoomById(activeRoomId);
        if (room != null) {
          await _isar.saveRoom(room.copyWith(
            countStatusReceived: 0,
            listIdMessageReceived: [],
          ));
          debugPrint('[ChatStorage] 🧹 Unread cleared: $activeRoomId');
        }
      }

      final List<String> failed = [];
      int processed = 0, readCount = 0, receivedCount = 0;

      for (final item in raw) {
        try {
          final detail = jsonDecode(item) as Map<String, dynamic>;
          final chatModel = ChatModel.fromJson(_normalizeDetailKeys(detail));
          if (chatModel.messageId.isEmpty) continue;

          final isActiveRoom = effectiveActiveRoom != null &&
              chatModel.roomId == effectiveActiveRoom;
          final targetStatus = isActiveRoom ? 'read' : 'received';

          final existsByMessageId =
              await _isar.messageExists(chatModel.messageId);
          if (existsByMessageId) {
            final isOwnEchoMsg = chatModel.senderId == currentUserId;

            if (!isOwnEchoMsg) {
              await _isar.updateMessageStatus(
                  chatModel.messageId, targetStatus);
              unawaited(_updateStatusViaHttp(
                messageId: chatModel.messageId,
                newStatus: targetStatus,
              ));
            } else {
              debugPrint(
                  '[ChatStorage] ⏭️ Drain own echo duplicate, skip status update: '
                  '${chatModel.messageId}');
            }
            debugPrint(
                '[ChatStorage] ⏭️ Drain exists → skip save: ${chatModel.messageId}');
            continue;
          }

          bool isOwnEcho = false;

          if (chatModel.localId != null &&
              chatModel.localId!.isNotEmpty &&
              chatModel.localId!.startsWith('local-')) {
            final localEntity =
                await _isar.getMessageByLocalId(chatModel.localId!);

            if (localEntity != null) {
              isOwnEcho = true;

              if (localEntity.roomId.isEmpty ||
                  localEntity.roomId.startsWith('temp-')) {
                await _handleFirstMessageEcho(
                  localEntity: localEntity,
                  serverMessage: _withStatus(chatModel, targetStatus),
                );
              } else {
                await _isar.replaceLocalMessage(
                  localId: chatModel.localId!,
                  serverEntity: ChatMessageEntity.fromChatModel(
                    _withStatus(chatModel, targetStatus),
                  ),
                );
              }
              debugPrint('[ChatStorage] ✅ Drain own echo (localId): '
                  '${chatModel.localId} → ${chatModel.messageId}');
            }
          }

          if (!isOwnEcho && chatModel.roomId.isNotEmpty) {
            final echoByContent = await _isar.findLocalEchoByContent(
              roomId: chatModel.roomId,
              message: chatModel.message,
              sentAt: chatModel.sentAt,
            );

            if (echoByContent != null) {
              isOwnEcho = true;

              if (echoByContent.roomId.isEmpty ||
                  echoByContent.roomId.startsWith('temp-')) {
                await _handleFirstMessageEcho(
                  localEntity: echoByContent,
                  serverMessage: _withStatus(chatModel, targetStatus),
                );
              } else {
                await _isar.replaceLocalMessage(
                  localId: echoByContent.messageId,
                  serverEntity: ChatMessageEntity.fromChatModel(
                    _withStatus(chatModel, targetStatus),
                  ),
                );
              }
              debugPrint('[ChatStorage] ✅ Drain own echo (content+roomId): '
                  '${echoByContent.messageId} → ${chatModel.messageId}');
            }
          }

          if (!isOwnEcho) {
            final echoNoRoom = await _isar.findLocalEchoByContentNoRoom(
              message: chatModel.message,
              sentAt: chatModel.sentAt,
              senderId: chatModel.senderId,
            );

            if (echoNoRoom != null) {
              isOwnEcho = true;

              if (echoNoRoom.roomId.isEmpty ||
                  echoNoRoom.roomId.startsWith('temp-')) {
                await _handleFirstMessageEcho(
                  localEntity: echoNoRoom,
                  serverMessage: _withStatus(chatModel, targetStatus),
                );
              } else {
                await _isar.replaceLocalMessage(
                  localId: echoNoRoom.messageId,
                  serverEntity: ChatMessageEntity.fromChatModel(
                    _withStatus(chatModel, targetStatus),
                  ),
                );
              }
              debugPrint('[ChatStorage] ✅ Drain own echo (content+noRoom): '
                  '${echoNoRoom.messageId} → ${chatModel.messageId}');
            }
          }

          if (!isOwnEcho) {
            await _handleIncoming(_withStatus(chatModel, targetStatus));
          }

          if (!isOwnEcho) {
            unawaited(_updateStatusViaHttp(
              messageId: chatModel.messageId,
              newStatus: isActiveRoom ? 'read' : 'received',
            ));
            if (isActiveRoom) {
              readCount++;
            } else {
              receivedCount++;
            }
          }

          processed++;
        } catch (e) {
          debugPrint('[ChatStorage] ⚠️ Drain item error: $e');
          failed.add(item);
        }
      }

      if (failed.isEmpty) {
        await prefs.remove(_kBgQueueKey);
      } else {
        await prefs.setStringList(_kBgQueueKey, failed);
      }

      debugPrint('[ChatStorage] ✅ Drained $processed '
          '($readCount read, $receivedCount received)');
      return processed;
    } catch (e, st) {
      debugPrint('[ChatStorage] ❌ drainBackgroundQueue: $e\n$st');
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HTTP STATUS UPDATE
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> _updateStatusViaHttp({
    required String messageId,
    required String newStatus,
  }) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      if (token == null || token.isEmpty) return;

      final uri = Uri.parse(
        '${Constants.baseUrl}/api/chat/update-send-status'
        '?message_id=$messageId&send_status=$newStatus',
      );

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Jenis-User': Constants.customer,
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('[ChatStorage] ${response.statusCode == 200 ? "✅" : "⚠️"} '
          'HTTP: $messageId → $newStatus (${response.statusCode})');
    } catch (e) {
      debugPrint('[ChatStorage] ⚠️ _updateStatusViaHttp: $e');
    }
  }

  static Future<void> _updateRoomStatusViaHttp({
    required List<String> messageIds,
    required String newStatus,
  }) async {
    if (messageIds.isEmpty) return;
    await Future.wait(
      messageIds.map(
          (id) => _updateStatusViaHttp(messageId: id, newStatus: newStatus)),
      eagerError: false,
    );
    debugPrint(
        '[ChatStorage] ✅ Bulk HTTP update ($newStatus, ${messageIds.length} msgs)');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIVE ROOM PREF
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> setActiveRoomPref(String? roomId) async {
    final prefs = await SharedPreferences.getInstance();
    if (roomId != null) {
      await prefs.setString(_kActiveRoomKey, roomId);
    } else {
      await prefs.remove(_kActiveRoomKey);
    }
    ChatStorageService.instance._activeRoomId = roomId;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // API BATCH SAVE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> persistMessagesFromApi(List<ChatModel> messages) async {
    if (messages.isEmpty) return;
    try {
      await _isar.saveAllMessages(
        messages.map((m) => ChatMessageEntity.fromChatModel(m)).toList(),
      );
      debugPrint('[ChatStorage] 💾 API batch: ${messages.length} messages');
    } catch (e, st) {
      debugPrint('[ChatStorage] ❌ persistMessagesFromApi: $e\n$st');
    }
  }

  Future<void> persistRoomsFromApi(
    List<RoomChatModel> rooms, {
    bool replace = false,
  }) async {
    if (rooms.isEmpty) return;

    final aktifRooms = rooms.where((r) => r.status == 'aktif').toList();
    final nonaktifIds = rooms
        .where((r) => r.status != 'aktif')
        .map((r) => r.roomId)
        .toSet();

    if (nonaktifIds.isNotEmpty) {
      debugPrint('[ChatStorage] 🗑 Nonaktif dari API: ${nonaktifIds.length} room(s)');
    }

    try {
      if (replace) {
        final entities = aktifRooms.map((room) {
          return RoomChatEntity.fromRoomChatModel(room)
            ..countStatusReceived = 0
            ..listIdMessageReceived = [];
        }).toList();

        await _isar.replaceAllRooms(entities);
        debugPrint('[ChatStorage] 🔄 Rooms replaced: ${aktifRooms.length}'
            '${nonaktifIds.isNotEmpty ? " (${nonaktifIds.length} nonaktif dibuang)" : ""}');
      } else {
        for (final room in aktifRooms) {
          final existing = await _isar.getRoomById(room.roomId);

          if (existing != null) {
            // Pilih lastMessage terbaik: API → existing Isar → rebuild dari pesan tersimpan
            String mergedLastMessage = room.lastMessage.isNotEmpty
                ? room.lastMessage
                : existing.lastMessage;
            // Rebuild jika kosong ATAU hanya berisi placeholder generik 'Pesan baru'
            // (bisa terjadi jika sesi sebelumnya menyimpan nilai salah untuk pesan pesanan/penawaran)
            if (mergedLastMessage.isEmpty || mergedLastMessage == 'Pesan baru') {
              final rebuilt = await _rebuildPreviewFromLastMessage(room.roomId);
              if (rebuilt.isNotEmpty) mergedLastMessage = rebuilt;
            }

            final updated = existing.copyWith(
              lastMessage: mergedLastMessage,
              lastMessageAt: room.lastMessageAt.isAfter(existing.lastMessageAt)
                  ? room.lastMessageAt
                  : existing.lastMessageAt,
              usernameLawan: room.usernameLawan?.isNotEmpty == true
                  ? room.usernameLawan
                  : existing.usernameLawan,
              idMediaLawan: room.idMediaLawan?.isNotEmpty == true
                  ? room.idMediaLawan
                  : existing.idMediaLawan,
              userIds:
                  room.userIds.isNotEmpty ? room.userIds : existing.userIds,
              roomType:
                  room.roomType.isNotEmpty ? room.roomType : existing.roomType,
              idLawan:
                  room.idLawan.isNotEmpty ? room.idLawan : existing.idLawan,
              tipeUserLawan: room.tipeUserLawan?.isNotEmpty == true
                  ? room.tipeUserLawan
                  : existing.tipeUserLawan,
            );
            await _isar.saveRoom(updated);
          } else {
            // Room baru dari API — jika lastMessage kosong, rebuild dari pesan tersimpan
            String lastMsg = room.lastMessage;
            if (lastMsg.isEmpty || lastMsg == 'Pesan baru') {
              final rebuilt = await _rebuildPreviewFromLastMessage(room.roomId);
              if (rebuilt.isNotEmpty) lastMsg = rebuilt;
            }
            final entity = RoomChatEntity.fromRoomChatModel(room)
              ..lastMessage = lastMsg
              ..countStatusReceived = 0
              ..listIdMessageReceived = [];
            await _isar.saveRoom(entity);
          }
        }

        for (final roomId in nonaktifIds) {
          final existing = await _isar.getRoomById(roomId);
          if (existing != null) {
            await _isar.deleteRoom(roomId);
            debugPrint('[ChatStorage] 🗑 Room nonaktif dihapus: $roomId');
          }
        }

        debugPrint('[ChatStorage] 💾 Rooms upserted: ${aktifRooms.length}'
            '${nonaktifIds.isNotEmpty ? " (+${nonaktifIds.length} nonaktif dihapus)" : ""}');
      }
    } catch (e, st) {
      debugPrint('[ChatStorage] ❌ persistRoomsFromApi: $e\n$st');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OPTIMISTIC MESSAGE (Local Echo)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> persistOptimisticMessage(ChatModel message) async {
    try {
      assert(
        message.localId != null && message.localId!.startsWith('local-'),
        'Optimistic message harus punya localId dimulai dengan "local-"',
      );
      await _isar.saveMessage(ChatMessageEntity.fromChatModel(message));
      debugPrint('[ChatStorage] ⏳ Optimistic: ${message.localId}');
    } catch (e, st) {
      debugPrint('[ChatStorage] ❌ persistOptimisticMessage: $e\n$st');
    }
  }

  Future<void> confirmOptimisticMessage({
    required String localId,
    required ChatModel serverMessage,
  }) async {
    try {
      final localEntity = await _isar.getMessageByLocalId(localId);
      final isFirstMessage = localEntity != null &&
          (localEntity.roomId.isEmpty ||
              localEntity.roomId.startsWith('temp-'));

      if (isFirstMessage) {
        final hasRealRoomId = serverMessage.roomId.isNotEmpty &&
            !serverMessage.roomId.startsWith('temp-');

        if (hasRealRoomId) {
          await _handleFirstMessageEcho(
            localEntity: localEntity,
            serverMessage: serverMessage,
          );
          debugPrint(
              '[ChatStorage] ✅ Confirmed first-msg: $localId → ${serverMessage.messageId}');
        } else {
          debugPrint(
              '[ChatStorage] ⏳ confirmOptimistic: roomId kosong dari API, tunggu FCM echo');
        }
        return;
      }

      await _isar.replaceLocalMessage(
        localId: localId,
        serverEntity: ChatMessageEntity.fromChatModel(serverMessage),
      );
      await _updateRoomLastMessage(serverMessage);
      debugPrint(
          '[ChatStorage] ✅ Confirmed: $localId → ${serverMessage.messageId}');
    } catch (e, st) {
      debugPrint('[ChatStorage] ❌ confirmOptimisticMessage: $e\n$st');
    }
  }

  Future<void> markOptimisticAsFailed(String localId) async {
    try {
      final entity = await _isar.getMessageByLocalId(localId);
      if (entity == null) return;
      await _isar.updateMessageStatus(entity.messageId, 'failed');
      debugPrint('[ChatStorage] ❌ Marked failed: $localId');
    } catch (e, st) {
      debugPrint('[ChatStorage] ❌ markOptimisticAsFailed: $e\n$st');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> updateLocalStatus(String messageId, String newStatus) async {
    return _isar.updateMessageStatus(messageId, newStatus);
  }

  Future<void> markRoomAsRead(String roomId) async {
    try {
      final unreadMessages = await _isar.getUnreadMessages(
        roomId,
        currentUserId: currentUserId,
      );

      final unreadIds = unreadMessages
          .map((e) => e.messageId)
          .where((id) => id.isNotEmpty && !id.startsWith('local-'))
          .toList();

      await _isar.markAllMessagesAsRead(roomId, currentUserId: currentUserId);
      await _isar.clearRoomUnread(roomId);

      debugPrint(
          '[ChatStorage] 👁️ Room read: $roomId (${unreadIds.length} msgs)');

      if (unreadIds.isNotEmpty) {
        final chatApi = ChatApiService();
        unawaited(Future.wait(
          unreadIds.map((id) => chatApi.updateMessageStatus(
                messageId: id,
                status: 'read',
              )),
          eagerError: false,
        ));
      }
    } catch (e, st) {
      debugPrint('[ChatStorage] ❌ markRoomAsRead: $e\n$st');
    }
  }

  Future<void> markAllSentAsReceived() async {
    if (currentUserId == null) return;
    try {
      final updatedIds =
          await _isar.markSentMessagesAsReceived(currentUserId!);
      debugPrint('[ChatStorage] 📬 ${updatedIds.length} msgs sent→received');
      if (updatedIds.isNotEmpty) {
        final chatApi = ChatApiService();
        unawaited(Future.wait(
          updatedIds.map((id) => chatApi.updateMessageStatus(
                messageId: id,
                status: 'received',
              )),
          eagerError: false,
        ));
      }
    } catch (e, st) {
      debugPrint('[ChatStorage] ❌ markAllSentAsReceived: $e\n$st');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEAR / LOGOUT
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> clearAll() async {
    await _isar.clearAll();
    currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBgQueueKey);
    await prefs.remove(_kPendingRoomFetchKey);
    debugPrint('[ChatStorage] 🧹 All cleared');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Rebuild preview text dari pesan terakhir yang tersimpan di database.
  /// Dipanggil saat lastMessage room kosong — biasanya karena API tidak
  /// mengembalikan Last_Message untuk pesan tipe pesanan/penawaran/paket.
  Future<String> _rebuildPreviewFromLastMessage(String roomId) async {
    try {
      final messages = await _isar.getMessagesByRoomPaged(
        roomId: roomId,
        offset: 0,
        limit: 1,
      );
      if (messages.isEmpty) return '';
      final last = messages.first;
      return chatPreviewText(
        jenis: JenisPesan.fromString(last.resolvedJenisPesan),
        message: last.message,
      );
    } catch (_) {
      return '';
    }
  }

  Future<void> _updateRoomLastMessage(ChatModel message) async {
    try {
      final room = await _isar.getRoomById(message.roomId);
      if (room == null) return;

      final preview = chatPreviewText(
        jenis: message.resolvedJenisPesan,
        message: message.message,
      );

      await _isar.updateRoomLastMessage(
        roomId: message.roomId,
        lastMessage: preview,
        lastMessageAt: message.sentAt,
      );
    } catch (e) {
      debugPrint('[ChatStorage] ⚠️ _updateRoomLastMessage: $e');
    }
  }

  Future<void> _incrementRoomReceived(ChatModel message) async {
    try {
      if (currentUserId != null && message.senderId == currentUserId) return;
      if (message.messageId.startsWith('local-')) return;

      final room = await _isar.getRoomById(message.roomId);
      if (room == null) return;
      if (room.listIdMessageReceived.contains(message.messageId)) return;

      final newList = [...room.listIdMessageReceived, message.messageId];
      await _isar.updateRoomUnread(
        roomId: message.roomId,
        countStatusReceived: newList.length,
        listIdMessageReceived: newList,
        countStatusSent: room.countStatusSent,
        listIdMessageSent: room.listIdMessageSent,
      );
      debugPrint(
          '[ChatStorage] 🔴 Unread +1: ${message.roomId} (total: ${newList.length})');
    } catch (e) {
      debugPrint('[ChatStorage] ⚠️ _incrementRoomReceived: $e');
    }
  }

  static ChatModel _withStatus(ChatModel model, String status) {
    return model.copyWith(sendStatus: status);
  }

  static Map<String, dynamic> _parseDetail(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    try {
      final decoded = jsonDecode(raw.toString());
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  static Map<String, dynamic> _normalizeDetailKeys(
      Map<String, dynamic> detail) {
    return {
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
  }
}
