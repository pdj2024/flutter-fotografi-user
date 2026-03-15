import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:mpjnew/src/data/isar/data/chat_message_entity.dart';
import 'package:mpjnew/src/data/isar/data/room_chat_entity.dart';
import 'package:path_provider/path_provider.dart';

/// Low-level Isar service.
/// Bertanggung jawab HANYA untuk operasi database (CRUD + stream).
/// Tidak boleh ada business logic di sini.
///
/// Gunakan [ChatStorageService] untuk operasi yang melibatkan
/// transformasi data atau business rule.
class ChatIsarService {
  // ─── Singleton ─────────────────────────────────────────────────────────────
  static final ChatIsarService instance = ChatIsarService._internal();
  factory ChatIsarService() => instance;
  ChatIsarService._internal();

  Isar? _isar;
  bool _initialized = false;

  bool get isInitialized => _initialized;
  Isar get _db {
    assert(_isar != null && _isar!.isOpen,
        'ChatIsarService belum di-initialize. Panggil initialize() dulu.');
    return _isar!;
  }

  // ─── Initialization ────────────────────────────────────────────────────────

  /// Harus dipanggil sekali saat app startup (di main.dart)
  /// Aman dipanggil di background isolate juga karena pakai path_provider
  Future<void> initialize() async {
    if (_initialized && (_isar?.isOpen ?? false)) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open(
        [ChatMessageEntitySchema, RoomChatEntitySchema],
        directory: dir.path,
        name: 'chat_db',
        inspector: kDebugMode, // Aktifkan Isar Inspector di debug mode
      );
      _initialized = true;
      debugPrint('[ChatIsarService] ✅ Database initialized at ${dir.path}');
    } catch (e, st) {
      debugPrint('[ChatIsarService] ❌ Init error: $e\n$st');
      rethrow;
    }
  }

  Future<void> close() async {
    await _isar?.close();
    _initialized = false;
    debugPrint('[ChatIsarService] 🔒 Database closed');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROOM OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  // ─── Read ───────────────────────────────────────────────────────────────

  Future<List<RoomChatEntity>> getAllRooms() async {
    return _db.roomChatEntitys.where().sortByLastMessageAtDesc().findAll();
  }

  Future<RoomChatEntity?> getRoomById(String roomId) async {
    return _db.roomChatEntitys.filter().roomIdEqualTo(roomId).findFirst();
  }

  Future<List<RoomChatEntity>> getRoomsWithUnread() async {
    return _db.roomChatEntitys
        .filter()
        .countStatusReceivedGreaterThan(0)
        .findAll();
  }

  // ─── Write ──────────────────────────────────────────────────────────────

  /// Upsert room (insert or replace berdasarkan roomId — unique index)
  Future<void> saveRoom(RoomChatEntity entity) async {
    await _db.writeTxn(() => _db.roomChatEntitys.put(entity));
    debugPrint('[ChatIsarService] 💾 Room saved: ${entity.roomId}');
  }

  Future<void> saveAllRooms(List<RoomChatEntity> entities) async {
    if (entities.isEmpty) return;
    await _db.writeTxn(() => _db.roomChatEntitys.putAll(entities));
    debugPrint('[ChatIsarService] 💾 ${entities.length} rooms saved');
  }

  Future<void> updateRoomLastMessage({
    required String roomId,
    required String lastMessage,
    required DateTime lastMessageAt,
  }) async {
    final entity = await getRoomById(roomId);
    if (entity == null) return;
    await _db.writeTxn(() async {
      entity.lastMessage = lastMessage;
      entity.lastMessageAt = lastMessageAt;
      await _db.roomChatEntitys.put(entity);
    });
  }

  Future<void> updateRoomUnread({
    required String roomId,
    required int countStatusReceived,
    required List<String> listIdMessageReceived,
    required int countStatusSent,
    required List<String> listIdMessageSent,
  }) async {
    final entity = await getRoomById(roomId);
    if (entity == null) return;
    await _db.writeTxn(() async {
      entity.countStatusReceived = countStatusReceived;
      entity.listIdMessageReceived = listIdMessageReceived;
      entity.countStatusSent = countStatusSent;
      entity.listIdMessageSent = listIdMessageSent;
      await _db.roomChatEntitys.put(entity);
    });
  }

  Future<void> clearRoomUnread(String roomId) async {
    final entity = await getRoomById(roomId);
    if (entity == null) return;
    await _db.writeTxn(() async {
      entity.unread = 0;
      entity.countStatusReceived = 0;
      entity.listIdMessageReceived = [];
      await _db.roomChatEntitys.put(entity);
    });
    debugPrint('[ChatIsarService] 🧹 Unread cleared for room: $roomId');
  }

  Future<void> deleteRoom(String roomId) async {
    final entity = await getRoomById(roomId);
    if (entity == null) return;
    await _db.writeTxn(() => _db.roomChatEntitys.delete(entity.id));
  }

  // ─── Stream ─────────────────────────────────────────────────────────────

  // ── Broadcast stream cache ────────────────────────────────────────────────
  // Isar streams adalah single-subscription. Agar aman untuk StreamBuilder
  // yang rebuild berkali-kali (setState, hot-reload, dll) semua stream di-cache
  // sebagai broadcast stream menggunakan asBroadcastStream().
  Stream<List<RoomChatEntity>>? _allRoomsStream;
  final Map<String, Stream<List<ChatMessageEntity>>> _messageStreams = {};
  final Map<String, Stream<void>> _roomStreams = {};

  /// Watch semua room — broadcast stream (aman untuk multi-listener / rebuild).
  Stream<List<RoomChatEntity>> watchAllRooms() {
    _allRoomsStream ??= _db.roomChatEntitys
        .where()
        .sortByLastMessageAtDesc()
        .watch(fireImmediately: true)
        .asBroadcastStream();
    return _allRoomsStream!;
  }

  /// Watch satu room (lazy) — broadcast stream.
  Stream<void> watchRoom(String roomId) {
    return _roomStreams.putIfAbsent(
      roomId,
      () => _db.roomChatEntitys
          .filter()
          .roomIdEqualTo(roomId)
          .watchLazy(fireImmediately: true)
          .asBroadcastStream(),
    );
  }

  /// Hapus cache stream untuk room tertentu (dipanggil saat disposeRoom).
  void disposeRoomStream(String roomId) {
    _messageStreams.remove(roomId);
    _roomStreams.remove(roomId);
  }

  /// Reset semua stream cache (dipanggil saat clearAll / logout).
  void resetStreamCache() {
    _allRoomsStream = null;
    _messageStreams.clear();
    _roomStreams.clear();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  // ─── Read ───────────────────────────────────────────────────────────────

  Future<List<ChatMessageEntity>> getMessagesByRoom(String roomId) async {
    return _db.chatMessageEntitys
        .filter()
        .roomIdEqualTo(roomId)
        .sortBySentAt()
        .findAll();
  }

  /// Ambil pesan dengan pagination (untuk infinite scroll)
  Future<List<ChatMessageEntity>> getMessagesByRoomPaged({
    required String roomId,
    required int offset,
    int limit = 30,
  }) async {
    return _db.chatMessageEntitys
        .filter()
        .roomIdEqualTo(roomId)
        .sortBySentAtDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  Future<ChatMessageEntity?> getMessageById(String messageId) async {
    return _db.chatMessageEntitys
        .filter()
        .messageIdEqualTo(messageId)
        .findFirst();
  }

  /// Cek apakah pesan sudah ada (untuk deduplifikasi)
  Future<bool> messageExists(String messageId) async {
    final count = await _db.chatMessageEntitys
        .filter()
        .messageIdEqualTo(messageId)
        .count();
    return count > 0;
  }

  /// Ambil pesan pending yang belum terkirim ke server
  Future<List<ChatMessageEntity>> getPendingMessages(String roomId) async {
    return _db.chatMessageEntitys
        .filter()
        .roomIdEqualTo(roomId)
        .sendStatusEqualTo('pending')
        .sortBySentAt()
        .findAll();
  }

  /// Ambil pesan yang belum di-read (untuk sync status)
  Future<List<ChatMessageEntity>> getUnreadMessages(
    String roomId, {
    String? currentUserId,
  }) async {
    var query = _db.chatMessageEntitys
        .filter()
        .roomIdEqualTo(roomId)
        .not()
        .sendStatusEqualTo('read')
        .not()
        .sendStatusEqualTo('failed');

    final all = await query.findAll();

    // Filter: bukan pesan sendiri, bukan local echo
    return all.where((e) {
      if (e.messageId.startsWith('local-')) return false;
      if (currentUserId != null && e.senderId == currentUserId) return false;
      return true;
    }).toList();
  }

  // ─── Write ──────────────────────────────────────────────────────────────

  /// Upsert satu pesan (insert or replace berdasarkan messageId — unique index)
  Future<void> saveMessage(ChatMessageEntity entity) async {
    await _db.writeTxn(() => _db.chatMessageEntitys.put(entity));
  }

  /// Upsert banyak pesan sekaligus (efisien untuk initial load dari API)
  Future<void> saveAllMessages(List<ChatMessageEntity> entities) async {
    if (entities.isEmpty) return;
    await _db.writeTxn(() => _db.chatMessageEntitys.putAll(entities));
    debugPrint('[ChatIsarService] 💾 ${entities.length} messages saved');
  }

  /// Update status pesan by messageId
  Future<bool> updateMessageStatus(String messageId, String newStatus) async {
    final entity = await getMessageById(messageId);
    if (entity == null) {
      debugPrint(
          '[ChatIsarService] ⚠️ updateMessageStatus: message not found ($messageId)');
      return false;
    }

    await _db.writeTxn(() async {
      entity.sendStatus = newStatus;
      // Set timestamp berdasarkan status
      if (newStatus == 'received' && entity.receivedAt == null) {
        entity.receivedAt = DateTime.now();
      } else if (newStatus == 'read' && entity.readAt == null) {
        entity.readAt = DateTime.now();
      }
      await _db.chatMessageEntitys.put(entity);
    });

    debugPrint('[ChatIsarService] 🔄 Status updated: $messageId → $newStatus');
    return true;
  }

  /// Update status pesan — hanya jika status baru lebih tinggi dari yang ada.
  ///
  /// Cegah downgrade: sent → received → read (tidak boleh balik ke sent).
  /// Dipakai saat FCM echo datang tidak berurutan.
  ///
  /// [priority] map: {'sent': 1, 'received': 2, 'read': 3}
  Future<bool> updateMessageStatusIfHigher(
    String messageId,
    String newStatus,
    Map<String, int> priority,
  ) async {
    final entity = await getMessageById(messageId);
    if (entity == null) {
      debugPrint(
          '[ChatIsarService] ⚠️ updateMessageStatusIfHigher: not found ($messageId)');
      return false;
    }

    final currentPriority = priority[entity.sendStatus] ?? 0;
    final newPriority = priority[newStatus] ?? 0;

    if (newPriority <= currentPriority) {
      debugPrint('[ChatIsarService] ⏭️ Status not upgraded: '
          '${entity.sendStatus}($currentPriority) → $newStatus($newPriority) skipped');
      return false;
    }

    await _db.writeTxn(() async {
      entity.sendStatus = newStatus;
      if (newStatus == 'received' && entity.receivedAt == null) {
        entity.receivedAt = DateTime.now();
      } else if (newStatus == 'read' && entity.readAt == null) {
        entity.readAt = DateTime.now();
        entity.receivedAt ??= DateTime.now(); // pastikan received juga ter-set
      }
      await _db.chatMessageEntitys.put(entity);
    });

    debugPrint('[ChatIsarService] ✅ Status upgraded: $messageId '
        '${entity.sendStatus} → $newStatus');
    return true;
  }

  /// Replace local echo (pesan optimistic) dengan pesan dari server
  Future<void> replaceLocalMessage({
    required String localId,
    required ChatMessageEntity serverEntity,
  }) async {
    await _db.writeTxn(() async {
      // Hapus local echo berdasarkan localId
      final local = await _db.chatMessageEntitys
          .filter()
          .localIdEqualTo(localId)
          .findFirst();
      if (local != null) {
        await _db.chatMessageEntitys.delete(local.id);
      }
      // Simpan data dari server
      await _db.chatMessageEntitys.put(serverEntity);
    });
    debugPrint(
        '[ChatIsarService] 🔁 Local message replaced: $localId → ${serverEntity.messageId}');
  }

  Future<void> deleteMessage(String messageId) async {
    final entity = await getMessageById(messageId);
    if (entity == null) return;
    await _db.writeTxn(() => _db.chatMessageEntitys.delete(entity.id));
  }

  Future<void> deleteMessagesByRoom(String roomId) async {
    await _db.writeTxn(() async {
      await _db.chatMessageEntitys.filter().roomIdEqualTo(roomId).deleteAll();
    });
    debugPrint('[ChatIsarService] 🗑️ Messages deleted for room: $roomId');
  }

  // ─── Stream ─────────────────────────────────────────────────────────────

  /// Watch pesan di room tertentu — broadcast stream (aman untuk multi-listen).
  Stream<List<ChatMessageEntity>> watchMessages(String roomId) {
    return _messageStreams.putIfAbsent(
      roomId,
      () => _db.chatMessageEntitys
          .filter()
          .roomIdEqualTo(roomId)
          .sortBySentAt()
          .watch(fireImmediately: true)
          .asBroadcastStream(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BULK / UTILITY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Hapus semua data (untuk logout / wipe)
  Future<void> clearAll() async {
    await _db.writeTxn(() async {
      await _db.chatMessageEntitys.clear();
      await _db.roomChatEntitys.clear();
    });
    resetStreamCache(); // ✅ Reset stream cache setelah wipe
    debugPrint('[ChatIsarService] 🧹 All chat data cleared');
  }

  /// Hapus semua data room tertentu (room + messages)
  Future<void> clearRoom(String roomId) async {
    await _db.writeTxn(() async {
      await _db.chatMessageEntitys.filter().roomIdEqualTo(roomId).deleteAll();
      final room =
          await _db.roomChatEntitys.filter().roomIdEqualTo(roomId).findFirst();
      if (room != null) await _db.roomChatEntitys.delete(room.id);
    });
    debugPrint('[ChatIsarService] 🗑️ Room cleared: $roomId');
  }

  /// Statistik database (untuk debugging)
  Future<Map<String, int>> getStats() async {
    final messageCount = await _db.chatMessageEntitys.count();
    final roomCount = await _db.roomChatEntitys.count();
    return {
      'messages': messageCount,
      'rooms': roomCount,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC QUERY HELPERS
  // Menggantikan akses _db langsung dari service lain (ChatStorageService,
  // ChatSyncService) agar enkapsulasi tetap terjaga.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cari entity by localId — untuk optimistic UI (confirm / fail).
  Future<ChatMessageEntity?> getMessageByLocalId(String localId) async {
    return _db.chatMessageEntitys.filter().localIdEqualTo(localId).findFirst();
  }

  /// Cek apakah ada local echo dengan localId tertentu.
  Future<bool> localEchoExists(String localId) async {
    final count =
        await _db.chatMessageEntitys.filter().localIdEqualTo(localId).count();
    return count > 0;
  }

  /// Cari local echo berdasarkan konten + room + waktu kirim.
  ///
  /// Dipakai saat FCM echo datang tanpa localId (atau localId tidak match)
  /// tapi kita perlu tahu apakah ini echo pesan sendiri atau pesan baru.
  ///
  /// Strategi match:
  ///   1. roomId harus sama
  ///   2. messageId harus diawali 'local-' (masih local echo, belum confirmed)
  ///   3. sendStatus harus 'pending' atau 'sent' (belum confirmed dari server)
  ///   4. message content harus sama
  ///   5. sentAt dalam toleransi 60 detik
  ///   6. (opsional) senderId hint — skip jika null
  ///
  /// Returns entity local echo jika ditemukan, null jika tidak.
  Future<ChatMessageEntity?> findLocalEchoByContent({
    required String roomId,
    required String message,
    required DateTime sentAt,
    String? senderIdHint,
  }) async {
    try {
      // Ambil semua local echo di room dengan content yang sama dan status sent
      // (local echo langsung dibuat dengan status sent — tidak ada pending lagi)
      final candidates = await _db.chatMessageEntitys
          .filter()
          .roomIdEqualTo(roomId)
          .messageEqualTo(message)
          .sendStatusEqualTo('sent')
          .findAll();

      if (candidates.isEmpty) return null;

      // Filter: messageId harus local- dan sentAt dalam 60 detik
      final threshold = const Duration(seconds: 60);
      for (final entity in candidates) {
        if (!entity.messageId.startsWith('local-')) continue;

        final diff = entity.sentAt.difference(sentAt).abs();
        if (diff > threshold) continue;

        // senderIdHint — jika ada, skip jika senderId entity tidak cocok
        // Tapi jangan terlalu strict: local echo mungkin punya senderId benar
        // sementara FCM echo dari partner punya senderId partner
        // Jadi kita hanya pakai hint sebagai bonus, bukan syarat wajib

        debugPrint(
            '[ChatIsarService] 🔍 Local echo match found: ${entity.messageId}');
        return entity;
      }

      return null;
    } catch (e) {
      debugPrint('[ChatIsarService] ⚠️ findLocalEchoByContent error: $e');
      return null;
    }
  }

  /// Ambil semua pesan failed di room tertentu.
  Future<List<ChatMessageEntity>> getFailedMessages(String roomId) async {
    return _db.chatMessageEntitys
        .filter()
        .roomIdEqualTo(roomId)
        .sendStatusEqualTo('failed')
        .sortBySentAt()
        .findAll();
  }

  /// Bulk update status + timestamp untuk semua pesan unread di room.
  /// Dipanggil saat user membuka chat (mark all as read).
  Future<void> markAllMessagesAsRead(
    String roomId, {
    String? currentUserId,
  }) async {
    final unread = await getUnreadMessages(
      roomId,
      currentUserId: currentUserId,
    );
    if (unread.isEmpty) return;

    final now = DateTime.now();
    await _db.writeTxn(() async {
      for (final msg in unread) {
        msg.sendStatus = 'read';
        msg.readAt ??= now;
      }
      await _db.chatMessageEntitys.putAll(unread);
    });

    debugPrint(
        '[ChatIsarService] 👁️ ${unread.length} partner msgs marked read: $roomId');
  }
}
