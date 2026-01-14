import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';
import 'package:mpjnew/src/features/customer/services/chat_service.dart';
import 'package:mpjnew/src/features/customer/view/chat/data/service/chat_api_service.dart';
import 'package:mpjnew/src/features/customer/view/chat/domain/chat_cache_manager.dart';

/// Main provider untuk chat
///
/// Features:
/// - Smart caching dengan delta sync
/// - Real-time updates via SignalR
/// - Optimistic UI (local echo)
/// - Message status tracking
/// - Support customer & vendor
class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final ChatCacheManager _cache = ChatCacheManager();

  // API Service akan di-set saat init
  ChatApiService? _apiService;

  String? _currentUserId;
  String? _userType; // 'customer' atau 'vendor'
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  String? _activeRoomId;

  // Stream subscriptions
  StreamSubscription? _roomsSubscription;
  StreamSubscription? _messagesSubscription;

  // Callbacks untuk external notifications
  Function(ChatModel message)? onNewMessageFromOther;
  Function(String roomId)? onRoomUpdated;
  Function(String roomId)? onOfferDataNeeded;

  ChatProvider() {
    _setupCacheListeners();
  }

  // =========================================
  // GETTERS
  // =========================================

  ChatService get chatService => _chatService;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isConnected => _chatService.isConnected;
  String? get currentUserId => _currentUserId;
  String? get userType => _userType;
  String? get error => _error;
  String? get activeRoomId => _activeRoomId;

  /// Get all rooms (sorted by lastMessageAt)
  List<RoomChatModel> get rooms => _cache.cachedRooms;

  /// Get messages untuk room
  List<ChatModel> getMessages(String roomId) => _cache.getMessages(roomId);

  /// Get message tertentu dalam room
  ChatModel getSinglemessage(String roomId, String messageId) =>
      _cache.getSingleMessage(roomId, messageId);

  /// Get single room
  RoomChatModel? getRoom(String roomId) => _cache.getRoom(roomId);

  /// Get total unread
  int get totalUnreadCount =>
      rooms.fold(0, (sum, room) => sum + (room.unread ?? 0));

  // =========================================
  // SETTERS (untuk kompatibilitas)
  // =========================================

  set rooms(List<RoomChatModel> value) {
    _cache.setRooms(value);
    notifyListeners();
  }

  set isReady(bool value) {
    _isInitialized = value;
    notifyListeners();
  }

  // =========================================
  // INITIALIZATION
  // =========================================

  /// Initialize chat provider
  ///
  /// Panggil ini setelah login berhasil
  Future<bool> init({
    required String userId,
    required String userType,
    required ChatServiceConfig config,
    required ChatApiService apiService,
  }) async {
    if (_isInitialized && _currentUserId == userId) {
      debugPrint('[ChatProvider] Already initialized for $userId');
      return true;
    }

    debugPrint('[ChatProvider] 🚀 Initializing for $userId ($userType)');

    _currentUserId = userId;
    _userType = userType;
    _apiService = apiService;
    _setLoading(true);

    try {
      // Setup SignalR callbacks
      _setupSignalRCallbacks();

      // Connect to SignalR
      final connected = await _chatService.connect(
        config: config,
        userId: userId,
      );

      if (!connected) {
        debugPrint('[ChatProvider] ⚠️ SignalR failed, using polling mode');
      }

      // Load initial rooms
      await loadRooms();

      _isInitialized = true;
      _error = null;

      debugPrint('[ChatProvider] ✅ Initialized');
      return true;
    } catch (e, st) {
      debugPrint('[ChatProvider] ❌ Init error: $e\n$st');
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Initialize dengan ApiClient yang sudah ada
  /// Alternatif method untuk kompatibilitas dengan kode lama
  Future<bool> initWithApiClient({
    required String userId,
    required String userType,
    required String hubUrl,
    required Future<String?> Function() getToken,
  }) async {
    // Buat wrapper untuk apiClient
    _apiService = ChatApiService();

    return init(
      userId: userId,
      userType: userType,
      config: ChatServiceConfig(
        hubUrl: hubUrl,
        role: userType,
        getToken: getToken,
      ),
      apiService: _apiService!,
    );
  }

  /// Disconnect
  Future<void> disconnect() async {
    debugPrint('[ChatProvider] 🔌 Disconnecting...');
    await _chatService.disconnect();
    _cache.clearAll();
    _isInitialized = false;
    _currentUserId = null;
    notifyListeners();
  }

  /// Dispose connection (alias untuk disconnect, kompatibilitas)
  Future<void> disposeConnection() async {
    await disconnect();
  }

  @override
  void dispose() {
    _roomsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _chatService.dispose();
    super.dispose();
  }

  // =========================================
  // SETUP LISTENERS
  // =========================================

  void _setupSignalRCallbacks() {
    // Message received
    _chatService.onMessageReceived = (ChatModel message) {
      _handleIncomingMessage(message);
    };

    // Room created
    _chatService.onRoomCreated = (roomId, roomName, createdAt) {
      _handleRoomCreated(roomId, roomName, createdAt);
    };

    // Reconnected
    _chatService.onReconnected = () {
      // Rejoin rooms yang sudah di-cache
      final roomIds = _cache.cachedRooms.map((r) => r.roomId).toList();
      _chatService.joinRooms(roomIds);
    };

    // Connection changed
    _chatService.onConnectionChanged = (isConnected, error) {
      notifyListeners();
    };
  }

  void _setupCacheListeners() {
    _roomsSubscription = _cache.roomsStream.listen((_) {
      notifyListeners();
    });

    _messagesSubscription = _cache.messagesStream.listen((_) {
      notifyListeners();
    });
  }

  // =========================================
  // ROOMS
  // =========================================

  /// Load rooms dari API
  Future<List<RoomChatModel>> loadRooms({bool forceRefresh = false}) async {
    if (_currentUserId == null || _apiService == null) return [];

    // Check cache
    if (!forceRefresh && _cache.isRoomsCacheValid) {
      debugPrint('[ChatProvider] Using cached rooms');
      return _cache.cachedRooms;
    }

    _setLoading(true);

    try {
      final rooms = await _apiService!.fetchRooms(userId: _currentUserId!);
      _cache.setRooms(rooms);

      // Join all rooms
      final roomIds =
          rooms.map((r) => r.roomId).where((id) => id.isNotEmpty).toList();
      await _chatService.joinRooms(roomIds);

      return rooms;
    } catch (e) {
      debugPrint('[ChatProvider] ❌ loadRooms error: $e');
      return _cache.cachedRooms;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch rooms (alias untuk loadRooms, kompatibilitas)
  Future<List<RoomChatModel>> fetchRooms({
    String? roomId,
    String? idLawan,
  }) async {
    if (_currentUserId == null || _apiService == null) return [];

    _setLoading(true);

    try {
      final rooms = await _apiService!.fetchRooms(
        userId: _currentUserId!,
        roomId: roomId,
        partnerId: idLawan,
      );

      // Jika fetch all (tanpa filter), update cache
      if (roomId == null && idLawan == null) {
        _cache.setRooms(rooms);

        // Join all rooms
        final roomIds =
            rooms.map((r) => r.roomId).where((id) => id.isNotEmpty).toList();
        await _chatService.joinRooms(roomIds);
      }

      return rooms;
    } catch (e) {
      debugPrint('[ChatProvider] ❌ fetchRooms error: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Find atau create room dengan partner
  Future<RoomChatModel?> findOrCreateRoom(String partnerId) async {
    if (_currentUserId == null || _apiService == null) return null;

    // Check cache first
    final cached = _cache.cachedRooms
        .where(
          (r) =>
              r.idLawan == partnerId ||
              r.getPartnerId(_currentUserId!) == partnerId,
        )
        .toList();

    if (cached.isNotEmpty) {
      return cached.first;
    }

    // Fetch dari API
    final rooms = await _apiService!.fetchRooms(
      userId: _currentUserId!,
      partnerId: partnerId,
    );

    if (rooms.isNotEmpty) {
      _cache.updateRoom(rooms.first);
      await _chatService.joinRoom(rooms.first.roomId);
      return rooms.first;
    }

    // Room belum ada, akan dibuat saat send message pertama
    return null;
  }

  /// Refresh rooms (kompatibilitas)
  Future<void> refreshRooms(
      String vendorId, String roomId, String userId) async {
    final rooms = await _apiService?.fetchRooms(
      userId: userId,
      roomId: roomId,
      partnerId: vendorId,
    );

    if (rooms != null && rooms.isNotEmpty) {
      for (final room in rooms) {
        _cache.updateRoom(room);
      }
      notifyListeners();
    }
  }

  /// Update room last message (kompatibilitas)
  void updateRoomLastMessage({
    required String roomId,
    required String lastMessage,
    required DateTime lastMessageAt,
  }) {
    final room = _cache.getRoom(roomId);
    if (room != null) {
      _cache.updateRoom(room.copyWith(
        lastMessage: lastMessage,
        lastMessageAt: lastMessageAt,
      ));
      notifyListeners();
    }
  }

  // =========================================
  // MESSAGES
  // =========================================

  /// Load messages untuk room (dengan smart caching)
  Future<List<ChatModel>> loadMessages(String roomId,
      {bool forceRefresh = false}) async {
    if (_apiService == null) return [];

    // Check cache
    if (!forceRefresh && _cache.isMessagesCacheValid(roomId)) {
      debugPrint('[ChatProvider] Using cached messages for $roomId');
      return _cache.getMessages(roomId);
    }

    _setLoading(true);

    try {
      // Delta sync: hanya fetch yang baru
      final lastTimestamp =
          forceRefresh ? null : _cache.getLastMessageTimestamp(roomId);

      final messages = await _apiService!.fetchMessages(
        roomId: roomId,
        since: lastTimestamp,
      );

      if (lastTimestamp != null && !forceRefresh) {
        _cache.mergeMessages(roomId, messages);
      } else {
        _cache.setMessages(roomId, messages);
      }

      // Join room
      await _chatService.joinRoom(roomId);

      // Mark as read
      await markRoomAsRead(roomId);

      return _cache.getMessages(roomId);
    } catch (e) {
      debugPrint('[ChatProvider] ❌ loadMessages error: $e');
      return _cache.getMessages(roomId);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch messages (alias, kompatibilitas)
  Future<void> fetchMessages(String roomId) async {
    await loadMessages(roomId);
  }

  /// Send message dengan optimistic update
  Future<bool> sendMessage({
    required String roomId,
    required String message,
    String? idPaket,
    String? noPenawaran,
    required List<String> userIds,
  }) async {
    if (_currentUserId == null || _apiService == null) {
      debugPrint('[ChatProvider] ❌ No currentUserId or apiService');
      return false;
    }

    if (message.trim().isEmpty && idPaket == null && noPenawaran == null) {
      debugPrint('[ChatProvider] ❌ Empty message');
      return false;
    }

    final localId = 'local-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    // Determine jenis pesan
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
      sendStatus: 'sending',
      roomType: 'direct',
      sentAt: now,
      userIds: userIds,
      localId: localId,
    );

    debugPrint('[ChatProvider] 📤 Sending (local: $localId)');

    // ✅ OPTIMISTIC UPDATE
    _cache.addLocalEcho(roomId, localMessage);
    _cache.updateRoomWithMessage(roomId, localMessage);
    notifyListeners();

    try {
      // Send to API
      final result = await _apiService!.sendMessage(message: localMessage);

      if (result != null) {
        debugPrint('[ChatProvider] ✅ Sent successfully');
        // Server akan broadcast via SignalR
        // _handleIncomingMessage akan replace local echo
        return true;
      } else {
        // Mark as failed
        _cache.updateMessageStatus(roomId, localId, 'failed');
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('[ChatProvider] ❌ Send error: $e');
      _cache.updateMessageStatus(roomId, localId, 'failed');
      notifyListeners();
      return false;
    }
  }

  /// Retry failed message
  Future<bool> retryMessage(String roomId, String localId) async {
    final messages = _cache.getMessages(roomId);
    final failed = messages.where((m) => m.localId == localId).toList();

    if (failed.isEmpty) return false;

    final msg = failed.first;

    // Remove failed message
    _cache.removeMessage(roomId, localId);

    // Retry send
    return sendMessage(
      roomId: roomId,
      message: msg.message,
      idPaket: msg.idPaket,
      noPenawaran: msg.noPenawaran,
      userIds: msg.userIds,
    );
  }

  /// Delete failed message
  void removeFailedMessage(String roomId, String localId) {
    _cache.removeMessage(roomId, localId);
    notifyListeners();
  }

  // =========================================
  // MESSAGE STATUS
  // =========================================

  /// Mark room as read
  Future<void> markRoomAsRead(String roomId) async {
    if (_currentUserId == null) return;

    // Get unread message IDs
    final messages = _cache.getMessages(roomId);

    final unreadIds = messages
        .where((m) => m.senderId != _currentUserId && m.sendStatus != 'read')
        .map((m) => m.messageId)
        .toList();

    // Update cache immediately
    _cache.clearRoomUnread(roomId);
    _cache.markMessagesAsRead(roomId, _currentUserId!);

    if (unreadIds.isEmpty) return;

    for (final id in unreadIds) {
      await _apiService?.updateMessageStatus(
        messageId: id,
        status: 'read',
      );
    }
  }

  /// Update message status (kompatibilitas)
  Future<bool> updateMessageStatus(String messageId, String status) async {
    return await _apiService?.updateMessageStatus(
          messageId: messageId,
          status: status,
        ) ??
        false;
  }

  // =========================================
  // ROOM MANAGEMENT (kompatibilitas dengan ChatService)
  // =========================================

  Future<void> joinRoom(String roomId) async {
    await _chatService.joinRoom(roomId);
  }

  Future<void> joinMultipleRooms(List<String> roomIds) async {
    await _chatService.joinRooms(roomIds);
  }

  Future<void> leaveRoom(String roomId) async {
    await _chatService.leaveRoom(roomId);
  }

  Future<void> joinUserChannel(String userId) async {
    await _chatService.joinUserChannel(userId);
  }

// =========================================
// ACTIVE ROOM MANAGEMENT
// =========================================

  /// Set active room dengan validasi
  void setActiveRoom(String? roomId) {
    if (_activeRoomId != roomId) {
      _activeRoomId = roomId;
      debugPrint('[ChatProvider] ActiveRoom set => $roomId');

      // Auto mark as read jika ada active room
      if (roomId != null && roomId.isNotEmpty) {
        markRoomAsRead(roomId);
      }

      notifyListeners();
    }
  }

  /// Set active room tanpa trigger mark as read
  void setActiveRoomSilently(String? roomId) {
    if (_activeRoomId != roomId) {
      _activeRoomId = roomId;
      debugPrint('[ChatProvider] ActiveRoom silently set => $roomId');
      // Tidak notifyListeners() agar tidak trigger rebuild
    }
  }

  /// Clear active room
  void clearActiveRoomSilently() {
    if (_activeRoomId != null) {
      debugPrint(
          '[ChatProvider] Clearing active room silently: $_activeRoomId');
      _activeRoomId = null;
    }
  }

  /// Check if room is currently active
  bool isRoomActive(String roomId) {
    return _activeRoomId == roomId;
  }

// =========================================
  // REALTIME HANDLERS - IMPROVED
  // =========================================

  void _handleIncomingMessage(ChatModel message) {
    debugPrint('');
    debugPrint('═══════════════════════════════════════');
    debugPrint('[ChatProvider] 📨 INCOMING MESSAGE');
    debugPrint('═══════════════════════════════════════');
    debugPrint('MessageId: ${message.messageId}');
    debugPrint('RoomId: ${message.roomId}');
    debugPrint('SenderId: ${message.senderId}');
    debugPrint('CurrentUserId: $_currentUserId');
    debugPrint('Message: ${message.message}');
    debugPrint('InitialStatus: ${message.sendStatus}');
    debugPrint('ActiveRoomId: $_activeRoomId');
    debugPrint('═══════════════════════════════════════');

    final isFromMe = message.senderId == _currentUserId;
    final isActiveRoom = _activeRoomId == message.roomId;

    if (isFromMe) {
      // ════════════════════════════════════════════════════════
      // CASE 1: PESAN DARI DIRI SENDIRI (Echo dari server)
      // ════════════════════════════════════════════════════════
      debugPrint('→ [CASE 1] Pesan dari diri sendiri');
      _handleOwnMessage(message);
    } else {
      // ════════════════════════════════════════════════════════
      // CASE 2: PESAN DARI ORANG LAIN
      // ════════════════════════════════════════════════════════
      debugPrint('→ [CASE 2] Pesan dari orang lain');
      _handleMessageFromOthers(message, isActiveRoom);
    }

    // Trigger callback untuk load offer data jika diperlukan
    _checkAndTriggerOfferDataLoad(message);

    notifyListeners();
    debugPrint('═══════════════════════════════════════\n');
  }

  /// Handle pesan dari diri sendiri (echo dari server) - IMPROVED
  void _handleOwnMessage(ChatModel message) {
    debugPrint('  ├─ Handling own message (echo from server)');
    debugPrint('  ├─ MessageId from server: ${message.messageId}');
    debugPrint('  ├─ Status from server: ${message.sendStatus}');

    // ════════════════════════════════════════════════════════
    // STEP 1: Try to replace local echo
    // ════════════════════════════════════════════════════════
    final replaced = _cache.replaceLocalEcho(message.roomId, message);

    if (replaced) {
      debugPrint('  ├─ ✅ Local echo replaced successfully');

      // Update status to 'sent' if still 'sending'
      if (message.sendStatus == 'sending' || message.sendStatus == '') {
        debugPrint('  ├─ 🔄 Updating status to "sent"');
        _cache.updateMessageStatus(message.roomId, message.messageId, 'sent');

        // Update via API
        _apiService?.updateMessageStatus(
          messageId: message.messageId,
          status: 'sent',
        );
      } else {
        debugPrint('  ├─ ℹ️ Status from server: ${message.sendStatus}');
        // Update dengan status dari server
        _cache.updateMessageStatus(
          message.roomId,
          message.messageId,
          message.sendStatus,
        );
      }
    } else {
      // ════════════════════════════════════════════════════════
      // STEP 2: No local echo found - might be from another device
      // ════════════════════════════════════════════════════════
      debugPrint('  ├─ ⚠️ No local echo found');
      debugPrint('  ├─ Checking if message already exists...');

      final existingMessages = _cache.getMessages(message.roomId);
      final exists =
          existingMessages.any((m) => m.messageId == message.messageId);

      if (exists) {
        debugPrint('  ├─ ℹ️ Message already exists in cache');

        // Update status jika berbeda
        final existing = existingMessages.firstWhere(
          (m) => m.messageId == message.messageId,
        );

        if (existing.sendStatus != message.sendStatus) {
          debugPrint(
              '  ├─ 🔄 Updating status: ${existing.sendStatus} → ${message.sendStatus}');
          _cache.updateMessageStatus(
            message.roomId,
            message.messageId,
            message.sendStatus,
          );
        }
      } else {
        debugPrint('  ├─ ➕ Adding message from another device');

        // Tambahkan dengan status 'sent'
        final messageToAdd =
            message.sendStatus == 'sending' || message.sendStatus == ''
                ? message.copyWith(sendStatus: 'sent')
                : message;

        _cache.addMessage(message.roomId, messageToAdd);

        debugPrint(
            '  ├─ ✅ Message added with status: ${messageToAdd.sendStatus}');
      }
    }

    // ════════════════════════════════════════════════════════
    // STEP 3: Update room preview
    // ════════════════════════════════════════════════════════
    _cache.updateRoomWithMessage(message.roomId, message,
        incrementUnread: false);

    debugPrint('  └─ ✅ Own message handled');
  }

  /// Handle pesan dari orang lain - IMPROVED WITH REAL-TIME STATUS UPDATES
  void _handleMessageFromOthers(ChatModel message, bool isActiveRoom) {
    debugPrint('  ├─ Handling message from others');
    debugPrint('  ├─ IsActiveRoom: $isActiveRoom');
    debugPrint('  ├─ MessageId: ${message.messageId}');
    debugPrint('  ├─ Initial status from server: ${message.sendStatus}');

    // ════════════════════════════════════════════════════════
    // STEP 1: Check if message already exists
    // ════════════════════════════════════════════════════════
    final existingMessages = _cache.getMessages(message.roomId);
    final existingIndex = existingMessages.indexWhere(
      (m) => m.messageId == message.messageId,
    );

    if (existingIndex != -1) {
      // Message sudah ada - update status jika berbeda
      final existingMessage = existingMessages[existingIndex];
      debugPrint('  ├─ ℹ️ Message already exists');
      debugPrint('  ├─ Existing status: ${existingMessage.sendStatus}');
      debugPrint('  ├─ New status from server: ${message.sendStatus}');

      // Cek apakah status berubah
      if (existingMessage.sendStatus != message.sendStatus) {
        debugPrint('  ├─ 🔄 Status changed, updating...');

        // Determine final status based on active room
        String finalStatus;
        bool shouldIncrementUnread;

        if (isActiveRoom) {
          // If in active room, mark as read
          finalStatus = 'read';
          shouldIncrementUnread = false;

          // Clear unread
          _cache.clearRoomUnread(message.roomId);
          _cache.markMessagesAsRead(message.roomId, _currentUserId!);

          debugPrint('  ├─ 👁️ In active room → status: "read"');
        } else {
          // If not in active room
          if (message.sendStatus == 'sending' || message.sendStatus == 'sent') {
            finalStatus = 'delivered';
            shouldIncrementUnread = existingMessage.sendStatus != 'delivered' &&
                existingMessage.sendStatus != 'read';
          } else if (message.sendStatus == 'delivered' ||
              message.sendStatus == 'read') {
            finalStatus = message.sendStatus;
            shouldIncrementUnread = existingMessage.sendStatus != 'delivered' &&
                existingMessage.sendStatus != 'read' &&
                message.sendStatus == 'delivered';
          } else {
            finalStatus = 'delivered';
            shouldIncrementUnread = true;
          }

          debugPrint('  ├─ 📱 Not in active room → status: "$finalStatus"');
        }

        // Update message status in cache
        _cache.updateMessageStatus(
            message.roomId, message.messageId, finalStatus);

        // Update room dengan message (increment unread jika perlu)
        if (shouldIncrementUnread) {
          _cache.updateRoomWithMessage(
            message.roomId,
            message.copyWith(sendStatus: finalStatus),
            incrementUnread: true,
          );
        }

        // Update via API jika status berbeda dari server
        if (message.sendStatus != finalStatus) {
          debugPrint(
              '  ├─ 📡 Updating status via API: ${message.sendStatus} → $finalStatus');
          _apiService?.updateMessageStatus(
            messageId: message.messageId,
            status: finalStatus,
          );
        }

        debugPrint(
            '  └─ ✅ Status updated: ${existingMessage.sendStatus} → $finalStatus');
      } else {
        debugPrint('  └─ ℹ️ Status unchanged, no update needed');
      }

      return; // Exit early - message already processed
    }

    // ════════════════════════════════════════════════════════
    // STEP 2: New message - add to cache
    // ════════════════════════════════════════════════════════
    debugPrint('  ├─ ➕ New message, adding to cache');

    String finalStatus;
    bool shouldIncrementUnread;

    if (isActiveRoom) {
      // ═══════════════════════════════════════════════════
      // SUB-CASE: User IN ACTIVE ROOM
      // ═══════════════════════════════════════════════════
      debugPrint('  ├─ 👁️ User is in this room (active)');

      finalStatus = 'read';
      shouldIncrementUnread = false;

      // Add message dengan status 'read'
      _cache.addMessage(message.roomId, message.copyWith(sendStatus: 'read'));

      // Clear unread dan mark as read
      _cache.clearRoomUnread(message.roomId);
      _cache.markMessagesAsRead(message.roomId, _currentUserId!);

      debugPrint('  ├─ ✅ Added with status: "read"');
    } else {
      // ═══════════════════════════════════════════════════
      // SUB-CASE: User NOT IN ACTIVE ROOM
      // ═══════════════════════════════════════════════════
      debugPrint('  ├─ 📱 User is NOT in this room');

      // Determine status
      if (message.sendStatus == 'sending' ||
          message.sendStatus == 'sent' ||
          message.sendStatus == '') {
        finalStatus = 'delivered';
        shouldIncrementUnread = true;
      } else if (message.sendStatus == 'read') {
        finalStatus = 'read';
        shouldIncrementUnread = false;
      } else {
        // Already 'delivered' or other
        finalStatus = message.sendStatus;
        shouldIncrementUnread = message.sendStatus == 'delivered';
      }

      // Add message dengan status yang sudah ditentukan
      _cache.addMessage(
        message.roomId,
        message.copyWith(sendStatus: finalStatus),
      );

      debugPrint('  ├─ ✅ Added with status: "$finalStatus"');

      // Trigger notification callback
      onNewMessageFromOther?.call(message);
    }

    // ════════════════════════════════════════════════════════
    // STEP 3: Update room with message
    // ════════════════════════════════════════════════════════
    _cache.updateRoomWithMessage(
      message.roomId,
      message.copyWith(sendStatus: finalStatus),
      incrementUnread: shouldIncrementUnread,
    );

    // ════════════════════════════════════════════════════════
    // STEP 4: Update via API if status changed
    // ════════════════════════════════════════════════════════
    if (message.sendStatus != finalStatus) {
      debugPrint(
          '  ├─ 📡 Updating status via API: ${message.sendStatus} → $finalStatus');
      _apiService?.updateMessageStatus(
        messageId: message.messageId,
        status: finalStatus,
      );
    }

    debugPrint(
        '  └─ ✅ Message from others handled (final status: $finalStatus, unread: $shouldIncrementUnread)');
  }

  /// Check apakah message membutuhkan load offer data
  void _checkAndTriggerOfferDataLoad(ChatModel message) {
    final needsOfferData =
        message.hasPaket || message.hasPenawaran || message.hasPesanan;

    if (needsOfferData) {
      debugPrint(
          '[ChatProvider] 🔔 Offer data needed for room: ${message.roomId}');
      debugPrint('  - HasPaket: ${message.hasPaket}');
      debugPrint('  - HasPenawaran: ${message.hasPenawaran}');
      debugPrint('  - HasPesanan: ${message.hasPesanan}');

      // Delay kecil untuk memastikan message sudah tersimpan
      Future.delayed(const Duration(milliseconds: 100), () {
        onOfferDataNeeded?.call(message.roomId);
      });
    }
  }

  void _handleRoomCreated(
      String roomId, String roomName, DateTime createdAt) async {
    debugPrint('[ChatProvider] 🆕 Room created: $roomId');

    if (_apiService == null || _currentUserId == null) return;

    // Fetch detail room
    final rooms = await _apiService!.fetchRooms(
      userId: _currentUserId!,
      roomId: roomId,
    );

    if (rooms.isNotEmpty) {
      _cache.updateRoom(rooms.first);
      await _chatService.joinRoom(roomId);
      onRoomUpdated?.call(roomId);
      notifyListeners();
    }
  }

  // =========================================
  // PENAWARAN -> PESANAN
  // =========================================

  /// Update ketika penawaran sudah jadi pesanan
  void updatePenawaranToPesanan(
      String roomId, String noPenawaran, String noPesanan) {
    _cache.updateMessageWithPesanan(roomId, noPenawaran, noPesanan);
    notifyListeners();
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

  /// Force refresh
  Future<void> refresh() async {
    _cache.invalidateRoomsCache();
    await loadRooms(forceRefresh: true);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Debug info
  void printDebug() {
    debugPrint('=== ChatProvider Debug ===');
    debugPrint('UserId: $_currentUserId');
    debugPrint('Type: $_userType');
    debugPrint('Connected: $isConnected');
    debugPrint('Initialized: $_isInitialized');
    _cache.printStats();
  }
}
