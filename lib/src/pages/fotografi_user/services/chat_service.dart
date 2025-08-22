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

  // ✅ Tambahin ini
Function(String roomId, String roomName, DateTime createdAt)? onRoomCreated;

  // ===========================
  // SIGNALR SECTION
  // ===========================

  Map<String, Object?> safeParse(dynamic obj) {
  if (obj is Map) {
    // cast aman → String, Object?
    return obj.map((key, value) => MapEntry(key.toString(), value as Object?));
  }
  if (obj is String) {
    final decoded = jsonDecode(obj);
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value as Object?));
    }
  }
  throw Exception("Unsupported payload type: ${obj.runtimeType}");
}



Future<int> connect(String currentUserId, ApiClient apiClient) async {
  print("======= INI MULAI CONNECT " + hubUrl);

  // Ambil token & role dari ApiClient
  final token = await apiClient.getIdToken();
  final role = apiClient.getRole() ?? 'customer'; // default vendor kalau belum diset

  // Pastikan token ada
  if (token == null || token.isEmpty) {
    print("[SignalR] ❌ Gagal connect: token kosong");
    return -1;
  }

  // Buat URL hub dengan query string supaya backend bisa baca
  final hubUri = Uri.parse(hubUrl).replace(queryParameters: {
    'access_token': token, // untuk Authorization
    'role': role,          // untuk X-Jenis-User
  });

  if (_connection == null) {
    _connection = HubConnectionBuilder()
      .withUrl(
          'http://43.228.212.41:15/api/chathub?role=$role',
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
             transport: HttpTransportType.WebSockets, // paksa langsung WS
              requestTimeout: 10000, // ✅ naikkan timeout
          ),
        )
        .withAutomaticReconnect(retryDelays: [1, 2, 5, 10]) // coba lagi 1s, 2s, 5s, 10s
        .build();


    // Listener untuk pesan masuk
  _connection!.on("ReceiveMessage", (args) {
  try {
    if (args == null || args.isEmpty) return;

    final msg = safeParse(args[0]);

    final roomId = msg["roomId"]?.toString() ?? "";
    final sender = msg["sender"]?.toString() ?? "";
    final text   = msg["message"]?.toString() ?? "";

    final sentAt = msg["sentAt"] != null
        ? DateTime.tryParse(msg["sentAt"].toString())?.toLocal() ?? DateTime.now()
        : DateTime.now();

    if (!_joinedRooms.contains(roomId)) {
      _joinedRooms.add(roomId);
    }

    onMessageReceived?.call(sender, text, sentAt);
    onRoomMessageReceived?.call(roomId, sender, text, sentAt);
  } catch (e, st) {
    print("[SignalR] Error parsing ReceiveMessage: $e\n$st");
  }
});





    // Listener untuk room baru
_connection!.on("RoomCreated", (args) {
  try {
    if (args == null || args.isEmpty) return;

    final Map<String, dynamic> payload;
    if (args[0] is Map) {
      payload = Map<String, dynamic>.from(args[0] as Map);
    } else {
      payload = jsonDecode(args[0].toString());
    }

    final roomId = payload["roomId"]?.toString() ?? "";
    final roomName = payload["roomName"]?.toString() ?? "";
    final createdAt = payload["createdAt"] != null
        ? DateTime.tryParse(payload["createdAt"].toString()) ?? DateTime.now()
        : DateTime.now();

    onRoomCreated?.call(roomId, roomName, createdAt);
    onNewRoomDetected?.call(roomId);
  } catch (e, st) {
    print("[SignalR] Error parsing RoomCreated: $e\n$st");
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

  return 99;
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
        print("======= MASUK ATAS");

    if (_connection?.state == HubConnectionState.Connected) {

         print("======= MASUK BAWAH");
      await _connection!
          .invoke("SendMessageToRoom", args: [roomId, senderUserId, message]);
      print("================ [SignalR] Sent message to $roomId: $message");
    }
  }

  Future<void> disconnect() async {
  if (_connection != null &&
      _connection!.state == HubConnectionState.Connected) {
    await _connection!.stop();
    print("[SignalR] Disconnected");
  }
  _connection = null;
  _joinedRooms.clear();
  _joinedUserChannels.clear();
}


  // ===========================
  // API SECTION
  // ===========================

  Future<List<Map<String, dynamic>>> fetchRoomsForUser(String userId, {String? room_id = null}) async {
  print('======== MASUK GET ROOM: $userId');

   final queryParams = {
    'user_id': userId,
    if (room_id != null) 'room_id': room_id, // hanya dikirim kalau tidak null
  };

  final response = await _client.get(
    '/$controller/getRooms',
    queryParameters: queryParams,
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> json = jsonDecode(response.body);
    final List<dynamic> data = json['Data'];

    return data.map<Map<String, dynamic>>((e) {
      return {
        'Room_Id': e['Room_Id'],
        'Room_Type': e['Room_Type'],
         'Id_Lawan': e['Id_Lawan'],
        'Username_Lawan': e['Username_Lawan'],
        'Id_Media_Lawan': e['Id_Media_Lawan'],
        'Tipe_User_Lawan': e['Tipe_User_Lawan'],
        'Last_Message_At': e['Last_Message_At'],
         'Last_Message': e['Last_Message'],
        'Status': e['Status'],
        'User_Ids': (e['User_Ids'] as List?)
        ?.where((id) => id != null)
        .map((id) => id.toString())
        .toList() ?? [],
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
   return data.map((m) => {
  'Sender': m['Sender_Id']?.toString() ?? '',
  'Text': m['Message']?.toString() ?? '',
  'SentAt': m['Sent_At'] != null
      ? DateTime.tryParse(m['Sent_At']) ?? DateTime.now()
      : DateTime.now(),
}).toList();
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