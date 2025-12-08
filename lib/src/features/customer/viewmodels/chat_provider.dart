import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';
import 'package:mpjnew/src/features/customer/services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<RoomChatModel> _rooms = [];
  Map<String, List<ChatModel>> _messages = {};

  String? _currentUserId;
  bool _initialized = false;
  bool _isLoading = false;

  //=============================
  // GETTER
  //=============================
  List<RoomChatModel> get rooms => _rooms;
  List<ChatModel> getMessages(String roomId) => _messages[roomId] ?? [];

  String? get currentUserId => _currentUserId;
  bool get isReady => _initialized;
  bool get isLoading => _isLoading;
  bool get isConnected => _chatService.isConnected;

  //=============================
  // SETTER
  //=============================
  set rooms(List<RoomChatModel> rooms) => _rooms = rooms;

  //=============================
  // INIT CONNECTION
  //=============================
  Future<void> init(String userId) async {
    if (_initialized) {
      print("CHAT_PROVIDER :: init dibatalkan, sudah initialized");
      return;
    }

    if (userId.isEmpty) {
      print("CHAT_PROVIDER :: init gagal, userId kosong");
      return;
    }

    _currentUserId = userId;
    print("CHAT_PROVIDER :: INIT dengan userId = $userId");

    // Connect SignalR
    final connectStatus = await _chatService.connect(userId, apiClient);
    print("CHAT_PROVIDER :: connect result = $connectStatus");

    if (connectStatus != 99) {
      print("CHAT_PROVIDER :: gagal connect ke SignalR");
    }

    //=============================
    // LISTENER PESAN MASUK
    //=============================
    _chatService.onRoomMessageReceived = (
      String roomId,
      String senderId,
      String message,
      DateTime sentAt,
    ) {
      print("CHAT_PROVIDER :: Pesan baru [$roomId] dari $senderId");

      // Update preview room
      final i = _rooms.indexWhere((r) => r.roomId == roomId);
      if (i >= 0) {
        _rooms[i] = _rooms[i].copyWith(
          lastMessage: message,
          lastMessageAt: sentAt,
        );
      }

      // Buat ChatModel lengkap
      final incoming = ChatModel(
        messageId:
            "client-temp-${DateTime.now().millisecondsSinceEpoch}", // boleh diganti
        roomId: roomId,
        senderId: senderId,
        tipeUser: apiClient.getRole() ?? "unknown",
        message: message,
        jenisPesan: "text", // atau dari server jika dikirim
        idPaket: null,
        noInvoice: null,
        sentAt: sentAt,
        editedAt: null,
        userIds: [],
      );

      final oldList = _messages[roomId] ?? [];
      _messages[roomId] = [...oldList, incoming];

      notifyListeners();
    };

    // =============================
    // LISTENER ROOM BARU
    // =============================
    _chatService.onRoomCreated = (
      String roomId,
      String roomName,
      DateTime createdAt,
    ) async {
      print("CHAT_PROVIDER :: Room baru terdeteksi: $roomId");

      final roomList =
          await _chatService.fetchRoomsForUser(userId, roomId: roomId);

      if (roomList.isNotEmpty) {
        _rooms.add(roomList.first);
        notifyListeners();
      }
    };

    await fetchRooms(); // load room
    _initialized = true;
    notifyListeners();
  }

  //=============================
  // DISCONNECT
  //=============================
  Future<void> disposeConnection() async {
    print("CHAT_PROVIDER :: Dispose connection");

    _rooms.clear();
    _messages.clear();
    _initialized = false;
    _currentUserId = null;

    await _chatService.disconnect();
    notifyListeners();
  }

  Future<void> refreshRooms(
      String customerId, String roomId, String userId) async {
    rooms = await _chatService.fetchRoomsForUser(userId,
        roomId: roomId, idLawan: customerId);
    notifyListeners();
  }

  void updateRoomLastMessage({
    required String roomId,
    required String lastMessage,
    required DateTime lastMessageAt,
  }) {
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
  Future<List<RoomChatModel>> fetchRooms(
      {String? roomId, String? idLawan}) async {
    if (_currentUserId == null) return [];

    print("CHAT_PROVIDER :: fetchRooms()");

    _isLoading = true;
    notifyListeners();

    try {
      final rooms = await _chatService.fetchRoomsForUser(
        _currentUserId!,
        roomId: roomId,
        idLawan: idLawan,
      );

      if (roomId == null && idLawan == null) {
        _rooms = List.from(rooms);
      }

      // Join semua room aktif
      final validRooms =
          _rooms.map((e) => e.roomId).where((id) => id.isNotEmpty).toList();

      if (validRooms.isNotEmpty) {
        try {
          await _chatService.joinMultipleRooms(validRooms);
          print("✅ CHAT_PROVIDER :: Join multiple rooms berhasil");
        } catch (e) {
          print("CHAT_PROVIDER :: Join multiple rooms gagal: $e");
        }
      } else {
        print("CHAT_PROVIDER :: Tidak ada room yang bisa di-join");
      }

      return rooms;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //=============================
  // FETCH MESSAGE PER ROOM
  //=============================
  Future<void> fetchMessages(String roomId) async {
    print("CHAT_PROVIDER :: fetchMessages($roomId)");

    _isLoading = true;
    notifyListeners();

    try {
      final msgs = await _chatService.fetchMessagesForRoom(roomId);
      _messages[roomId] = msgs;

      await _chatService.joinRoom(roomId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //=============================
  // SEND MESSAGE
  //=============================
  Future<void> sendMessage(
    String roomId,
    String text,
    String? idPaket,
    String? noInvoice,
    List<String> userIds,
  ) async {
    if (_currentUserId == null) return;

    // ===== LOCAL ECHO =====
    final localMsg = ChatModel(
      messageId: "local-${DateTime.now().millisecondsSinceEpoch}",
      roomId: roomId,
      senderId: _currentUserId!,
      tipeUser: apiClient.getRole() ?? "unknown",
      message: text,
      jenisPesan: "text",
      idPaket: idPaket,
      noInvoice: noInvoice,
      sentAt: DateTime.now(),
      editedAt: null,
      userIds: userIds,
    );

    final old = _messages[roomId] ?? [];
    _messages[roomId] = [...old, localMsg];
    notifyListeners();

    // ===== KIRIM KE SERVER =====
    await _chatService.sendMessage(
      roomId,
      _currentUserId!,
      apiClient.getRole() ?? "customer",
      text,
      idPaket,
      noInvoice,
      userIds,
    );
  }

  //=============================
  // POST CHAT (API)
  //=============================
  Future<bool> postChat(Map<String, dynamic> payload) async {
    print("CHAT_PROVIDER :: postChat()");
    return await _chatService.postChat(payload);
  }

  //=============================
  // SIGNALR WRAPPER
  //=============================
  Future<void> joinRoom(String roomId) async {
    print("CHAT_PROVIDER :: joinRoom($roomId)");
    await _chatService.joinRoom(roomId);
  }

  Future<void> joinMultipleRooms(List<String> roomIds) async {
    print("CHAT_PROVIDER :: joinMultipleRooms(${roomIds.length} rooms)");
    await _chatService.joinMultipleRooms(roomIds);
  }

  Future<void> joinUserChannel(String userId) async {
    print("CHAT_PROVIDER :: joinUserChannel($userId)");
    await _chatService.joinUserChannel(userId);
  }
}
