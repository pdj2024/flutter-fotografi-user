import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/pages/core/api_singleton.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<Map<String, dynamic>> _rooms = [];
  Map<String, List<Map<String, dynamic>>> _messages = {};

  String? _currentUserId;
  bool _initialized = false;
  bool _isLoading = false;

  // =======================
  // GETTER
  // =======================
  List<Map<String, dynamic>> get rooms => _rooms;

  List<Map<String, dynamic>> getMessages(String roomId) =>
      _messages[roomId] ?? [];

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

    final cobaConnect = await _chatService.connect(userId, apiClient);
    if (cobaConnect != 99) {
      print("===== GAGAL CONNECT");
    }

    // handle pesan masuk
    _chatService.onRoomMessageReceived =
    (String roomId, String sender, String message, DateTime sentAt) {
  final idx = _rooms.indexWhere((r) => r['Room_Id'] == roomId);
  if (idx >= 0) {
    _rooms[idx]['Last_Message'] = message;
    _rooms[idx]['Last_Message_At'] = sentAt; // <-- simpan langsung DateTime
  }

  final msgs = _messages[roomId] ?? [];
  msgs.add({
    'Sender': sender,
    'Text': message,
    'SentAt': sentAt, // <-- DateTime
  });
  _messages[roomId] = List<Map<String, dynamic>>.from(msgs);
  notifyListeners();
};


    // handle room baru
    _chatService.onRoomCreated =
        (String roomId, String roomName, DateTime createdAt) async {
      final room = await _chatService.fetchRoomsForUser(userId, room_id: roomId);
      if (room.isNotEmpty && room.first['Room_Id'] != null) {
        _rooms.add(Map<String, dynamic>.from(room.first)); // <-- cast aman
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
  Future<void> fetchRooms({String? room_id = null}) async {
    if (_currentUserId == null) return;

    print("=== MASUK FETCH ROOMS");

    _isLoading = true;
    notifyListeners();

    try {
      final rooms = await _chatService.fetchRoomsForUser(_currentUserId!);
      _rooms = List<Map<String, dynamic>>.from(rooms); // <-- cast aman

      if (_rooms.isNotEmpty) {
        try {
          await _chatService.joinMultipleRooms(
            _rooms
                .map((r) => r['Room_Id']?.toString() ?? '')
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
      _messages[roomId] = List<Map<String, dynamic>>.from(msgs); // <-- cast aman
      await _chatService.joinRoom(roomId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String roomId, String text) async {
    if (_currentUserId != null) {
      await _chatService.sendMessage(roomId, _currentUserId!, text);
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
