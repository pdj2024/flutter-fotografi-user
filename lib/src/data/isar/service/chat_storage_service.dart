import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
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

/// Bridge antara FCM / REST API dan Isar — Customer Edition.
///
/// ─── Alur Status Pesan ────────────────────────────────────────────────────
///
///   [User kirim]
///   User kirim pesan → simpan ke Isar dengan messageId = "local-xxx"
///   sendStatus = pending
///
///   [FCM echo #1] senderId = user sendiri, messageId = ID dari DB (baru), status = sent
///   → Ada local echo "local-xxx" di Isar → REPLACE local-xxx dengan messageId DB
///   → sendStatus: pending → sent
///
///   [FCM echo #2] messageId = SAMA dengan #1, status = received
///   → messageId sudah ada di Isar → UPDATE status saja: sent → received
///
///   [FCM echo #3] messageId = SAMA dengan #1, status = read
///   → messageId sudah ada di Isar → UPDATE status saja: received → read
///
/// ─── Anti-double ──────────────────────────────────────────────────────────
///
///   Saat FCM echo datang dan _currentUserId BELUM ter-set (race condition):
///   senderId tidak match → masuk ke path "incoming" → cek local echo via
///   content match sebelum disimpan sebagai pesan baru → cegah double.

class ChatStorageService {
  static final ChatStorageService instance = ChatStorageService._internal();
  factory ChatStorageService() => instance;
  ChatStorageService._internal();

  final ChatIsarService _isar = ChatIsarService.instance;
  String? _currentUserId;

