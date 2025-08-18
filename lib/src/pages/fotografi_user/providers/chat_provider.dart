import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/pages/core/api_singleton.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<Map<String, dynamic>> _rooms = [];
  Map<String, List<Map<String, dynamic>>> _messages = {};

  String? _currentUserId;
  bool _initialized = false;
  bool _isLoading = false; // ✅ buat flag loading

  List<Map<String, dynamic>> get rooms => _rooms;
  List<Map<String, dynamic>> getMessages(String roomId) =>
      _messages[roomId] ?? [];

  bool get isReady => _initialized;
  bool get isLoading => _isLoading; // ✅ getter loading

  Future<void> init(String userId) async {
    if (_initialized) return; // sudah pernah init

    _currentUserId = userId;
    await _chatService.connect(userId, apiClient);

    _chatService.onRoomMessageReceived =
        (roomId, sender, message, sentAt) {
      final idx = _rooms.indexWhere((r) => r['Room_Id'] == roomId);
      if (idx >= 0) {
        _rooms[idx]['Last_Message'] = message;
        _rooms[idx]['Last_Message_At'] = sentAt.toIso8601String();
      }

      final msgs = _messages[roomId] ?? [];
      msgs.add({
        'Sender': sender ?? '',
        'Text': message ?? '',
        'SentAt': sentAt ?? DateTime.now(),
      });
      _messages[roomId] = msgs;
      notifyListeners();
    };

    _chatService.onRoomCreated =
        (roomId, roomName, createdAt) async {
      final room = await _chatService.fetchRoomsForUser(userId, room_id: roomId);
      if (room.isNotEmpty && room.first['Room_Id'] != null) {
        _rooms.add(room.first);
        notifyListeners();
      }
    };

    await fetchRooms();
    _initialized = true;
  }

  Future<void> fetchRooms() async {
    if (_currentUserId == null) return;

    _isLoading = true; // ✅ mulai loading
    notifyListeners();

    try {
      final rooms = await _chatService.fetchRoomsForUser(_currentUserId!);
      _rooms = rooms;
      if (rooms.isNotEmpty) {
        await _chatService.joinMultipleRooms(
           rooms.map((r) => r['Room_Id']?.toString() ?? '').where((id) => id.isNotEmpty).toList());

      }
    } finally {
      _isLoading = false; // ✅ selesai loading
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

  Future<void> sendMessage(String roomId, String text) async {
    if (_currentUserId != null) {
      await _chatService.sendMessage(roomId, _currentUserId!, text);
    }
  }

  Future<void> disposeConnection() async {
    _rooms.clear();
    _messages.clear();
    _currentUserId = null;
    _initialized = false;
    await _chatService.disconnect(); // tambahin method disconnect di ChatService
    notifyListeners();
  }
}
