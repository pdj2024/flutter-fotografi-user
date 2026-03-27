import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:mpjnew/src/data/isar/data/chat_message_entity.dart';
import 'package:mpjnew/src/data/isar/data/room_chat_entity.dart';
import 'package:path_provider/path_provider.dart';

/// Low-level Isar service.
/// Bertanggung jawab HANYA untuk operasi database (CRUD + stream).
/// Tidak boleh ada business logic di sini.
class ChatIsarService {
  static final ChatIsarService instance = ChatIsarService._internal();
  factory ChatIsarService() => instance;
  ChatIsarService._internal();

  Isar? _isar;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Isar get _db {
    assert(
      _isar != null && _isar!.isOpen,
      'ChatIsarService belum di-initialize. Panggil initialize() dulu.',
    );
    return _isar!;
  }

  // ─── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized && (_isar?.isOpen ?? false)) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open(
        [ChatMessageEntitySchema, RoomChatEntitySchema],
        directory: dir.path,
        name: 'chat_db',
        inspector: kDebugMode,
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

  Future<void> saveRoom(RoomChatEntity entity) async {
    await _db.writeTxn(() => _db.roomChatEntitys.put(entity));
    debugPrint('[ChatIsarService] 💾 Room saved: ${entity.roomId}');
  }

  Future<void> saveAllRooms(List<RoomChatEntity> entities) async {
    if (entities.isEmpty) return;
    await _db.writeTxn(() => _db.roomChatEntitys.putAll(entities));
    debugPrint('[ChatIsarService] 💾 ${entities.length} rooms saved');
  }

  /// ✅ REPLACE semua rooms — hapus yang tidak ada di API response.
  ///
  /// Dipakai saat pull-to-refresh ChatListPage.
  /// Unread count lokal dipertahankan untuk room yang masih ada di API,
  /// agar badge tidak hilang saat refresh.
  ///
  /// Room yang sudah tidak ada di API response → ikut terhapus.
  Future<void> replaceAllRooms(List<RoomChatEntity> newEntities) async {
    await _db.writeTxn(() async {
      // 1️⃣ Ambil semua room yang ada saat ini untuk preserve unread
      final existingRooms = await _db.roomChatEntitys.where().findAll();
      final existingMap = {
        for (final r in existingRooms) r.roomId: r,
      };

      // 2️⃣ Hapus SEMUA room lama
      await _db.roomChatEntitys.where().deleteAll();

      // 3️⃣ Simpan room baru — merge dengan unread count lokal
      final mergedEntities = newEntities.map((newRoom) {
        final existing = existingMap[newRoom.roomId];
        if (existing != null) {
          // Room masih ada di API — pertahankan unread count lokal
          // API tidak tahu pesan mana yang sudah dibaca di device ini
          return newRoom
            ..countStatusReceived = existing.countStatusReceived
            ..listIdMessageReceived =
                List<String>.from(existing.listIdMessageReceived)
            ..unread = existing.unread;
        }
        // Room baru dari API — unread = 0 (belum ada data lokal)
        return newRoom;
      }).toList();

      if (mergedEntities.isNotEmpty) {
        await _db.roomChatEntitys.putAll(mergedEntities);
      }
    });

    debugPrint(
        '[ChatIsarService] 🔄 All rooms replaced: ${newEntities.length}');
  }

  Future<ChatMessageEntity?> findLocalEchoByContentNoRoom({
    required String message,
    required DateTime sentAt,
    required String senderId,
  }) async {
    try {
      // ✅ FIX: Gunakan _db getter (bukan _isar.isar yang nullable)
      // _db sudah include null check + assert initialized
      final cutoff = sentAt.subtract(const Duration(seconds: 10));

      final candidates = await _db.chatMessageEntitys
          .filter()
          .messageIdStartsWith('local-')
          .and()
          .senderIdEqualTo(senderId)
          .and()
          .messageEqualTo(message)
          .and()
          .sentAtGreaterThan(cutoff)
          .findAll();

      if (candidates.isEmpty) return null;

      // Ambil yang paling dekat dengan sentAt
      candidates.sort((a, b) => a.sentAt.difference(sentAt).abs().compareTo(
            b.sentAt.difference(sentAt).abs(),
          ));

      debugPrint('[ChatIsarService] 🔍 findLocalEchoByContentNoRoom: '
          'found ${candidates.first.messageId}');
      return candidates.first;
    } catch (e) {
      debugPrint('[ChatIsarService] ⚠️ findLocalEchoByContentNoRoom: $e');
      return null;
    }
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
    debugPrint('[ChatIsarService] 🧹 Unread cleared: $roomId');
  }

