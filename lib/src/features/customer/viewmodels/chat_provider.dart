import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/services/penawaran_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/view/chat/data/service/chat_api_service.dart';
import 'package:mpjnew/src/data/hive_entity/chat_message_entity.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';
import 'package:mpjnew/src/data/repositories/hive_chat_repository.dart';

/// ✅ ChatProvider with IMPROVED FCM Integration + Status Updates
/// Real-time updates via FCM with proper status flow
///
/// Storage Strategy:
/// 1. Hive - Latest 100 messages (persistent, fast access)
/// 2. In-Memory - ALL messages from API (volatile, full history)
///
/// Display Strategy:
/// - INSTANT: Show Hive data immediately (< 50ms)
/// - BACKGROUND: Sync from API silently
class ChatProvider extends ChangeNotifier {
  final ChatApiService _apiService = ChatApiService();
  final HiveChatRepository _repository = HiveChatRepository();

  // State
  String? _currentUserId;
  String? _userType;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  String? _activeRoomId;

  // ✅ Stream controllers for messages
  final Map<String, StreamController<List<ChatMessageEntity>>>
      _messagesStreamControllers = {};

  // In-Memory Storage
  final Map<String, List<ChatMessageEntity>> _allMessagesInMemory = {};
  final Map<String, RoomChatModel> _roomInfoCache = {};

  HiveChatRepository get repository => _repository;

  final Map<String, int> _displayedCount = {};
  static const int _initialDisplayCount = 100;
  static const int _loadMoreIncrement = 100;

  // Tracked rooms (for FCM filtering)
  final Set<String> _trackedRooms = {};

  // ✅ Track pending local messages for better echo detection
  final Map<String, Set<String>> _pendingLocalMessages = {};

  // =========================================
  // CALLBACKS
  // =========================================
  Function(ChatModel message)? onNewMessageFromOther;
  Function(String roomId)? onRoomUpdated;

  // =========================================
  // GETTERS
  // =========================================
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;
  String? get userType => _userType;
  String? get error => _error;
  String? get activeRoomId => _activeRoomId;

  Stream<List<ChatMessageEntity>> getMessagesStream(String roomId) async* {
    debugPrint('[ChatProvider] 🎛️ Creating stream for: $roomId');

    // PHASE 1: Emit from Hive IMMEDIATELY
    final hiveMessages = await _repository.getMessages(roomId);
    if (!_displayedCount.containsKey(roomId)) {
      _displayedCount[roomId] = _initialDisplayCount;
    }
    yield hiveMessages;

    // PHASE 2: Check in-memory data
    if (_allMessagesInMemory.containsKey(roomId)) {
      yield getMessagesForDisplay(roomId);
    }

    // PHASE 3: Listen to future updates
    if (!_messagesStreamControllers.containsKey(roomId)) {
      _messagesStreamControllers[roomId] =
          StreamController<List<ChatMessageEntity>>.broadcast();
    }

    yield* _messagesStreamControllers[roomId]!.stream.asyncMap((_) {
      return getMessagesForDisplay(roomId);
    });
  }

  void _notifyMessagesUpdate(String roomId) {
    if (_messagesStreamControllers.containsKey(roomId) &&
        !_messagesStreamControllers[roomId]!.isClosed) {
      _messagesStreamControllers[roomId]!.add(getMessagesForDisplay(roomId));
      debugPrint('[ChatProvider] 🔔 Stream updated: $roomId');
    }
  }

  List<ChatMessageEntity> getMessagesForDisplay(String roomId) {
    if (!_allMessagesInMemory.containsKey(roomId)) return [];
    final all = _allMessagesInMemory[roomId]!;
    final count = _displayedCount[roomId] ?? _initialDisplayCount;
    return all.length <= count ? all : all.sublist(all.length - count);
  }

  List<RoomChatModel> get rooms =>
      _repository.getRooms().map((e) => e.toRoomChatModel()).toList();

  RoomChatModel? getRoom(String roomId) => _repository.getRoomModel(roomId);
  int get totalUnreadCount => _repository.getTotalUnreadCount();
  List<ChatMessageEntity> getAllMessagesInMemory(String roomId) =>
      _allMessagesInMemory[roomId] ?? [];

  String getSenderName(String roomId, String senderId) {
    final room = _roomInfoCache[roomId] ?? getRoom(roomId);
    return room?.usernameLawan ?? 'New Message';
  }

  bool isRoomTracked(String roomId) => _trackedRooms.contains(roomId);
  Set<String> get trackedRooms => Set.unmodifiable(_trackedRooms);

  // =========================================
  // INITIALIZATION
  // =========================================

  ChatProvider() {
    _initRepository();
  }

