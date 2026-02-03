import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/features/customer/services/chat_service.dart';
import 'package:mpjnew/src/data/hive_entity/chat_message_entity.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';
import 'package:mpjnew/src/data/repositories/hive_chat_repository.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/services/penawaran_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/view/chat/data/service/chat_api_service.dart';
import 'package:mpjnew/src/features/customer/viewmodels/paket_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/penawaran_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';

/// ✅ DUAL STORAGE ChatProvider
///
/// Storage Strategy:
/// 1. Hive - Stores latest 100 messages only (persistent, fast access)
/// 2. In-Memory Map - Stores ALL messages from API (volatile, full history)
///
/// Benefits:
/// - Fast initial load from Hive (100 messages)
/// - Full history available in memory for pagination
/// - Hive auto-trims to 100 to save space
class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final HiveChatRepository _repository = HiveChatRepository();

  ChatApiService? _apiService;

  // Provider dependencies
  PaketProvider? paketProvider;
  PenawaranProvider? penawaranProvider;
  PesananProvider? pesananProvider;

  String? _currentUserId;
  String? _userType;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  String? _activeRoomId;

  // ✅ IN-MEMORY STORAGE: Map<roomId, List<ChatMessageEntity>>
  // Stores ALL messages from API in memory
  final Map<String, List<ChatMessageEntity>> _allMessagesInMemory = {};

  // ✅ Room info cache for notifications
  final Map<String, RoomChatModel> _roomInfoCache = {};

  // Callbacks
  Function(ChatModel message)? onNewMessageFromOther;
  Function(String roomId)? onRoomUpdated;
  Function(String roomId)? onOfferDataNeeded;

  ChatProvider() {
    _initRepository();
  }

  Future<void> _initRepository() async {
    try {
      await _repository.init();
    } catch (e) {
      debugPrint('[ChatProvider] ❌ Repository init failed: $e');
    }
  }

  // =========================================
  // DEPENDENCY INJECTION
  // =========================================

  void setProviders({
    PaketProvider? paket,
    PenawaranProvider? penawaran,
    PesananProvider? pesanan,
  }) {
    paketProvider = paket;
    penawaranProvider = penawaran;
    pesananProvider = pesanan;
    debugPrint('[ChatProvider] ✅ Providers set');
  }

  // =========================================
  // GETTERS
  // =========================================

  ChatService get chatService => _chatService;
  HiveChatRepository get repository => _repository;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isConnected => _chatService.isConnected;
  String? get currentUserId => _currentUserId;
  String? get userType => _userType;
  String? get error => _error;
  String? get activeRoomId => _activeRoomId;

  List<RoomChatModel> get rooms {
    return _repository.getRooms().map((e) => e.toRoomChatModel()).toList();
  }

  List<ChatModel> getMessages(String roomId) => [];

  RoomChatModel? getRoom(String roomId) => _repository.getRoomModel(roomId);

  int get totalUnreadCount => _repository.getTotalUnreadCount();

  /// Get ALL messages in memory for a room
  List<ChatMessageEntity> getAllMessagesInMemory(String roomId) {
    return _allMessagesInMemory[roomId] ?? [];
  }

  /// Get sender name for notifications
  String _getSenderName(String roomId) {
    final room = _roomInfoCache[roomId] ?? getRoom(roomId);
    if (room != null) {
      return room.usernameLawan ?? 'Unknown User';
    }
    return 'New Message';
  }

  // =========================================
  // INITIALIZATION
  // =========================================

  Future<bool> init({
    required String userId,
    required String userType,
    required ChatServiceConfig config,
    required ChatApiService apiService,
  }) async {
    debugPrint('[ChatProvider] 🚀 Initializing for $userId ($userType)');

    _currentUserId = userId;
    _userType = userType;
    _apiService = apiService;
    _setLoading(true);

    try {
      await _repository.init();
      _setupSignalRCallbacks();

      final connected = await _chatService.connect(
        config: config,
        userId: userId,
      );

      if (!connected) {
        debugPrint('[ChatProvider] ⚠️ SignalR failed, using polling mode');
      }

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

  Future<bool> initWithApiClient({
    required String userId,
    required String userType,
    required String hubUrl,
    required Future<String?> Function() getToken,
  }) async {
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

  Future<void> disconnect() async {
    debugPrint('[ChatProvider] 🔌 Disconnecting...');
    await _chatService.disconnect();
    _isInitialized = false;
    _currentUserId = null;
    _activeRoomId = null;
    _roomInfoCache.clear();
    _allMessagesInMemory.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _chatService.dispose();
    _roomInfoCache.clear();
    _allMessagesInMemory.clear();
    super.dispose();
  }

  // =========================================
  // SIGNALR CALLBACKS
  // =========================================

  void _setupSignalRCallbacks() {
    _chatService.onMessageReceived = (ChatModel message) {
      _handleIncomingMessage(message);
    };

    _chatService.onRoomCreated = (roomId, roomName, createdAt) {
      _handleRoomCreated(roomId, roomName, createdAt);
    };

    _chatService.onReconnected = () {
      final roomIds = _repository.getRooms().map((r) => r.roomId).toList();
      _chatService.joinRooms(roomIds);
    };

    _chatService.onConnectionChanged = (isConnected, error) {
      notifyListeners();
    };
  }

  // =========================================
  // ROOMS MANAGEMENT
  // =========================================

  Future<List<RoomChatModel>> loadRooms({bool forceRefresh = false}) async {
    if (_currentUserId == null || _apiService == null) return [];

    _setLoading(true);

    try {
      final roomModels = await _apiService!.fetchRooms(userId: _currentUserId!);
      await _repository.setRoomsFromModels(roomModels);

      // ✅ Cache room info for notifications
      for (final room in roomModels) {
        _roomInfoCache[room.roomId] = room;
      }

      final roomIds =
          roomModels.map((r) => r.roomId).where((id) => id.isNotEmpty).toList();
      await _chatService.joinRooms(roomIds);

      return roomModels;
    } catch (e) {
      debugPrint('[ChatProvider] ❌ loadRooms error: $e');
      return rooms;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<RoomChatModel>> fetchRooms(
      {String? roomId, String? idLawan}) async {
    if (_currentUserId == null || _apiService == null) return [];

    _setLoading(true);

    try {
      final roomModels = await _apiService!.fetchRooms(
        userId: _currentUserId!,
        roomId: roomId,
        partnerId: idLawan,
      );

      if (roomId == null && idLawan == null) {
        await _repository.setRoomsFromModels(roomModels);

        for (final room in roomModels) {
          _roomInfoCache[room.roomId] = room;
        }

        final roomIds = roomModels
            .map((r) => r.roomId)
            .where((id) => id.isNotEmpty)
            .toList();
        await _chatService.joinRooms(roomIds);
      } else {
        for (final room in roomModels) {
          await _repository.upsertRoomFromModel(room);
          _roomInfoCache[room.roomId] = room;
        }
      }

      return roomModels;
    } catch (e) {
      debugPrint('[ChatProvider] ❌ fetchRooms error: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<RoomChatModel?> findOrCreateRoom(String partnerId) async {
    if (_currentUserId == null || _apiService == null) return null;

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

    final roomModels = await _apiService!.fetchRooms(
      userId: _currentUserId!,
      partnerId: partnerId,
    );

    if (roomModels.isNotEmpty) {
      await _repository.upsertRoomFromModel(roomModels.first);
      await _chatService.joinRoom(roomModels.first.roomId);
      _roomInfoCache[roomModels.first.roomId] = roomModels.first;
      return roomModels.first;
    }

    return null;
  }

  // =========================================
  // MESSAGES - DUAL STORAGE
  // =========================================

  Future<List<ChatModel>> loadMessages(String roomId,
      {bool forceRefresh = false}) async {
    if (_apiService == null) return [];

    _setLoading(true);

    try {
      debugPrint('[ChatProvider] 📡 Loading messages for room: $roomId');

      final lastTimestamp = forceRefresh
          ? null
          : await _repository.getLastMessageTimestamp(roomId);

      // ✅ Fetch ALL messages from API
      final messageModels = await _apiService!.fetchMessages(
        roomId: roomId,
        since: lastTimestamp,
      );

      debugPrint(
          '[ChatProvider] 📥 Fetched ${messageModels.length} messages from API');

      if (messageModels.isNotEmpty) {
        // ✅ Enrich and save to BOTH storages
        await _enrichAndSaveToDualStorage(roomId, messageModels);
      }

      await _chatService.joinRoom(roomId);
      await markRoomAsRead(roomId);
      await _repository.saveLastSync(roomId, DateTime.now());

      return await _repository.getMessagesAsModels(roomId);
    } catch (e) {
      debugPrint('[ChatProvider] ❌ loadMessages error: $e');
      return await _repository.getMessagesAsModels(roomId);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMessages(String roomId) async {
    await loadMessages(roomId);
  }

  // =========================================
  // ENRICH AND SAVE - DUAL STORAGE
  // =========================================

  Future<void> _enrichAndSaveToDualStorage(
      String roomId, List<ChatModel> messages) async {
    debugPrint('[ChatProvider] 💾 Saving to dual storage...');

    // ✅ Batch fetch all required data
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

    debugPrint('[ChatProvider] 📦 Need to fetch:');
    debugPrint('  - Paket: ${paketIds.length} unique');
    debugPrint('  - Penawaran: ${penawaranIds.length} unique');
    debugPrint('  - Pesanan: ${pesananIds.length} unique');

    final paketMap = await _batchFetchPaket(paketIds);
    final penawaranMap = await _batchFetchPenawaran(penawaranIds);
    final pesananMap = await _batchFetchPesanan(pesananIds);

    // ✅ Convert to entities with enriched data
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

    // ✅ STEP 1: Store ALL in memory (sorted by sentAt)
    enrichedEntities.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    _allMessagesInMemory[roomId] = enrichedEntities;

    debugPrint(
        '[ChatProvider] 🧠 Stored ${enrichedEntities.length} messages in memory');

    // ✅ STEP 2: Store only latest 100 in Hive
    final latest100 = enrichedEntities.length > 100
        ? enrichedEntities.sublist(enrichedEntities.length - 100)
        : enrichedEntities;

    await _repository.storeLatest100Messages(roomId, latest100);

    debugPrint('[ChatProvider] 💾 Stored ${latest100.length} messages in Hive');
    debugPrint('[ChatProvider] ✅ Dual storage complete');
  }

  // =========================================
  // BATCH FETCH DATA
  // =========================================

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

      debugPrint(
          '[ChatProvider] ✅ Fetched ${result.length}/${ids.length} pesanan');
      return result;
    } catch (e) {
      debugPrint('[ChatProvider] ❌ Batch fetch pesanan error: $e');
      return {};
    }
  }

  Future<PaketModel?> _loadPaketModel(String? idPaket) async {
    if (idPaket == null || idPaket.isEmpty) return null;

    try {
      if (paketProvider != null) {
        final cached = paketProvider!.paketList.firstWhere(
          (p) => p.no_id == idPaket && p.status == 'aktif',
          orElse: () => PaketModel(
            no_id: '',
            nama_paket: '',
            harga: 0,
            id_vendor: '',
            status: '',
            rincian: '',
          ),
        );

        if (cached.no_id.isNotEmpty) {
          return cached;
        }
      }

      final paketService = PaketService();
      return await paketService.getPaketById(noId: idPaket);
    } catch (e) {
      debugPrint('[ChatProvider] ❌ Error loading paket $idPaket: $e');
      return null;
    }
  }

  Future<PenawaranModel?> _loadPenawaranModel(String? noPenawaran) async {
    if (noPenawaran == null || noPenawaran.isEmpty) return null;

    try {
      if (penawaranProvider != null) {
        final cached = penawaranProvider!.penawaranList.firstWhere(
          (p) => p.noId == noPenawaran && p.status == 'aktif',
          orElse: () => PenawaranModel(
            noId: '',
            idCustomer: '',
            idVendor: '',
            status: '',
            noTrackingPenawaran: '',
            noPesanan: '',
            namaVendor: '',
            namaCustomer: '',
            idPaket: '',
            namaPaket: '',
            harga: 0,
            lokasi: '',
            kota: '',
            namaKota: '',
            deskripsi: '',
            tglRealisasi: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );

        if (cached.noId.isNotEmpty) {
          return cached;
        }
      }

      final penawaranService = PenawaranService();
      final list = await penawaranService.getAll(noId: noPenawaran);
      return list.isNotEmpty ? list.first : null;
    } catch (e) {
      debugPrint('[ChatProvider] ❌ Error loading penawaran $noPenawaran: $e');
      return null;
    }
  }

  Future<PesananModel?> _loadPesananModel(String? noInvoice) async {
    if (noInvoice == null || noInvoice.isEmpty) return null;

    try {
      if (pesananProvider != null) {
        final allPesanan = [
          ...pesananProvider!.pesananUnpaid,
          ...pesananProvider!.pesananProgress,
          ...pesananProvider!.pesananSelesai,
        ];

        final cached = allPesanan.firstWhere(
          (p) => p.noBukti == noInvoice,
          orElse: () => PesananModel(
            noBukti: '',
            idCustomer: '',
            idVendor: '',
            status: '',
            statusProgresPesanan: '',
            idPaket: '',
            namaPaket: '',
            harga: 0,
            lokasi: '',
            kota: '',
            tglRealisasi: DateTime.now(),
            subtotal: 0,
            grandTotal: 0,
          ),
        );

        if (cached.noBukti.isNotEmpty) {
          return cached;
        }
      }

      final pesananService = PesananService();
      final list = await pesananService.getAll(noBukti: noInvoice);
      return list.isNotEmpty ? list.first : null;
    } catch (e) {
      debugPrint('[ChatProvider] ❌ Error loading pesanan $noInvoice: $e');
      return null;
    }
  }

  // =========================================
  // ✅ SEND MESSAGE - COMPLETE WITH CORRECT FLOW
  // =========================================

  /// Send message with correct status flow:
  /// 1. LOCAL: Create with "pending"
  /// 2. API: Send with "sent"
  /// 3. LOCAL: Update to "sent" if success, "failed" if error
  Future<bool> sendMessage({
    required String roomId,
    required String message,
    String? idPaket,
    String? noPenawaran,
    required List<String> userIds,
  }) async {
    if (_currentUserId == null || _apiService == null) return false;

    if (message.trim().isEmpty && idPaket == null && noPenawaran == null) {
      return false;
    }

    final localId = 'local-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    String jenisPesan = 'text';
    if (idPaket != null && idPaket.isNotEmpty) {
      jenisPesan = 'paket';
    } else if (noPenawaran != null && noPenawaran.isNotEmpty) {
      jenisPesan = 'penawaran';
    }

    // ✅ STEP 1: Create LOCAL message with status "pending"
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
      sendStatus: 'pending', // ✅ LOCAL: pending
      roomType: 'direct',
      sentAt: now,
      userIds: userIds,
      receiverIds: [],
      localId: localId,
      noInvoice: null,
      editedAt: null,
      receivedAt: null, // ✅ Changed from deliveredAt
      readAt: null,
    );

    // ✅ Load nested data
    final paket = await _loadPaketModel(idPaket);
    final penawaran = await _loadPenawaranModel(noPenawaran);

    final localEntity = ChatMessageEntity.fromChatModel(
      localMessage,
      paket: paket,
      penawaran: penawaran,
    );

    // ✅ Add to BOTH storages with "pending" status
    await _repository.addMessage(localEntity);

    // Add to in-memory storage
    if (_allMessagesInMemory.containsKey(roomId)) {
      _allMessagesInMemory[roomId]!.add(localEntity);
      _allMessagesInMemory[roomId]!
          .sort((a, b) => a.sentAt.compareTo(b.sentAt));
    } else {
      _allMessagesInMemory[roomId] = [localEntity];
    }

    // ✅ Update room with message
    await _repository.updateRoomWithMessage(
      roomId: roomId,
      lastMessage: message.isEmpty ? '📦 Paket ditawarkan' : message,
      lastMessageAt: now,
      incrementUnread: false,
    );

    // ✅ STEP 2: Send to API with status "sent"
    try {
      final apiMessage = localMessage.copyWith(
        sendStatus: 'sent', // ✅ API: always "sent"
      );

      debugPrint('[ChatProvider] 📤 Sending to API...');
      debugPrint('[ChatProvider]   Local status: pending');
      debugPrint('[ChatProvider]   API status: sent');

      final result = await _apiService!.sendMessage(message: apiMessage);

      // ✅ STEP 3: Update local status based on API response
      if (result != null) {
        debugPrint('[ChatProvider] ✅ API success (200)');

        // Update to "sent" in local storage
        await _repository.updateMessageStatus(
          roomId: roomId,
          messageId: localId,
          newStatus: 'sent',
        );

        // Update in-memory storage
        if (_allMessagesInMemory.containsKey(roomId)) {
          final index = _allMessagesInMemory[roomId]!
              .indexWhere((m) => m.messageId == localId);
          if (index != -1) {
            _allMessagesInMemory[roomId]![index] =
                _allMessagesInMemory[roomId]![index]
                    .copyWith(sendStatus: 'sent');
          }
        }

        debugPrint('[ChatProvider] ✅ Local status updated: pending → sent');
        return true;
      } else {
        debugPrint('[ChatProvider] ❌ API returned null');

        // Mark as failed
        await _repository.updateMessageStatus(
          roomId: roomId,
          messageId: localId,
          newStatus: 'failed',
        );

        // Update in-memory storage
        if (_allMessagesInMemory.containsKey(roomId)) {
          final index = _allMessagesInMemory[roomId]!
              .indexWhere((m) => m.messageId == localId);
          if (index != -1) {
            _allMessagesInMemory[roomId]![index] =
                _allMessagesInMemory[roomId]![index]
                    .copyWith(sendStatus: 'failed');
          }
        }

        return false;
      }
    } catch (e) {
      debugPrint('[ChatProvider] ❌ API error: $e');

      // Mark as failed
      await _repository.updateMessageStatus(
        roomId: roomId,
        messageId: localId,
        newStatus: 'failed',
      );

      // Update in-memory storage
      if (_allMessagesInMemory.containsKey(roomId)) {
        final index = _allMessagesInMemory[roomId]!
            .indexWhere((m) => m.messageId == localId);
        if (index != -1) {
          _allMessagesInMemory[roomId]![index] =
              _allMessagesInMemory[roomId]![index]
                  .copyWith(sendStatus: 'failed');
        }
      }

      return false;
    }
  }

  Future<bool> retryMessage(String roomId, String localId) async {
    final messages = await _repository.getMessagesAsModels(roomId);
    final failed = messages.where((m) => m.localId == localId).toList();

    if (failed.isEmpty) return false;

    final msg = failed.first;

    // Remove from both storages
    await _repository.deleteMessage(roomId, localId);
    _removeFromInMemory(roomId, localId);

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
  }

  // =========================================
  // MESSAGE STATUS
  // =========================================

  Future<void> markRoomAsRead(String roomId) async {
    if (_currentUserId == null) return;

    final messages = await _repository.getMessages(roomId);
    final unreadIds = messages
        .where((m) => m.senderId != _currentUserId && m.sendStatus != 'read')
        .map((m) => m.messageId)
        .toList();

    await _repository.clearRoomUnread(roomId);
    await _repository.markAllMessagesAsRead(
      roomId: roomId,
      currentUserId: _currentUserId!,
    );

    if (unreadIds.isNotEmpty) {
      for (final id in unreadIds) {
        await _apiService?.updateMessageStatus(messageId: id, status: 'read');
      }
    }
  }

  Future<bool> updateMessageStatus(String messageId, String status) async {
    return await _apiService?.updateMessageStatus(
          messageId: messageId,
          status: status,
        ) ??
        false;
  }

  // =========================================
  // ACTIVE ROOM
  // =========================================

  void setActiveRoom(String? roomId) {
    if (_activeRoomId != roomId) {
      _activeRoomId = roomId;
      _chatService.setActiveRoom(roomId);

      if (roomId != null && roomId.isNotEmpty) {
        markRoomAsRead(roomId);
      }

      notifyListeners();
    }
  }

  void setActiveRoomSilently(String? roomId) {
    if (_activeRoomId != roomId) {
      _activeRoomId = roomId;
      _chatService.setActiveRoom(roomId);
    }
  }

  void clearActiveRoomSilently() {
    if (_activeRoomId != null) {
      _activeRoomId = null;
      _chatService.setActiveRoom(null);
    }
  }

  bool isRoomActive(String roomId) => _activeRoomId == roomId;

  // =========================================
  // ✅ REALTIME HANDLERS - COMPLETE VERSION
  // Combines: Customer's "received" + Vendor's smart update
  // =========================================

  Future<void> _handleIncomingMessage(ChatModel message) async {
    final isFromMe = message.senderId == _currentUserId;
    final isActiveRoom = _activeRoomId == message.roomId;

    debugPrint('[ChatProvider] 📩 Incoming: ${message.messageId}');
    debugPrint('  - From me: $isFromMe');
    debugPrint('  - Active room: $isActiveRoom');
    debugPrint('  - Status: ${message.sendStatus}');

    // ✅ ALWAYS enrich message with latest data
    final paket = await _loadPaketModel(message.idPaket);
    final penawaran = await _loadPenawaranModel(message.noPenawaran);
    final pesanan = await _loadPesananModel(message.noInvoice);

    if (isFromMe) {
      await _handleOwnMessage(message,
          paket: paket, penawaran: penawaran, pesanan: pesanan);
    } else {
      await _handleMessageFromOthers(message, isActiveRoom,
          paket: paket, penawaran: penawaran, pesanan: pesanan);
    }
  }

  /// Handle messages sent by current user (local echo replacement)
  Future<void> _handleOwnMessage(
    ChatModel message, {
    PaketModel? paket,
    PenawaranModel? penawaran,
    PesananModel? pesanan,
  }) async {
    debugPrint('[ChatProvider] 📤 Handling own message: ${message.messageId}');

    // Try to replace local echo
    final replaced = await _repository.replaceLocalEcho(
      roomId: message.roomId,
      serverMessage: ChatMessageEntity.fromChatModel(
        message,
        paket: paket,
        penawaran: penawaran,
        pesanan: pesanan,
      ),
    );

    if (replaced) {
      debugPrint('[ChatProvider] ✅ Replaced local echo with server message');

      // ✅ Ensure status is "sent" for own messages from server
      if (message.sendStatus != 'sent') {
        await _repository.updateMessageStatus(
          roomId: message.roomId,
          messageId: message.messageId,
          newStatus: 'sent',
        );
      }

      // ✅ Update in-memory storage
      final updatedEntity = ChatMessageEntity.fromChatModel(
        message.copyWith(sendStatus: 'sent'),
        paket: paket,
        penawaran: penawaran,
        pesanan: pesanan,
      );
      _updateInMemoryMessage(message.roomId, updatedEntity);
    } else {
      // Message doesn't exist as local echo, check if it exists at all
      final exists =
          await _repository.messageExists(message.roomId, message.messageId);

      if (!exists) {
        debugPrint(
            '[ChatProvider] 🆕 New message from server (not local echo)');

        // New message from server, add it
        final messageToAdd = message.copyWith(sendStatus: 'sent');

        final entity = ChatMessageEntity.fromChatModel(
          messageToAdd,
          paket: paket,
          penawaran: penawaran,
          pesanan: pesanan,
        );

        await _repository.addMessage(entity);

        // ✅ Add to in-memory
        _addToInMemory(message.roomId, entity);
      } else {
        debugPrint('[ChatProvider] 🔄 Message exists, updating status');

        // Message exists, just update status if needed
        await _repository.updateMessageStatus(
          roomId: message.roomId,
          messageId: message.messageId,
          newStatus:
              message.sendStatus == 'pending' ? 'sent' : message.sendStatus,
        );

        // ✅ Update in-memory
        final updatedEntity = ChatMessageEntity.fromChatModel(
          message.copyWith(
              sendStatus: message.sendStatus == 'pending'
                  ? 'sent'
                  : message.sendStatus),
          paket: paket,
          penawaran: penawaran,
          pesanan: pesanan,
        );
        _updateInMemoryMessage(message.roomId, updatedEntity);
      }
    }

    // Update room
    await _repository.updateRoomWithMessage(
      roomId: message.roomId,
      lastMessage: _buildLastMessage(message),
      lastMessageAt: message.sentAt,
      incrementUnread: false,
    );
  }

  /// ✅ COMPLETE: Handle messages from others
  /// Combines:
  /// - Customer's "received" terminology
  /// - Vendor's smart update (check for nested data changes)
  Future<void> _handleMessageFromOthers(
    ChatModel message,
    bool isActiveRoom, {
    PaketModel? paket,
    PenawaranModel? penawaran,
    PesananModel? pesanan,
  }) async {
    debugPrint(
        '[ChatProvider] 📥 Handling message from others: ${message.messageId}');

    final exists =
        await _repository.messageExists(message.roomId, message.messageId);

    String finalStatus;
    bool shouldIncrementUnread;

    if (exists) {
      debugPrint('[ChatProvider] ♻️ Message exists, checking for updates...');

      // ✅ VENDOR FEATURE: Get existing message to compare
      final existing = await _repository.getMessage(
        message.roomId,
        message.messageId,
      );

      // ✅ VENDOR FEATURE: Check if nested data needs update
      final needsUpdate = existing != null &&
          (existing.paket == null && paket != null ||
              existing.penawaran == null && penawaran != null ||
              existing.pesanan == null && pesanan != null ||
              existing.sendStatus != message.sendStatus);

      if (needsUpdate) {
        debugPrint(
            '[ChatProvider] 🔄 Updating existing message with new data...');

        if (isActiveRoom) {
          finalStatus = 'read';
          shouldIncrementUnread = false;

          await _repository.clearRoomUnread(message.roomId);
          await _repository.markAllMessagesAsRead(
            roomId: message.roomId,
            currentUserId: _currentUserId!,
          );
        } else {
          // ✅ CUSTOMER FEATURE: "received" instead of "delivered"
          finalStatus = message.sendStatus == 'sent'
              ? 'received' // ✅ Changed from "delivered"
              : message.sendStatus;
          shouldIncrementUnread = false;
        }

        // ✅ VENDOR FEATURE: Smart update with new data (if available)
        if (_repository.smartUpdateMessage != null) {
          await _repository.smartUpdateMessage(
            roomId: message.roomId,
            messageId: message.messageId,
            newStatus: finalStatus,
            paket: paket,
            penawaran: penawaran,
            pesanan: pesanan,
          );
        } else {
          // Fallback to manual update
          await _repository.updateMessageStatus(
            roomId: message.roomId,
            messageId: message.messageId,
            newStatus: finalStatus,
          );
        }

        // ✅ CUSTOMER FEATURE: Update in-memory
        final updatedEntity = ChatMessageEntity.fromChatModel(
          message.copyWith(sendStatus: finalStatus),
          paket: paket,
          penawaran: penawaran,
          pesanan: pesanan,
        );
        _updateInMemoryMessage(message.roomId, updatedEntity);
      } else {
        debugPrint('[ChatProvider] ⏭️ No update needed');

        if (isActiveRoom) {
          finalStatus = 'read';
          shouldIncrementUnread = false;

          await _repository.updateMessageStatus(
            roomId: message.roomId,
            messageId: message.messageId,
            newStatus: finalStatus,
          );
        } else {
          // ✅ CUSTOMER FEATURE: "received"
          finalStatus = message.sendStatus == 'sent'
              ? 'received' // ✅ Changed from "delivered"
              : message.sendStatus;
          shouldIncrementUnread = false;
        }

        // ✅ Update in-memory even if no Hive update
        if (_allMessagesInMemory.containsKey(message.roomId)) {
          final index = _allMessagesInMemory[message.roomId]!
              .indexWhere((m) => m.messageId == message.messageId);
          if (index != -1) {
            _allMessagesInMemory[message.roomId]![index] =
                _allMessagesInMemory[message.roomId]![index]
                    .copyWith(sendStatus: finalStatus);
          }
        }
      }
    } else {
      debugPrint('[ChatProvider] 🆕 New incoming message');

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

        // ✅ CUSTOMER FEATURE: Add to in-memory
        _addToInMemory(message.roomId, entity);
      } else {
        // ✅ CUSTOMER FEATURE: "received" instead of "delivered"
        finalStatus = 'received'; // ✅ Changed from "delivered"
        shouldIncrementUnread = true;

        final entity = ChatMessageEntity.fromChatModel(
          message.copyWith(sendStatus: 'received'), // ✅ Changed
          paket: paket,
          penawaran: penawaran,
          pesanan: pesanan,
        );

        await _repository.addMessage(entity);

        // ✅ CUSTOMER FEATURE: Add to in-memory
        _addToInMemory(message.roomId, entity);
      }

      await _repository.updateRoomWithMessage(
        roomId: message.roomId,
        lastMessage: _buildLastMessage(message),
        lastMessageAt: message.sentAt,
        incrementUnread: shouldIncrementUnread,
      );

      if (!isActiveRoom) {
        onNewMessageFromOther?.call(message);
      }
    }

    // ✅ Sync status to API if status changed
    if (message.sendStatus != finalStatus) {
      debugPrint(
          '[ChatProvider] 🔄 Syncing status to API: ${message.sendStatus} → $finalStatus');
      _apiService?.updateMessageStatus(
        messageId: message.messageId,
        status: finalStatus,
      );
    }
  }

  Future<void> _handleRoomCreated(
      String roomId, String roomName, DateTime createdAt) async {
    if (_apiService == null || _currentUserId == null) return;

    debugPrint('[ChatProvider] 🆕 Room created: $roomId');

    final roomModels = await _apiService!.fetchRooms(
      userId: _currentUserId!,
      roomId: roomId,
    );

    if (roomModels.isNotEmpty) {
      await _repository.upsertRoomFromModel(roomModels.first);
      _roomInfoCache[roomModels.first.roomId] = roomModels.first;
      await _chatService.joinRoom(roomId);
      onRoomUpdated?.call(roomId);
    }
  }

  // =========================================
  // ✅ IN-MEMORY SYNC HELPERS
  // These methods keep in-memory storage in sync with Hive
  // =========================================

  /// Add or update message in in-memory storage
  void _addToInMemory(String roomId, ChatMessageEntity entity) {
    if (!_allMessagesInMemory.containsKey(roomId)) {
      _allMessagesInMemory[roomId] = [];
    }

    // Check if already exists
    final existingIndex = _allMessagesInMemory[roomId]!
        .indexWhere((m) => m.messageId == entity.messageId);

    if (existingIndex >= 0) {
      // Replace existing
      _allMessagesInMemory[roomId]![existingIndex] = entity;
      debugPrint('[ChatProvider] 🔄 Updated in-memory: ${entity.messageId}');
    } else {
      // Add new
      _allMessagesInMemory[roomId]!.add(entity);
      debugPrint('[ChatProvider] ➕ Added to in-memory: ${entity.messageId}');
    }

    // Keep sorted
    _allMessagesInMemory[roomId]!.sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }

  /// Update existing message in in-memory storage
  void _updateInMemoryMessage(String roomId, ChatMessageEntity entity) {
    if (!_allMessagesInMemory.containsKey(roomId)) {
      _allMessagesInMemory[roomId] = [entity];
      return;
    }

    final index = _allMessagesInMemory[roomId]!
        .indexWhere((m) => m.messageId == entity.messageId);

    if (index >= 0) {
      _allMessagesInMemory[roomId]![index] = entity;
      debugPrint('[ChatProvider] 🔄 Updated in-memory: ${entity.messageId}');
    } else {
      _allMessagesInMemory[roomId]!.add(entity);
      _allMessagesInMemory[roomId]!
          .sort((a, b) => a.sentAt.compareTo(b.sentAt));
      debugPrint('[ChatProvider] ➕ Added to in-memory: ${entity.messageId}');
    }
  }

  /// Remove message from in-memory storage
  void _removeFromInMemory(String roomId, String messageId) {
    if (_allMessagesInMemory.containsKey(roomId)) {
      _allMessagesInMemory[roomId]!
          .removeWhere((m) => m.messageId == messageId);
      debugPrint('[ChatProvider] 🗑️ Removed from in-memory: $messageId');
    }
  }

  // =========================================
  // SPECIAL UPDATES
  // =========================================

  /// Update penawaran to pesanan (Customer only - untuk menerima pesanan)
  /// Vendor provider tidak perlu method ini karena vendor yang create offer
  Future<bool> updatePenawaranToPesanan({
    required ChatModel message,
    required String pesananId,
  }) async {
    try {
      if (pesananId.isEmpty) {
        debugPrint('[ChatProvider] ❌ Pesanan ID kosong');
        return false;
      }

      if (_apiService == null) {
        debugPrint('[ChatProvider] ❌ API Service tidak tersedia');
        return false;
      }

      debugPrint('[ChatProvider] 🔄 Updating penawaran to pesanan...');
      debugPrint('  Room ID: ${message.roomId}');
      debugPrint('  Message ID: ${message.messageId}');
      debugPrint('  Pesanan ID: $pesananId');

      // Step 1: Update via API
      final newMessage = message.copyWith(noInvoice: pesananId);
      final result = await _apiService!.update(newMessage);

      if (result.isEmpty) {
        debugPrint('[ChatProvider] ⚠️ API returned empty result');
        return false;
      }

      debugPrint('[ChatProvider] ✅ API update successful');

      // Step 2: Load pesanan data
      final pesanan = await _loadPesananModel(pesananId);

      if (pesanan == null) {
        debugPrint('[ChatProvider] ⚠️ Pesanan not found: $pesananId');
      }

      // Step 3: Get current message from Hive to preserve existing data
      final currentMessage =
          await _repository.getMessage(message.roomId, message.messageId);

      if (currentMessage == null) {
        debugPrint('[ChatProvider] ⚠️ Current message not found in Hive');
        return false;
      }

      // Step 4: Create updated entity with all data preserved
      final updatedEntity = currentMessage.copyWith(
        pesanan: pesanan,
        paket: currentMessage.paket,
        penawaran: currentMessage.penawaran,
      );

      // Step 5: Update in Hive (using upsert pattern)
      await _repository.addMessage(updatedEntity);

      debugPrint('[ChatProvider] ✅ Hive message updated');

      // Step 6: Update in-memory storage
      if (_allMessagesInMemory.containsKey(message.roomId)) {
        final messages = _allMessagesInMemory[message.roomId]!;
        final index =
            messages.indexWhere((m) => m.messageId == message.messageId);

        if (index != -1) {
          _allMessagesInMemory[message.roomId]![index] = updatedEntity;
          debugPrint('[ChatProvider] ✅ In-memory message updated');
        } else {
          debugPrint('[ChatProvider] ⚠️ Message not found in memory');
        }
      }

      // Step 7: Update room last message
      await _repository.updateRoomWithMessage(
        roomId: message.roomId,
        lastMessage: _buildLastMessage(message),
        lastMessageAt: message.sentAt,
        incrementUnread: false,
      );

      // Step 8: Notify listeners
      notifyListeners();

      debugPrint('[ChatProvider] ✅ Update complete');
      return true;
    } catch (e, stackTrace) {
      debugPrint('[ChatProvider] ❌ Error updating penawaran to pesanan: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
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

  Future<void> refresh() async {
    await loadRooms(forceRefresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void printDebug() {
    debugPrint('=== ChatProvider Debug ===');
    debugPrint('UserId: $_currentUserId');
    debugPrint('Type: $_userType');
    debugPrint('Connected: $isConnected');
    debugPrint('Initialized: $_isInitialized');
    debugPrint('Active Room: $_activeRoomId');
    debugPrint('Cached Rooms: ${_roomInfoCache.length}');
    debugPrint('In-Memory Messages:');
    _allMessagesInMemory.forEach((roomId, messages) {
      debugPrint('  $roomId: ${messages.length} messages');
    });
    _repository.printStats();
  }

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

  Future<void> refreshRooms(
      String vendorId, String roomId, String userId) async {
    final roomModels = await _apiService?.fetchRooms(
      userId: userId,
      roomId: roomId,
      partnerId: vendorId,
    );

    if (roomModels != null && roomModels.isNotEmpty) {
      for (final room in roomModels) {
        await _repository.upsertRoomFromModel(room);
        _roomInfoCache[room.roomId] = room;
      }
    }
  }

  Future<void> updateRoomLastMessage({
    required String roomId,
    required String lastMessage,
    required DateTime lastMessageAt,
  }) async {
    await _repository.updateRoomWithMessage(
      roomId: roomId,
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
    );
  }

  String _buildLastMessage(ChatModel message) {
    if (message.message.isNotEmpty) {
      return message.message;
    }

    if (message.noInvoice?.isNotEmpty == true) {
      return "🧾 Customer menerima pesanan";
    }

    if (message.noPenawaran?.isNotEmpty == true) {
      return "💰 Penawaran baru";
    }

    return "📦 Paket ditawarkan";
  }

  /// Clear in-memory storage for a specific room
  void clearInMemoryMessages(String roomId) {
    _allMessagesInMemory.remove(roomId);
    debugPrint('[ChatProvider] 🧹 Cleared in-memory messages for: $roomId');
  }

  /// Clear all in-memory storage
  void clearAllInMemoryMessages() {
    _allMessagesInMemory.clear();
    debugPrint('[ChatProvider] 🧹 Cleared all in-memory messages');
  }
}
