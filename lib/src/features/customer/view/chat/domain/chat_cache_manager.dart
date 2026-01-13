import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';

/// Manager untuk caching data chat di memory
/// 
/// Features:
/// - In-memory cache untuk rooms dan messages
/// - Smart sync dengan timestamp tracking
/// - Reactive updates via streams
class ChatCacheManager {
  // Singleton
  static final ChatCacheManager _instance = ChatCacheManager._internal();
  factory ChatCacheManager() => _instance;
  ChatCacheManager._internal();

  // Cache storage
  final Map<String, RoomChatModel> _roomsCache = {};
  final Map<String, List<ChatModel>> _messagesCache = {};
  final Map<String, DateTime> _messagesLastFetch = {};
  DateTime? _roomsLastFetch;

  // Config
  static const Duration _roomsCacheExpiry = Duration(minutes: 5);
  static const Duration _messagesCacheExpiry = Duration(minutes: 2);
  static const int _maxMessagesPerRoom = 100;

  // Stream controllers
  final _roomsController = StreamController<List<RoomChatModel>>.broadcast();
  final _messagesController = StreamController<MapEntry<String, List<ChatModel>>>.broadcast();

  // Streams
  Stream<List<RoomChatModel>> get roomsStream => _roomsController.stream;
  Stream<MapEntry<String, List<ChatModel>>> get messagesStream => _messagesController.stream;

  // =========================================
  // ROOMS CACHE
  // =========================================

  /// Get all cached rooms sorted by lastMessageAt
  List<RoomChatModel> get cachedRooms {
    final rooms = _roomsCache.values.toList();
    rooms.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return rooms;
  }

  /// Get single room
  RoomChatModel? getRoom(String roomId) => _roomsCache[roomId];

  /// Check if rooms cache is valid
  bool get isRoomsCacheValid {
    if (_roomsCache.isEmpty || _roomsLastFetch == null) return false;
    return DateTime.now().difference(_roomsLastFetch!) < _roomsCacheExpiry;
  }

  /// Update rooms cache (full replace)
  void setRooms(List<RoomChatModel> rooms) {
    _roomsCache.clear();
    for (final room in rooms) {
      _roomsCache[room.roomId] = room;
    }
    _roomsLastFetch = DateTime.now();
    _notifyRoomsUpdate();
    debugPrint('[ChatCache] Set ${rooms.length} rooms');
  }

  /// Update single room
  void updateRoom(RoomChatModel room) {
    _roomsCache[room.roomId] = room;
    _notifyRoomsUpdate();
  }

  /// Update room dengan pesan baru
  void updateRoomWithMessage(String roomId, ChatModel message, {bool incrementUnread = false}) {
    final room = _roomsCache[roomId];
    if (room != null) {
      _roomsCache[roomId] = room.withNewMessage(message, incrementUnread: incrementUnread);
      _notifyRoomsUpdate();
    }
  }

  /// Clear unread untuk room
  void clearRoomUnread(String roomId) {
    final room = _roomsCache[roomId];
    if (room != null) {
      _roomsCache[roomId] = room.clearUnread();
      _notifyRoomsUpdate();
    }
  }

  /// Invalidate rooms cache
  void invalidateRoomsCache() {
    _roomsLastFetch = null;
  }

  // =========================================
  // MESSAGES CACHE
  // =========================================

  /// Get cached messages untuk room
  List<ChatModel> getMessages(String roomId) {
    return List.unmodifiable(_messagesCache[roomId] ?? []);
  }

  ChatModel getSingleMessage(String roomId, String messageId) {
    final messages = _messagesCache[roomId] ?? [];
    return messages.firstWhere((m) => m.messageId == messageId);
  }

  /// Check if messages cache valid untuk room
  bool isMessagesCacheValid(String roomId) {
    if (!_messagesCache.containsKey(roomId)) return false;
    final lastFetch = _messagesLastFetch[roomId];
    if (lastFetch == null) return false;
    return DateTime.now().difference(lastFetch) < _messagesCacheExpiry;
  }

  /// Get last message timestamp untuk delta sync
  DateTime? getLastMessageTimestamp(String roomId) {
    final messages = _messagesCache[roomId];
    if (messages == null || messages.isEmpty) return null;
    final sorted = [...messages]..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return sorted.first.sentAt;
  }

  /// Set messages (full replace)
  void setMessages(String roomId, List<ChatModel> messages) {
    _messagesCache[roomId] = List.from(messages);
    _messagesLastFetch[roomId] = DateTime.now();
    _trimMessages(roomId);
    _notifyMessagesUpdate(roomId);
    debugPrint('[ChatCache] Set ${messages.length} messages for room $roomId');
  }

  /// Merge new messages (untuk delta sync)
  void mergeMessages(String roomId, List<ChatModel> newMessages) {
    final existing = _messagesCache[roomId] ?? [];
    final existingIds = existing.map((m) => m.messageId).toSet();
    
    final toAdd = newMessages.where((m) => !existingIds.contains(m.messageId)).toList();
    
    if (toAdd.isNotEmpty) {
      _messagesCache[roomId] = [...existing, ...toAdd]
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      _trimMessages(roomId);
      _notifyMessagesUpdate(roomId);
      debugPrint('[ChatCache] Merged ${toAdd.length} new messages for room $roomId');
    }
  }

