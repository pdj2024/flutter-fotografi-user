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

const _kBgQueueKey = 'chat_bg_queue';
const _kActiveRoomKey = 'chat_active_room_id';

/// Key untuk roomId yang perlu di-fetch info-nya dari API.
///
/// Diisi saat FCM masuk dengan room yang belum ada di Isar:
///   - Background: _incrementRoomUnreadCount → buat minimal room → enqueue
///   - Foreground: _handleIncoming → buat minimal room → enqueue
///
/// Di-drain saat:
///   - App resume (ChatProvider.syncRoomFromHiveAndNotify)
///   - ChatProvider.initialize (setelah login)
///   - Foreground FCM masuk (ChatProvider.handleMessageFromFCM)
const _kPendingRoomFetchKey = 'chat_pending_room_fetch';

/// Bridge antara FCM / REST API dan Isar — Customer Edition.
///
/// ─── Alur Room Baru via FCM ──────────────────────────────────────────────
///
///   [FCM masuk — room BELUM ada di Isar]
///
///   BACKGROUND isolate:
///     → _incrementRoomUnreadCount
///       → buat minimal room (roomId, idLawan, preview)  ← badge muncul
///       → enqueue roomId ke _kPendingRoomFetchKey
///     → app resume → ChatProvider._drainPendingRoomFetchIfNeeded()
///       → drainPendingRoomFetch(userId)
///         → fetchRooms via apiClient (GET /chat/getRooms)
///         → UPSERT ke Isar: update usernameLawan, idMediaLawan, userIds
///         → fetchMessages via apiClient (GET /chat/getAll)
///         → simpan messages ke Isar (UPSERT)
///       → Isar stream emit → ChatListPage rebuild (nama, avatar muncul)
///
///   FOREGROUND (app terbuka):
///     → _handleIncoming → buat minimal room → enqueue
///     → ChatProvider.handleMessageFromFCM
///       → _drainPendingRoomFetchIfNeeded() langsung
///       → fetch rooms + messages → UPSERT → stream emit → UI update
class ChatStorageService {
  static final ChatStorageService instance = ChatStorageService._internal();
  factory ChatStorageService() => instance;
  ChatStorageService._internal();

  final ChatIsarService _isar = ChatIsarService.instance;
  String? _currentUserId;
  String? _activeRoomId;
  void Function(String roomId)? onRoomResolved;

