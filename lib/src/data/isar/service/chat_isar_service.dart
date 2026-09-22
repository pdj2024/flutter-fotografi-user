import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/data/isar/data/chat_message_entity.dart';
import 'package:mpjnew/src/data/isar/data/room_chat_entity.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/sqflite/chat_database.dart';
import 'package:sqflite/sqflite.dart';

/// Low-level sqflite service.
/// Bertanggung jawab HANYA untuk operasi database (CRUD + stream).
/// API publik identik dengan versi Isar sebelumnya — tidak ada perubahan
/// di ChatStorageService, ChatSyncService, atau provider.
class ChatIsarService {
  static final ChatIsarService instance = ChatIsarService._internal();
  factory ChatIsarService() => instance;
  ChatIsarService._internal();

  bool _initialized = false;

  bool get isInitialized => _initialized;
  bool get _isAvailable => _initialized;

  Future<Database> get _db => ChatDatabase.instance.db;

  // ─── Stream controllers ───────────────────────────────────────────────────

  final StreamController<List<RoomChatEntity>> _roomsController =
      StreamController<List<RoomChatEntity>>.broadcast();

  final Map<String, StreamController<List<ChatMessageEntity>>>
      _messageControllers = {};

  final Map<String, StreamController<void>> _roomWatchControllers = {};

  // Emisi terakhir per stream. Broadcast controller polos tidak mengirim
  // apa-apa ke subscriber baru, jadi tanpa cache ini setiap StreamBuilder
  // selalu mulai dari ConnectionState.waiting → shimmer walau data sudah ada.
  List<RoomChatEntity>? _latestRooms;
  final Map<String, List<ChatMessageEntity>> _latestMessages = {};
  final Map<String, List<ChatMessageEntity>> _latestPendingMessages = {};

  /// Snapshot sinkron untuk dipakai sebagai `initialData` StreamBuilder.
  List<ChatMessageEntity>? cachedMessages(String roomId) =>
      _latestMessages[roomId];

  /// Sama seperti [cachedMessages] tapi untuk pesan pending (belum ada room
  /// resmi — dikirim sebelum room pertama terbentuk).
  List<ChatMessageEntity>? cachedPendingMessages(String senderId) =>
      _latestPendingMessages[senderId];

  List<RoomChatEntity>? get cachedRooms => _latestRooms;

  StreamController<List<ChatMessageEntity>> _msgCtrl(String roomId) {
    return _messageControllers.putIfAbsent(
      roomId,
      () => StreamController<List<ChatMessageEntity>>.broadcast(),
    );
  }

  StreamController<void> _roomWatchCtrl(String roomId) {
    return _roomWatchControllers.putIfAbsent(
      roomId,
      () => StreamController<void>.broadcast(),
    );
  }