  /// Add single message
  void addMessage(String roomId, ChatModel message) {
    final messages = _messagesCache[roomId] ?? [];
    
    // Check duplicate
    final existingIndex = messages.indexWhere((m) => m.messageId == message.messageId);
    if (existingIndex != -1) {
      messages[existingIndex] = message;
    } else {
      messages.add(message);
    }
    
    _messagesCache[roomId] = messages..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    _trimMessages(roomId);
    _notifyMessagesUpdate(roomId);
  }

  /// Add local echo (optimistic update)
  void addLocalEcho(String roomId, ChatModel localMessage) {
    final messages = _messagesCache[roomId] ?? [];
    messages.add(localMessage);
    _messagesCache[roomId] = messages;
    _notifyMessagesUpdate(roomId);
    debugPrint('[ChatCache] Added local echo: ${localMessage.localId}');
  }

  /// Replace local echo dengan server message
  bool replaceLocalEcho(String roomId, ChatModel serverMessage) {
    final messages = _messagesCache[roomId];
    if (messages == null) return false;

    // Cari by localId atau by content match
    final index = messages.indexWhere((m) =>
        m.isLocalEcho &&
        m.senderId == serverMessage.senderId &&
        m.message == serverMessage.message &&
        m.sentAt.difference(serverMessage.sentAt).inSeconds.abs() < 10);

    if (index != -1) {
      final oldLocalId = messages[index].localId;
      messages[index] = serverMessage;
      _messagesCache[roomId] = messages;
      _notifyMessagesUpdate(roomId);
      debugPrint('[ChatCache] Replaced local echo $oldLocalId with ${serverMessage.messageId}');
      return true;
    }
    return false;
  }

  /// Update message status
  void updateMessageStatus(String roomId, String messageId, String newStatus) {
    final messages = _messagesCache[roomId];
    if (messages == null) return;

    final index = messages.indexWhere((m) => 
        m.messageId == messageId || m.localId == messageId);
    if (index != -1) {
      messages[index] = messages[index].copyWith(sendStatus: newStatus);
      _messagesCache[roomId] = messages;
      _notifyMessagesUpdate(roomId);
    }
  }

  /// Update message dengan noPesanan (penawaran -> pesanan)
  void updateMessageWithPesanan(String roomId, String noPenawaran, String noPesanan) {
    final messages = _messagesCache[roomId];
    if (messages == null) return;

    bool updated = false;
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].noPenawaran == noPenawaran) {
        messages[i] = messages[i].copyWith(noInvoice: noPesanan);
        updated = true;
      }
    }

    if (updated) {
      _messagesCache[roomId] = messages;
      _notifyMessagesUpdate(roomId);
      debugPrint('[ChatCache] Updated penawaran $noPenawaran with pesanan $noPesanan');
    }
  }

  /// Remove message (untuk failed messages)
  void removeMessage(String roomId, String messageIdOrLocalId) {
    final messages = _messagesCache[roomId];
    if (messages == null) return;

    messages.removeWhere((m) => 
        m.messageId == messageIdOrLocalId || m.localId == messageIdOrLocalId);
    _messagesCache[roomId] = messages;
    _notifyMessagesUpdate(roomId);
  }

  /// Mark all messages as read untuk room
  void markMessagesAsRead(String roomId, String currentUserId) {
    final messages = _messagesCache[roomId];
    if (messages == null) return;

    bool updated = false;
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].senderId != currentUserId && 
          !messages[i].sendStatusEnum.isRead) {
        messages[i] = messages[i].copyWith(
          sendStatus: 'read',
          readAt: DateTime.now(),
        );
        updated = true;
      }
    }

    if (updated) {
      _messagesCache[roomId] = messages;
      _notifyMessagesUpdate(roomId);
    }
  }

  /// Invalidate messages cache untuk room
  void invalidateMessagesCache(String roomId) {
    _messagesLastFetch.remove(roomId);
  }

  // =========================================
  // UTILITIES
  // =========================================

  void _trimMessages(String roomId) {
    final messages = _messagesCache[roomId];
    if (messages != null && messages.length > _maxMessagesPerRoom) {
      _messagesCache[roomId] = messages.sublist(messages.length - _maxMessagesPerRoom);
    }
  }

  void _notifyRoomsUpdate() {
    if (!_roomsController.isClosed) {
      _roomsController.add(cachedRooms);
    }
  }

  void _notifyMessagesUpdate(String roomId) {
    if (!_messagesController.isClosed) {
      _messagesController.add(MapEntry(roomId, getMessages(roomId)));
    }
  }

  /// Clear all cache
  void clearAll() {
    _roomsCache.clear();
    _messagesCache.clear();
    _messagesLastFetch.clear();
    _roomsLastFetch = null;
    debugPrint('[ChatCache] Cleared all');
  }

  /// Clear cache untuk room tertentu
  void clearRoom(String roomId) {
    _messagesCache.remove(roomId);
    _messagesLastFetch.remove(roomId);
  }

  /// Dispose
  void dispose() {
    _roomsController.close();
    _messagesController.close();
    clearAll();
  }

  /// Debug info
  void printStats() {
    debugPrint('=== Chat Cache Stats ===');
    debugPrint('Rooms: ${_roomsCache.length}');
    debugPrint('Rooms with messages: ${_messagesCache.length}');
    for (final entry in _messagesCache.entries) {
      debugPrint('  ${entry.key}: ${entry.value.length} msgs');
    }
  }
}