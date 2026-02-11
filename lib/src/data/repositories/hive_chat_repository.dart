import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mpjnew/src/data/hive_entity/chat_message_entity.dart';
import 'package:mpjnew/src/data/hive_entity/room_chat_entity.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';

/// ✅ IMPROVED: Repository dengan real-time Hive watch stream
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

  // ✅ NEW: Track box watch subscriptions
  final Map<String, StreamSubscription> _boxWatchSubscriptions = {};

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

      // ✅ Setup rooms box watcher
      _setupRoomsBoxWatcher();

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

    // ✅ Setup watcher untuk box ini
    _setupMessagesBoxWatcher(roomId, box);

    debugPrint('[HiveChatRepo] 📦 Opened messages box: $roomId');
    return box;
  }

  Future<void> _closeMessagesBox(String roomId) async {
    // ✅ Cancel box watch subscription
    _boxWatchSubscriptions[roomId]?.cancel();
    _boxWatchSubscriptions.remove(roomId);

    final box = _messagesBoxes.remove(roomId);
    if (box != null && box.isOpen) {
      await box.close();
    }
  }

  // ✅ NEW: Setup rooms box watcher
  void _setupRoomsBoxWatcher() {
    if (_roomsBox == null) return;

    _roomsBox!.watch().listen((event) {
      debugPrint('[HiveChatRepo] 📡 Rooms box changed');
      _notifyRoomsUpdate();
    });
  }

  // ✅ NEW: Setup messages box watcher
  void _setupMessagesBoxWatcher(String roomId, Box<ChatMessageEntity> box) {
    // Cancel existing subscription if any
    _boxWatchSubscriptions[roomId]?.cancel();

    // Create new subscription
    _boxWatchSubscriptions[roomId] = box.watch().listen((BoxEvent event) {
      debugPrint('[HiveChatRepo] 📡 Messages box changed: $roomId');
      debugPrint(
          '[HiveChatRepo]   Event: ${event.key}, deleted: ${event.deleted}');

      // Emit to stream controller
      if (_messagesStreamControllers.containsKey(roomId) &&
          !_messagesStreamControllers[roomId]!.isClosed) {
        final messages = _getMessagesFromBox(box);
        _messagesStreamControllers[roomId]!.add(messages);
        debugPrint(
            '[HiveChatRepo] ✅ Stream updated with ${messages.length} messages');
      }
    });

    debugPrint('[HiveChatRepo] 👁️ Box watcher setup for: $roomId');
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

  /// ✅ IMPROVED: Get total unread dari countStatusReceived
  int getTotalUnreadCount() {
    if (_roomsBox == null) return 0;
    return _roomsBox!.values
        .fold(0, (sum, room) => sum + room.countStatusReceived);
  }

  Future<void> setRooms(List<RoomChatEntity> rooms) async {
    if (_roomsBox == null) return;
    await _roomsBox!.clear();
    await _roomsBox!.putAll({for (var room in rooms) room.roomId: room});
    debugPrint('[HiveChatRepo] ✅ Set ${rooms.length} rooms');

    // Debug info
    final totalUnread = getTotalUnreadCount();
    debugPrint('[HiveChatRepo] 📊 Total unread (received): $totalUnread');

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
    // No need to call _notifyRoomsUpdate() - box watcher will do it
  }

  Future<void> upsertRoomFromModel(RoomChatModel model) async {
    await upsertRoom(RoomChatEntity.fromRoomChatModel(model));
  }

  /// ✅ IMPROVED: Update room dengan support untuk received list
  Future<void> updateRoomWithMessage({
    required String roomId,
    required String lastMessage,
    required DateTime lastMessageAt,
    bool incrementUnread = false,
    bool addToReceivedList = false,
    String? messageId,
  }) async {
    if (_roomsBox == null) return;
    final room = _roomsBox!.get(roomId);
    if (room == null) return;

    List<String> updatedReceivedList =
        List<String>.from(room.listIdMessageReceived);
    int updatedReceivedCount = room.countStatusReceived;

    if (addToReceivedList &&
        messageId != null &&
        !updatedReceivedList.contains(messageId)) {
      updatedReceivedList.add(messageId);
      updatedReceivedCount = updatedReceivedList.length;

      debugPrint('[HiveChatRepo] ➕ Added to received list: $messageId');
      debugPrint('[HiveChatRepo] 📊 Received count: $updatedReceivedCount');
    }

    final updatedRoom = room.copyWith(
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
      unread: incrementUnread ? room.unread + 1 : room.unread,
      countStatusReceived: updatedReceivedCount,
      listIdMessageReceived: updatedReceivedList,
    );

    await _roomsBox!.put(roomId, updatedRoom);
    // Box watcher will trigger update automatically
  }

  Future<void> clearRoomUnread(String roomId) async {
    if (_roomsBox == null) return;
    final room = _roomsBox!.get(roomId);
    if (room != null && (room.unread > 0 || room.countStatusReceived > 0)) {
      await _roomsBox!.put(
        roomId,
        room.copyWith(
          unread: 0,
          countStatusReceived: 0,
          listIdMessageReceived: [],
        ),
      );

      debugPrint('[HiveChatRepo] ✅ Cleared unread for: $roomId');
      debugPrint('[HiveChatRepo] 📊 Received count: 0');
    }
  }

  Future<void> clearRoomReceivedList(String roomId) async {
    if (_roomsBox == null) return;
    final room = _roomsBox!.get(roomId);

    if (room != null && room.countStatusReceived > 0) {
      final updated = room.copyWith(
        countStatusReceived: 0,
        listIdMessageReceived: [],
      );

      await _roomsBox!.put(roomId, updated);

      debugPrint('[HiveChatRepo] ✅ Cleared received list for room: $roomId');
    }
  }

  Future<void> removeFromReceivedList(String roomId, String messageId) async {
    if (_roomsBox == null) return;
    final room = _roomsBox!.get(roomId);

    if (room != null && room.listIdMessageReceived.contains(messageId)) {
      List<String> updatedList = List<String>.from(room.listIdMessageReceived);
      updatedList.remove(messageId);

      final updated = room.copyWith(
        countStatusReceived: updatedList.length,
        listIdMessageReceived: updatedList,
      );

      await _roomsBox!.put(roomId, updated);

      debugPrint('[HiveChatRepo] ✅ Removed $messageId from received list');
      debugPrint('[HiveChatRepo] 📊 New received count: ${updatedList.length}');
    }
  }

  Future<void> addToReceivedList(String roomId, String messageId) async {
    if (_roomsBox == null) return;
    final room = _roomsBox!.get(roomId);

    if (room != null && !room.listIdMessageReceived.contains(messageId)) {
      List<String> updatedList = List<String>.from(room.listIdMessageReceived);
      updatedList.add(messageId);

      final updated = room.copyWith(
        countStatusReceived: updatedList.length,
        listIdMessageReceived: updatedList,
      );

      await _roomsBox!.put(roomId, updated);

      debugPrint('[HiveChatRepo] ➕ Added $messageId to received list');
      debugPrint('[HiveChatRepo] 📊 New received count: ${updatedList.length}');
    }
  }

  Future<void> recalculateUnreadForRoom(
      String roomId, String currentUserId) async {
    try {
      debugPrint('[HiveChatRepo] 🔄 Recalculating unread for: $roomId');

      final messages = await getMessages(roomId);

      final receivedMessages = messages.where((msg) {
        final isFromOther = msg.senderId != currentUserId;
        final isReceived = msg.sendStatus == 'received';
        return isFromOther && isReceived;
      }).toList();

      final receivedMessageIds =
          receivedMessages.map((msg) => msg.messageId).toList();

      final room = _roomsBox?.get(roomId);
      if (room != null) {
        final updated = room.copyWith(
          countStatusReceived: receivedMessages.length,
          listIdMessageReceived: receivedMessageIds,
        );

        await _roomsBox!.put(roomId, updated);

        debugPrint('[HiveChatRepo] ✅ Recalculated unread for $roomId');
        debugPrint(
            '[HiveChatRepo] 📊 Received count: ${receivedMessages.length}');
        debugPrint('[HiveChatRepo] 📋 Message IDs: $receivedMessageIds');
      } else {
        debugPrint('[HiveChatRepo] ⚠️ Room not found: $roomId');
      }
    } catch (e, st) {
      debugPrint('[HiveChatRepo] ❌ Recalculate error for $roomId: $e\n$st');
    }
  }

  Future<void> recalculateAllUnreadCounts(String currentUserId) async {
    try {
      final rooms = getRooms();

      if (rooms.isEmpty) {
        debugPrint('[HiveChatRepo] ⚠️ No rooms to recalculate');
        return;
      }

      debugPrint(
          '[HiveChatRepo] 🔄 Recalculating unread for ${rooms.length} rooms...');

      int totalRecalculated = 0;
      int totalUnreadCount = 0;

      for (final room in rooms) {
        try {
          await recalculateUnreadForRoom(room.roomId, currentUserId);
          totalRecalculated++;

          final updatedRoom = _roomsBox?.get(room.roomId);
          if (updatedRoom != null) {
            totalUnreadCount += updatedRoom.countStatusReceived;
          }
        } catch (e) {
          debugPrint(
              '[HiveChatRepo] ⚠️ Failed to recalculate ${room.roomId}: $e');
        }
      }

      debugPrint('[HiveChatRepo] ✅ Recalculation complete');
      debugPrint(
          '[HiveChatRepo] 📊 Recalculated: $totalRecalculated/${rooms.length} rooms');
      debugPrint('[HiveChatRepo] 📊 Total unread: $totalUnreadCount');
    } catch (e, st) {
      debugPrint('[HiveChatRepo] ❌ Recalculate all error: $e\n$st');
    }
  }

  Future<void> deleteRoom(String roomId) async {
    if (_roomsBox == null) return;
    await _roomsBox!.delete(roomId);
    await deleteAllMessages(roomId);
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

  /// ✅ IMPROVED: Stream with Hive box watch
  Stream<List<ChatMessageEntity>> getMessagesStream(String roomId) async* {
    final box = await _openMessagesBox(roomId);

    // ✅ Initial emission - get current state
    final initialMessages = _getMessagesFromBox(box);
    debugPrint(
        '[HiveChatRepo] 📤 Initial emission: ${initialMessages.length} messages');
    yield initialMessages;

    // ✅ Create controller if not exists
    if (!_messagesStreamControllers.containsKey(roomId)) {
      _messagesStreamControllers[roomId] =
          StreamController<List<ChatMessageEntity>>.broadcast();

      debugPrint('[HiveChatRepo] 🎛️ Stream controller created for: $roomId');
    }

    // ✅ Emit all future updates from controller
    // The controller is fed by _setupMessagesBoxWatcher()
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
      shouldUpdate = true;
      debugPrint('[HiveChatRepo] ➕ Adding new: ${message.messageId}');
    } else {
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
      debugPrint('[HiveChatRepo] ✅ Message saved to Hive');
      // Box watcher will trigger stream update automatically
    }
  }

  bool _hasNestedDataChanged<T>(T? oldData, T? newData) {
    if (oldData == null && newData == null) return false;
    if (oldData == null || newData == null) return true;
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
      debugPrint(
          '[HiveChatRepo] ✅ Upserted ${messagesToUpsert.length} (added: $added, updated: $updated)');
      // Box watcher will trigger stream update
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
    // Box watcher will trigger stream update
  }

  Future<void> updateMessageStatus({
    required String roomId,
    required String messageId,
    required String newStatus,
  }) async {
    final box = await _openMessagesBox(roomId);
    final message = box.get(messageId);

    if (message != null) {
      final oldStatus = message.sendStatus;
      DateTime? readAt;
      DateTime? receivedAt;

      if (newStatus == 'read') {
        readAt = DateTime.now();
        receivedAt = message.receivedAt ?? DateTime.now();
      } else if (newStatus == 'received') {
        receivedAt = DateTime.now();
      }

      await box.put(
          messageId,
          message.copyWith(
            sendStatus: newStatus,
            readAt: readAt,
            receivedAt: receivedAt,
          ));

      debugPrint('[HiveChatRepo] ✅ Status: $messageId → $newStatus');

      await _handleReceivedListOnStatusChange(
        roomId: roomId,
        messageId: messageId,
        oldStatus: oldStatus,
        newStatus: newStatus,
      );
      // Box watcher will trigger stream update
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

    final oldStatus = existing.sendStatus;
    DateTime? readAt = existing.readAt;
    DateTime? receivedAt = existing.receivedAt;

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
      receivedAt: receivedAt,
    );

    await box.put(messageId, updated);

    debugPrint('[HiveChatRepo] ✅ Smart update completed for: $messageId');

    if (newStatus != null) {
      await _handleReceivedListOnStatusChange(
        roomId: roomId,
        messageId: messageId,
        oldStatus: oldStatus,
        newStatus: newStatus,
      );
    }
    // Box watcher will trigger stream update
  }

  Future<void> _handleReceivedListOnStatusChange({
    required String roomId,
    required String messageId,
    required String oldStatus,
    required String newStatus,
  }) async {
    if (oldStatus == 'received' && newStatus == 'read') {
      await removeFromReceivedList(roomId, messageId);
      debugPrint('[HiveChatRepo] 📉 Removed from received (read): $messageId');
    } else if (oldStatus == 'sent' && newStatus == 'received') {
      await addToReceivedList(roomId, messageId);
      debugPrint('[HiveChatRepo] 📈 Added to received (new): $messageId');
    }
  }

  Future<void> storeLatest100Messages(
      String roomId, List<ChatMessageEntity> messages) async {
    final box = await _openMessagesBox(roomId);

    await box.clear();

    final messagesToStore = <String, ChatMessageEntity>{};
    for (final message in messages) {
      messagesToStore[message.messageId] = message;
    }

    await box.putAll(messagesToStore);

    debugPrint(
        '[HiveChatRepo] ✅ Stored latest ${messages.length} messages in Hive (max 100)');
    // Box watcher will trigger stream update
  }

  Future<bool> replaceLocalEcho({
    required String roomId,
    required ChatMessageEntity serverMessage,
  }) async {
    final box = await _openMessagesBox(roomId);
    String? localKey;

    for (final entry in box.toMap().entries) {
      if (entry.value.localId == serverMessage.messageId) {
        localKey = entry.key;
        break;
      }
    }

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
      debugPrint('[HiveChatRepo] 🔄 Replaced local echo: $localKey');
      return true;
    }

    debugPrint('[HiveChatRepo] ⚠️ Local echo not found, adding as new message');
    await box.put(serverMessage.messageId, serverMessage);
    return false;
    // Box watcher will trigger stream update
  }

  Future<void> markAllMessagesAsRead({
    required String roomId,
    required String currentUserId,
  }) async {
    final box = await _openMessagesBox(roomId);
    final updatedMessages = <String, ChatMessageEntity>{};
    final messageIdsToRemoveFromReceived = <String>[];

    for (final message in box.values) {
      if (message.senderId != currentUserId && message.sendStatus != 'read') {
        updatedMessages[message.messageId] = message.copyWith(
          sendStatus: 'read',
          readAt: DateTime.now(),
          receivedAt: message.receivedAt ?? DateTime.now(),
        );

        if (message.sendStatus == 'received') {
          messageIdsToRemoveFromReceived.add(message.messageId);
        }
      }
    }

    if (updatedMessages.isNotEmpty) {
      await box.putAll(updatedMessages);
      debugPrint(
          '[HiveChatRepo] ✅ Marked ${updatedMessages.length} messages as read');
    }

    await clearRoomReceivedList(roomId);
    // Box watcher will trigger stream update
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
      debugPrint(
          '[HiveChatRepo] ✅ Updated ${updatedMessages.length} with pesanan');
    }
    // Box watcher will trigger stream update
  }

  Future<void> deleteMessage(String roomId, String messageId) async {
    final box = await _openMessagesBox(roomId);
    await box.delete(messageId);

    await removeFromReceivedList(roomId, messageId);
    // Box watcher will trigger stream update
  }

  Future<void> deleteAllMessages(String roomId) async {
    final box = await _openMessagesBox(roomId);
    await box.clear();
    await _closeMessagesBox(roomId);
    _messagesStreamControllers[roomId]?.close();
    _messagesStreamControllers.remove(roomId);

    await clearRoomReceivedList(roomId);
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
    // ✅ Cancel all box watch subscriptions
    for (final subscription in _boxWatchSubscriptions.values) {
      await subscription.cancel();
    }
    _boxWatchSubscriptions.clear();

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
    debugPrint('═══════════════════════════════════════');
    debugPrint('📊 HIVE CHAT REPOSITORY STATS');
    debugPrint('═══════════════════════════════════════');
    debugPrint('Rooms: ${_roomsBox?.length ?? 0}');
    debugPrint('Message boxes: ${_messagesBoxes.length}');
    debugPrint('Total Unread (Received): ${getTotalUnreadCount()}');

    if (_roomsBox != null && _roomsBox!.isNotEmpty) {
      debugPrint('\n📋 Room Details:');
      for (final room in _roomsBox!.values) {
        debugPrint('  ${room.roomId}:');
        debugPrint('    - Partner: ${room.usernameLawan}');
        debugPrint('    - Unread (old): ${room.unread}');
        debugPrint('    - ✅ Received: ${room.countStatusReceived}');
        debugPrint(
            '    - Received IDs: ${room.listIdMessageReceived.length} messages');
        debugPrint('    - Sent: ${room.countStatusSent}');
        debugPrint('    - Last: ${room.lastMessage}');
      }
    }

    for (final entry in _messagesBoxes.entries) {
      debugPrint('  ${entry.key}: ${entry.value.length} messages');
    }

    debugPrint('═══════════════════════════════════════');
  }
}
