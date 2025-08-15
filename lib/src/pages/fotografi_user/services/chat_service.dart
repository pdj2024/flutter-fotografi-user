import 'dart:convert';
import 'package:path/path.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../core/api_client.dart';
import '../../core/api_singleton.dart';
import '../../providers/constants.dart';
import '../providers/user_provider.dart';

class ChatService {
  final String controller = 'chat';
  final ApiClient _client = apiClient;

  final String hubUrl = "${Constants.baseUrl}/api/chathub";

  HubConnection? _connection;
  final List<String> _joinedRooms = [];
  final Set<String> _joinedUserChannels = {};

  String _lastConnectedUserId = "";

  bool get isConnected =>
      _connection?.state == HubConnectionState.Connected;

  // Event callbacks
  Function(String sender, String message, DateTime sentAt)? onMessageReceived;
  Function(String roomId, String sender, String message, DateTime sentAt)?
      onRoomMessageReceived;
  Function(String roomId)? onNewRoomDetected;

  // ===========================
  // SIGNALR SECTION
  // ===========================

Future<void> connect(String currentUserId, ApiClient apiClient) async {
  print("======= INI MULAI CONNECT " + hubUrl);

  // Ambil token & role dari ApiClient
  final token = await apiClient.getIdToken();
  final role = apiClient.getRole() ?? 'customer'; // default vendor kalau belum diset

  // Pastikan token ada
  if (token == null || token.isEmpty) {
    print("[SignalR] ❌ Gagal connect: token kosong");
    return;
  }

  // Buat URL hub dengan query string supaya backend bisa baca
  final hubUri = Uri.parse(hubUrl).replace(queryParameters: {
    'access_token': token, // untuk Authorization
    'role': role,          // untuk X-Jenis-User
  });

  if (_connection == null) {
    _connection = HubConnectionBuilder()
        .withUrl(
          hubUri.toString(),
          options: HttpConnectionOptions(
            // SignalR tetap minta accessTokenFactory
            accessTokenFactory: () async => token,
            transport: HttpTransportType.WebSockets,
          ),
        )
        .withAutomaticReconnect()
        .build();

    // Listener untuk pesan masuk
    _connection!.on("ReceiveMessage", (args) {
      try {
        final Map<String, dynamic> msg = jsonDecode(jsonEncode(args![0]));
        final roomId = msg["roomId"] ?? "";
        final sender = msg["sender"] ?? "";
        final text = msg["message"] ?? "";
        final sentAt = DateTime.parse(msg["sentAt"]);

        if (!_joinedRooms.contains(roomId)) {
          _joinedRooms.add(roomId);
        }

        onMessageReceived?.call(sender, text, sentAt);
        onRoomMessageReceived?.call(roomId, sender, text, sentAt);
      } catch (e) {
        print("[SignalR] Error parsing ReceiveMessage: $e");
      }
    });

    // Listener untuk room baru
    _connection!.on("RoomCreated", (args) {
      try {
        final Map<String, dynamic> payload = jsonDecode(jsonEncode(args![0]));
        final roomId = payload["roomId"] ?? "";
        onNewRoomDetected?.call(roomId);
      } catch (e) {
        print("[SignalR] Error parsing RoomCreated: $e");
      }
    });

    // Auto reconnect kalau koneksi terputus
    _connection!.onclose(({error}) async {
      print("[SignalR] Connection closed: $error");
      _joinedRooms.clear();
      _joinedUserChannels.clear();
      _lastConnectedUserId = "";
      await Future.delayed(const Duration(seconds: 2));
      await connect(currentUserId, apiClient);
    });
  }

  // Start koneksi kalau belum terhubung
  if (_connection!.state != HubConnectionState.Connected) {
    await _connection!.start();
    print("[SignalR] ✅ Connected");
  }

  // Join channel user kalau belum
  if (currentUserId != _lastConnectedUserId ||
      !_joinedUserChannels.contains(currentUserId)) {
    await joinUserChannel(currentUserId);
    _lastConnectedUserId = currentUserId;
  }
}



  Future<void> joinRoom(String roomId) async {
    if (_connection?.state == HubConnectionState.Connected &&
        !_joinedRooms.contains(roomId)) {
      await _connection!.invoke("JoinRoom", args: [roomId]);
      _joinedRooms.add(roomId);
      print("[SignalR] Joined room $roomId");
    }
  }

  Future<void> joinMultipleRooms(List<String> roomIds) async {
    for (final roomId in roomIds) {
      await joinRoom(roomId);
    }
  }

  Future<void> joinUserChannel(String userId) async {
    if (_connection?.state == HubConnectionState.Connected &&
        !_joinedUserChannels.contains(userId)) {
      await _connection!.invoke("JoinUserChannel", args: [userId]);
      _joinedUserChannels.add(userId);
      print("[SignalR] Joined user channel user-$userId");
    }
  }

  Future<void> sendMessage(
      String roomId, String senderUserId, String message) async {
    if (_connection?.state == HubConnectionState.Connected) {
      await _connection!
          .invoke("SendMessageToRoom", args: [roomId, senderUserId, message]);
      print("[SignalR] Sent message to $roomId: $message");
    }
  }

  // ===========================
  // API SECTION
  // ===========================

  Future<List<Map<String, dynamic>>> fetchRoomsForUser(String userId) async {
  print('======== MASUK GET ROOM: $userId');

  final response = await _client.get(
    '/$controller/getRooms',
    queryParameters: {'user_id': userId},
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> json = jsonDecode(response.body);
    final List<dynamic> data = json['Data'];

    return data.map<Map<String, dynamic>>((e) {
      return {
        'Room_Id': e['Room_Id'],
        'Room_Type': e['Room_Type'],
        'Username_Lawan': e['Username_Lawan'],
        'Id_Media_Lawan': e['Id_Media_Lawan'],
        'Tipe_User_Lawan': e['Tipe_User_Lawan'],
        'Last_Message_At': e['Last_Message_At'],
         'Last_Message': e['Last_Message'],
        'Status': e['Status'],
        'User_Ids': List<String>.from(e['User_Ids'] ?? []),
      };
    }).toList();
  }

  return [];
}

Future<List<Map<String, dynamic>>> fetchMessagesForRoom( String roomId) async 
{ 
  final response = await _client.get( '/$controller/getAll', queryParameters: {'room_id': roomId}, ); 
  if (response.statusCode == 200) 
  { 
    final Map<String, dynamic> json = jsonDecode(response.body); 
    final List<dynamic> data = json['Data']; 
    return data .map((m) => 
    { 
      'Sender': m['Sender_Id'],
       'Text': m['Message'], 
       'SentAt': DateTime.parse(m['Sent_At']) }) .toList(); 
  } 
  return [];
 }

  

  Future<bool> postChat(Map<String, dynamic> payload) async {
    final response = await _client.post(
      '/$controller/create',
      body: jsonEncode(payload),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }
}