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

  // ✅ NEW: Track pending local messages for better echo detection
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

    // ✅ PHASE 1: Emit from Hive IMMEDIATELY
    final hiveMessages = await _repository.getMessages(roomId);

    if (!_displayedCount.containsKey(roomId)) {
      _displayedCount[roomId] = _initialDisplayCount;
    }

    debugPrint(
        '[ChatProvider] ⚡ INSTANT emit from Hive: ${hiveMessages.length} messages');
    yield hiveMessages;

    // ✅ PHASE 2: Check in-memory data
    if (_allMessagesInMemory.containsKey(roomId)) {
      final displayLimited = getMessagesForDisplay(roomId);
      debugPrint(
          '[ChatProvider] 💾 Emit from memory: ${displayLimited.length} messages');
      yield displayLimited;
    }

    // ✅ PHASE 3: Listen to future updates
    if (!_messagesStreamControllers.containsKey(roomId)) {
      _messagesStreamControllers[roomId] =
          StreamController<List<ChatMessageEntity>>.broadcast();
      debugPrint('[ChatProvider] 🎛️ Stream controller created for: $roomId');
    }

    yield* _messagesStreamControllers[roomId]!.stream.asyncMap((_) {
      return getMessagesForDisplay(roomId);
    });
  }

  void _notifyMessagesUpdate(String roomId) {
    if (_messagesStreamControllers.containsKey(roomId) &&
        !_messagesStreamControllers[roomId]!.isClosed) {
      final displayLimited = getMessagesForDisplay(roomId);
      _messagesStreamControllers[roomId]!.add(displayLimited);
      debugPrint('[ChatProvider] 🔔 Notified stream update for $roomId');
    }
  }

  List<ChatMessageEntity> getMessagesForDisplay(String roomId) {
    if (!_allMessagesInMemory.containsKey(roomId)) {
      return [];
    }

    final allMessages = _allMessagesInMemory[roomId]!;
    final displayCount = _displayedCount[roomId] ?? _initialDisplayCount;

    if (allMessages.length <= displayCount) {
      return allMessages;
    }

    return allMessages.sublist(allMessages.length - displayCount);
  }

  List<RoomChatModel> get rooms {
    return _repository.getRooms().map((e) => e.toRoomChatModel()).toList();
  }

  RoomChatModel? getRoom(String roomId) => _repository.getRoomModel(roomId);
  int get totalUnreadCount => _repository.getTotalUnreadCount();

  List<ChatMessageEntity> getAllMessagesInMemory(String roomId) {
    return _allMessagesInMemory[roomId] ?? [];
  }

  String getSenderName(String roomId, String senderId) {
    final room = _roomInfoCache[roomId] ?? getRoom(roomId);
    if (room != null) {
      return room.usernameLawan ?? 'Unknown User';
    }
    return 'New Message';
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

    debugPrint('[ChatProvider] ═══════════════════════════════════════');
    debugPrint('[ChatProvider] 🚀 INITIALIZING (Instant Hive Mode)');
    debugPrint('[ChatProvider] ═══════════════════════════════════════');
    debugPrint('[ChatProvider] 👤 User: $userId ($userType)');

    _currentUserId = userId;
    _userType = userType;

    try {
      await _repository.init();

      _isInitialized = true;
      _error = null;

      debugPrint('[ChatProvider] ✅ Initialized (instant mode)');
      notifyListeners();

      _backgroundLoadRooms();
      _backgroundRecalculateUnread(userId);

      debugPrint('[ChatProvider] ═══════════════════════════════════════');
      return true;
    } catch (e, st) {
      debugPrint('[ChatProvider] ❌ Init error: $e');
      debugPrint('[ChatProvider] Stack: $st');

      _error = e.toString();
      _isInitialized = false;
      notifyListeners();

      return false;
    }
  }

  void _backgroundLoadRooms() {
    debugPrint('[ChatProvider] 🔄 Background: Loading rooms from API...');

    loadRooms(forceRefresh: true, silent: true).then((rooms) {
      debugPrint('[ChatProvider] ✅ Background: Loaded ${rooms.length} rooms');
    }).catchError((e) {
      debugPrint('[ChatProvider] ⚠️ Background: Failed to load rooms: $e');
    });
  }

  void _backgroundRecalculateUnread(String userId) {
    debugPrint('[ChatProvider] 🔄 Background: Recalculating unread...');

    _repository.recalculateAllUnreadCounts(userId).then((_) {
      debugPrint('[ChatProvider] ✅ Background: Unread recalculated');
      notifyListeners();
    }).catchError((e) {
      debugPrint('[ChatProvider] ⚠️ Background: Failed to recalculate: $e');
    });
  }

  // =========================================
  // FCM INTEGRATION - IMPROVED
  // =========================================

  /// ✅ IMPROVED: Main FCM message handler with better routing
  Future<void> handleMessageFromFCM(ChatModel message) async {
    debugPrint('[ChatProvider] ═══════════════════════════════════════');
    debugPrint('[ChatProvider] 📨 MESSAGE FROM FCM');
    debugPrint('[ChatProvider] ═══════════════════════════════════════');
    debugPrint('[ChatProvider] 📦 Room: ${message.roomId}');
    debugPrint('[ChatProvider] 📝 Message ID: ${message.messageId}');
    debugPrint('[ChatProvider] 🏷️  Local ID: ${message.localId}');
    debugPrint('[ChatProvider] 👤 Sender: ${message.senderId}');
    debugPrint('[ChatProvider] 🔖 Status: ${message.sendStatus}');
    debugPrint('[ChatProvider] 📍 Current User: $_currentUserId');
    debugPrint('[ChatProvider] ═══════════════════════════════════════');

    final isFromMe = message.senderId == _currentUserId;
    final isActiveRoom = _activeRoomId == message.roomId;

    debugPrint('[ChatProvider] 📊 Context:');
    debugPrint('[ChatProvider]   From me: $isFromMe');
    debugPrint('[ChatProvider]   Active room: $isActiveRoom');

    // ✅ CRITICAL FIX: Better message routing
    // Own message = sent by me (pending/sent status changes)
    // Other message = sent by partner (received/read status changes)

    if (isFromMe) {
      // ═══════════════════════════════════════════════════════════
      // OWN MESSAGE: Handle echo from server (pending → sent)
      // Only for messages that WE sent
      // ═══════════════════════════════════════════════════════════

      // ✅ Check: Is this truly our echo?
      // Our echo should have status 'sent' OR have localId
      final isLikelyOurEcho = message.sendStatus == 'sent' ||
          message.sendStatus == 'pending' ||
          (message.localId != null && message.localId!.isNotEmpty);

      if (isLikelyOurEcho) {
        debugPrint('[ChatProvider] ✅ Confirmed own message (echo from server)');
        await _handleOwnMessageFromFCM(message);
      } else {
        // ⚠️ Edge case: Message dari kita tapi status sudah read/received
        // Ini berarti partner sudah baca/terima pesan kita
        // Treat as status update, bukan echo
        debugPrint(
            '[ChatProvider] ⚠️ Own message with status update: ${message.sendStatus}');
        await _handleOwnMessageStatusUpdate(message);
      }
    } else {
      // ═══════════════════════════════════════════════════════════
      // MESSAGE FROM OTHERS
      // ═══════════════════════════════════════════════════════════
      await _handleMessageFromOthers(message, isActiveRoom);
    }

    debugPrint('[ChatProvider] ═══════════════════════════════════════');
  }

  /// ✅ IMPROVED: Handle own message (echo from server)
  Future<void> _handleOwnMessageFromFCM(ChatModel message) async {
    debugPrint('[ChatProvider] ═══════════════════════════════════════');
    debugPrint('[ChatProvider] 📤 HANDLING OWN MESSAGE FROM FCM (ECHO)');
    debugPrint('[ChatProvider] ═══════════════════════════════════════');
    debugPrint('[ChatProvider] Message ID: ${message.messageId}');
    debugPrint('[ChatProvider] Local ID: ${message.localId}');
    debugPrint('[ChatProvider] Status: ${message.sendStatus}');

    // Load nested data
    final paket = await _loadPaketModel(message.idPaket);
    final penawaran = await _loadPenawaranModel(message.noPenawaran);
    final pesanan = await _loadPesananModel(message.noInvoice);

    final serverEntity = ChatMessageEntity.fromChatModel(
      message.copyWith(sendStatus: 'sent'),
      paket: paket,
      penawaran: penawaran,
      pesanan: pesanan,
    );

    // ═══════════════════════════════════════════════════════════
    // STEP 1: Check if server message already exists
    // ═══════════════════════════════════════════════════════════
    final alreadyExists = await _repository.messageExists(
      message.roomId,
      message.messageId,
    );

    if (alreadyExists) {
      debugPrint('[ChatProvider] ℹ️ Server message already exists');
      await _updateExistingServerMessage(
          message, serverEntity, paket, penawaran, pesanan);
      return;
    }

    // ═══════════════════════════════════════════════════════════
    // STEP 2: Try to find and replace local echo
    // ═══════════════════════════════════════════════════════════
    debugPrint('[ChatProvider] 🔍 Looking for local echo...');

    final localEchoFound = await _findAndReplaceLocalEcho(
      message: message,
      serverEntity: serverEntity,
    );

    if (localEchoFound) {
      debugPrint('[ChatProvider] ✅ Local echo replaced successfully');
      _removeFromPendingTracking(message.roomId, message.messageId);
      _removeFromPendingTracking(message.roomId, message.localId ?? '');
    } else {
      debugPrint('[ChatProvider] ⚠️ No local echo found, adding as new');
      await _repository.addMessage(serverEntity);
      _addToInMemory(message.roomId, serverEntity);
      debugPrint(
          '[ChatProvider] ✅ Added server message (sent from another device)');
    }

    // Update room
    await _repository.updateRoomWithMessage(
      roomId: message.roomId,
      lastMessage: _buildLastMessage(message),
      lastMessageAt: message.sentAt,
      incrementUnread: false,
    );

    // ✅ Notify stream update
    _notifyMessagesUpdate(message.roomId);
    notifyListeners();

    debugPrint('[ChatProvider] ═══════════════════════════════════════');
  }

  /// ✅ IMPROVED: Handle status update AND content update untuk own message
  Future<void> _handleOwnMessageStatusUpdate(ChatModel message) async {
    debugPrint('[ChatProvider] ═══════════════════════════════════════');
    debugPrint('[ChatProvider] 🔄 HANDLING OWN MESSAGE STATUS/CONTENT UPDATE');
    debugPrint('[ChatProvider] ═══════════════════════════════════════');
    debugPrint('[ChatProvider] Message ID: ${message.messageId}');
    debugPrint('[ChatProvider] New Status: ${message.sendStatus}');
    debugPrint('[ChatProvider] Invoice: ${message.noInvoice}');
    debugPrint('[ChatProvider] Penawaran: ${message.noPenawaran}');
    debugPrint('[ChatProvider] Paket: ${message.idPaket}');

    // Check if message exists
    final exists = await _repository.messageExists(
      message.roomId,
      message.messageId,
    );

    if (!exists) {
      debugPrint('[ChatProvider] ⚠️ Message not found, ignoring update');
      return;
    }

    final existing = await _repository.getMessage(
      message.roomId,
      message.messageId,
    );

    if (existing == null) return;

    // ✅ CRITICAL: Check what changed
    final statusChanged = existing.sendStatus != message.sendStatus;
    final invoiceChanged = (existing.pesanan == null &&
        message.noInvoice != null &&
        message.noInvoice!.isNotEmpty);
    final penawaranChanged = (existing.penawaran == null &&
        message.noPenawaran != null &&
        message.noPenawaran!.isNotEmpty);
    final paketChanged = (existing.paket == null &&
        message.idPaket != null &&
        message.idPaket!.isNotEmpty);

    debugPrint('[ChatProvider] 📊 Changes detected:');
    debugPrint('[ChatProvider]   Status: $statusChanged');
    debugPrint('[ChatProvider]   Invoice: $invoiceChanged');
    debugPrint('[ChatProvider]   Penawaran: $penawaranChanged');
    debugPrint('[ChatProvider]   Paket: $paketChanged');

    // ✅ Check if ANY update is needed
    if (statusChanged || invoiceChanged || penawaranChanged || paketChanged) {
      // ✅ Load nested data if needed
      PaketModel? paket = existing.paket;
      PenawaranModel? penawaran = existing.penawaran;
      PesananModel? pesanan = existing.pesanan;

      if (paketChanged) {
        debugPrint('[ChatProvider] 📦 Loading paket data...');
        paket = await _loadPaketModel(message.idPaket);
      }

      if (penawaranChanged) {
        debugPrint('[ChatProvider] 💼 Loading penawaran data...');
        penawaran = await _loadPenawaranModel(message.noPenawaran);
      }

      if (invoiceChanged) {
        debugPrint('[ChatProvider] 🧾 Loading pesanan data...');
        pesanan = await _loadPesananModel(message.noInvoice);
      }

      // ✅ Determine new status
      String finalStatus = message.sendStatus;
      DateTime? readAt = existing.readAt;
      DateTime? receivedAt = existing.receivedAt;

      if (statusChanged) {
        debugPrint(
            '[ChatProvider] 🔄 Status change: ${existing.sendStatus} → ${message.sendStatus}');

        if (message.sendStatus == 'read') {
          readAt = DateTime.now();
          receivedAt = receivedAt ?? DateTime.now();
        } else if (message.sendStatus == 'received') {
          receivedAt = DateTime.now();
        }
      }

      // ✅ Update in Hive with smart update
      await _repository.smartUpdateMessage(
        roomId: message.roomId,
        messageId: message.messageId,
        newStatus: finalStatus,
        paket: paket,
        penawaran: penawaran,
        pesanan: pesanan,
      );

      // ✅ Update in Memory (CRITICAL!)
      final updatedEntity = existing.copyWith(
        sendStatus: finalStatus,
        readAt: readAt,
        receivedAt: receivedAt,
        paket: paket,
        penawaran: penawaran,
        pesanan: pesanan,
      );
      _updateInMemoryMessage(message.roomId, updatedEntity);

      debugPrint('[ChatProvider] ✅ Message updated successfully');

      if (statusChanged) {
        debugPrint(
            '[ChatProvider]   ✅ Status: ${existing.sendStatus} → $finalStatus');
      }
      if (invoiceChanged) {
        debugPrint(
            '[ChatProvider]   ✅ Invoice: ${existing.pesanan?.noBukti} → ${pesanan?.noBukti}');
      }
      if (penawaranChanged) {
        debugPrint(
            '[ChatProvider]   ✅ Penawaran: ${existing.penawaran?.noId} → ${penawaran?.noId}');
      }
      if (paketChanged) {
        debugPrint(
            '[ChatProvider]   ✅ Paket: ${existing.paket?.no_id} → ${paket?.no_id}');
      }

      // ✅ Update room if invoice added (important for last message)
      if (invoiceChanged) {
        await _repository.updateRoomWithMessage(
          roomId: message.roomId,
          lastMessage: _buildLastMessage(message),
          lastMessageAt: message.sentAt,
          incrementUnread: false,
        );
      }

      // ✅ Notify stream update
      _notifyMessagesUpdate(message.roomId);
    } else {
      debugPrint('[ChatProvider] ⏭️ No changes detected, skipping update');
    }

    notifyListeners();
    debugPrint('[ChatProvider] ═══════════════════════════════════════');
  }

  /// ✅ NEW: Update existing server message
  Future<void> _updateExistingServerMessage(
    ChatModel message,
    ChatMessageEntity serverEntity,
    PaketModel? paket,
    PenawaranModel? penawaran,
    PesananModel? pesanan,
  ) async {
    final existing = await _repository.getMessage(
      message.roomId,
      message.messageId,
    );

    if (existing != null) {
      final needsUpdate = (existing.paket == null && paket != null) ||
          (existing.penawaran == null && penawaran != null) ||
          (existing.pesanan == null && pesanan != null) ||
          (existing.sendStatus != 'sent');

      if (needsUpdate) {
        debugPrint('[ChatProvider] 🔄 Updating existing server message...');

        await _repository.smartUpdateMessage(
          roomId: message.roomId,
          messageId: message.messageId,
          newStatus: 'sent',
          paket: paket,
          penawaran: penawaran,
          pesanan: pesanan,
        );

        _updateInMemoryMessage(message.roomId, serverEntity);
        debugPrint('[ChatProvider] ✅ Updated existing message');

        // ✅ Notify stream update
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

  /// ✅ IMPROVED: Better local echo detection (4 strategies)
  Future<bool> _findAndReplaceLocalEcho({
    required ChatModel message,
    required ChatMessageEntity serverEntity,
  }) async {
    final allMessages = await _repository.getMessages(message.roomId);

    debugPrint('[ChatProvider] 🔍 Finding local echo...');
    debugPrint('[ChatProvider]   Server ID: ${message.messageId}');
    debugPrint('[ChatProvider]   Local ID: ${message.localId}');
    debugPrint('[ChatProvider]   Total local messages: ${allMessages.length}');

    // STRATEGY 1: Match by localId
    if (message.localId != null && message.localId!.isNotEmpty) {
      debugPrint('[ChatProvider] 🎯 Strategy 1: Trying localId match...');

      final localMsg = allMessages.firstWhere(
        (m) => m.localId == message.localId || m.messageId == message.localId,
        orElse: () => allMessages.first, // dummy
      );

      if (localMsg.messageId != allMessages.first.messageId ||
          localMsg.localId == message.localId) {
        debugPrint('[ChatProvider] ✅ Found by localId: ${message.localId}');
        await _replaceMessage(localMsg.messageId, serverEntity);
        return true;
      }
    }

    // STRATEGY 2: Match by "local-" prefix
    debugPrint('[ChatProvider] 🎯 Strategy 2: Trying local- prefix match...');

    for (final msg in allMessages) {
      if (msg.messageId.startsWith('local-') &&
          msg.senderId == message.senderId &&
          msg.message == message.message &&
          (msg.sendStatus == 'pending' || msg.sendStatus == 'sent')) {
        debugPrint('[ChatProvider] ✅ Found by local- prefix');
        debugPrint('[ChatProvider]   Local messageId: ${msg.messageId}');
        await _replaceMessage(msg.messageId, serverEntity);
        return true;
      }
    }

    // STRATEGY 3: Match by content + time
    debugPrint('[ChatProvider] 🎯 Strategy 3: Trying content+time match...');

    for (final msg in allMessages) {
      if (msg.senderId != message.senderId) continue;
      if (msg.sendStatus != 'pending' && msg.sendStatus != 'sent') continue;

      final contentMatch = msg.message == message.message &&
          msg.paket?.no_id == message.idPaket &&
          msg.penawaran?.noId == message.noPenawaran;

      if (!contentMatch) continue;

      final timeDiff = msg.sentAt.difference(message.sentAt).inSeconds.abs();
      if (timeDiff > 60) continue;

      debugPrint('[ChatProvider] ✅ Found by content+time match');
      debugPrint('[ChatProvider]   Time diff: ${timeDiff}s');
      await _replaceMessage(msg.messageId, serverEntity);
      return true;
    }

    // STRATEGY 4: Check pending tracking
    if (_pendingLocalMessages.containsKey(message.roomId)) {
      final pending = _pendingLocalMessages[message.roomId]!;

      if (message.localId != null && pending.contains(message.localId)) {
        debugPrint('[ChatProvider] 🎯 Strategy 4: Found in pending tracking');

        final localMsg = allMessages.firstWhere(
          (m) => m.messageId == message.localId || m.localId == message.localId,
          orElse: () => allMessages.first,
        );

        if (localMsg.messageId != allMessages.first.messageId) {
          debugPrint('[ChatProvider] ✅ Found via pending tracking');
          await _replaceMessage(localMsg.messageId, serverEntity);
          return true;
        }
      }
    }

    debugPrint('[ChatProvider] ❌ No local echo found with any strategy');
    return false;
  }

  /// ✅ Helper: Replace message
  Future<void> _replaceMessage(
    String oldMessageId,
    ChatMessageEntity newMessage,
  ) async {
    debugPrint('[ChatProvider] 🔄 Replacing message...');
    debugPrint('[ChatProvider]   Old ID: $oldMessageId');
    debugPrint('[ChatProvider]   New ID: ${newMessage.messageId}');

    await _repository.deleteMessage(newMessage.roomId, oldMessageId);
    _removeFromInMemory(newMessage.roomId, oldMessageId);

    await _repository.addMessage(newMessage);
    _addToInMemory(newMessage.roomId, newMessage);

    // ✅ Notify stream update
    _notifyMessagesUpdate(newMessage.roomId);

    debugPrint('[ChatProvider] ✅ Message replaced successfully');
  }

  /// ✅ CRITICAL FIX: Handle incoming messages with PROPER status flow
  Future<void> _handleMessageFromOthers(
    ChatModel message,
    bool isActiveRoom,
  ) async {
    debugPrint('[ChatProvider] ═══════════════════════════════════════');
    debugPrint('[ChatProvider] 📥 HANDLING MESSAGE FROM OTHERS');
    debugPrint('[ChatProvider] ═══════════════════════════════════════');
    debugPrint('[ChatProvider] Message ID: ${message.messageId}');
    debugPrint('[ChatProvider] Active Room: $isActiveRoom');
    debugPrint('[ChatProvider] Incoming Status: ${message.sendStatus}');

    // Load nested data
    final paket = await _loadPaketModel(message.idPaket);
    final penawaran = await _loadPenawaranModel(message.noPenawaran);
    final pesanan = await _loadPesananModel(message.noInvoice);

    final exists = await _repository.messageExists(
      message.roomId,
      message.messageId,
    );

    String finalStatus;
    bool shouldIncrementUnread;
    bool shouldAddToReceivedList = false;

    if (exists) {
      // ═══════════════════════════════════════════════════════════
      // Message exists - update if needed
      // ═══════════════════════════════════════════════════════════
      debugPrint('[ChatProvider] ♻️ Message exists, checking for updates...');

      final existing = await _repository.getMessage(
        message.roomId,
        message.messageId,
      );

      if (existing == null) return;

      final needsUpdate = (existing.paket == null && paket != null) ||
          (existing.penawaran == null && penawaran != null) ||
          (existing.pesanan == null && pesanan != null) ||
          (existing.sendStatus != message.sendStatus);

      if (needsUpdate) {
        // ✅ CRITICAL: Determine correct final status
        if (isActiveRoom) {
          // Room is active - mark as read
          finalStatus = 'read';
          shouldIncrementUnread = false;
          shouldAddToReceivedList = false;

          debugPrint('[ChatProvider] 📖 Active room → marking as READ');

          await _repository.clearRoomUnread(message.roomId);
          await _repository.markAllMessagesAsRead(
            roomId: message.roomId,
            currentUserId: _currentUserId!,
          );
        } else {
          // Room is NOT active
          if (message.sendStatus == 'sent') {
            // New message - mark as received
            finalStatus = 'received';
            shouldIncrementUnread = false;
            shouldAddToReceivedList = existing.sendStatus != 'received';

            debugPrint(
                '[ChatProvider] 📬 Inactive room + sent → marking as RECEIVED');
          } else {
            // Keep status from FCM
            finalStatus = message.sendStatus;
            shouldIncrementUnread = false;
            shouldAddToReceivedList = false;

            debugPrint('[ChatProvider] ⏩ Keeping FCM status: $finalStatus');
          }
        }

        // ✅ Update in Hive
        await _repository.smartUpdateMessage(
          roomId: message.roomId,
          messageId: message.messageId,
          newStatus: finalStatus,
          paket: paket,
          penawaran: penawaran,
          pesanan: pesanan,
        );

        // ✅ Update in Memory
        final updatedEntity = ChatMessageEntity.fromChatModel(
          message.copyWith(sendStatus: finalStatus),
          paket: paket,
          penawaran: penawaran,
          pesanan: pesanan,
        );
        _updateInMemoryMessage(message.roomId, updatedEntity);

        debugPrint('[ChatProvider] ✅ Updated message');
        debugPrint('[ChatProvider]   Final status: $finalStatus');
      } else {
        // No major update needed, but check if we need to mark as read
        if (isActiveRoom && existing.sendStatus != 'read') {
          finalStatus = 'read';
          shouldIncrementUnread = false;
          shouldAddToReceivedList = false;

          debugPrint('[ChatProvider] 📖 Active room → updating to READ');

          await _repository.updateMessageStatus(
            roomId: message.roomId,
            messageId: message.messageId,
            newStatus: finalStatus,
          );

          final updatedEntity = existing.copyWith(sendStatus: 'read');
          _updateInMemoryMessage(message.roomId, updatedEntity);
        } else {
          finalStatus = existing.sendStatus;
          shouldIncrementUnread = false;
          shouldAddToReceivedList = false;

          debugPrint('[ChatProvider] ⏭️ No status change needed');
        }
      }
    } else {
      // ═══════════════════════════════════════════════════════════
      // New message from partner
      // ═══════════════════════════════════════════════════════════
      debugPrint('[ChatProvider] 🆕 New incoming message');

      if (isActiveRoom) {
        // Room is active - save as read
        finalStatus = 'read';
        shouldIncrementUnread = false;
        shouldAddToReceivedList = false;

        debugPrint('[ChatProvider] 📖 Active room → saving as READ');

        final entity = ChatMessageEntity.fromChatModel(
          message.copyWith(sendStatus: 'read'),
          paket: paket,
          penawaran: penawaran,
          pesanan: pesanan,
        );

        await _repository.addMessage(entity);
        await _repository.clearRoomUnread(message.roomId);
        _addToInMemory(message.roomId, entity);

        debugPrint('[ChatProvider] ✅ Saved as read');
      } else {
        // Room is NOT active - save as received
        finalStatus = 'received';
        shouldIncrementUnread = true;
        shouldAddToReceivedList = true;

        debugPrint('[ChatProvider] 📬 Inactive room → saving as RECEIVED');

        final entity = ChatMessageEntity.fromChatModel(
          message.copyWith(sendStatus: 'received'),
          paket: paket,
          penawaran: penawaran,
          pesanan: pesanan,
        );

        await _repository.addMessage(entity);
        _addToInMemory(message.roomId, entity);

        debugPrint('[ChatProvider] ✅ Saved as received');
      }

      // Trigger callback for new messages
      if (!isActiveRoom) {
        onNewMessageFromOther?.call(message);
      }
    }

    // Update room
    await _repository.updateRoomWithMessage(
      roomId: message.roomId,
      lastMessage: _buildLastMessage(message),
      lastMessageAt: message.sentAt,
      incrementUnread: shouldIncrementUnread,
      addToReceivedList: shouldAddToReceivedList,
      messageId: message.messageId,
    );

    // ✅ CRITICAL: Sync status to API if we changed it
    if (message.sendStatus != finalStatus) {
      debugPrint(
          '[ChatProvider] 🔄 Syncing status to API: ${message.sendStatus} → $finalStatus');

      _apiService
          .updateMessageStatus(
        messageId: message.messageId,
        status: finalStatus,
      )
          .then((_) {
        debugPrint('[ChatProvider] ✅ Status synced to API: $finalStatus');
      }).catchError((e) {
        debugPrint('[ChatProvider] ⚠️ Failed to sync status to API: $e');
      });
    }

    // Recalculate unread
    await _repository.recalculateUnreadForRoom(
      message.roomId,
      _currentUserId!,
    );

    // ✅ Notify stream update
    _notifyMessagesUpdate(message.roomId);
    notifyListeners();

    debugPrint('[ChatProvider] ═══════════════════════════════════════');
  }

  // =========================================
  // ROOM MANAGEMENT
  // =========================================

  Future<void> trackRoom(String roomId) async {
    debugPrint('[ChatProvider] ═══════════════════════════════════════');
    debugPrint('[ChatProvider] 📍 TRACKING ROOM: $roomId');
    debugPrint('[ChatProvider] ═══════════════════════════════════════');

    if (_trackedRooms.contains(roomId)) {
      debugPrint('[ChatProvider] ℹ️ Already tracking');
      return;
    }

    _trackedRooms.add(roomId);
    debugPrint('[ChatProvider] ✅ Room tracked');

    final hiveMessages = await _repository.getMessages(roomId);
    if (hiveMessages.isNotEmpty) {
      _allMessagesInMemory[roomId] = hiveMessages;
      debugPrint(
          '[ChatProvider] ⚡ Loaded ${hiveMessages.length} from Hive (instant)');
    }

    loadMessages(roomId, silent: true);

    debugPrint('[ChatProvider] ═══════════════════════════════════════');
  }

  void untrackRoom(String roomId) {
    debugPrint('[ChatProvider] 👋 Untracking room: $roomId');
    _trackedRooms.remove(roomId);
    _pendingLocalMessages.remove(roomId);
  }

  Future<List<RoomChatModel>> loadRooms({
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    if (_currentUserId == null) return [];

    if (!silent) {
      _setLoading(true);
    }

    try {
      final roomModels = await _apiService.fetchRooms(userId: _currentUserId!);
      await _repository.setRoomsFromModels(roomModels);

      for (final room in roomModels) {
        _roomInfoCache[room.roomId] = room;
      }

      await _repository.recalculateAllUnreadCounts(_currentUserId!);

      debugPrint('[ChatProvider] ✅ Loaded ${roomModels.length} rooms');

      if (!silent) {
        notifyListeners();
      }

      return roomModels;
    } catch (e) {
      debugPrint('[ChatProvider] ❌ loadRooms error: $e');
      return rooms;
    } finally {
      if (!silent) {
        _setLoading(false);
      }
    }
  }

  Future<RoomChatModel?> findOrCreateRoom(String partnerId) async {
    if (_currentUserId == null) return null;

    final allRooms = _repository.getRooms();
    final cached = allRooms
        .where((r) =>
            r.idLawan == partnerId ||
            r.getPartnerId(_currentUserId!) == partnerId)
        .toList();

    if (cached.isNotEmpty) {
      final roomModel = cached.first.toRoomChatModel();
      _roomInfoCache[roomModel.roomId] = roomModel;
      return roomModel;
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

    if (!silent) {
      _setLoading(true);
    }

    try {
      debugPrint('[ChatProvider] 📡 Loading ALL messages for: $roomId');

      final lastTimestamp = forceRefresh
          ? null
          : await _repository.getLastMessageTimestamp(roomId);

      final messageModels = await _apiService.fetchMessages(
        roomId: roomId,
        since: lastTimestamp,
      );

      debugPrint('[ChatProvider] 📥 Fetched ${messageModels.length} messages');

      if (messageModels.isNotEmpty) {
        await _enrichAndSaveToDualStorage(roomId, messageModels);
        _resetDisplayCount(roomId);

        // ✅ Notify stream update
        _notifyMessagesUpdate(roomId);
      }

      await _repository.recalculateUnreadForRoom(roomId, _currentUserId!);
      await markRoomAsRead(roomId);
      await _repository.saveLastSync(roomId, DateTime.now());

      return await _repository.getMessagesAsModels(roomId);
    } catch (e) {
      debugPrint('[ChatProvider] ❌ loadMessages error: $e');
      return await _repository.getMessagesAsModels(roomId);
    } finally {
      if (!silent) {
        _setLoading(false);
      }
    }
  }

  Future<void> _enrichAndSaveToDualStorage(
    String roomId,
    List<ChatModel> messages,
  ) async {
    debugPrint('[ChatProvider] 💾 Saving to dual storage...');

    final paketIds = messages
        .where((m) => m.idPaket != null && m.idPaket!.isNotEmpty)
        .map((m) => m.idPaket!)
        .toSet()
        .toList();

    final penawaranIds = messages
        .where((m) => m.noPenawaran != null && m.noPenawaran!.isNotEmpty)
        .map((m) => m.noPenawaran!)
        .toSet()
        .toList();

    final pesananIds = messages
        .where((m) => m.noInvoice != null && m.noInvoice!.isNotEmpty)
        .map((m) => m.noInvoice!)
        .toSet()
        .toList();

    final paketMap = await _batchFetchPaket(paketIds);
    final penawaranMap = await _batchFetchPenawaran(penawaranIds);
    final pesananMap = await _batchFetchPesanan(pesananIds);

    List<ChatMessageEntity> enrichedEntities = [];

    for (final message in messages) {
      final paket = paketMap[message.idPaket];
      final penawaran = penawaranMap[message.noPenawaran];
      final pesanan = pesananMap[message.noInvoice];

      final entity = ChatMessageEntity.fromChatModel(
        message,
        paket: paket,
        penawaran: penawaran,
        pesanan: pesanan,
      );

      enrichedEntities.add(entity);
    }

    enrichedEntities.sort((a, b) => a.sentAt.compareTo(b.sentAt));

    _allMessagesInMemory[roomId] = enrichedEntities;

    final latest100 = enrichedEntities.length > 100
        ? enrichedEntities.sublist(enrichedEntities.length - 100)
        : enrichedEntities;

    await _repository.storeLatest100Messages(roomId, latest100);

    debugPrint('[ChatProvider] 💾 Stored ${enrichedEntities.length} in memory');
    debugPrint('[ChatProvider] 💾 Stored ${latest100.length} in Hive');
  }

  Future<Map<String, PaketModel>> _batchFetchPaket(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final paketService = PaketService();
      final list = await paketService.getAll(idList: ids);
      return {for (var p in list) p.no_id: p};
    } catch (e) {
      debugPrint('[ChatProvider] ❌ Batch fetch paket error: $e');
      return {};
    }
  }

  Future<Map<String, PenawaranModel>> _batchFetchPenawaran(
      List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final penawaranService = PenawaranService();
      final list = await penawaranService.getAll(idList: ids);
      return {for (var p in list) p.noId: p};
    } catch (e) {
      debugPrint('[ChatProvider] ❌ Batch fetch penawaran error: $e');
      return {};
    }
  }

  Future<Map<String, PesananModel>> _batchFetchPesanan(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final pesananService = PesananService();
      final Map<String, PesananModel> result = {};

      final futures = ids.map((id) async {
        try {
          final list =
              await pesananService.getAll(noBukti: id, status: 'aktif');
          if (list.isNotEmpty) {
            result[id] = list.first;
          }
        } catch (e) {
          debugPrint('[ChatProvider] ⚠️ Error fetching pesanan $id: $e');
        }
      });

      await Future.wait(futures);
      return result;
    } catch (e) {
      debugPrint('[ChatProvider] ❌ Batch fetch pesanan error: $e');
      return {};
    }
  }

  Future<PaketModel?> _loadPaketModel(String? idPaket) async {
    if (idPaket == null || idPaket.isEmpty) return null;
    try {
      final paketService = PaketService();
      return await paketService.getPaketById(noId: idPaket);
    } catch (e) {
      debugPrint('[ChatProvider] ❌ Error loading paket: $e');
      return null;
    }
  }

  Future<PenawaranModel?> _loadPenawaranModel(String? noPenawaran) async {
    if (noPenawaran == null || noPenawaran.isEmpty) return null;
    try {
      final penawaranService = PenawaranService();
      final list = await penawaranService.getAll(noId: noPenawaran);
      return list.isNotEmpty ? list.first : null;
    } catch (e) {
      debugPrint('[ChatProvider] ❌ Error loading penawaran: $e');
      return null;
    }
  }

  Future<PesananModel?> _loadPesananModel(String? noInvoice) async {
    if (noInvoice == null || noInvoice.isEmpty) return null;
    try {
      final pesananService = PesananService();
      final list = await pesananService.getAll(noBukti: noInvoice);
      return list.isNotEmpty ? list.first : null;
    } catch (e) {
      debugPrint('[ChatProvider] ❌ Error loading pesanan: $e');
      return null;
    }
  }

  bool loadMoreDisplayedMessages(String roomId) {
    if (!_allMessagesInMemory.containsKey(roomId)) {
      debugPrint('[ChatProvider] ⚠️ No messages in memory for: $roomId');
      return false;
    }

    final allMessages = _allMessagesInMemory[roomId]!;
    final currentDisplayCount = _displayedCount[roomId] ?? _initialDisplayCount;

    if (currentDisplayCount >= allMessages.length) {
      debugPrint('[ChatProvider] ℹ️ All messages already displayed');
      return false;
    }

    final newDisplayCount =
        (currentDisplayCount + _loadMoreIncrement).clamp(0, allMessages.length);

    _displayedCount[roomId] = newDisplayCount;

    debugPrint('[ChatProvider] ✅ Display count increased');
    debugPrint('[ChatProvider]   From: $currentDisplayCount');
    debugPrint('[ChatProvider]   To: $newDisplayCount');

    // ✅ Trigger stream update
    _notifyMessagesUpdate(roomId);

    return true;
  }

  int getTotalMessagesCount(String roomId) {
    return _allMessagesInMemory[roomId]?.length ?? 0;
  }

  int getDisplayedMessagesCount(String roomId) {
    return _displayedCount[roomId] ?? _initialDisplayCount;
  }

  bool hasMoreToDisplay(String roomId) {
    final total = getTotalMessagesCount(roomId);
    final displayed = getDisplayedMessagesCount(roomId);
    return displayed < total;
  }

  void _resetDisplayCount(String roomId) {
    _displayedCount[roomId] = _initialDisplayCount;
  }

  // =========================================
  // SEND MESSAGE - IMPROVED
  // =========================================

  /// ✅ IMPROVED: Send message with proper tracking
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

    debugPrint('[ChatProvider] ═══════════════════════════════════════');
    debugPrint('[ChatProvider] 📤 SENDING MESSAGE');
    debugPrint('[ChatProvider] ═══════════════════════════════════════');
    debugPrint('[ChatProvider] Local ID: $localId');
    debugPrint('[ChatProvider] Room: $roomId');

    String jenisPesan = 'text';
    if (idPaket != null && idPaket.isNotEmpty) {
      jenisPesan = 'paket';
    } else if (noPenawaran != null && noPenawaran.isNotEmpty) {
      jenisPesan = 'penawaran';
    }

    // Create local message
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
      localId: localId, // ✅ CRITICAL
      noInvoice: null,
      editedAt: null,
      receivedAt: null,
      readAt: null,
    );

    final paket = await _loadPaketModel(idPaket);
    final penawaran = await _loadPenawaranModel(noPenawaran);

    final localEntity = ChatMessageEntity.fromChatModel(
      localMessage,
      paket: paket,
      penawaran: penawaran,
    );

    // ✅ Track as pending
    _addToPendingTracking(roomId, localId);

    // Save to storage
    await _repository.addMessage(localEntity);
    _addToInMemory(roomId, localEntity);

    debugPrint('[ChatProvider] ✅ Local message saved (pending)');

    await _repository.updateRoomWithMessage(
      roomId: roomId,
      lastMessage: message.isEmpty ? '📦 Paket ditawarkan' : message,
      lastMessageAt: now,
      incrementUnread: false,
    );

    // ✅ Notify stream update
    _notifyMessagesUpdate(roomId);
    notifyListeners();

    // Send to API
    try {
      debugPrint('[ChatProvider] 🌐 Sending to API...');

      final apiMessage = localMessage.copyWith(sendStatus: 'sent');
      final result = await _apiService.sendMessage(message: apiMessage);

      if (result != null) {
        debugPrint('[ChatProvider] ✅ API success');

        await _repository.updateMessageStatus(
          roomId: roomId,
          messageId: localId,
          newStatus: 'sent',
        );

        _updateInMemoryMessage(
          roomId,
          localEntity.copyWith(sendStatus: 'sent'),
        );

        debugPrint('[ChatProvider] ✅ Local message updated to sent');

        // ✅ Notify stream update
        _notifyMessagesUpdate(roomId);
        notifyListeners();

        return true;
      } else {
        debugPrint('[ChatProvider] ❌ API returned null');
        await _handleSendFailure(roomId, localId, localEntity);
        return false;
      }
    } catch (e) {
      debugPrint('[ChatProvider] ❌ Send error: $e');
      await _handleSendFailure(roomId, localId, localEntity);
      return false;
    } finally {
      debugPrint('[ChatProvider] ═══════════════════════════════════════');
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

    _updateInMemoryMessage(
      roomId,
      localEntity.copyWith(sendStatus: 'failed'),
    );

    _removeFromPendingTracking(roomId, localId);

    // ✅ Notify stream update
    _notifyMessagesUpdate(roomId);
    notifyListeners();
  }

  void _addToPendingTracking(String roomId, String localId) {
    if (!_pendingLocalMessages.containsKey(roomId)) {
      _pendingLocalMessages[roomId] = {};
    }
    _pendingLocalMessages[roomId]!.add(localId);

    debugPrint('[ChatProvider] 📌 Added to pending tracking: $localId');
  }

  void _removeFromPendingTracking(String roomId, String localId) {
    if (_pendingLocalMessages.containsKey(roomId)) {
      _pendingLocalMessages[roomId]!.remove(localId);

      debugPrint('[ChatProvider] 📌 Removed from pending tracking: $localId');

      if (_pendingLocalMessages[roomId]!.isEmpty) {
        _pendingLocalMessages.remove(roomId);
      }
    }
  }

  // =========================================
  // MESSAGE STATUS & ACTIONS
  // =========================================

  /// ✅ CRITICAL: Mark room as read with proper API sync
  Future<void> markRoomAsRead(String roomId) async {
    if (_currentUserId == null) return;

    debugPrint('[ChatProvider] ═══════════════════════════════════════');
    debugPrint('[ChatProvider] 📖 MARKING ROOM AS READ: $roomId');
    debugPrint('[ChatProvider] ═══════════════════════════════════════');

    final messages = await _repository.getMessages(roomId);
    final unreadIds = messages
        .where((m) => m.senderId != _currentUserId && m.sendStatus != 'read')
        .map((m) => m.messageId)
        .toList();

    debugPrint('[ChatProvider] 📊 Unread messages: ${unreadIds.length}');

    await _repository.clearRoomUnread(roomId);
    await _repository.clearRoomReceivedList(roomId);

    await _repository.markAllMessagesAsRead(
      roomId: roomId,
      currentUserId: _currentUserId!,
    );

    // ✅ Update in-memory
    if (_allMessagesInMemory.containsKey(roomId)) {
      final updatedMessages = _allMessagesInMemory[roomId]!.map((msg) {
        if (msg.senderId != _currentUserId && msg.sendStatus != 'read') {
          return msg.copyWith(sendStatus: 'read');
        }
        return msg;
      }).toList();

      _allMessagesInMemory[roomId] = updatedMessages;
      debugPrint('[ChatProvider] ✅ Updated in-memory messages to read');
    }

    // ✅ Sync to API
    if (unreadIds.isNotEmpty) {
      debugPrint(
          '[ChatProvider] 🔄 Syncing ${unreadIds.length} read statuses to API...');

      for (final id in unreadIds) {
        _apiService
            .updateMessageStatus(messageId: id, status: 'read')
            .then((_) {
          debugPrint('[ChatProvider] ✅ Synced read status: $id');
        }).catchError((e) {
          debugPrint(
              '[ChatProvider] ⚠️ Failed to sync read status for $id: $e');
        });
      }
    }

    // ✅ Notify stream update
    _notifyMessagesUpdate(roomId);
    notifyListeners();

    debugPrint('[ChatProvider] ═══════════════════════════════════════');
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

    // ✅ Notify stream update
    _notifyMessagesUpdate(roomId);
    notifyListeners();
  }

  Future<bool> updatePenawaranToPesanan({
    required ChatModel message,
    required String pesananId,
  }) async {
    try {
      if (pesananId.isEmpty) return false;

      final newMessage = message.copyWith(noInvoice: pesananId);
      final result = await _apiService.update(newMessage);

      if (result.isEmpty) return false;

      final pesanan = await _loadPesananModel(pesananId);

      final currentMessage =
          await _repository.getMessage(message.roomId, message.messageId);

      if (currentMessage == null) return false;

      final updatedEntity = currentMessage.copyWith(
        pesanan: pesanan,
        paket: currentMessage.paket,
        penawaran: currentMessage.penawaran,
      );

      await _repository.addMessage(updatedEntity);

      if (_allMessagesInMemory.containsKey(message.roomId)) {
        final messages = _allMessagesInMemory[message.roomId]!;
        final index =
            messages.indexWhere((m) => m.messageId == message.messageId);

        if (index != -1) {
          _allMessagesInMemory[message.roomId]![index] = updatedEntity;
        }
      }

      await _repository.updateRoomWithMessage(
        roomId: message.roomId,
        lastMessage: _buildLastMessage(message),
        lastMessageAt: message.sentAt,
        incrementUnread: false,
      );

      // ✅ Notify stream update
      _notifyMessagesUpdate(message.roomId);
      notifyListeners();

      return true;
    } catch (e, st) {
      debugPrint('[ChatProvider] ❌ Error updating penawaran to pesanan: $e');
      debugPrint('StackTrace: $st');
      return false;
    }
  }

  // =========================================
  // ACTIVE ROOM
  // =========================================

  void setActiveRoom(String? roomId) {
    if (_activeRoomId != roomId) {
      _activeRoomId = roomId;

      if (roomId != null && roomId.isNotEmpty) {
        markRoomAsRead(roomId);
      }

      notifyListeners();
    }
  }

  bool isRoomActive(String roomId) => _activeRoomId == roomId;

  // =========================================
  // IN-MEMORY SYNC HELPERS
  // =========================================

  void _addToInMemory(String roomId, ChatMessageEntity entity) {
    if (!_allMessagesInMemory.containsKey(roomId)) {
      _allMessagesInMemory[roomId] = [];
    }

    final existingIndex = _allMessagesInMemory[roomId]!
        .indexWhere((m) => m.messageId == entity.messageId);

    if (existingIndex >= 0) {
      _allMessagesInMemory[roomId]![existingIndex] = entity;
    } else {
      _allMessagesInMemory[roomId]!.add(entity);
    }

    _allMessagesInMemory[roomId]!.sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }

  void _updateInMemoryMessage(String roomId, ChatMessageEntity entity) {
    if (!_allMessagesInMemory.containsKey(roomId)) {
      _allMessagesInMemory[roomId] = [entity];
      return;
    }

    final index = _allMessagesInMemory[roomId]!
        .indexWhere((m) => m.messageId == entity.messageId);

    if (index >= 0) {
      _allMessagesInMemory[roomId]![index] = entity;
    } else {
      _allMessagesInMemory[roomId]!.add(entity);
      _allMessagesInMemory[roomId]!
          .sort((a, b) => a.sentAt.compareTo(b.sentAt));
    }
  }

  void _removeFromInMemory(String roomId, String messageId) {
    if (_allMessagesInMemory.containsKey(roomId)) {
      _allMessagesInMemory[roomId]!
          .removeWhere((m) => m.messageId == messageId);
    }
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
    if (message.message.isNotEmpty) {
      return message.message;
    }

    if (message.noInvoice?.isNotEmpty == true) {
      return "🧾 Vendor mengirim pesanan";
    }

    if (message.noPenawaran?.isNotEmpty == true) {
      return "💰 Penawaran baru";
    }

    return "📦 Paket ditawarkan";
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