  Future<void> deleteRoom(String roomId) async {
    final entity = await getRoomById(roomId);
    if (entity == null) return;
    await _db.writeTxn(() => _db.roomChatEntitys.delete(entity.id));
  }

  // ─── Stream ──────────────────────────────────────────────────────────────

  Stream<List<RoomChatEntity>>? _allRoomsStream;
  final Map<String, Stream<List<ChatMessageEntity>>> _messageStreams = {};
  final Map<String, Stream<void>> _roomStreams = {};

  Stream<List<RoomChatEntity>> watchAllRooms() {
    _allRoomsStream ??= _db.roomChatEntitys
        .where()
        .sortByLastMessageAtDesc()
        .watch(fireImmediately: true)
        .asBroadcastStream();
    return _allRoomsStream!;
  }

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

  Stream<List<ChatMessageEntity>> watchPendingMessages(String senderId) {
    return _db.chatMessageEntitys
        .filter()
        .roomIdEqualTo('')
        .and()
        .senderIdEqualTo(senderId)
        .sortBySentAt()
        .watch(fireImmediately: true)
        .asBroadcastStream();
  }

  void disposeRoomStream(String roomId) {
    _messageStreams.remove(roomId);
    _roomStreams.remove(roomId);
  }

  void resetStreamCache() {
    _allRoomsStream = null;
    _messageStreams.clear();
    _roomStreams.clear();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<ChatMessageEntity>> getMessagesByRoom(String roomId) async {
    return _db.chatMessageEntitys
        .filter()
        .roomIdEqualTo(roomId)
        .sortBySentAt()
        .findAll();
  }

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

  Future<bool> messageExists(String messageId) async {
    final count = await _db.chatMessageEntitys
        .filter()
        .messageIdEqualTo(messageId)
        .count();
    return count > 0;
  }

  Future<List<ChatMessageEntity>> getPendingMessages(String roomId) async {
    return _db.chatMessageEntitys
        .filter()
        .roomIdEqualTo(roomId)
        .sendStatusEqualTo('pending')
        .sortBySentAt()
        .findAll();
  }

  Future<List<ChatMessageEntity>> getUnreadMessages(
    String roomId, {
    String? currentUserId,
  }) async {
    final query = _db.chatMessageEntitys
        .filter()
        .roomIdEqualTo(roomId)
        .not()
        .sendStatusEqualTo('read')
        .not()
        .sendStatusEqualTo('failed');

    final all = await query.findAll();

    return all.where((e) {
      if (e.messageId.startsWith('local-')) return false;
      if (currentUserId != null && e.senderId == currentUserId) return false;
      return true;
    }).toList();
  }

  Future<void> saveMessage(ChatMessageEntity entity) async {
    await _db.writeTxn(() => _db.chatMessageEntitys.put(entity));
  }

  Future<void> saveAllMessages(List<ChatMessageEntity> entities) async {
    if (entities.isEmpty) return;
    await _db.writeTxn(() => _db.chatMessageEntitys.putAll(entities));
    debugPrint('[ChatIsarService] 💾 ${entities.length} messages saved');
  }

  /// ✅ REPLACE — hapus semua pesan di room lalu simpan data baru.
  /// Dipakai saat pull-to-refresh RoomChatPage.
  /// local-xxx yang sudah dikonfirmasi server ikut terhapus.
  Future<void> replaceRoomMessages({
    required String roomId,
    required List<ChatMessageEntity> newEntities,
  }) async {
    await _db.writeTxn(() async {
      // 1️⃣ Hapus semua pesan lama (termasuk local-xxx obsolete)
      await _db.chatMessageEntitys.filter().roomIdEqualTo(roomId).deleteAll();

      // 2️⃣ Simpan data baru dari API
      if (newEntities.isNotEmpty) {
        await _db.chatMessageEntitys.putAll(newEntities);
      }
    });

    debugPrint('[ChatIsarService] 🔄 Room messages replaced: $roomId '
        '(${newEntities.length} messages)');
  }

  Future<bool> updateMessageStatus(String messageId, String newStatus) async {
    final entity = await getMessageById(messageId);
    if (entity == null) {
      debugPrint(
          '[ChatIsarService] ⚠️ updateMessageStatus: not found ($messageId)');
      return false;
    }

    await _db.writeTxn(() async {
      entity.sendStatus = newStatus;
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

  /// Update status hanya jika status baru lebih tinggi (cegah downgrade).
  /// Flow: sent(1) < received(2) < read(3)
  Future<bool> updateMessageStatusIfHigher(
    String messageId,
    String newStatus,
    Map<String, int> priority,
  ) async {
    final entity = await getMessageById(messageId);
    if (entity == null) return false;

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
        entity.receivedAt ??= DateTime.now();
      }
      await _db.chatMessageEntitys.put(entity);
    });

    debugPrint('[ChatIsarService] ✅ Status upgraded: $messageId → $newStatus');
    return true;
  }

  Future<void> replaceLocalMessage({
    required String localId,
    required ChatMessageEntity serverEntity,
  }) async {
    await _db.writeTxn(() async {
      final local = await _db.chatMessageEntitys
          .filter()
          .localIdEqualTo(localId)
          .findFirst();
      if (local != null) {
        await _db.chatMessageEntitys.delete(local.id);
      }
      await _db.chatMessageEntitys.put(serverEntity);
    });
    debugPrint(
        '[ChatIsarService] 🔁 Local replaced: $localId → ${serverEntity.messageId}');
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

  // ─── Stream ──────────────────────────────────────────────────────────────

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

  Future<void> clearAll() async {
    await _db.writeTxn(() async {
      await _db.chatMessageEntitys.clear();
      await _db.roomChatEntitys.clear();
    });
    resetStreamCache();
    debugPrint('[ChatIsarService] 🧹 All chat data cleared');
  }

  Future<void> clearRoom(String roomId) async {
    await _db.writeTxn(() async {
      await _db.chatMessageEntitys.filter().roomIdEqualTo(roomId).deleteAll();
      final room =
          await _db.roomChatEntitys.filter().roomIdEqualTo(roomId).findFirst();
      if (room != null) await _db.roomChatEntitys.delete(room.id);
    });
    debugPrint('[ChatIsarService] 🗑️ Room cleared: $roomId');
  }

  Future<Map<String, int>> getStats() async {
    final messageCount = await _db.chatMessageEntitys.count();
    final roomCount = await _db.roomChatEntitys.count();
    return {'messages': messageCount, 'rooms': roomCount};
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<ChatMessageEntity?> getMessageByLocalId(String localId) async {
    return _db.chatMessageEntitys.filter().localIdEqualTo(localId).findFirst();
  }

  Future<bool> localEchoExists(String localId) async {
    final count =
        await _db.chatMessageEntitys.filter().localIdEqualTo(localId).count();
    return count > 0;
  }

  Future<ChatMessageEntity?> findLocalEchoByContent({
    required String roomId,
    required String message,
    required DateTime sentAt,
    String? senderIdHint,
  }) async {
    try {
      final candidates = await _db.chatMessageEntitys
          .filter()
          .roomIdEqualTo(roomId)
          .messageEqualTo(message)
          .sendStatusEqualTo('sent')
          .findAll();

      if (candidates.isEmpty) return null;

      const threshold = Duration(seconds: 60);
      for (final entity in candidates) {
        if (!entity.messageId.startsWith('local-')) continue;
        final diff = entity.sentAt.difference(sentAt).abs();
        if (diff > threshold) continue;
        debugPrint(
            '[ChatIsarService] 🔍 Local echo match: ${entity.messageId}');
        return entity;
      }

      return null;
    } catch (e) {
      debugPrint('[ChatIsarService] ⚠️ findLocalEchoByContent: $e');
      return null;
    }
  }

  Future<List<ChatMessageEntity>> getFailedMessages(String roomId) async {
    return _db.chatMessageEntitys
        .filter()
        .roomIdEqualTo(roomId)
        .sendStatusEqualTo('failed')
        .sortBySentAt()
        .findAll();
  }

  Future<void> markAllMessagesAsRead(
    String roomId, {
    String? currentUserId,
  }) async {
    final unread =
        await getUnreadMessages(roomId, currentUserId: currentUserId);
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
        '[ChatIsarService] 👁️ ${unread.length} msgs marked read: $roomId');
  }
}