  void setCurrentUser(String userId) {
    _currentUserId = userId;
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

      final isOwnMessage = chatModel.senderId == _currentUserId;

      // ✅ FIX BUG 1: Izinkan roomId kosong untuk own echo (local echo pesan pertama)
      // Sebelumnya: (messageId.isEmpty || roomId.isEmpty) → tolak semua
      // Sekarang: roomId kosong hanya valid jika own message (local echo)
      if (chatModel.roomId.isEmpty && !isOwnMessage) {
        debugPrint(
            '[ChatStorage] ⚠️ Invalid: empty roomId for incoming message');
        return false;
      }

      debugPrint('[ChatStorage] 📨 persist: ${chatModel.messageId}'
          ' sender=${chatModel.senderId} me=$_currentUserId'
          ' roomId="${chatModel.roomId.isEmpty ? "(first msg)" : chatModel.roomId}"'
          ' status=${chatModel.sendStatus}');

      if (isOwnMessage) {
        return await _handleOwnEcho(chatModel);
      }

      final existsByMessageId = await _isar.messageExists(chatModel.messageId);
      if (existsByMessageId) {
        await _isar.updateMessageStatus(
            chatModel.messageId, chatModel.sendStatus);
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

    // ── STRATEGI 1: Match by localId (paling akurat) ────────────────────
    if (chatModel.localId != null &&
        chatModel.localId!.isNotEmpty &&
        chatModel.localId!.startsWith('local-')) {
      final localEntity = await _isar.getMessageByLocalId(chatModel.localId!);

      if (localEntity != null) {
        debugPrint('[ChatStorage] ✅ Own echo matched by localId: '
            '${chatModel.localId} → ${chatModel.messageId}');

        // Deteksi pesan pertama: roomId kosong atau temp-
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

      // localId ada di FCM tapi tidak ditemukan di Isar
      // Kemungkinan: sudah di-replace sebelumnya, atau Isar belum sync
      debugPrint(
          '[ChatStorage] ⚠️ localId not found in Isar: ${chatModel.localId}');
    }

    // ── STRATEGI 2: Match by sentAt + message content ─────────────────────
    // Fallback jika localId tidak ada atau tidak ditemukan
    // Cari di room yang sama dulu
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

    // ── STRATEGI 3: Match by sentAt + content tanpa filter roomId ─────────
    // Untuk kasus pesan pertama: local echo punya roomId='' tapi FCM bawa roomId asli
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

    // ── STRATEGI 4: Cek duplikat by messageId ────────────────────────────
    // Mungkin FCM echo datang dua kali
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

    // ── STRATEGI 5: Simpan langsung sebagai pesan baru ────────────────────
    // Tidak ada local echo yang cocok — kemungkinan dikirim dari device lain
    // atau local echo sudah terhapus
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

    // ── 1. Buat room baru di Isar ─────────────────────────────────────
    final roomExists = await _isar.getRoomById(roomId);
    if (roomExists == null) {
      // idLawan = partner (bukan diri sendiri)
      final idLawan = serverMessage.userIds
          .firstWhere((id) => id != _currentUserId, orElse: () => '');

      final newRoom = RoomChatEntity()
        ..roomId = roomId
        ..roomType = serverMessage.roomType
        ..idLawan = idLawan
        ..lastMessage = serverMessage.message.isNotEmpty
            ? serverMessage.message
            : _formatPreview(serverMessage.jenisPesan ?? 'text')
        ..lastMessageAt = serverMessage.sentAt
        ..unread = 0
        ..countStatusReceived = 0
        ..listIdMessageReceived = []
        ..countStatusSent = 0
        ..listIdMessageSent = []
        ..userIds = serverMessage.userIds;
      // usernameLawan, idMediaLawan: kosong dulu
      // akan diisi oleh drainPendingRoomFetch

      await _isar.saveRoom(newRoom);
      debugPrint('[ChatStorage] ✅ Room baru: $roomId (idLawan: $idLawan)');

      // Enqueue untuk fetch usernameLawan + idMediaLawan dari API
      await _enqueuePendingRoomFetch(roomId);
    }

    // ── 1b. Hapus temp room jika ada ─────────────────────────────────
    if (localEntity.roomId.startsWith('temp-')) {
      await _isar.deleteRoom(localEntity.roomId);
      debugPrint('[ChatStorage] 🗑️ Temp room deleted: ${localEntity.roomId}');
    }

    // ── 2. Replace local echo dengan serverMessage ────────────────────
    await _isar.replaceLocalMessage(
      localId: localEntity.messageId,
      serverEntity: ChatMessageEntity.fromChatModel(serverMessage),
    );

    // ── 3. Update lastMessage room ───────────────────────────────────────
    await _updateRoomLastMessage(serverMessage);

    // ── 4. Notify RoomChatProvider via callback ──────────────────────────
    // RoomChatProvider akan setup stream dengan roomId asli
    if (onRoomResolved != null) {
      debugPrint('[ChatStorage] 📣 onRoomResolved($roomId)');
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
    // Cari normal dulu (by roomId + content)
    final result = await _isar.findLocalEchoByContent(
      roomId: chatModel.roomId,
      message: chatModel.message,
      sentAt: chatModel.sentAt,
    );
    if (result != null) return result;

    // ✅ FIX: Fallback untuk pesan pertama
    // Local echo disimpan dengan roomId='', FCM echo datang dengan roomId asli.
    // findLocalEchoByContent filter by roomId → tidak match.
    // Fallback: cari tanpa filter roomId.
    if (chatModel.roomId.isNotEmpty && chatModel.senderId == _currentUserId) {
      return await _isar.findLocalEchoByContentNoRoom(
        message: chatModel.message,
        sentAt: chatModel.sentAt,
        senderId: chatModel.senderId,
      );
    }
    return null;
  }

  /// Handle pesan masuk dari orang lain (foreground).
  ///
  /// Jika room belum ada:
  ///   1. Buat minimal room agar badge tampil segera
  ///   2. Enqueue roomId → ChatProvider drain → fetch data lengkap dari API
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
        ..lastMessage = chatModel.message.isNotEmpty
            ? chatModel.message
            : _formatPreview(chatModel.jenisPesan ?? 'text')
        ..lastMessageAt = chatModel.sentAt
        ..unread = 0
        ..countStatusReceived = 0
        ..listIdMessageReceived = []
        ..countStatusSent = 0
        ..listIdMessageSent = []
        ..userIds = [];
      await _isar.saveRoom(minimalRoom);
    }

    // ✅ Tentukan status berdasarkan apakah user sedang di room ini
    final bool isUserInSameRoom = _activeRoomId != null &&
        _activeRoomId!.isNotEmpty &&
        _activeRoomId == chatModel.roomId;

    final String targetStatus = isUserInSameRoom ? 'read' : 'received';

    // Simpan pesan dengan status yang tepat
    final modelWithStatus = chatModel.copyWith(sendStatus: targetStatus);
    await _isar.saveMessage(ChatMessageEntity.fromChatModel(modelWithStatus));
    await _updateRoomLastMessage(modelWithStatus);

    // ✅ Hanya increment unread jika user TIDAK sedang di room ini
    if (!isUserInSameRoom) {
      await _incrementRoomReceived(modelWithStatus);
    } else {
      // User sudah baca — langsung update status ke API
      unawaited(_updateStatusViaHttp(
        messageId: chatModel.messageId,
        newStatus: 'read',
      ));
      debugPrint(
          '[ChatStorage] 👁️ User in room, skip unread increment: ${chatModel.roomId}');
    }

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

  /// Drain pending room fetch — fetch room info + messages dari API.
  ///
  /// Endpoint (sama dengan ChatApiService customer):
  ///   - fetchRooms: GET /chat/getRooms?user_id={userId}
  ///   - fetchMessages: GET /chat/getAll?room_id={roomId}&status=aktif
  Future<void> drainPendingRoomFetch({required String userId}) async {
    try {
      final pendingIds = await getPendingRoomFetchIds();
      if (pendingIds.isEmpty) return;

      debugPrint(
          '[ChatStorage] 🔄 Draining ${pendingIds.length} pending rooms: $pendingIds');

      // Step 1: Fetch semua rooms dari API
      final rooms = await _fetchRoomsViaApiClient(userId: userId);

      if (rooms.isEmpty) {
        debugPrint(
            '[ChatStorage] ⚠️ drainPendingRoomFetch: rooms empty, retry later');
        return;
      }

      // Step 2: UPSERT rooms → update minimal room dengan data lengkap
      await persistRoomsFromApi(rooms, replace: false);
      debugPrint('[ChatStorage] ✅ Rooms upserted: ${rooms.length}');

      // Step 3: Fetch messages untuk setiap room baru
      for (final roomId in pendingIds) {
        await _fetchAndSaveMessages(roomId: roomId);
      }

      // Step 4: Clear queue setelah berhasil
      await clearPendingRoomFetch();

      debugPrint(
          '[ChatStorage] ✅ Pending room fetch complete (${pendingIds.length} rooms)');
    } catch (e, st) {
      debugPrint('[ChatStorage] ❌ drainPendingRoomFetch: $e\n$st');
    }
  }

  /// Fetch rooms via apiClient.
  /// Endpoint: GET /chat/getRooms?user_id={userId}
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

  /// Fetch messages untuk satu room via apiClient.
  /// Endpoint: GET /chat/getAll?room_id={roomId}&status=aktif
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

      // UPSERT — tidak hapus local-xxx
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

      // Buat minimal room + enqueue pending fetch jika room baru
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

      unawaited(
          _updateStatusViaHttp(messageId: messageId, newStatus: 'received'));
      return true;
    } catch (e, st) {
      debugPrint('[ChatStorage] ❌ enqueueBackgroundMessage: $e\n$st');
      return false;
    }
  }

