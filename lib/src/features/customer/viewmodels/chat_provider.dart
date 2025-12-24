import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/paket_model.dart';
import 'package:mpjnew/src/data/models/penawaran_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';
import 'package:mpjnew/src/features/customer/services/chat_service.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/services/penawaran_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final ApiClient _client = apiClient;

  List<RoomChatModel> _rooms = [];
  Map<String, List<ChatModel>> _messages = {};
  Map<String, PaketModel> _paketCache = {}; // Cache untuk paket
  Map<String, PenawaranModel> _penawaranCache = {}; // Cache untuk penawaran

  String? _currentUserId;
  bool _initialized = false;
  bool _isLoading = false;

  //=============================
  // GETTER
  //=============================
  ChatService get chatService => _chatService;
  List<RoomChatModel> get rooms => _rooms;
  List<ChatModel> getMessages(String roomId) => _messages[roomId] ?? [];
  PaketModel? getPaket(String idPaket) => _paketCache[idPaket];
  PenawaranModel? getPenawaran(String noInvoice) => _penawaranCache[noInvoice];

  String? get currentUserId => _currentUserId;
  bool get isReady => _initialized;
  bool get isLoading => _isLoading;
  bool get isConnected => _chatService.isConnected;

  //=============================
  // SETTER
  //=============================
  set rooms(List<RoomChatModel> rooms) => _rooms = rooms;
  set isReady(bool isReady) {
    _initialized = isReady;
    notifyListeners();
  }

  Function(PaketModel)? onPaketDataReceived;
  Function(PenawaranModel)? onPenawaranDataReceived;

  //=============================
  // INIT CONNECTION - UPDATED
  //=============================
  Future<void> init(String userId) async {
    if (_initialized) {
      debugPrint("CHAT_PROVIDER :: init dibatalkan, sudah initialized");
      return;
    }

    if (userId.isEmpty) {
      debugPrint("CHAT_PROVIDER :: init gagal, userId kosong");
      return;
    }

    _currentUserId = userId;
    debugPrint("CHAT_PROVIDER :: INIT dengan userId = $userId");

    // Connect SignalR
    final connectStatus = await _chatService.connect(userId, _client);
    debugPrint("CHAT_PROVIDER :: connect result = $connectStatus");

    if (connectStatus != 99) {
      debugPrint("CHAT_PROVIDER :: gagal connect ke SignalR");
    }

    //=============================
    // ✅ LISTENER PESAN MASUK - UPDATED
    //=============================
    _chatService.onFullMessageReceived = (ChatModel chat) {
      debugPrint(
          "CHAT_PROVIDER :: Pesan diterima dengan idPaket: ${chat.idPaket}, noInvoice: ${chat.noInvoice}");

      _chatService.updateMessageStatus(chat.messageId, "received");

      // Update preview room
      final i = _rooms.indexWhere((r) => r.roomId == chat.roomId);
      if (i >= 0) {
        _rooms[i] = _rooms[i].copyWith(
          lastMessage: chat.message,
          lastMessageAt: chat.sentAt,
        );
      }

      // Tambahkan ke messages list
      final oldList = _messages[chat.roomId] ?? [];

      // Cek duplikasi berdasarkan messageId
      final isDuplicate = oldList.any((m) => m.messageId == chat.messageId);

      if (!isDuplicate) {
        _messages[chat.roomId] = [...oldList, chat];
        notifyListeners();
      } else {
        debugPrint("CHAT_PROVIDER :: Message duplicate detected, skip add");
      }
    };

    //=============================
    // ✅ LISTENER DATA PAKET YANG SUDAH DI-FETCH
    //=============================
    _chatService.onPaketDataReceived = (PaketModel paket) {
      debugPrint("CHAT_PROVIDER :: Data paket diterima: ${paket.nama_paket}");

      // Simpan ke cache
      _paketCache[paket.no_id] = paket;

      // Notify listeners untuk update UI
      notifyListeners();

      // Notify RoomChatProvider jika ada yang listen
      if (onPaketDataReceived != null) {
        onPaketDataReceived!(paket);
      }
    };

    //=============================
    // ✅ LISTENER DATA PENAWARAN YANG SUDAH DI-FETCH
    //=============================
    _chatService.onPenawaranDataReceived = (PenawaranModel penawaran) {
      debugPrint(
          "CHAT_PROVIDER :: Data penawaran diterima: ${penawaran.noPesanan}");

      // Simpan ke cache
      _penawaranCache[penawaran.noPesanan] = penawaran;

      // Notify listeners untuk update UI
      notifyListeners();

      // Notify RoomChatProvider jika ada yang listen
      if (onPenawaranDataReceived != null) {
        onPenawaranDataReceived!(penawaran);
      }
    };

    //=============================
    // ✅ LISTENER ROOM BARU
    //=============================
    _chatService.onRoomCreated = (
      String roomId,
      String roomName,
      DateTime createdAt,
    ) async {
      debugPrint("CHAT_PROVIDER :: Room baru terdeteksi: $roomId ($roomName)");

      final roomList =
          await _chatService.fetchRoomsForUser(userId, roomId: roomId);

      if (roomList.isNotEmpty) {
        final exists = _rooms.any((r) => r.roomId == roomId);

        if (!exists) {
          _rooms.add(roomList.first);
          notifyListeners();
          debugPrint("CHAT_PROVIDER :: Room baru ditambahkan ke list");
        } else {
          debugPrint("CHAT_PROVIDER :: Room sudah ada di list");
        }
      }
    };

    await fetchRooms(); // load room
    _initialized = true;
    notifyListeners();

    debugPrint("CHAT_PROVIDER :: Init completed successfully");
  }

  //=============================
  // ✅ GET DATA DARI CACHE ATAU FETCH ULANG
  //=============================
  Future<PaketModel?> fetchPaket(String idPaket,
      {bool forceRefresh = false}) async {
    // Jika ada di cache dan tidak force refresh, return dari cache
    if (!forceRefresh && _paketCache.containsKey(idPaket)) {
      return _paketCache[idPaket];
    }

    try {
      final paket = await PaketService().getAll(noId: idPaket);
      if (paket != null) {
        _paketCache[idPaket] = paket.first;
        notifyListeners();
      }
      return paket.first;
    } catch (e) {
      debugPrint("CHAT_PROVIDER :: Error fetching paket: $e");
      return null;
    }
  }

  Future<PenawaranModel?> fetchPenawaran(String noInvoice,
      {bool forceRefresh = false}) async {
    // Jika ada di cache dan tidak force refresh, return dari cache
    if (!forceRefresh && _penawaranCache.containsKey(noInvoice)) {
      return _penawaranCache[noInvoice];
    }

    try {
      final penawaran = await PenawaranService().getAll(noId: noInvoice);
      if (penawaran != null) {
        _penawaranCache[noInvoice] = penawaran.first;
        notifyListeners();
      }
      return penawaran.first;
    } catch (e) {
      debugPrint("CHAT_PROVIDER :: Error fetching penawaran: $e");
      return null;
    }
  }

  //=============================
  // DISCONNECT
  //=============================
  Future<void> disposeConnection() async {
    debugPrint("CHAT_PROVIDER :: Dispose connection");

    _rooms.clear();
    _messages.clear();
    _initialized = false;
    _currentUserId = null;

    await _chatService.disconnect();
    notifyListeners();
  }

  Future<void> refreshRooms(
      String vendorId, String roomId, String userId) async {
    debugPrint("CHAT_PROVIDER :: Refresh rooms");

    rooms = await _chatService.fetchRoomsForUser(
      userId,
      roomId: roomId,
      idLawan: vendorId,
    );

    notifyListeners();
  }

  void updateRoomLastMessage({
    required String roomId,
    required String lastMessage,
    required DateTime lastMessageAt,
  }) {
    debugPrint("CHAT_PROVIDER :: Update room last message for $roomId");

    _rooms = _rooms.map((room) {
      if (room.roomId == roomId) {
        return room.copyWith(
          lastMessage: lastMessage,
          lastMessageAt: lastMessageAt,
        );
      }
      return room;
    }).toList();

    notifyListeners();
  }

  //=============================
  // FETCH ROOMS
  //=============================
  Future<List<RoomChatModel>> fetchRooms({
    String? roomId,
    String? idLawan,
  }) async {
    if (_currentUserId == null) return [];

    debugPrint(
        "CHAT_PROVIDER :: fetchRooms() - roomId: $roomId, idLawan: $idLawan");

    _isLoading = true;
    notifyListeners();

    try {
      final rooms = await _chatService.fetchRoomsForUser(
        _currentUserId!,
        roomId: roomId,
        idLawan: idLawan,
      );

      // Update internal state jika fetch all rooms
      if (roomId == null && idLawan == null) {
        _rooms = List.from(rooms);
        debugPrint("CHAT_PROVIDER :: Loaded ${_rooms.length} rooms");
      }

      // Join semua room aktif ke SignalR
      final validRooms =
          _rooms.map((e) => e.roomId).where((id) => id.isNotEmpty).toList();

      if (validRooms.isNotEmpty) {
        try {
          await _chatService.joinMultipleRooms(validRooms);
          debugPrint("✅ CHAT_PROVIDER :: Joined ${validRooms.length} rooms");
        } catch (e) {
          debugPrint("❌ CHAT_PROVIDER :: Join multiple rooms gagal: $e");
        }
      } else {
        debugPrint("CHAT_PROVIDER :: Tidak ada room yang bisa di-join");
      }

      return rooms;
    } catch (e, st) {
      debugPrint("❌ CHAT_PROVIDER :: fetchRooms error: $e\n$st");
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //=============================
  // FETCH MESSAGE PER ROOM
  //=============================
  Future<void> fetchMessages(String roomId) async {
    debugPrint("CHAT_PROVIDER :: fetchMessages($roomId)");

    _isLoading = true;
    notifyListeners();

    try {
      final msgs = await _chatService.fetchMessagesForRoom(roomId);
      _messages[roomId] = msgs;

      debugPrint(
          "CHAT_PROVIDER :: Loaded ${msgs.length} messages for room $roomId");

      // Pastikan sudah join room ini
      await _chatService.joinRoom(roomId);
    } catch (e, st) {
      debugPrint("❌ CHAT_PROVIDER :: fetchMessages error: $e\n$st");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //=============================
  // ✅ SEND MESSAGE - UPDATED
  //=============================
  Future<void> sendMessage(
    String roomId,
    String text,
    String? idPaket,
    String? noInvoice,
    List<String> userIds,
  ) async {
    if (_currentUserId == null) {
      debugPrint("❌ CHAT_PROVIDER :: Cannot send, no currentUserId");
      return;
    }

    if (text.trim().isEmpty) {
      debugPrint("❌ CHAT_PROVIDER :: Cannot send empty message");
      return;
    }

    // Generate unique messageId
    final messageId = "local-${DateTime.now().millisecondsSinceEpoch}";
    final now = DateTime.now();

    debugPrint("""
CHAT_PROVIDER :: Sending message
  - RoomId: $roomId
  - Message: $text
  - IdPaket: $idPaket
  - NoInvoice: $noInvoice
  - UserIds: $userIds
    """);

    // ===============================
    // ✅ LOCAL ECHO (Optimistic UI)
    // ===============================
    final chat = ChatModel(
      messageId: messageId,
      roomId: roomId,
      senderId: _currentUserId!,
      tipeUser: _client.getRole() ?? "vendor",
      message: text,
      jenisPesan: "text",
      idPaket: idPaket,
      noInvoice: noInvoice,
      sentAt: now,
      editedAt: null,
      userIds: userIds,
      status: 'aktif',
      sendStatus: 'sent',
      roomType: 'direct',
    );

    // Tambahkan ke local state untuk immediate feedback
    _messages[roomId] = [...?_messages[roomId], chat];

    // Update room preview
    updateRoomLastMessage(
      roomId: roomId,
      lastMessage: text,
      lastMessageAt: now,
    );

    notifyListeners();

    // ===============================
    // ✅ SEND TO SERVER
    // ===============================
    try {
      await _chatService.sendMessage(chat: chat);
      debugPrint("✅ CHAT_PROVIDER :: Message sent successfully");
    } catch (e, st) {
      debugPrint("❌ CHAT_PROVIDER :: sendMessage failed: $e\n$st");

      // Rollback optimistic update jika gagal
      final currentMessages = _messages[roomId] ?? [];
      _messages[roomId] =
          currentMessages.where((m) => m.messageId != messageId).toList();

      notifyListeners();

      rethrow;
    }
  }

  //=============================
  // POST CHAT (API) - untuk custom payload
  //=============================
  // Future<bool> postChat(Map<String, dynamic> payload) async {
  //   debugPrint("CHAT_PROVIDER :: postChat()");

  //   try {
  //     return await _chatService.postChat(payload);
  //   } catch (e) {
  //     debugPrint("❌ CHAT_PROVIDER :: postChat error: $e");
  //     return false;
  //   }
  // }

  //=============================
  // SIGNALR WRAPPER METHODS
  //=============================
  Future<void> joinRoom(String roomId) async {
    debugPrint("CHAT_PROVIDER :: joinRoom($roomId)");
    await _chatService.joinRoom(roomId);
  }

  Future<void> leaveRoom(String roomId) async {
    debugPrint("CHAT_PROVIDER :: leaveRoom($roomId)");
    await _chatService.leaveRoom(roomId);
  }

  Future<void> joinMultipleRooms(List<String> roomIds) async {
    debugPrint("CHAT_PROVIDER :: joinMultipleRooms(${roomIds.length} rooms)");
    await _chatService.joinMultipleRooms(roomIds);
  }

  Future<void> joinUserChannel(String userId) async {
    debugPrint("CHAT_PROVIDER :: joinUserChannel($userId)");
    await _chatService.joinUserChannel(userId);
  }

  //=============================
  // UTILITY METHODS
  //=============================

  /// Clear messages untuk room tertentu
  void clearMessagesForRoom(String roomId) {
    _messages.remove(roomId);
    notifyListeners();
  }

  /// Clear semua messages
  void clearAllMessages() {
    _messages.clear();
    notifyListeners();
  }

  /// Get total unread messages (implement jika ada field unread)
  // int getUnreadCount() {
  //   return _rooms.fold(0, (sum, room) => sum + (room.unreadCount ?? 0));
  // }

  /// Mark room as read (implement jika ada API)
  // Future<void> markRoomAsRead(String roomId) async {
  //   // TODO: Call API to mark as read
  //   final index = _rooms.indexWhere((r) => r.roomId == roomId);
  //   if (index >= 0) {
  //     _rooms[index] = _rooms[index].copyWith(unreadCount: 0);
  //     notifyListeners();
  //   }
  // }
}