  void setCurrentUser(String userId) {
    _currentUserId = userId;
    debugPrint('[ChatStorage] 👤 Current user: $userId');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FOREGROUND: FCM → Isar
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> persistForegroundMessage(ChatModel chatModel) async {
    try {
      if (chatModel.messageId.isEmpty || chatModel.roomId.isEmpty) {
        debugPrint('[ChatStorage] ⚠️ Invalid: empty id/roomId');
        return false;
      }

      debugPrint('[ChatStorage] 📨 persist: ${chatModel.messageId}'
          ' sender=${chatModel.senderId} me=$_currentUserId'
          ' status=${chatModel.sendStatus}');

      // ─── Cek apakah ini pesan milik user sendiri ─────────────────────────
      // Dua cara mendeteksi: senderId match ATAU ada local echo di Isar
      final isOwnMessage = chatModel.senderId == _currentUserId;

      if (isOwnMessage) {
        return await _handleOwnEcho(chatModel);
      }

      // senderId tidak match (atau _currentUserId belum di-set)
      // → Cek dulu apakah messageId sudah ada (echo #2, #3 = received/read)
      final existsByMessageId = await _isar.messageExists(chatModel.messageId);
      if (existsByMessageId) {
        // messageId sudah ada → hanya update status (echo received/read)
        await _isar.updateMessageStatus(
            chatModel.messageId, chatModel.sendStatus);
        debugPrint('[ChatStorage] 🔄 Status update (exists): '
            '${chatModel.messageId} → ${chatModel.sendStatus}');
        return false;
      }

      // messageId belum ada → cek apakah ada local echo yang cocok
      // (terjadi saat _currentUserId belum ter-set = race condition)
      final localEcho = await _findMatchingLocalEcho(chatModel);
      if (localEcho != null) {
        debugPrint('[ChatStorage] 📤 Own echo detected via local match: '
            '${localEcho.messageId} → ${chatModel.messageId}');
        return await _replaceLocalEcho(
          localMessageId: localEcho.messageId,
          serverMessage: chatModel,
        );
      }

      // Benar-benar pesan dari orang lain → simpan sebagai incoming
      return await _handleIncoming(chatModel);
    } catch (e, st) {
      debugPrint('[ChatStorage] ❌ persistForegroundMessage: $e\n$st');
      return false;
    }
  }

  // ─── Handle echo pesan sendiri ─────────────────────────────────────────────
  //
  // Echo bisa datang dalam urutan apapun karena FCM tidak menjamin urutan:
  //
  //   Normal:   #1(sent) → #2(received) → #3(read)
  //   Race:     #3(read) datang SEBELUM #1(sent) selesai di-confirm
  //             → local-xxx masih ada, messageId DB belum ada di Isar
  //
  // Strategi:
  //   1. Cari local echo dulu (via localId atau content match)
  //   2. Jika ada → REPLACE dengan messageId DB + status terbaru
  //      (apapun statusnya: sent/received/read — ambil yang tertinggi)
  //   3. Jika tidak ada local echo, cek messageId DB sudah ada di Isar
  //      → UPDATE status (pastikan tidak downgrade)
  //   4. Jika tidak ada keduanya → simpan langsung (multi-device)
  //
  // Status priority (tidak boleh downgrade): sent < received < read

  static const _statusPriority = {
    'sent': 1,
    'received': 2,
    'read': 3,
  };

  Future<bool> _handleOwnEcho(ChatModel chatModel) async {
    final incomingStatus = chatModel.sendStatus;

    debugPrint(
        '[ChatStorage] 📤 Own echo: ${chatModel.messageId} status=$incomingStatus');

    // ── Step 1: Cari local echo dulu ─────────────────────────────────────────
    // Harus dicek SEBELUM messageExists karena echo #3(read) bisa datang
    // saat local-xxx masih ada (confirmOptimistic belum selesai)

    // Prioritas 1a: localId dari payload FCM
    if (chatModel.localId != null &&
        chatModel.localId!.isNotEmpty &&
        chatModel.localId!.startsWith('local-')) {
      final hasLocal = await _isar.localEchoExists(chatModel.localId!);
      if (hasLocal) {
        debugPrint('[ChatStorage] ✅ Own echo via localId: '
            '${chatModel.localId} → ${chatModel.messageId} ($incomingStatus)');
        return await _replaceLocalEcho(
          localMessageId: chatModel.localId!,
          serverMessage: chatModel,
        );
      }
    }

    // Prioritas 1b: content match (fallback jika backend tidak kirim localId)
    final localEcho = await _findMatchingLocalEcho(chatModel);
    if (localEcho != null) {
      debugPrint('[ChatStorage] ✅ Own echo via content: '
          '${localEcho.messageId} → ${chatModel.messageId} ($incomingStatus)');
      return await _replaceLocalEcho(
        localMessageId: localEcho.messageId,
        serverMessage: chatModel,
      );
    }

    // ── Step 2: Local echo tidak ada → cek messageId DB di Isar ─────────────
    final alreadyExists = await _isar.messageExists(chatModel.messageId);
    if (alreadyExists) {
      // Update status — tapi jangan downgrade (sent→received→read, tidak boleh balik)
      await _isar.updateMessageStatusIfHigher(
        chatModel.messageId,
        incomingStatus,
        _statusPriority,
      );
      debugPrint('[ChatStorage] 🔄 Own echo status update (no downgrade): '
          '${chatModel.messageId} → $incomingStatus');
      return false;
    }

    // ── Step 3: Tidak ada di mana-mana → multi-device, simpan langsung ───────
    await _isar.saveMessage(ChatMessageEntity.fromChatModel(chatModel));
    await _updateRoomLastMessage(chatModel);
    debugPrint(
        '[ChatStorage] 📤 Own saved (no local echo): ${chatModel.messageId}');
    return true;
  }

  // ─── Replace local echo dengan data dari server ────────────────────────────

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
        '$localMessageId → ${serverMessage.messageId} (${serverMessage.sendStatus})');
    return true;
  }

  // ─── Cari local echo yang cocok dengan pesan dari server ──────────────────
  //
  // Dipakai sebagai fallback saat:
  //   - _currentUserId belum ter-set (race condition saat startup)
  //   - Backend tidak mengirim localId di payload FCM
  //
  // Kriteria match:
  //   - roomId sama
  //   - messageId diawali "local-" (masih local echo)
  //   - sendStatus "pending" atau "sent" (belum di-replace server)
  //   - message content sama
  //   - sentAt dalam toleransi 60 detik

  Future<ChatMessageEntity?> _findMatchingLocalEcho(ChatModel chatModel) async {
    return _isar.findLocalEchoByContent(
      roomId: chatModel.roomId,
      message: chatModel.message,
      sentAt: chatModel.sentAt,
    );
  }

  // ─── Handle pesan masuk dari orang lain ────────────────────────────────────

  Future<bool> _handleIncoming(ChatModel chatModel) async {
    final exists = await _isar.messageExists(chatModel.messageId);
    if (exists) {
      await _isar.updateMessageStatus(
          chatModel.messageId, chatModel.sendStatus);
      debugPrint(
          '[ChatStorage] ⏭️ Incoming dup → status ${chatModel.sendStatus}: ${chatModel.messageId}');
      return false;
    }

    await _isar.saveMessage(ChatMessageEntity.fromChatModel(chatModel));
    await _updateRoomLastMessage(chatModel);
    await _incrementRoomReceived(chatModel);

    debugPrint('[ChatStorage] 💬 Incoming saved: ${chatModel.messageId}');
    return true;
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

      // ✅ Skip echo status update (received/read) di background.
      // Echo received = partner sudah terima → tidak perlu notif untuk pengirim.
      // Echo read = partner sudah baca → tidak perlu notif untuk pengirim.
      // Hanya proses status 'sent' = pesan baru dari orang lain.
      if (sendStatus != 'sent') {
        debugPrint(
            '[ChatStorage] ℹ️ Skip background enqueue (echo: $sendStatus): $messageId');
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

  Future<int> drainBackgroundQueue({String? activeRoomId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kBgQueueKey) ?? [];
      if (raw.isEmpty) return 0;

      debugPrint('[ChatStorage] 📬 Draining ${raw.length} messages...');

      final effectiveActiveRoom =
          activeRoomId ?? prefs.getString(_kActiveRoomKey);
      debugPrint('[ChatStorage] 🏠 Active room: $effectiveActiveRoom');

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

          // ── Step 1: messageId sudah ada → hanya update status ─────────────
          final existsByMessageId =
              await _isar.messageExists(chatModel.messageId);
          if (existsByMessageId) {
            await _isar.updateMessageStatus(chatModel.messageId, targetStatus);
            if (isActiveRoom) {
              unawaited(_updateStatusViaHttp(
                  messageId: chatModel.messageId, newStatus: targetStatus));
            }
            debugPrint(
                '[ChatStorage] ⏭️ Drain exists → $targetStatus: ${chatModel.messageId}');
            continue;
          }

          // ── Step 2: Cek apakah ada local echo (own echo via localId) ──────
          bool isOwnEcho = false;

          if (chatModel.localId != null &&
              chatModel.localId!.isNotEmpty &&
              chatModel.localId!.startsWith('local-')) {
            final hasLocal = await _isar.localEchoExists(chatModel.localId!);
            if (hasLocal) {
              isOwnEcho = true;
              await _isar.replaceLocalMessage(
                localId: chatModel.localId!,
                serverEntity: ChatMessageEntity.fromChatModel(
                    _withStatus(chatModel, targetStatus)),
              );
              debugPrint('[ChatStorage] ✅ Drain own echo (localId): '
                  '${chatModel.localId} → ${chatModel.messageId}');
            }
          }

          // ── Step 3: Cek own echo via content match (fallback) ─────────────
          if (!isOwnEcho) {
            final echoByContent = await _isar.findLocalEchoByContent(
              roomId: chatModel.roomId,
              message: chatModel.message,
              sentAt: chatModel.sentAt,
            );
            if (echoByContent != null) {
              isOwnEcho = true;
              await _isar.replaceLocalMessage(
                localId: echoByContent.messageId,
                serverEntity: ChatMessageEntity.fromChatModel(
                    _withStatus(chatModel, targetStatus)),
              );
              debugPrint('[ChatStorage] ✅ Drain own echo (content): '
                  '${echoByContent.messageId} → ${chatModel.messageId}');
            }
          }

          // ── Step 4: Benar-benar incoming baru ────────────────────────────
          if (!isOwnEcho) {
            await _handleIncoming(_withStatus(chatModel, targetStatus));
          }

          if (isActiveRoom) {
            unawaited(_updateStatusViaHttp(
                messageId: chatModel.messageId, newStatus: 'read'));
            readCount++;
          } else {
            receivedCount++;
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
          '($readCount read, $receivedCount received)'
          '${failed.isNotEmpty ? ", ${failed.length} failed" : ""}');

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
          'HTTP status: $messageId → $newStatus (${response.statusCode})');
    } catch (e) {
      debugPrint('[ChatStorage] ⚠️ _updateStatusViaHttp: $e');
    }
  }

  static Future<void> _updateRoomStatusViaHttp({
    required List<String> messageIds,
    required String newStatus,
  }) async {
    if (messageIds.isEmpty) return;
    final futures = messageIds.map(
      (id) => _updateStatusViaHttp(messageId: id, newStatus: newStatus),
    );
    await Future.wait(futures, eagerError: false);
    debugPrint(
        '[ChatStorage] ✅ Bulk HTTP update done ($newStatus, ${messageIds.length} msgs)');
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

  Future<void> persistRoomsFromApi(List<RoomChatModel> rooms) async {
    if (rooms.isEmpty) return;
    try {
      for (final room in rooms) {
        final existing = await _isar.getRoomById(room.roomId);

        if (existing != null) {
          // ✅ Room sudah ada — pertahankan unread count lokal
          // API tidak tahu pesan mana yang sudah dibaca di device ini
          // Hanya update metadata: nama partner, avatar, last message
          final updated = existing.copyWith(
            lastMessage: room.lastMessage.isNotEmpty
                ? room.lastMessage
                : existing.lastMessage,
            lastMessageAt: room.lastMessageAt.isAfter(existing.lastMessageAt)
                ? room.lastMessageAt
                : existing.lastMessageAt,
            // countStatusReceived & listIdMessageReceived TIDAK di-pass
            // → pakai nilai existing (lokal yang benar)
          );
          await _isar.saveRoom(updated);
        } else {
          // Room baru — simpan dari API tapi reset unread
          // (kita belum tahu pesan mana yang belum dibaca secara lokal)
          final entity = RoomChatEntity.fromRoomChatModel(room)
            ..countStatusReceived = 0
            ..listIdMessageReceived = [];
          await _isar.saveRoom(entity);
        }
      }

      debugPrint(
          '[ChatStorage] 💾 API: ${rooms.length} rooms (unread preserved)');
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
      // ✅ Filter: hanya pesan dari partner (bukan milik sendiri)
      // currentUserId dipass agar getUnreadMessages bisa filter
      final unreadMessages =
          await _isar.getUnreadMessages(roomId, currentUserId: _currentUserId);

      final unreadIds = unreadMessages
          .map((e) => e.messageId)
          .where((id) => id.isNotEmpty && !id.startsWith('local-'))
          .toList();

      // Update Isar lokal
      await _isar.markAllMessagesAsRead(roomId, currentUserId: _currentUserId);
      await _isar.clearRoomUnread(roomId);

      debugPrint(
          '[ChatStorage] 👁️ Room read: $roomId (${unreadIds.length} partner msgs)');

      // Hit API — hanya untuk pesan dari partner
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
      // ✅ Guard: jangan hitung pesan sendiri sebagai unread
      if (_currentUserId != null && message.senderId == _currentUserId) {
        debugPrint('[ChatStorage] ⏭️ Skip increment: own message');
        return;
      }

      // ✅ Guard: jangan hitung local echo
      if (message.messageId.startsWith('local-')) {
        debugPrint('[ChatStorage] ⏭️ Skip increment: local echo');
        return;
      }

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

      debugPrint('[ChatStorage] 🔴 Unread +1: ${message.roomId} '
          '(total: ${newList.length})');
    } catch (e) {
      debugPrint('[ChatStorage] ⚠️ _incrementRoomReceived: $e');
    }
  }

  static ChatModel _withStatus(ChatModel model, String status) {
    final json = model.toJson();
    json['Send_Status'] = status;
    return ChatModel.fromJson(json);
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