  /// Buat minimal room + enqueue pending fetch (background isolate).
  static Future<void> _incrementRoomUnreadCount(
    String roomId,
    Map<String, dynamic> detail,
  ) async {
    try {
      final isar = ChatIsarService.instance;
      if (!isar.isInitialized) await isar.initialize();

      // ✅ Baca activeRoomId dari SharedPreferences
      // (background isolate tidak punya akses ke instance variable)
      final prefs = await SharedPreferences.getInstance();
      final activeRoomId = prefs.getString(_kActiveRoomKey);
      final isUserInSameRoom = activeRoomId != null &&
          activeRoomId.isNotEmpty &&
          activeRoomId == roomId;

      final messageId = detail['message_id']?.toString() ?? '';
      final messageText = detail['message']?.toString() ?? '';
      final jenisPesan = detail['jenis_pesan']?.toString() ?? 'text';
      final sentAt = DateTime.tryParse(detail['sent_at']?.toString() ?? '') ??
          DateTime.now();
      final preview =
          messageText.isNotEmpty ? messageText : _formatPreview(jenisPesan);

      final existing = await isar.getRoomById(roomId);

      if (existing != null) {
        if (messageId.isNotEmpty &&
            existing.listIdMessageReceived.contains(messageId)) {
          debugPrint('[ChatStorage] ⏭️ Duplicate: $messageId');
          return;
        }

        // ✅ Hanya tambah ke listIdMessageReceived jika user TIDAK di room ini
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
          // User sudah di room ini — hanya update preview, skip unread
          final updated = existing.copyWith(
            lastMessage: preview,
            lastMessageAt: sentAt,
          );
          await isar.saveRoom(updated);
          debugPrint(
              '[ChatStorage] 👁️ BG skip unread (user in room): $roomId');

          // Update status ke read via HTTP
          if (messageId.isNotEmpty) {
            unawaited(_updateStatusViaHttp(
              messageId: messageId,
              newStatus: 'read',
            ));
          }
        }
      } else {
        // Room belum ada → buat minimal
        // Jika user sedang di room ini (edge case), unread = 0
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

        if (isUserInSameRoom && messageId.isNotEmpty) {
          unawaited(_updateStatusViaHttp(
            messageId: messageId,
            newStatus: 'read',
          ));
        }

        // Enqueue untuk fetch info lengkap saat app resume
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

  static String _formatPreview(String jenisPesan) {
    switch (jenisPesan) {
      case 'image':
        return '🖼️ Gambar';
      case 'paket':
        return '📦 Paket';
      case 'penawaran':
        return '💼 Penawaran';
      case 'pesanan':
        return '🧾 Pesanan';
      default:
        return 'Pesan baru';
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
            // ✅ FIX: Cek apakah own echo sebelum update status
            final isOwnEchoMsg = chatModel.senderId == _currentUserId;

            if (!isOwnEchoMsg) {
              // Hanya update status untuk pesan dari orang lain
              await _isar.updateMessageStatus(
                  chatModel.messageId, targetStatus);
              if (isActiveRoom) {
                unawaited(_updateStatusViaHttp(
                  messageId: chatModel.messageId,
                  newStatus: targetStatus,
                ));
              }
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

// Strategi 1: by localId
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

// Strategi 2: by content+time (roomId sama dulu)
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

          // Strategi 3: by content+time tanpa filter roomId (first message)
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

// ✅ FIX: Hanya update status via HTTP untuk pesan dari orang lain
          if (!isOwnEcho) {
            if (isActiveRoom) {
              unawaited(_updateStatusViaHttp(
                messageId: chatModel.messageId,
                newStatus: 'read',
              ));
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
  // HTTP STATUS UPDATE — untuk background isolate
  // Endpoint: PUT /chat/update-send-status?message_id=&send_status=
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
    // ✅ Sync instance variable juga
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

    try {
      if (replace) {
        final entities = rooms.map((room) {
          return RoomChatEntity.fromRoomChatModel(room)
            ..countStatusReceived = 0
            ..listIdMessageReceived = [];
        }).toList();

        await _isar.replaceAllRooms(entities);
        debugPrint('[ChatStorage] 🔄 Rooms replaced: ${rooms.length}');
      } else {
        // UPSERT — update semua field termasuk minimal room dari FCM
        for (final room in rooms) {
          final existing = await _isar.getRoomById(room.roomId);

          if (existing != null) {
            final updated = existing.copyWith(
              lastMessage: room.lastMessage.isNotEmpty
                  ? room.lastMessage
                  : existing.lastMessage,
              lastMessageAt: room.lastMessageAt.isAfter(existing.lastMessageAt)
                  ? room.lastMessageAt
                  : existing.lastMessageAt,
              // Update field yang mungkin kosong di minimal room
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
            final entity = RoomChatEntity.fromRoomChatModel(room)
              ..countStatusReceived = 0
              ..listIdMessageReceived = [];
            await _isar.saveRoom(entity);
          }
        }
        debugPrint('[ChatStorage] 💾 Rooms upserted: ${rooms.length}');
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
      // Deteksi first-message: local echo punya roomId='' atau 'temp-...'
      final localEntity = await _isar.getMessageByLocalId(localId);
      final isFirstMessage = localEntity != null &&
          (localEntity.roomId.isEmpty ||
              localEntity.roomId.startsWith('temp-'));

      if (isFirstMessage) {
        // Server sudah assign roomId asli → selesaikan via _handleFirstMessageEcho
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
          // Belum ada roomId asli dari API — tunggu FCM echo
          // Pesan tetap tampil di temp room stream
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
        currentUserId: _currentUserId,
      );

      final unreadIds = unreadMessages
          .map((e) => e.messageId)
          .where((id) => id.isNotEmpty && !id.startsWith('local-'))
          .toList();

      await _isar.markAllMessagesAsRead(roomId, currentUserId: _currentUserId);
      await _isar.clearRoomUnread(roomId);

      debugPrint(
          '[ChatStorage] 👁️ Room read: $roomId (${unreadIds.length} msgs)');

      if (unreadIds.isNotEmpty) {
        unawaited(_updateRoomStatusViaHttp(
          messageIds: unreadIds,
          newStatus: 'read',
        ));
      }
    } catch (e, st) {
      debugPrint('[ChatStorage] ❌ markRoomAsRead: $e\n$st');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEAR / LOGOUT
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> clearAll() async {
    await _isar.clearAll();
    _currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBgQueueKey);
    await prefs.remove(_kPendingRoomFetchKey);
    debugPrint('[ChatStorage] 🧹 All cleared');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _updateRoomLastMessage(ChatModel message) async {
    try {
      final room = await _isar.getRoomById(message.roomId);
      if (room == null) return;

      String preview = message.message;
      if (preview.isEmpty) {
        switch (message.resolvedJenisPesan) {
          case JenisPesan.paket:
            preview = '📦 Paket ditawarkan';
            break;
          case JenisPesan.penawaran:
            preview = '💰 Penawaran baru';
            break;
          case JenisPesan.pesanan:
            preview = '🧾 Detail pesanan';
            break;
          case JenisPesan.image:
            preview = '🖼️ Gambar';
            break;
          default:
            preview = 'Pesan baru';
        }
      }

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
      if (_currentUserId != null && message.senderId == _currentUserId) return;
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