  // ─── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await ChatDatabase.instance.db; // trigger open
      _initialized = true;
      debugPrint('[ChatIsarService] ✅ Database initialized (sqflite)');
    } catch (e, st) {
      _initialized = false;
      debugPrint('[ChatIsarService] ⚠️ DB unavailable (${e.runtimeType}): $e\n$st');
    }
  }

  Future<void> close() async {
    await ChatDatabase.instance.close();
    _initialized = false;
    debugPrint('[ChatIsarService] 🔒 Database closed');
  }

  // ─── Notify helpers ───────────────────────────────────────────────────────

  Future<void> _notifyRoomsChanged() async {
    if (_roomsController.isClosed) return;
    final rooms = await getAllRooms();
    _latestRooms = rooms;
    _roomsController.add(rooms);
  }

  Future<void> _notifyMessagesChanged(String roomId) async {
    final ctrl = _messageControllers[roomId];
    if (ctrl == null || ctrl.isClosed) return;
    final msgs = await getMessagesByRoom(roomId);
    _latestMessages[roomId] = msgs;
    ctrl.add(msgs);
  }

  /// Pesan pending (roomId == '') di-notify lewat controller '__pending__$senderId',
  /// bukan controller ber-key roomId — perlu jalur notify sendiri.
  Future<List<ChatMessageEntity>> _queryPendingMessages(String senderId) async {
    final db = await _db;
    final maps = await db.query(
      'messages',
      where: "room_id = '' AND sender_id = ?",
      whereArgs: [senderId],
      orderBy: 'sent_at ASC',
    );
    return maps.map(ChatMessageEntity.fromMap).toList();
  }

  Future<void> _notifyPendingMessagesChanged(String senderId) async {
    final key = '__pending__$senderId';
    final ctrl = _messageControllers[key];
    if (ctrl == null || ctrl.isClosed) return;
    final msgs = await _queryPendingMessages(senderId);
    _latestPendingMessages[senderId] = msgs;
    ctrl.add(msgs);
  }

  void _notifyRoomWatch(String roomId) {
    final ctrl = _roomWatchControllers[roomId];
    if (ctrl == null || ctrl.isClosed) return;
    ctrl.add(null);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROOM OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<RoomChatEntity>> getAllRooms() async {
    if (!_isAvailable) return [];
    final db = await _db;
    final maps = await db.query(
      'rooms',
      orderBy: 'last_message_at DESC',
    );
    return maps.map(RoomChatEntity.fromMap).toList();
  }

  Future<RoomChatEntity?> getRoomById(String roomId) async {
    if (!_isAvailable) return null;
    final db = await _db;
    final maps = await db.query(
      'rooms',
      where: 'room_id = ?',
      whereArgs: [roomId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RoomChatEntity.fromMap(maps.first);
  }

  Future<List<RoomChatEntity>> getRoomsWithUnread() async {
    if (!_isAvailable) return [];
    final db = await _db;
    final maps = await db.query(
      'rooms',
      where: 'count_status_received > 0',
    );
    return maps.map(RoomChatEntity.fromMap).toList();
  }

  Future<void> saveRoom(RoomChatEntity entity) async {
    if (!_isAvailable) return;
    final db = await _db;
    await db.insert(
      'rooms',
      entity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('[ChatIsarService] 💾 Room saved: ${entity.roomId}');
    await _notifyRoomsChanged();
    _notifyRoomWatch(entity.roomId);
  }

  Future<void> saveAllRooms(List<RoomChatEntity> entities) async {
    if (!_isAvailable || entities.isEmpty) return;
    final db = await _db;
    final batch = db.batch();
    for (final e in entities) {
      batch.insert('rooms', e.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    debugPrint('[ChatIsarService] 💾 ${entities.length} rooms saved');
    await _notifyRoomsChanged();
  }

  /// ✅ REPLACE semua rooms — hapus yang tidak ada di API response.
  Future<void> replaceAllRooms(List<RoomChatEntity> newEntities) async {
    if (!_isAvailable) return;
    final db = await _db;

    await db.transaction((txn) async {
      // 1️⃣ Ambil semua room yang ada untuk preserve unread
      final existingMaps = await txn.query('rooms');
      final existingMap = {
        for (final m in existingMaps)
          (m['room_id'] as String): RoomChatEntity.fromMap(m),
      };

      // 2️⃣ Hapus SEMUA room lama
      await txn.delete('rooms');

      // 3️⃣ Simpan room baru — merge dengan unread count lokal
      final batch = txn.batch();
      for (final newRoom in newEntities) {
        final existing = existingMap[newRoom.roomId];
        if (existing != null) {
          newRoom
            ..countStatusReceived = existing.countStatusReceived
            ..listIdMessageReceived =
                List<String>.from(existing.listIdMessageReceived)
            ..unread = existing.unread;

          // Server mengirim Last_Message kosong untuk pesan pesanan/penawaran.
          // Tanpa ini, preview hasil repair lokal ketimpa string kosong tiap
          // kali room list di-refresh → "Belum ada pesan" padahal ada pesan.
          if (newRoom.lastMessage.isEmpty && existing.lastMessage.isNotEmpty) {
            newRoom
              ..lastMessage = existing.lastMessage
              ..lastMessageAt = existing.lastMessageAt;
          }
        }
        batch.insert('rooms', newRoom.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });

    debugPrint(
        '[ChatIsarService] 🔄 All rooms replaced: ${newEntities.length}');
    await _notifyRoomsChanged();
  }

  Future<void> updateRoomLastMessage({
    required String roomId,
    required String lastMessage,
    required DateTime lastMessageAt,
  }) async {
    if (!_isAvailable) return;
    final db = await _db;
    await db.update(
      'rooms',
      {
        'last_message': lastMessage,
        'last_message_at': lastMessageAt.millisecondsSinceEpoch,
      },
      where: 'room_id = ?',
      whereArgs: [roomId],
    );
    await _notifyRoomsChanged();
    _notifyRoomWatch(roomId);
  }

  Future<void> updateRoomUnread({
    required String roomId,
    required int countStatusReceived,
    required List<String> listIdMessageReceived,
    required int countStatusSent,
    required List<String> listIdMessageSent,
  }) async {
    if (!_isAvailable) return;
    final db = await _db;
    await db.update(
      'rooms',
      {
        'count_status_received': countStatusReceived,
        'list_id_message_received':
            _encodeList(listIdMessageReceived),
        'count_status_sent': countStatusSent,
        'list_id_message_sent': _encodeList(listIdMessageSent),
      },
      where: 'room_id = ?',
      whereArgs: [roomId],
    );
    await _notifyRoomsChanged();
    _notifyRoomWatch(roomId);
  }

  Future<void> clearRoomUnread(String roomId) async {
    if (!_isAvailable) return;
    final db = await _db;
    await db.update(
      'rooms',
      {
        'unread': 0,
        'count_status_received': 0,
        'list_id_message_received': '[]',
      },
      where: 'room_id = ?',
      whereArgs: [roomId],
    );
    debugPrint('[ChatIsarService] 🧹 Unread cleared: $roomId');
    await _notifyRoomsChanged();
    _notifyRoomWatch(roomId);
  }

  Future<void> deleteRoom(String roomId) async {
    if (!_isAvailable) return;
    final db = await _db;
    await db.delete('rooms', where: 'room_id = ?', whereArgs: [roomId]);
    await _notifyRoomsChanged();
  }

  // ─── Room Streams ─────────────────────────────────────────────────────────

  Stream<List<RoomChatEntity>> watchAllRooms() {
    if (!_isAvailable) return const Stream.empty();
    // Fire immediately dengan data saat ini, lalu repair lastMessage kosong
    Future.microtask(() async {
      final rooms = await getAllRooms();
      _latestRooms = rooms;
      if (!_roomsController.isClosed) _roomsController.add(rooms);
      // Repair rooms dengan lastMessage kosong dari pesan tersimpan
      await _repairEmptyLastMessages(rooms);
    });
    // Replay emisi terakhir ke subscriber baru supaya UI tidak balik ke
    // loading state saat halaman dibuka ulang.
    return Stream.multi((c) {
      final latest = _latestRooms;
      if (latest != null) c.add(latest);
      final sub = _roomsController.stream.listen(c.add, onError: c.addError);
      c.onCancel = sub.cancel;
    });
  }

  /// Repair rooms yang lastMessage-nya kosong atau 'Pesan baru' (placeholder generik).
  /// Mengambil pesan terakhir dari tabel messages dan mengisi ulang lastMessage.
  ///
  /// Ini cuma jalan SEKALI, tepat saat watchAllRooms() pertama kali
  /// di-subscribe (ChatListPage cache stream-nya sekali di initState). Kalau
  /// di momen itu pesannya belum tersimpan lokal, room ini permanen
  /// tertinggal — makanya ada refreshRoomPreviewIfStale() untuk dipanggil
  /// ulang tepat saat pesan sebuah room BENAR-BENAR baru tersimpan lokal
  /// (lihat ChatSyncService.loadMessages).
  Future<void> _repairEmptyLastMessages(List<RoomChatEntity> rooms) async {
    if (!_isAvailable) return;
    bool anyUpdated = false;
    for (final room in rooms) {
      if (await _rebuildRoomPreview(room.roomId, currentLastMessage: room.lastMessage)) {
        anyUpdated = true;
      }
    }
    if (anyUpdated) await _notifyRoomsChanged();
  }

  /// Tulis ulang preview room dari pesan lokal terakhirnya kalau preview
  /// saat ini masih kosong/generik. Return true kalau benar-benar menulis.
  /// currentLastMessage opsional — kalau tidak diisi, dibaca dari DB dulu.
  Future<bool> _rebuildRoomPreview(String roomId,
      {String? currentLastMessage}) async {
    if (!_isAvailable) return false;
    try {
      final db = await _db;
      String lastMessage;
      DateTime? currentLastMessageAt;
      if (currentLastMessage != null) {
        lastMessage = currentLastMessage;
      } else {
        final room = await getRoomById(roomId);
        if (room == null) return false;
        lastMessage = room.lastMessage;
        currentLastMessageAt = room.lastMessageAt;
      }
      // Sudah ada preview bermakna — jangan timpa (no-op murah, dipanggil
      // tiap kali room dibuka jadi ini harus cepat untuk kasus normal).
      if (lastMessage.isNotEmpty && lastMessage != 'Pesan baru') return false;

      final maps = await db.query(
        'messages',
        where: 'room_id = ?',
        whereArgs: [roomId],
        orderBy: 'sent_at DESC',
        limit: 1,
      );
      if (maps.isEmpty) return false;
      final last = ChatMessageEntity.fromMap(maps.first);
      final jenis = JenisPesan.fromString(last.resolvedJenisPesan);
      // Pesan teks kosong bertipe text → tidak ada preview bermakna;
      // biarkan apa adanya daripada menimpa dengan "Pesan baru".
      if (last.message.isEmpty && jenis == JenisPesan.text) return false;

      // Guard anti-timpa: kalau ada lastMessageAt yang lebih baru sudah
      // ter-set (mis. FCM live yang datang sesaat sebelum ini jalan), jangan
      // timpa dengan hasil baca lokal yang lebih basi.
      currentLastMessageAt ??= (await getRoomById(roomId))?.lastMessageAt;
      if (currentLastMessageAt != null &&
          last.sentAt.isBefore(currentLastMessageAt)) {
        return false;
      }

      final preview = chatPreviewText(jenis: jenis, message: last.message);

      await db.update(
        'rooms',
        {
          'last_message': preview,
          'last_message_at': last.sentAt.millisecondsSinceEpoch,
        },
        where: 'room_id = ?',
        whereArgs: [roomId],
      );
      debugPrint('[ChatIsarService] 🔧 Repaired lastMessage: $roomId → "$preview"');
      return true;
    } catch (e) {
      debugPrint('[ChatIsarService] ⚠️ _rebuildRoomPreview $roomId: $e');
      return false;
    }
  }

  /// Dipanggil tepat setelah pesan sebuah room benar-benar tersimpan lokal
  /// (lihat ChatSyncService.loadMessages) — supaya room yang lolos dari
  /// _repairEmptyLastMessages (karena saat itu belum ada pesan lokal) tetap
  /// dapat preview yang benar begitu pesannya ada.
  Future<void> refreshRoomPreviewIfStale(String roomId) async {
    if (await _rebuildRoomPreview(roomId)) {
      await _notifyRoomsChanged();
    }
  }

  Stream<void> watchRoom(String roomId) {
    if (!_isAvailable) return const Stream.empty();
    final ctrl = _roomWatchCtrl(roomId);
    // Fire immediately
    Future.microtask(() {
      if (!ctrl.isClosed) ctrl.add(null);
    });
    return ctrl.stream;
  }

  void disposeRoomStream(String roomId) {
    _messageControllers.remove(roomId)?.close();
    _roomWatchControllers.remove(roomId)?.close();
    // _latestMessages sengaja TIDAK dihapus: snapshot-nya masih valid dan
    // itu yang membuat buka room yang sama lagi langsung tampil tanpa shimmer.
    // Dibersihkan di resetStreamCache() saat logout.
  }

  void resetStreamCache() {
    for (final ctrl in _messageControllers.values) {
      ctrl.close();
    }
    _messageControllers.clear();
    for (final ctrl in _roomWatchControllers.values) {
      ctrl.close();
    }
    _roomWatchControllers.clear();
    _latestMessages.clear();
    _latestPendingMessages.clear();
    _latestRooms = null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<ChatMessageEntity>> getMessagesByRoom(String roomId) async {
    if (!_isAvailable) return [];
    final db = await _db;
    final maps = await db.query(
      'messages',
      where: 'room_id = ?',
      whereArgs: [roomId],
      orderBy: 'sent_at ASC',
    );
    return maps.map(ChatMessageEntity.fromMap).toList();
  }

  Future<List<ChatMessageEntity>> getMessagesByRoomPaged({
    required String roomId,
    required int offset,
    int limit = 30,
  }) async {
    if (!_isAvailable) return [];
    final db = await _db;
    final maps = await db.query(
      'messages',
      where: 'room_id = ?',
      whereArgs: [roomId],
      orderBy: 'sent_at DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map(ChatMessageEntity.fromMap).toList();
  }

  Future<ChatMessageEntity?> getMessageById(String messageId) async {
    if (!_isAvailable) return null;
    final db = await _db;
    final maps = await db.query(
      'messages',
      where: 'message_id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ChatMessageEntity.fromMap(maps.first);
  }

  Future<bool> messageExists(String messageId) async {
    if (!_isAvailable) return false;
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM messages WHERE message_id = ?',
      [messageId],
    );
    return (result.first['cnt'] as int) > 0;
  }

  Future<List<ChatMessageEntity>> getPendingMessages(String roomId) async {
    if (!_isAvailable) return [];
    final db = await _db;
    final maps = await db.query(
      'messages',
      where: 'room_id = ? AND send_status = ?',
      whereArgs: [roomId, 'pending'],
      orderBy: 'sent_at ASC',
    );
    return maps.map(ChatMessageEntity.fromMap).toList();
  }

  Future<List<ChatMessageEntity>> getUnreadMessages(
    String roomId, {
    String? currentUserId,
  }) async {
    if (!_isAvailable) return [];
    final db = await _db;
    final maps = await db.query(
      'messages',
      where:
          "room_id = ? AND send_status != 'read' AND send_status != 'failed'",
      whereArgs: [roomId],
    );
    final all = maps.map(ChatMessageEntity.fromMap).toList();
    return all.where((e) {
      if (e.messageId.startsWith('local-')) return false;
      if (currentUserId != null && e.senderId == currentUserId) return false;
      return true;
    }).toList();
  }

  Future<void> saveMessage(ChatMessageEntity entity) async {
    if (!_isAvailable) return;
    final db = await _db;
    await db.insert(
      'messages',
      entity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Pesan pending (belum ada room resmi) di-notify lewat controller
    // '__pending__$senderId' — bukan roomId kosong, yang tidak pernah
    // dipakai controller manapun.
    if (entity.roomId.isEmpty) {
      await _notifyPendingMessagesChanged(entity.senderId);
    } else {
      await _notifyMessagesChanged(entity.roomId);
    }
  }

  Future<void> saveAllMessages(List<ChatMessageEntity> entities) async {
    if (!_isAvailable || entities.isEmpty) return;
    final db = await _db;

    // Fetch existing statuses in one query to avoid downgrading higher status
    // (e.g. 'read' must not be overwritten by API's 'received'/'sent')
    final ids = entities.map((e) => e.messageId).toList();
    final placeholders = List.filled(ids.length, '?').join(', ');
    final existingRows = await db.query(
      'messages',
      columns: ['message_id', 'send_status'],
      where: 'message_id IN ($placeholders)',
      whereArgs: ids,
    );
    final existingStatus = {
      for (final row in existingRows)
        row['message_id'] as String: row['send_status'] as String
    };

    const statusPriority = {'read': 3, 'received': 2, 'sent': 1};

    final batch = db.batch();
    for (final e in entities) {
      final current = existingStatus[e.messageId];
      final map = e.toMap();
      if (current != null &&
          (statusPriority[current] ?? 0) > (statusPriority[e.sendStatus] ?? 0)) {
        map['send_status'] = current;
      }
      batch.insert('messages', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    debugPrint('[ChatIsarService] 💾 ${entities.length} messages saved');

    // Notify per unique roomId
    final roomIds = entities.map((e) => e.roomId).toSet();
    for (final roomId in roomIds) {
      await _notifyMessagesChanged(roomId);
    }
  }

  /// ✅ REPLACE — hapus semua pesan di room lalu simpan data baru.
  Future<void> replaceRoomMessages({
    required String roomId,
    required List<ChatMessageEntity> newEntities,
  }) async {
    if (!_isAvailable) return;
    final db = await _db;

    await db.transaction((txn) async {
      await txn.delete('messages',
          where: 'room_id = ?', whereArgs: [roomId]);
      if (newEntities.isNotEmpty) {
        final batch = txn.batch();
        for (final e in newEntities) {
          batch.insert('messages', e.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      }
    });

    debugPrint('[ChatIsarService] 🔄 Room messages replaced: $roomId '
        '(${newEntities.length} messages)');
    await _notifyMessagesChanged(roomId);
  }

  Future<bool> updateMessageStatus(String messageId, String newStatus) async {
    if (!_isAvailable) return false;
    final entity = await getMessageById(messageId);
    if (entity == null) {
      debugPrint(
          '[ChatIsarService] ⚠️ updateMessageStatus: not found ($messageId)');
      return false;
    }

    final now = DateTime.now();
    final updates = <String, dynamic>{'send_status': newStatus};
    if (newStatus == 'received' && entity.receivedAt == null) {
      updates['received_at'] = now.millisecondsSinceEpoch;
    } else if (newStatus == 'read' && entity.readAt == null) {
      updates['read_at'] = now.millisecondsSinceEpoch;
    }

    final db = await _db;
    await db.update(
      'messages',
      updates,
      where: 'message_id = ?',
      whereArgs: [messageId],
    );

    debugPrint('[ChatIsarService] 🔄 Status updated: $messageId → $newStatus');
    await _notifyMessagesChanged(entity.roomId);
    return true;
  }

  /// Update status hanya jika status baru lebih tinggi (cegah downgrade).
  Future<bool> updateMessageStatusIfHigher(
    String messageId,
    String newStatus,
    Map<String, int> priority,
  ) async {
    if (!_isAvailable) return false;
    final entity = await getMessageById(messageId);
    if (entity == null) return false;

    final currentPriority = priority[entity.sendStatus] ?? 0;
    final newPriority = priority[newStatus] ?? 0;

    if (newPriority <= currentPriority) {
      debugPrint('[ChatIsarService] ⏭️ Status not upgraded: '
          '${entity.sendStatus}($currentPriority) → $newStatus($newPriority) skipped');
      return false;
    }

    final now = DateTime.now();
    final updates = <String, dynamic>{'send_status': newStatus};
    if (newStatus == 'received' && entity.receivedAt == null) {
      updates['received_at'] = now.millisecondsSinceEpoch;
    } else if (newStatus == 'read' && entity.readAt == null) {
      updates['read_at'] = now.millisecondsSinceEpoch;
      updates['received_at'] ??= now.millisecondsSinceEpoch;
    }

    final db = await _db;
    await db.update(
      'messages',
      updates,
      where: 'message_id = ?',
      whereArgs: [messageId],
    );

    debugPrint('[ChatIsarService] ✅ Status upgraded: $messageId → $newStatus');
    await _notifyMessagesChanged(entity.roomId);
    return true;
  }

  Future<void> replaceLocalMessage({
    required String localId,
    required ChatMessageEntity serverEntity,
  }) async {
    if (!_isAvailable) return;
    final db = await _db;

    await db.transaction((txn) async {
      await txn.delete('messages',
          where: 'local_id = ?', whereArgs: [localId]);
      await txn.insert('messages', serverEntity.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    });

    debugPrint(
        '[ChatIsarService] 🔁 Local replaced: $localId → ${serverEntity.messageId}');
    await _notifyMessagesChanged(serverEntity.roomId);
  }

  Future<void> deleteMessage(String messageId) async {
    if (!_isAvailable) return;
    final entity = await getMessageById(messageId);
    if (entity == null) return;
    final db = await _db;
    await db.delete('messages',
        where: 'message_id = ?', whereArgs: [messageId]);
    await _notifyMessagesChanged(entity.roomId);
  }

  Future<void> deleteMessagesByRoom(String roomId) async {
    if (!_isAvailable) return;
    final db = await _db;
    await db.delete('messages', where: 'room_id = ?', whereArgs: [roomId]);
    debugPrint('[ChatIsarService] 🗑️ Messages deleted for room: $roomId');
    await _notifyMessagesChanged(roomId);
  }

  // ─── Message Streams ──────────────────────────────────────────────────────

  Stream<List<ChatMessageEntity>> watchMessages(String roomId) {
    if (!_isAvailable) return const Stream.empty();
    final ctrl = _msgCtrl(roomId);
    // Fire immediately
    Future.microtask(() async {
      final msgs = await getMessagesByRoom(roomId);
      _latestMessages[roomId] = msgs;
      if (!ctrl.isClosed) ctrl.add(msgs);
    });
    // Replay emisi terakhir ke subscriber baru supaya buka-tutup room tidak
    // memicu shimmer padahal pesannya sudah ada di memory.
    return Stream.multi((c) {
      final latest = _latestMessages[roomId];
      if (latest != null) c.add(latest);
      final sub = ctrl.stream.listen(c.add, onError: c.addError);
      c.onCancel = sub.cancel;
    });
  }

  Stream<List<ChatMessageEntity>> watchPendingMessages(String senderId) {
    if (!_isAvailable) return const Stream.empty();
    // Buat controller khusus untuk pending messages
    final key = '__pending__$senderId';
    final ctrl = _messageControllers.putIfAbsent(
      key,
      () => StreamController<List<ChatMessageEntity>>.broadcast(),
    );

    Future.microtask(() async {
      final msgs = await _queryPendingMessages(senderId);
      _latestPendingMessages[senderId] = msgs;
      if (!ctrl.isClosed) ctrl.add(msgs);
    });

    // Replay emisi terakhir ke subscriber baru — tanpa ini, tiap kali chat
    // dengan partner baru (belum ada room) dibuka, StreamBuilder-nya selalu
    // mulai dari waiting/!hasData walau jawabannya (list kosong) trivial.
    return Stream.multi((c) {
      final latest = _latestPendingMessages[senderId];
      if (latest != null) c.add(latest);
      final sub = ctrl.stream.listen(c.add, onError: c.addError);
      c.onCancel = sub.cancel;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BULK / UTILITY
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> clearAll() async {
    if (!_isAvailable) return;
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('messages');
      await txn.delete('rooms');
    });
    resetStreamCache();
    debugPrint('[ChatIsarService] 🧹 All chat data cleared');
    await _notifyRoomsChanged();
  }

  Future<void> clearRoom(String roomId) async {
    if (!_isAvailable) return;
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('messages',
          where: 'room_id = ?', whereArgs: [roomId]);
      await txn.delete('rooms',
          where: 'room_id = ?', whereArgs: [roomId]);
    });
    debugPrint('[ChatIsarService] 🗑️ Room cleared: $roomId');
    await _notifyRoomsChanged();
    await _notifyMessagesChanged(roomId);
  }

  Future<Map<String, int>> getStats() async {
    if (!_isAvailable) return {'messages': 0, 'rooms': 0};
    final db = await _db;
    final msgResult =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM messages');
    final roomResult =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM rooms');
    return {
      'messages': (msgResult.first['cnt'] as int),
      'rooms': (roomResult.first['cnt'] as int),
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<ChatMessageEntity?> getMessageByLocalId(String localId) async {
    if (!_isAvailable) return null;
    final db = await _db;
    final maps = await db.query(
      'messages',
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ChatMessageEntity.fromMap(maps.first);
  }

  Future<bool> localEchoExists(String localId) async {
    if (!_isAvailable) return false;
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM messages WHERE local_id = ?',
      [localId],
    );
    return (result.first['cnt'] as int) > 0;
  }

  Future<ChatMessageEntity?> findLocalEchoByContent({
    required String roomId,
    required String message,
    required DateTime sentAt,
    String? senderIdHint,
  }) async {
    if (!_isAvailable) return null;
    try {
      final db = await _db;
      final maps = await db.query(
        'messages',
        where:
            "room_id = ? AND message = ? AND message_id LIKE 'local-%'",
        whereArgs: [roomId, message],
      );

      if (maps.isEmpty) return null;

      const threshold = Duration(minutes: 5);
      final candidates = maps
          .map(ChatMessageEntity.fromMap)
          .where((e) => e.sentAt.difference(sentAt).abs() <= threshold)
          .toList();

      if (candidates.isEmpty) return null;

      candidates.sort((a, b) => a.sentAt
          .difference(sentAt)
          .abs()
          .compareTo(b.sentAt.difference(sentAt).abs()));

      debugPrint('[ChatIsarService] 🔍 findLocalEchoByContent: '
          'found ${candidates.first.messageId} '
          'Δt=${candidates.first.sentAt.difference(sentAt).abs().inSeconds}s');
      return candidates.first;
    } catch (e) {
      debugPrint('[ChatIsarService] ⚠️ findLocalEchoByContent: $e');
      return null;
    }
  }

  Future<ChatMessageEntity?> findLocalEchoByContentNoRoom({
    required String message,
    required DateTime sentAt,
    required String senderId,
  }) async {
    if (!_isAvailable) return null;
    try {
      final cutoffEarliest =
          sentAt.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch;
      final cutoffLatest =
          sentAt.add(const Duration(minutes: 5)).millisecondsSinceEpoch;

      final db = await _db;
      final maps = await db.query(
        'messages',
        where:
            "message_id LIKE 'local-%' AND sender_id = ? AND message = ? "
            "AND sent_at >= ? AND sent_at <= ?",
        whereArgs: [senderId, message, cutoffEarliest, cutoffLatest],
      );

      if (maps.isEmpty) return null;

      final candidates = maps.map(ChatMessageEntity.fromMap).toList();
      candidates.sort((a, b) => a.sentAt
          .difference(sentAt)
          .abs()
          .compareTo(b.sentAt.difference(sentAt).abs()));

      debugPrint('[ChatIsarService] 🔍 findLocalEchoByContentNoRoom: '
          'found ${candidates.first.messageId} '
          'roomId="${candidates.first.roomId}" '
          'Δt=${candidates.first.sentAt.difference(sentAt).abs().inSeconds}s');
      return candidates.first;
    } catch (e) {
      debugPrint('[ChatIsarService] ⚠️ findLocalEchoByContentNoRoom: $e');
      return null;
    }
  }

  Future<List<ChatMessageEntity>> getFailedMessages(String roomId) async {
    if (!_isAvailable) return [];
    final db = await _db;
    final maps = await db.query(
      'messages',
      where: "room_id = ? AND send_status = 'failed'",
      whereArgs: [roomId],
      orderBy: 'sent_at ASC',
    );
    return maps.map(ChatMessageEntity.fromMap).toList();
  }

  Future<void> markAllMessagesAsRead(
    String roomId, {
    String? currentUserId,
  }) async {
    if (!_isAvailable) return;
    final unread =
        await getUnreadMessages(roomId, currentUserId: currentUserId);
    if (unread.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final db = await _db;
    final batch = db.batch();
    for (final msg in unread) {
      batch.update(
        'messages',
        {
          'send_status': 'read',
          'read_at': now,
        },
        where: 'message_id = ?',
        whereArgs: [msg.messageId],
      );
    }
    await batch.commit(noResult: true);

    debugPrint(
        '[ChatIsarService] 👁️ ${unread.length} msgs marked read: $roomId');
    await _notifyMessagesChanged(roomId);
  }

  Future<List<String>> markSentMessagesAsReceived(String currentUserId) async {
    if (!_isAvailable) return [];
    final db = await _db;

    final maps = await db.query(
      'messages',
      columns: ['message_id', 'room_id'],
      where:
          "send_status = 'sent' AND sender_id != ? AND message_id NOT LIKE 'local-%'",
      whereArgs: [currentUserId],
    );
    if (maps.isEmpty) return [];

    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();
    for (final m in maps) {
      batch.update(
        'messages',
        {'send_status': 'received', 'received_at': now},
        where: 'message_id = ?',
        whereArgs: [m['message_id']],
      );
    }
    await batch.commit(noResult: true);

    final messageIds = maps.map((m) => m['message_id'] as String).toList();
    final roomIds = maps.map((m) => m['room_id'] as String).toSet();
    debugPrint(
        '[ChatIsarService] 📬 ${messageIds.length} msgs sent→received');
    for (final roomId in roomIds) {
      await _notifyMessagesChanged(roomId);
    }
    return messageIds;
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  String _encodeList(List<String> list) => jsonEncode(list);
}