  Future<void> _initRepository() async {
    try {
      await _repository.init();
      debugPrint('[ChatProvider] ✅ Repository initialized');
    } catch (e) {
      debugPrint('[ChatProvider] ❌ Repository init failed: $e');
    }
  }

  Future<bool> initialize({
    required String userId,
    required String userType,
  }) async {
    if (_isInitialized) {
      debugPrint('[ChatProvider] ℹ️ Already initialized');
      return true;
    }

    debugPrint('[ChatProvider] 🚀 INITIALIZING: $userId ($userType)');
    _currentUserId = userId;
    _userType = userType;

    try {
      await _repository.init();
      _isInitialized = true;
      _error = null;
      notifyListeners();

      _backgroundLoadRooms();
      _backgroundRecalculateUnread(userId);
      return true;
    } catch (e, st) {
      debugPrint('[ChatProvider] ❌ Init error: $e\n$st');
      _error = e.toString();
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }

  void _backgroundLoadRooms() {
    loadRooms(forceRefresh: true, silent: true)
        .then((r) => debugPrint('[ChatProvider] ✅ Background: ${r.length} rooms'))
        .catchError((e) => debugPrint('[ChatProvider] ⚠️ Background rooms: $e'));
  }

  void _backgroundRecalculateUnread(String userId) {
    _repository
        .recalculateAllUnreadCounts(userId)
        .then((_) {
          debugPrint('[ChatProvider] ✅ Unread recalculated');
          notifyListeners();
        })
        .catchError((e) => debugPrint('[ChatProvider] ⚠️ Unread recalc: $e'));
  }

  // =========================================
  // ✅ LOGOUT — Clear in-memory + close Hive boxes
  // =========================================

  /// Dipanggil oleh CustomerLocalStorageManager.clearOnLogout()
  ///
  /// Yang dilakukan:
  /// 1. Clear semua in-memory state
  /// 2. Close semua stream controllers
  /// 3. Tutup semua Hive box (data di disk TETAP)
  /// 4. Reset _isInitialized → bisa init ulang saat login berikutnya
  Future<void> closeAndClearInMemory() async {
    debugPrint('[ChatProvider] ═══════════════════════════════════════');
    debugPrint('[ChatProvider] 🚪 LOGOUT: closeAndClearInMemory');
    debugPrint('[ChatProvider] ═══════════════════════════════════════');

    // 1. Nonaktifkan active room dulu
    _activeRoomId = null;

    // 2. Clear in-memory
    _allMessagesInMemory.clear();
    _roomInfoCache.clear();
    _displayedCount.clear();
    _trackedRooms.clear();
    _pendingLocalMessages.clear();
    debugPrint('[ChatProvider]    ✅ In-memory cleared');

    // 3. Close stream controllers
    for (final entry in _messagesStreamControllers.entries) {
      if (!entry.value.isClosed) {
        await entry.value.close();
      }
    }
    _messagesStreamControllers.clear();
    debugPrint('[ChatProvider]    ✅ Streams closed');

    // 4. Tutup Hive boxes via repository (data tetap di disk)
    await _repository.closeAndClearInMemory();
    debugPrint('[ChatProvider]    ✅ Hive boxes closed (data on disk intact)');

    // 5. Reset state flags
    _currentUserId = null;
    _userType = null;
    _isInitialized = false;
    _isLoading = false;
    _error = null;

    notifyListeners();

    debugPrint('[ChatProvider] ✅ closeAndClearInMemory complete');
    debugPrint('[ChatProvider] ═══════════════════════════════════════');
  }

  // =========================================
  // FCM INTEGRATION
  // =========================================

  Future<void> handleMessageFromFCM(ChatModel message) async {
    // Guard: jangan proses jika sudah logout
    if (!_isInitialized || _currentUserId == null) {
      debugPrint('[ChatProvider] ⚠️ Not initialized, skipping FCM');
      return;
    }

    debugPrint('[ChatProvider] 📨 FCM: ${message.messageId} from ${message.senderId}');

    final isFromMe = message.senderId == _currentUserId;
    final isActiveRoom = _activeRoomId == message.roomId;

    if (isFromMe) {
      final isLikelyOurEcho = message.sendStatus == 'sent' ||
          message.sendStatus == 'pending' ||
          (message.localId != null && message.localId!.isNotEmpty);

      if (isLikelyOurEcho) {
        await _handleOwnMessageFromFCM(message);
      } else {
        await _handleOwnMessageStatusUpdate(message);
      }
    } else {
      await _handleMessageFromOthers(message, isActiveRoom);
    }
  }

  Future<void> _handleOwnMessageFromFCM(ChatModel message) async {
    debugPrint('[ChatProvider] 📤 Own echo: ${message.messageId}');

    final paket = await _loadPaketModel(message.idPaket);
    final penawaran = await _loadPenawaranModel(message.noPenawaran);
    final pesanan = await _loadPesananModel(message.noInvoice);

    final serverEntity = ChatMessageEntity.fromChatModel(
      message.copyWith(sendStatus: 'sent'),
      paket: paket,
      penawaran: penawaran,
      pesanan: pesanan,
    );

    final alreadyExists =
        await _repository.messageExists(message.roomId, message.messageId);

    if (alreadyExists) {
      await _updateExistingServerMessage(
          message, serverEntity, paket, penawaran, pesanan);
      return;
    }

    final localEchoFound = await _findAndReplaceLocalEcho(
      message: message,
      serverEntity: serverEntity,
    );

    if (localEchoFound) {
      _removeFromPendingTracking(message.roomId, message.messageId);
      _removeFromPendingTracking(message.roomId, message.localId ?? '');
    } else {
      await _repository.addMessage(serverEntity);
      _addToInMemory(message.roomId, serverEntity);
      debugPrint('[ChatProvider] ✅ Added (from another device)');
    }

    await _repository.updateRoomWithMessage(
      roomId: message.roomId,
      lastMessage: _buildLastMessage(message),
      lastMessageAt: message.sentAt,
      incrementUnread: false,
    );

    _notifyMessagesUpdate(message.roomId);
    notifyListeners();
  }

  Future<void> _handleOwnMessageStatusUpdate(ChatModel message) async {
    debugPrint('[ChatProvider] 🔄 Own status update: ${message.messageId}');

    final exists =
        await _repository.messageExists(message.roomId, message.messageId);
    if (!exists) return;

    final existing =
        await _repository.getMessage(message.roomId, message.messageId);
    if (existing == null) return;

    final statusChanged = existing.sendStatus != message.sendStatus;
    final invoiceChanged = existing.pesanan == null &&
        message.noInvoice != null &&
        message.noInvoice!.isNotEmpty;
    final penawaranChanged = existing.penawaran == null &&
        message.noPenawaran != null &&
        message.noPenawaran!.isNotEmpty;
    final paketChanged = existing.paket == null &&
        message.idPaket != null &&
        message.idPaket!.isNotEmpty;

    if (!statusChanged && !invoiceChanged && !penawaranChanged && !paketChanged) {
      debugPrint('[ChatProvider] ⏭️ No changes, skipping');
      return;
    }

    PaketModel? paket = existing.paket;
    PenawaranModel? penawaran = existing.penawaran;
    PesananModel? pesanan = existing.pesanan;

    if (paketChanged) paket = await _loadPaketModel(message.idPaket);
    if (penawaranChanged) penawaran = await _loadPenawaranModel(message.noPenawaran);
    if (invoiceChanged) pesanan = await _loadPesananModel(message.noInvoice);

    String finalStatus = message.sendStatus;
    DateTime? readAt = existing.readAt;
    DateTime? receivedAt = existing.receivedAt;

    if (statusChanged && message.sendStatus == 'read') {
      readAt = DateTime.now();
      receivedAt = receivedAt ?? DateTime.now();
    } else if (statusChanged && message.sendStatus == 'received') {
      receivedAt = DateTime.now();
    }

    await _repository.smartUpdateMessage(
      roomId: message.roomId,
      messageId: message.messageId,
      newStatus: finalStatus,
      paket: paket,
      penawaran: penawaran,
      pesanan: pesanan,
    );

    _updateInMemoryMessage(
      message.roomId,
      existing.copyWith(
        sendStatus: finalStatus,
        readAt: readAt,
        receivedAt: receivedAt,
        paket: paket,
        penawaran: penawaran,
        pesanan: pesanan,
      ),
    );

    if (invoiceChanged) {
      await _repository.updateRoomWithMessage(
        roomId: message.roomId,
        lastMessage: _buildLastMessage(message),
        lastMessageAt: message.sentAt,
        incrementUnread: false,
      );
    }

    _notifyMessagesUpdate(message.roomId);
    notifyListeners();
  }

  Future<void> _updateExistingServerMessage(
    ChatModel message,
    ChatMessageEntity serverEntity,
    PaketModel? paket,
    PenawaranModel? penawaran,
    PesananModel? pesanan,
  ) async {
    final existing =
        await _repository.getMessage(message.roomId, message.messageId);

    if (existing != null) {
      final needsUpdate = (existing.paket == null && paket != null) ||
          (existing.penawaran == null && penawaran != null) ||
          (existing.pesanan == null && pesanan != null) ||
          existing.sendStatus != 'sent';

      if (needsUpdate) {
        await _repository.smartUpdateMessage(
          roomId: message.roomId,
          messageId: message.messageId,
          newStatus: 'sent',
          paket: paket,
          penawaran: penawaran,
          pesanan: pesanan,
        );
        _updateInMemoryMessage(message.roomId, serverEntity);
        _notifyMessagesUpdate(message.roomId);
      }
    }

    await _repository.updateRoomWithMessage(
      roomId: message.roomId,
      lastMessage: _buildLastMessage(message),
      lastMessageAt: message.sentAt,
      incrementUnread: false,
    );
    notifyListeners();
  }

  Future<bool> _findAndReplaceLocalEcho({
    required ChatModel message,
    required ChatMessageEntity serverEntity,
  }) async {
    final allMessages = await _repository.getMessages(message.roomId);

    // STRATEGY 1: Match by localId
    if (message.localId != null && message.localId!.isNotEmpty) {
      try {
        final localMsg = allMessages.firstWhere(
          (m) => m.localId == message.localId || m.messageId == message.localId,
        );
        await _replaceMessage(localMsg.messageId, serverEntity);
        return true;
      } catch (_) {}
    }

    // STRATEGY 2: Match by "local-" prefix
    for (final msg in allMessages) {
      if (msg.messageId.startsWith('local-') &&
          msg.senderId == message.senderId &&
          msg.message == message.message &&
          (msg.sendStatus == 'pending' || msg.sendStatus == 'sent')) {
        await _replaceMessage(msg.messageId, serverEntity);
        return true;
      }
    }

    // STRATEGY 3: Match by content + time
    for (final msg in allMessages) {
      if (msg.senderId != message.senderId) continue;
      if (msg.sendStatus != 'pending' && msg.sendStatus != 'sent') continue;

      final contentMatch = msg.message == message.message &&
          msg.paket?.no_id == message.idPaket &&
          msg.penawaran?.noId == message.noPenawaran;
      if (!contentMatch) continue;

      if (msg.sentAt.difference(message.sentAt).inSeconds.abs() > 60) continue;

      await _replaceMessage(msg.messageId, serverEntity);
      return true;
    }

    // STRATEGY 4: Pending tracking
    if (message.localId != null &&
        (_pendingLocalMessages[message.roomId]?.contains(message.localId) ?? false)) {
      try {
        final localMsg = allMessages.firstWhere(
          (m) => m.messageId == message.localId || m.localId == message.localId,
        );
        await _replaceMessage(localMsg.messageId, serverEntity);
        return true;
      } catch (_) {}
    }

    return false;
  }

  Future<void> _replaceMessage(
    String oldMessageId,
    ChatMessageEntity newMessage,
  ) async {
    await _repository.deleteMessage(newMessage.roomId, oldMessageId);
    _removeFromInMemory(newMessage.roomId, oldMessageId);
    await _repository.addMessage(newMessage);
    _addToInMemory(newMessage.roomId, newMessage);
    _notifyMessagesUpdate(newMessage.roomId);
    debugPrint('[ChatProvider] 🔄 Replaced: $oldMessageId → ${newMessage.messageId}');
  }

  Future<void> _handleMessageFromOthers(
    ChatModel message,
    bool isActiveRoom,
  ) async {
    debugPrint('[ChatProvider] 📥 From others: ${message.messageId}');

    final paket = await _loadPaketModel(message.idPaket);
    final penawaran = await _loadPenawaranModel(message.noPenawaran);
    final pesanan = await _loadPesananModel(message.noInvoice);

    final exists =
        await _repository.messageExists(message.roomId, message.messageId);

    String finalStatus;
    bool shouldIncrementUnread;
    bool shouldAddToReceivedList = false;

    if (exists) {
      final existing =
          await _repository.getMessage(message.roomId, message.messageId);
      if (existing == null) return;

      final needsUpdate = (existing.paket == null && paket != null) ||
          (existing.penawaran == null && penawaran != null) ||
          (existing.pesanan == null && pesanan != null) ||
          existing.sendStatus != message.sendStatus;

      if (needsUpdate) {
        if (isActiveRoom) {
          finalStatus = 'read';
          shouldIncrementUnread = false;
          await _repository.clearRoomUnread(message.roomId);
          await _repository.markAllMessagesAsRead(
            roomId: message.roomId,
            currentUserId: _currentUserId!,
          );
        } else if (message.sendStatus == 'sent') {
          finalStatus = 'received';
          shouldIncrementUnread = false;
          shouldAddToReceivedList = existing.sendStatus != 'received';
        } else {
          finalStatus = message.sendStatus;
          shouldIncrementUnread = false;
        }

        await _repository.smartUpdateMessage(
          roomId: message.roomId,
          messageId: message.messageId,
          newStatus: finalStatus,
          paket: paket,
          penawaran: penawaran,
          pesanan: pesanan,
        );
        _updateInMemoryMessage(
          message.roomId,
          ChatMessageEntity.fromChatModel(
            message.copyWith(sendStatus: finalStatus),
            paket: paket,
            penawaran: penawaran,
            pesanan: pesanan,
          ),
        );
      } else {
        if (isActiveRoom && existing.sendStatus != 'read') {
          finalStatus = 'read';
          shouldIncrementUnread = false;
          await _repository.updateMessageStatus(
            roomId: message.roomId,
            messageId: message.messageId,
            newStatus: 'read',
          );
          _updateInMemoryMessage(
              message.roomId, existing.copyWith(sendStatus: 'read'));
        } else {
          finalStatus = existing.sendStatus;
          shouldIncrementUnread = false;
        }
      }
    } else {
      if (isActiveRoom) {
        finalStatus = 'read';
        shouldIncrementUnread = false;
        final entity = ChatMessageEntity.fromChatModel(
          message.copyWith(sendStatus: 'read'),
          paket: paket,
          penawaran: penawaran,
          pesanan: pesanan,
        );
        await _repository.addMessage(entity);
        await _repository.clearRoomUnread(message.roomId);
        _addToInMemory(message.roomId, entity);
      } else {
        finalStatus = 'received';
        shouldIncrementUnread = true;
        shouldAddToReceivedList = true;
        final entity = ChatMessageEntity.fromChatModel(
          message.copyWith(sendStatus: 'received'),
          paket: paket,
          penawaran: penawaran,
          pesanan: pesanan,
        );
        await _repository.addMessage(entity);
        _addToInMemory(message.roomId, entity);
      }

      if (!isActiveRoom) onNewMessageFromOther?.call(message);
    }

    await _repository.updateRoomWithMessage(
      roomId: message.roomId,
      lastMessage: _buildLastMessage(message),
      lastMessageAt: message.sentAt,
      incrementUnread: shouldIncrementUnread,
      addToReceivedList: shouldAddToReceivedList,
      messageId: message.messageId,
    );

    if (message.sendStatus != finalStatus) {
      _apiService
          .updateMessageStatus(messageId: message.messageId, status: finalStatus)
          .then((_) => debugPrint('[ChatProvider] ✅ Status synced: $finalStatus'))
          .catchError((e) => debugPrint('[ChatProvider] ⚠️ Sync failed: $e'));
    }

    await _repository.recalculateUnreadForRoom(message.roomId, _currentUserId!);
    _notifyMessagesUpdate(message.roomId);
    notifyListeners();
  }

  // =========================================
  // ROOM MANAGEMENT
  // =========================================

  Future<void> trackRoom(String roomId) async {
    if (_trackedRooms.contains(roomId)) return;
    _trackedRooms.add(roomId);
    debugPrint('[ChatProvider] 📍 Tracking: $roomId');

    final hiveMessages = await _repository.getMessages(roomId);
    if (hiveMessages.isNotEmpty) {
      _allMessagesInMemory[roomId] = hiveMessages;
    }
    loadMessages(roomId, silent: true);
  }

  void untrackRoom(String roomId) {
    _trackedRooms.remove(roomId);
    _pendingLocalMessages.remove(roomId);
    debugPrint('[ChatProvider] 👋 Untracked: $roomId');
  }

  Future<List<RoomChatModel>> loadRooms({
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    if (_currentUserId == null) return [];
    if (!silent) _setLoading(true);

    try {
      final roomModels = await _apiService.fetchRooms(userId: _currentUserId!);
      await _repository.setRoomsFromModels(roomModels);
      for (final room in roomModels) {
        _roomInfoCache[room.roomId] = room;
      }
      await _repository.recalculateAllUnreadCounts(_currentUserId!);
      if (!silent) notifyListeners();
      return roomModels;
    } catch (e) {
      debugPrint('[ChatProvider] ❌ loadRooms: $e');
      return rooms;
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  Future<RoomChatModel?> findOrCreateRoom(String partnerId) async {
    if (_currentUserId == null) return null;

    final allRooms = _repository.getRooms();
    final cached = allRooms.where((r) =>
        r.idLawan == partnerId ||
        r.getPartnerId(_currentUserId!) == partnerId).toList();

    if (cached.isNotEmpty) {
      final m = cached.first.toRoomChatModel();
      _roomInfoCache[m.roomId] = m;
      return m;
    }

    final roomModels = await _apiService.fetchRooms(
      userId: _currentUserId!,
      partnerId: partnerId,
    );

    if (roomModels.isNotEmpty) {
      await _repository.upsertRoomFromModel(roomModels.first);
      _roomInfoCache[roomModels.first.roomId] = roomModels.first;
      return roomModels.first;
    }

    return null;
  }

  // =========================================
  // MESSAGES MANAGEMENT
  // =========================================

  Future<List<ChatModel>> loadMessages(
    String roomId, {
    bool forceRefresh = false,
    bool silent = true,
  }) async {
    if (_currentUserId == null) return [];
    if (!silent) _setLoading(true);

    try {
      final lastTimestamp = forceRefresh
          ? null
          : await _repository.getLastMessageTimestamp(roomId);

      final messageModels = await _apiService.fetchMessages(
        roomId: roomId,
        since: lastTimestamp,
      );

      if (messageModels.isNotEmpty) {
        await _enrichAndSaveToDualStorage(roomId, messageModels);
        _resetDisplayCount(roomId);
        _notifyMessagesUpdate(roomId);
      }

      await _repository.recalculateUnreadForRoom(roomId, _currentUserId!);
      await markRoomAsRead(roomId);
      await _repository.saveLastSync(roomId, DateTime.now());

      return await _repository.getMessagesAsModels(roomId);
    } catch (e) {
      debugPrint('[ChatProvider] ❌ loadMessages: $e');
      return await _repository.getMessagesAsModels(roomId);
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  Future<void> _enrichAndSaveToDualStorage(
    String roomId,
    List<ChatModel> messages,
  ) async {
    final paketIds = messages
        .where((m) => m.idPaket?.isNotEmpty == true)
        .map((m) => m.idPaket!)
        .toSet()
        .toList();
    final penawaranIds = messages
        .where((m) => m.noPenawaran?.isNotEmpty == true)
        .map((m) => m.noPenawaran!)
        .toSet()
        .toList();
    final pesananIds = messages
        .where((m) => m.noInvoice?.isNotEmpty == true)
        .map((m) => m.noInvoice!)
        .toSet()
        .toList();

    final paketMap = await _batchFetchPaket(paketIds);
    final penawaranMap = await _batchFetchPenawaran(penawaranIds);
    final pesananMap = await _batchFetchPesanan(pesananIds);

    final enriched = messages.map((m) => ChatMessageEntity.fromChatModel(
          m,
          paket: paketMap[m.idPaket],
          penawaran: penawaranMap[m.noPenawaran],
          pesanan: pesananMap[m.noInvoice],
        )).toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

    _allMessagesInMemory[roomId] = enriched;

    final latest100 = enriched.length > 100
        ? enriched.sublist(enriched.length - 100)
        : enriched;
    await _repository.storeLatest100Messages(roomId, latest100);

    debugPrint('[ChatProvider] 💾 Memory: ${enriched.length} | Hive: ${latest100.length}');
  }

  Future<Map<String, PaketModel>> _batchFetchPaket(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final list = await PaketService().getAll(idList: ids);
      return {for (var p in list) p.no_id: p};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, PenawaranModel>> _batchFetchPenawaran(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final list = await PenawaranService().getAll(idList: ids);
      return {for (var p in list) p.noId: p};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, PesananModel>> _batchFetchPesanan(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final result = <String, PesananModel>{};
      await Future.wait(ids.map((id) async {
        try {
          final list = await PesananService().getAll(noBukti: id, status: 'aktif');
          if (list.isNotEmpty) result[id] = list.first;
        } catch (_) {}
      }));
      return result;
    } catch (e) {
      return {};
    }
  }

  Future<PaketModel?> _loadPaketModel(String? idPaket) async {
    if (idPaket == null || idPaket.isEmpty) return null;
    try {
      return await PaketService().getPaketById(noId: idPaket);
    } catch (_) {
      return null;
    }
  }

  Future<PenawaranModel?> _loadPenawaranModel(String? noPenawaran) async {
    if (noPenawaran == null || noPenawaran.isEmpty) return null;
    try {
      final list = await PenawaranService().getAll(noId: noPenawaran);
      return list.isNotEmpty ? list.first : null;
    } catch (_) {
      return null;
    }
  }

  Future<PesananModel?> _loadPesananModel(String? noInvoice) async {
    if (noInvoice == null || noInvoice.isEmpty) return null;
    try {
      final list = await PesananService().getAll(noBukti: noInvoice);
      return list.isNotEmpty ? list.first : null;
    } catch (_) {
      return null;
    }
  }

  bool loadMoreDisplayedMessages(String roomId) {
    if (!_allMessagesInMemory.containsKey(roomId)) return false;
    final all = _allMessagesInMemory[roomId]!;
    final current = _displayedCount[roomId] ?? _initialDisplayCount;
    if (current >= all.length) return false;

    _displayedCount[roomId] =
        (current + _loadMoreIncrement).clamp(0, all.length);
    _notifyMessagesUpdate(roomId);
    return true;
  }

  int getTotalMessagesCount(String roomId) =>
      _allMessagesInMemory[roomId]?.length ?? 0;
  int getDisplayedMessagesCount(String roomId) =>
      _displayedCount[roomId] ?? _initialDisplayCount;
  bool hasMoreToDisplay(String roomId) =>
      getDisplayedMessagesCount(roomId) < getTotalMessagesCount(roomId);

  void _resetDisplayCount(String roomId) {
    _displayedCount[roomId] = _initialDisplayCount;
  }

  // =========================================
  // SEND MESSAGE
  // =========================================

  Future<bool> sendMessage({
    required String roomId,
    required String message,
    String? idPaket,
    String? noPenawaran,
    required List<String> userIds,
  }) async {
    if (_currentUserId == null) return false;
    if (message.trim().isEmpty && idPaket == null && noPenawaran == null) {
      return false;
    }

    final localId =
        'local-${DateTime.now().millisecondsSinceEpoch}-${_currentUserId!.hashCode}';
    final now = DateTime.now();

    String jenisPesan = 'text';
    if (idPaket?.isNotEmpty == true) jenisPesan = 'paket';
    else if (noPenawaran?.isNotEmpty == true) jenisPesan = 'penawaran';

    final localMessage = ChatModel(
      messageId: localId,
      roomId: roomId,
      senderId: _currentUserId!,
      tipeUser: _userType ?? 'customer',
      message: message,
      jenisPesan: jenisPesan,
      idPaket: idPaket,
      noPenawaran: noPenawaran,
      status: 'aktif',
      sendStatus: 'pending',
      roomType: 'direct',
      sentAt: now,
      userIds: userIds,
      receiverIds: [],
      localId: localId,
      noInvoice: null,
      editedAt: null,
      receivedAt: null,
      readAt: null,
    );

    final paket = await _loadPaketModel(idPaket);
    final penawaran = await _loadPenawaranModel(noPenawaran);
    final localEntity =
        ChatMessageEntity.fromChatModel(localMessage, paket: paket, penawaran: penawaran);

    _addToPendingTracking(roomId, localId);
    await _repository.addMessage(localEntity);
    _addToInMemory(roomId, localEntity);

    await _repository.updateRoomWithMessage(
      roomId: roomId,
      lastMessage: message.isEmpty ? '📦 Paket ditawarkan' : message,
      lastMessageAt: now,
      incrementUnread: false,
    );

    _notifyMessagesUpdate(roomId);
    notifyListeners();

    try {
      final result =
          await _apiService.sendMessage(message: localMessage.copyWith(sendStatus: 'sent'));

      if (result != null) {
        await _repository.updateMessageStatus(
          roomId: roomId,
          messageId: localId,
          newStatus: 'sent',
        );
        _updateInMemoryMessage(roomId, localEntity.copyWith(sendStatus: 'sent'));
        _notifyMessagesUpdate(roomId);
        notifyListeners();
        return true;
      } else {
        await _handleSendFailure(roomId, localId, localEntity);
        return false;
      }
    } catch (e) {
      debugPrint('[ChatProvider] ❌ Send error: $e');
      await _handleSendFailure(roomId, localId, localEntity);
      return false;
    }
  }

  Future<void> _handleSendFailure(
    String roomId,
    String localId,
    ChatMessageEntity localEntity,
  ) async {
    await _repository.updateMessageStatus(
      roomId: roomId,
      messageId: localId,
      newStatus: 'failed',
    );
    _updateInMemoryMessage(roomId, localEntity.copyWith(sendStatus: 'failed'));
    _removeFromPendingTracking(roomId, localId);
    _notifyMessagesUpdate(roomId);
    notifyListeners();
  }

  void _addToPendingTracking(String roomId, String localId) {
    _pendingLocalMessages.putIfAbsent(roomId, () => {}).add(localId);
  }

  void _removeFromPendingTracking(String roomId, String localId) {
    _pendingLocalMessages[roomId]?.remove(localId);
    if (_pendingLocalMessages[roomId]?.isEmpty ?? false) {
      _pendingLocalMessages.remove(roomId);
    }
  }

  // =========================================
  // MESSAGE STATUS & ACTIONS
  // =========================================

  Future<void> markRoomAsRead(String roomId) async {
    if (_currentUserId == null) return;

    debugPrint('[ChatProvider] 📖 Mark as read: $roomId');

    final messages = await _repository.getMessages(roomId);
    final unreadIds = messages
        .where((m) => m.senderId != _currentUserId && m.sendStatus != 'read')
        .map((m) => m.messageId)
        .toList();

    await _repository.clearRoomUnread(roomId);
    await _repository.clearRoomReceivedList(roomId);
    await _repository.markAllMessagesAsRead(
      roomId: roomId,
      currentUserId: _currentUserId!,
    );

    if (_allMessagesInMemory.containsKey(roomId)) {
      _allMessagesInMemory[roomId] = _allMessagesInMemory[roomId]!.map((msg) {
        if (msg.senderId != _currentUserId && msg.sendStatus != 'read') {
          return msg.copyWith(sendStatus: 'read');
        }
        return msg;
      }).toList();
    }

    for (final id in unreadIds) {
      _apiService
          .updateMessageStatus(messageId: id, status: 'read')
          .catchError((_) {});
    }

    _notifyMessagesUpdate(roomId);
    notifyListeners();
  }

  Future<bool> retryMessage(String roomId, String localId) async {
    final messages = await _repository.getMessagesAsModels(roomId);
    final failed = messages.where((m) => m.localId == localId).toList();
    if (failed.isEmpty) return false;

    final msg = failed.first;
    await _repository.deleteMessage(roomId, localId);
    _removeFromInMemory(roomId, localId);
    _removeFromPendingTracking(roomId, localId);

    return sendMessage(
      roomId: roomId,
      message: msg.message,
      idPaket: msg.idPaket,
      noPenawaran: msg.noPenawaran,
      userIds: msg.userIds,
    );
  }

  Future<void> removeFailedMessage(String roomId, String localId) async {
    await _repository.deleteMessage(roomId, localId);
    _removeFromInMemory(roomId, localId);
    _removeFromPendingTracking(roomId, localId);
    _notifyMessagesUpdate(roomId);
    notifyListeners();
  }

  Future<bool> updatePenawaranToPesanan({
    required ChatModel message,
    required String pesananId,
  }) async {
    try {
      if (pesananId.isEmpty) return false;

      final result = await _apiService.update(message.copyWith(noInvoice: pesananId));
      if (result.isEmpty) return false;

      final pesanan = await _loadPesananModel(pesananId);
      final current =
          await _repository.getMessage(message.roomId, message.messageId);
      if (current == null) return false;

      final updated = current.copyWith(
        pesanan: pesanan,
        paket: current.paket,
        penawaran: current.penawaran,
      );

      await _repository.addMessage(updated);

      final idx = _allMessagesInMemory[message.roomId]
          ?.indexWhere((m) => m.messageId == message.messageId) ?? -1;
      if (idx != -1) _allMessagesInMemory[message.roomId]![idx] = updated;

      await _repository.updateRoomWithMessage(
        roomId: message.roomId,
        lastMessage: _buildLastMessage(message),
        lastMessageAt: message.sentAt,
        incrementUnread: false,
      );

      _notifyMessagesUpdate(message.roomId);
      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrint('[ChatProvider] ❌ updatePenawaranToPesanan: $e\n$st');
      return false;
    }
  }

  // =========================================
  // ACTIVE ROOM
  // =========================================

  void setActiveRoom(String? roomId) {
    if (_activeRoomId != roomId) {
      _activeRoomId = roomId;
      if (roomId != null && roomId.isNotEmpty) markRoomAsRead(roomId);
      notifyListeners();
    }
  }

  bool isRoomActive(String roomId) => _activeRoomId == roomId;

  // =========================================
  // IN-MEMORY SYNC HELPERS
  // =========================================

  void _addToInMemory(String roomId, ChatMessageEntity entity) {
    final list = _allMessagesInMemory.putIfAbsent(roomId, () => []);
    final idx = list.indexWhere((m) => m.messageId == entity.messageId);
    if (idx >= 0) {
      list[idx] = entity;
    } else {
      list.add(entity);
      list.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    }
  }

  void _updateInMemoryMessage(String roomId, ChatMessageEntity entity) {
    if (!_allMessagesInMemory.containsKey(roomId)) {
      _allMessagesInMemory[roomId] = [entity];
      return;
    }
    final list = _allMessagesInMemory[roomId]!;
    final idx = list.indexWhere((m) => m.messageId == entity.messageId);
    if (idx >= 0) {
      list[idx] = entity;
    } else {
      list.add(entity);
      list.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    }
  }

  void _removeFromInMemory(String roomId, String messageId) {
    _allMessagesInMemory[roomId]?.removeWhere((m) => m.messageId == messageId);
  }

  // =========================================
  // UTILITIES
  // =========================================

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  String _buildLastMessage(ChatModel message) {
    if (message.message.isNotEmpty) return message.message;
    if (message.noInvoice?.isNotEmpty == true) return '🧾 Vendor mengirim pesanan';
    if (message.noPenawaran?.isNotEmpty == true) return '💰 Penawaran baru';
    return '📦 Paket ditawarkan';
  }

  @override
  void dispose() {
    for (final controller in _messagesStreamControllers.values) {
      controller.close();
    }
    _messagesStreamControllers.clear();
    _roomInfoCache.clear();
    _allMessagesInMemory.clear();
    _trackedRooms.clear();
    _pendingLocalMessages.clear();
    super.dispose();
  }
}