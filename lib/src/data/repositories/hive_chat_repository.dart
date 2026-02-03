import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mpjnew/src/data/hive_entity/chat_message_entity.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/room_chat_entity.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';

/// ✅ FIXED: Repository dengan Migration Support dan Upsert Pattern
class HiveChatRepository {
  // Box names
  static const String _roomsBoxName = 'chat_rooms';
  static const String _messagesBoxPrefix = 'chat_messages_';
  static const String _metaBoxName = 'chat_meta';

  // Boxes
  Box<RoomChatEntity>? _roomsBox;
  final Map<String, Box<ChatMessageEntity>> _messagesBoxes = {};
  Box? _metaBox;

  // Stream controllers
  final _roomsStreamController =
      StreamController<List<RoomChatEntity>>.broadcast();
  final Map<String, StreamController<List<ChatMessageEntity>>>
      _messagesStreamControllers = {};

  // =========================================
  // INITIALIZATION
  // =========================================

  Future<void> init() async {
    try {
      debugPrint('[HiveChatRepo] 🚀 Initializing Hive...');

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ChatMessageEntityAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(RoomChatEntityAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(PaketModelAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(PenawaranModelAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(PesananModelAdapter());
      }

      // Open boxes
      _roomsBox = await _safeOpenBox<RoomChatEntity>(_roomsBoxName);
      _metaBox = await _safeOpenBox(_metaBoxName);

      debugPrint('[HiveChatRepo] ✅ Initialized (${_roomsBox!.length} rooms)');
      _notifyRoomsUpdate();
    } catch (e, st) {
      debugPrint('[HiveChatRepo] ❌ Init error: $e\n$st');
      rethrow;
    }
  }

  Future<Box<T>> _safeOpenBox<T>(String boxName) async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (e) {
      if (e.toString().contains('type') &&
          e.toString().contains('is not a subtype')) {
        debugPrint('[HiveChatRepo] 🔄 Type mismatch: $boxName');
        try {
          if (Hive.isBoxOpen(boxName)) {
            await Hive.box(boxName).close();
          }
        } catch (_) {}
        await Hive.deleteBoxFromDisk(boxName);
        return await Hive.openBox<T>(boxName);
      }
      rethrow;
    }
  }

  Future<Box<ChatMessageEntity>> _openMessagesBox(String roomId) async {
    if (_messagesBoxes.containsKey(roomId)) {
      return _messagesBoxes[roomId]!;
    }

    final boxName = '$_messagesBoxPrefix$roomId';
    final box = await _safeOpenBox<ChatMessageEntity>(boxName);
    _messagesBoxes[roomId] = box;

    debugPrint('[HiveChatRepo] 📦 Opened messages box: $roomId');
    return box;
  }

  Future<void> _closeMessagesBox(String roomId) async {
    final box = _messagesBoxes.remove(roomId);
    if (box != null && box.isOpen) {
      await box.close();
    }
  }

  // =========================================
  // ROOMS
  // =========================================

  List<RoomChatEntity> getRooms() {
    if (_roomsBox == null) return [];
    final rooms = _roomsBox!.values.toList();
    rooms.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return rooms;
  }

  Stream<List<RoomChatEntity>> getRoomsStream() {
    _notifyRoomsUpdate();
    return _roomsStreamController.stream;
  }

  RoomChatEntity? getRoom(String roomId) => _roomsBox?.get(roomId);

  RoomChatModel? getRoomModel(String roomId) =>
      getRoom(roomId)?.toRoomChatModel();

  int getTotalUnreadCount() {
    if (_roomsBox == null) return 0;
    return _roomsBox!.values.fold(0, (sum, room) => sum + room.unread);
  }

  Future<void> setRooms(List<RoomChatEntity> rooms) async {
    if (_roomsBox == null) return;
    await _roomsBox!.clear();
    await _roomsBox!.putAll({for (var room in rooms) room.roomId: room});
    debugPrint('[HiveChatRepo] ✅ Set ${rooms.length} rooms');
    _notifyRoomsUpdate();
  }

  Future<void> setRoomsFromModels(List<RoomChatModel> models) async {
    final entities =
        models.map((m) => RoomChatEntity.fromRoomChatModel(m)).toList();
    await setRooms(entities);
  }

  Future<void> upsertRoom(RoomChatEntity room) async {
    if (_roomsBox == null) return;
    await _roomsBox!.put(room.roomId, room);
    _notifyRoomsUpdate();
  }

  Future<void> upsertRoomFromModel(RoomChatModel model) async {
    await upsertRoom(RoomChatEntity.fromRoomChatModel(model));
  }

  Future<void> updateRoomWithMessage({
    required String roomId,
    required String lastMessage,
    required DateTime lastMessageAt,
    bool incrementUnread = false,
  }) async {
    if (_roomsBox == null) return;
    final room = _roomsBox!.get(roomId);
    if (room == null) return;

    final updatedRoom = room.copyWith(
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
      unread: incrementUnread ? room.unread + 1 : room.unread,
    );
    await _roomsBox!.put(roomId, updatedRoom);
    _notifyRoomsUpdate();
  }

  Future<void> clearRoomUnread(String roomId) async {
    if (_roomsBox == null) return;
    final room = _roomsBox!.get(roomId);
    if (room != null && room.unread > 0) {
      await _roomsBox!.put(roomId, room.copyWith(unread: 0));
      _notifyRoomsUpdate();
    }
  }

  Future<void> deleteRoom(String roomId) async {
    if (_roomsBox == null) return;
    await _roomsBox!.delete(roomId);
    await deleteAllMessages(roomId);
    _notifyRoomsUpdate();
  }

  // =========================================
  // MESSAGES - READ
  // =========================================

  Future<List<ChatMessageEntity>> getMessages(String roomId) async {
    final box = await _openMessagesBox(roomId);
    final messages = box.values.toList();
    messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return messages;
  }

  Stream<List<ChatMessageEntity>> getMessagesStream(String roomId) async* {
    final box = await _openMessagesBox(roomId);
    yield _getMessagesFromBox(box);

    if (!_messagesStreamControllers.containsKey(roomId)) {
      _messagesStreamControllers[roomId] =
          StreamController<List<ChatMessageEntity>>.broadcast();
    }
    yield* _messagesStreamControllers[roomId]!.stream;
  }

  Future<List<ChatModel>> getMessagesAsModels(String roomId) async {
    final entities = await getMessages(roomId);
    final room = getRoom(roomId);
    if (room == null) return [];

    return entities
        .map((e) => e.toChatModel(
              tipeUser: 'customer',
              roomType: room.roomType,
              userIds: room.userIds,
            ))
        .toList();
  }

  List<ChatMessageEntity> _getMessagesFromBox(Box<ChatMessageEntity> box) {
    final messages = box.values.toList();
    messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return messages;
  }

  Future<ChatMessageEntity?> getMessage(String roomId, String messageId) async {
    final box = await _openMessagesBox(roomId);
    return box.get(messageId);
  }

  Future<bool> messageExists(String roomId, String messageId) async {
    final box = await _openMessagesBox(roomId);
    return box.containsKey(messageId);
  }

  Future<DateTime?> getLastMessageTimestamp(String roomId) async {
    final messages = await getMessages(roomId);
    return messages.isEmpty ? null : messages.last.sentAt;
  }

  // =========================================
  // MESSAGES - WRITE (UPSERT)
  // =========================================

  /// ✅ UPSERT: Add or update message
  Future<void> addMessage(ChatMessageEntity message) async {
    final box = await _openMessagesBox(message.roomId);
    final existing = box.get(message.messageId);

    bool shouldUpdate = false;

    if (existing == null) {
      // New message - always add
      shouldUpdate = true;
      debugPrint('[HiveChatRepo] ➕ Adding new: ${message.messageId}');
    } else {
      // Check if nested data changed
      final paketChanged = _hasNestedDataChanged(
        existing.paket,
        message.paket,
      );
      final penawaranChanged = _hasNestedDataChanged(
        existing.penawaran,
        message.penawaran,
      );
      final pesananChanged = _hasNestedDataChanged(
        existing.pesanan,
        message.pesanan,
      );
      final statusChanged = existing.sendStatus != message.sendStatus;

      if (paketChanged || penawaranChanged || pesananChanged || statusChanged) {
        shouldUpdate = true;
        debugPrint('[HiveChatRepo] 🔄 Updating: ${message.messageId}');
        debugPrint('  - Paket changed: $paketChanged');
        debugPrint('  - Penawaran changed: $penawaranChanged');
        debugPrint('  - Pesanan changed: $pesananChanged');
        debugPrint('  - Status changed: $statusChanged');
      } else {
        debugPrint('[HiveChatRepo] ⏭️ No changes: ${message.messageId}');
      }
    }

    if (shouldUpdate) {
      await box.put(message.messageId, message);
      _notifyMessagesUpdate(message.roomId);
    }
  }

  /// ✅ NEW: Deep comparison helper
  bool _hasNestedDataChanged<T>(T? oldData, T? newData) {
    // Both null - no change
    if (oldData == null && newData == null) return false;

    // One is null, other isn't - changed
    if (oldData == null || newData == null) return true;

    // Both exist - compare (implement equality check based on type)
    // For now, treat any existence as changed if they differ
    return oldData.toString() != newData.toString();
  }

  Future<void> addMessageFromModel(ChatModel model) async {
    await addMessage(ChatMessageEntity.fromChatModel(model));
  }

  Future<void> addMessageFromModelWithAddons(
    ChatModel model, {
    PaketModel? paket,
    PenawaranModel? penawaran,
    PesananModel? pesanan,
  }) async {
    await addMessage(ChatMessageEntity.fromChatModel(
      model,
      paket: paket,
      penawaran: penawaran,
      pesanan: pesanan,
    ));
  }

  /// ✅ UPSERT: Batch add or update
  Future<void> addMessages(
      String roomId, List<ChatMessageEntity> messages) async {
    final box = await _openMessagesBox(roomId);
    final messagesToUpsert = <String, ChatMessageEntity>{};
    int added = 0, updated = 0;

    for (final message in messages) {
      if (box.containsKey(message.messageId)) {
        updated++;
      } else {
        added++;
      }
      messagesToUpsert[message.messageId] = message;
    }

    if (messagesToUpsert.isNotEmpty) {
      await box.putAll(messagesToUpsert);
      _notifyMessagesUpdate(roomId);
      debugPrint(
          '[HiveChatRepo] ✅ Upserted ${messagesToUpsert.length} (added: $added, updated: $updated)');
    }
  }

  Future<void> addMessagesFromModels(
      String roomId, List<ChatModel> models) async {
    final entities =
        models.map((m) => ChatMessageEntity.fromChatModel(m)).toList();
    await addMessages(roomId, entities);
  }

  Future<void> updateMessage(ChatMessageEntity message) async {
    final box = await _openMessagesBox(message.roomId);
    if (!box.containsKey(message.messageId)) {
      debugPrint('[HiveChatRepo] ⚠️ Message not found: ${message.messageId}');
      return;
    }
    await box.put(message.messageId, message);
    _notifyMessagesUpdate(message.roomId);
  }

  Future<void> updateMessageStatus({
    required String roomId,
    required String messageId,
    required String newStatus,
  }) async {
    final box = await _openMessagesBox(roomId);
    final message = box.get(messageId);

    if (message != null) {
      DateTime? readAt;
      DateTime? receivedAt;

      // ✅ Set timestamps based on status
      if (newStatus == 'read') {
        readAt = DateTime.now();
        receivedAt = message.receivedAt ?? DateTime.now(); // Preserve or set
      } else if (newStatus == 'received') {
        receivedAt = DateTime.now();
      }

      await box.put(
          messageId,
          message.copyWith(
            sendStatus: newStatus,
            readAt: readAt,
            receivedAt: receivedAt, // ✅ Changed from deliveredAt
          ));
      _notifyMessagesUpdate(roomId);

      debugPrint('[HiveChatRepo] ✅ Status: $messageId → $newStatus');
    } else {
      debugPrint('[HiveChatRepo] ⚠️ Message not found: $messageId');
    }
  }

  Future<void> smartUpdateMessage({
    required String roomId,
    required String messageId,
    String? newStatus,
    PaketModel? paket,
    PenawaranModel? penawaran,
    PesananModel? pesanan,
  }) async {
    final box = await _openMessagesBox(roomId);
    final existing = box.get(messageId);

    if (existing == null) {
      debugPrint(
          '[HiveChatRepo] ⚠️ Message not found for smart update: $messageId');
      return;
    }

    DateTime? readAt = existing.readAt;
    DateTime? receivedAt = existing.receivedAt;

    // ✅ Update timestamps based on new status
    if (newStatus != null) {
      if (newStatus == 'read') {
        readAt = DateTime.now();
        receivedAt = receivedAt ?? DateTime.now();
      } else if (newStatus == 'received') {
        receivedAt = DateTime.now();
      }
    }

    final updated = existing.copyWith(
      sendStatus: newStatus ?? existing.sendStatus,
      paket: paket ?? existing.paket,
      penawaran: penawaran ?? existing.penawaran,
      pesanan: pesanan ?? existing.pesanan,
      readAt: readAt,
      receivedAt: receivedAt, // ✅ Changed from deliveredAt
    );

    await box.put(messageId, updated);
    _notifyMessagesUpdate(roomId);

    debugPrint('[HiveChatRepo] ✅ Smart update completed for: $messageId');
  }

  Future<void> storeLatest100Messages(
      String roomId, List<ChatMessageEntity> messages) async {
    final box = await _openMessagesBox(roomId);

    // Clear existing messages in Hive
    await box.clear();

    // Store latest 100 (messages should already be sorted by sentAt ascending)
    final messagesToStore = <String, ChatMessageEntity>{};
    for (final message in messages) {
      messagesToStore[message.messageId] = message;
    }

    await box.putAll(messagesToStore);
    _notifyMessagesUpdate(roomId);

    debugPrint(
        '[HiveChatRepo] ✅ Stored latest ${messages.length} messages in Hive (max 100)');
  }

  Future<bool> replaceLocalEcho({
    required String roomId,
    required ChatMessageEntity serverMessage,
  }) async {
    final box = await _openMessagesBox(roomId);
    String? localKey;

    // Find by localId
    for (final entry in box.toMap().entries) {
      if (entry.value.localId == serverMessage.messageId) {
        localKey = entry.key;
        break;
      }
    }

    // Fuzzy match if not found
    if (localKey == null) {
      for (final entry in box.toMap().entries) {
        final msg = entry.value;
        if (msg.isLocalEcho &&
            msg.senderId == serverMessage.senderId &&
            msg.message == serverMessage.message &&
            msg.sentAt.difference(serverMessage.sentAt).inSeconds.abs() <= 10) {
          localKey = entry.key;
          break;
        }
      }
    }

    if (localKey != null) {
      await box.delete(localKey);
      await box.put(serverMessage.messageId, serverMessage);
      _notifyMessagesUpdate(roomId);
      debugPrint('[HiveChatRepo] 🔄 Replaced local echo: $localKey');
      return true;
    }

    debugPrint('[HiveChatRepo] ⚠️ Local echo not found, adding as new message');
    // ✅ FIXED: Even if local echo not found, add the message
    await box.put(serverMessage.messageId, serverMessage);
    _notifyMessagesUpdate(roomId);
    return false;
  }

  Future<void> markAllMessagesAsRead({
    required String roomId,
    required String currentUserId,
  }) async {
    final box = await _openMessagesBox(roomId);
    final updatedMessages = <String, ChatMessageEntity>{};

    for (final message in box.values) {
      // Only update messages from others that aren't already read
      if (message.senderId != currentUserId && message.sendStatus != 'read') {
        updatedMessages[message.messageId] = message.copyWith(
          sendStatus: 'read',
          readAt: DateTime.now(),
          receivedAt:
              message.receivedAt ?? DateTime.now(), // Ensure receivedAt is set
        );
      }
    }

    if (updatedMessages.isNotEmpty) {
      await box.putAll(updatedMessages);
      _notifyMessagesUpdate(roomId);
      debugPrint(
          '[HiveChatRepo] ✅ Marked ${updatedMessages.length} messages as read');
    }
  }

  Future<void> updateMessageWithPesanan({
    required String roomId,
    required String noPenawaran,
    required String noPesanan,
    PesananModel? pesananModel,
  }) async {
    final box = await _openMessagesBox(roomId);
    final updatedMessages = <String, ChatMessageEntity>{};

    for (final message in box.values) {
      if (message.penawaran?.noId == noPenawaran) {
        updatedMessages[message.messageId] = message.copyWith(
          penawaran: message.penawaran!.copyWith(noPesanan: noPesanan),
          pesanan: pesananModel,
        );
      }
    }

    if (updatedMessages.isNotEmpty) {
      await box.putAll(updatedMessages);
      _notifyMessagesUpdate(roomId);
      debugPrint(
          '[HiveChatRepo] ✅ Updated ${updatedMessages.length} with pesanan');
    }
  }

  Future<void> deleteMessage(String roomId, String messageId) async {
    final box = await _openMessagesBox(roomId);
    await box.delete(messageId);
    _notifyMessagesUpdate(roomId);
  }

  Future<void> deleteAllMessages(String roomId) async {
    final box = await _openMessagesBox(roomId);
    await box.clear();
    await _closeMessagesBox(roomId);
    _messagesStreamControllers[roomId]?.close();
    _messagesStreamControllers.remove(roomId);
  }

  // =========================================
  // METADATA
  // =========================================

  Future<void> saveLastSync(String roomId, DateTime timestamp) async {
    await _metaBox?.put('last_sync_$roomId', timestamp.toIso8601String());
  }

  DateTime? getLastSync(String roomId) {
    final timestampStr = _metaBox?.get('last_sync_$roomId');
    if (timestampStr == null) return null;
    try {
      return DateTime.parse(timestampStr);
    } catch (_) {
      return null;
    }
  }

  // =========================================
  // UTILITIES
  // =========================================

  void _notifyRoomsUpdate() {
    if (!_roomsStreamController.isClosed) {
      _roomsStreamController.add(getRooms());
    }
  }

  void _notifyMessagesUpdate(String roomId) async {
    if (_messagesStreamControllers.containsKey(roomId) &&
        !_messagesStreamControllers[roomId]!.isClosed) {
      final messages = await getMessages(roomId);
      _messagesStreamControllers[roomId]!.add(messages);
    }
  }

  Future<void> clearAll() async {
    await _roomsBox?.clear();
    for (final box in _messagesBoxes.values) {
      await box.clear();
    }
    await _metaBox?.clear();
    _notifyRoomsUpdate();
    debugPrint('[HiveChatRepo] 🧹 Cleared all data');
  }

  Future<void> close() async {
    await _roomsBox?.close();
    await _metaBox?.close();
    for (final box in _messagesBoxes.values) {
      await box.close();
    }
    _roomsStreamController.close();
    for (final controller in _messagesStreamControllers.values) {
      controller.close();
    }
  }

  void printStats() {
    debugPrint('=== Hive Chat Repository ===');
    debugPrint('Rooms: ${_roomsBox?.length ?? 0}');
    debugPrint('Message boxes: ${_messagesBoxes.length}');
    for (final entry in _messagesBoxes.entries) {
      debugPrint('  ${entry.key}: ${entry.value.length} messages');
    }
  }
}
