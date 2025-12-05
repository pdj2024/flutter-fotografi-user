import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';

import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<RoomChatModel> _rooms = [];
  Map<String, List<ChatModel>> _messages = {};

  String? _currentUserId;
  bool _initialized = false;
  bool _isLoading = false;

  // =======================
  // GETTER
  // =======================
  List<RoomChatModel> get rooms => _rooms;
  String? get currentUserId => _currentUserId;

  List<ChatModel> getMessages(String roomId) => _messages[roomId] ?? [];

  bool get isReady => _initialized;
  bool get isLoading => _isLoading;
  bool get isConnected => _chatService.isConnected;

  // =======================
  // INIT & CONNECTION
  // =======================
  Future<void> init(String userId) async {
    if (_initialized) return;
    if (userId.isEmpty) return;

    _currentUserId = userId;
    print("===== Current User ID: " + _currentUserId.toString());

    final cobaConnect = await _chatService.connect(userId, apiClient);
    if (cobaConnect != 99) {
      print("===== GAGAL CONNECT");
    }

    // handle pesan masuk
    _chatService.onRoomMessageReceived = (
      String roomId,
      String sender,
      String message,
      DateTime sentAt,
    ) {
      final idx = _rooms.indexWhere((r) => r.roomId == roomId);

      if (idx >= 0) {
        final old = _rooms[idx];

        // GANTI OBJECT DENGAN COPY BARU
        _rooms[idx] = old.copyWith(
          lastMessage: message,
          lastMessageAt: sentAt,
        );
      }

      // // simpan pesan ke memory
      // final msgs = _messages[roomId] ?? [];
      // msgs.add({
      //   'Sender': sender,
      //   'Text': message,
      //   'SentAt': sentAt,
      // });
      // _messages[roomId] = List<ChatModel>.from(msgs);

      notifyListeners();
    };

    // handle room baru
    _chatService.onRoomCreated =
        (String roomId, String roomName, DateTime createdAt) async {
      final room = await _chatService.fetchRoomsForUser(userId, roomId: roomId);
      if (room.isNotEmpty) {
        _rooms.add(room.first); // <-- cast aman
        notifyListeners();
      }
    };

    await fetchRooms();
    _initialized = true;
  }

  Future<void> disposeConnection() async {
    _rooms.clear();
    _messages.clear();
    _currentUserId = null;
    _initialized = false;
    await _chatService.disconnect();
    notifyListeners();
  }

  // =======================
  // ROOM & MESSAGE HANDLER
  // =======================
  Future<List<RoomChatModel>> fetchRooms(
      {String? roomId, String? idLawan}) async {
    if (_currentUserId == null) return [];

    print("=== MASUK FETCH ROOMS");

    _isLoading = true;
    notifyListeners();

    try {
      final rooms = await _chatService.fetchRoomsForUser(
        _currentUserId!,
        roomId: roomId,
        idLawan: idLawan,
      );

      // kalau tidak filter (ambil semua room)
      if (roomId == null && idLawan == null) {
        _rooms = List<RoomChatModel>.from(rooms); // simpan ke state global
      }

      if (_rooms.isNotEmpty) {
        try {
          await _chatService.joinMultipleRooms(
            _rooms
                .map((r) => r.roomId.toString())
                .where((id) => id.isNotEmpty)
                .toList(),
          );
          print("=== JOIN MULTIPLE ROOM BERHASIL");
        } catch (e) {
          print("=== JOIN MULTIPLE GAGAL: $e");
        }
      } else {
        print("=== ROOM EMPTY");
      }

      print("=== ROOMS: ${rooms}");

      return rooms; // <- bisa dipakai di SingleChat
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String roomId) async {
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

  Future<void> sendMessage(String roomId, String text, String? idPaket,
      String? noInvoice, List<String> userIds) async {
    print("====== CHAT PROVIDER 1: " + _currentUserId.toString());
    if (_currentUserId != null) {
      final role = apiClient.getRole() ?? 'customer';

      print("====== MASUK CHAT PROVIDER");
      await _chatService.sendMessage(
          roomId, _currentUserId!, role, text, idPaket, noInvoice, userIds);
    }
  }

  Future<bool> postChat(Map<String, dynamic> payload) async {
    return await _chatService.postChat(payload);
  }

  // =======================
  // SIGNALR WRAPPER
  // =======================
  Future<void> joinRoom(String roomId) async {
    await _chatService.joinRoom(roomId);
  }

  Future<void> joinMultipleRooms(List<String> roomIds) async {
    await _chatService.joinMultipleRooms(roomIds);
  }

  Future<void> joinUserChannel(String userId) async {
    await _chatService.joinUserChannel(userId);
  }
}
