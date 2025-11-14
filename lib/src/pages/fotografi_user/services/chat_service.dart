import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/api_singleton.dart';

class ChatService {
  final String controller = 'chat';
  final ApiClient _client = apiClient;

  final String hubUrl = "${Constants.baseUrl}/api/chathub";

  HubConnection? _connection;
  final List<String> _joinedRooms = [];
  final Set<String> _joinedUserChannels = {};

  String _lastConnectedUserId = "";

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

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
      return obj
          .map((key, value) => MapEntry(key.toString(), value as Object?));
    }
    if (obj is String) {
      final decoded = jsonDecode(obj);
      if (decoded is Map) {
        return decoded
            .map((key, value) => MapEntry(key.toString(), value as Object?));
      }
    }
    throw Exception("Unsupported payload type: ${obj.runtimeType}");
  }

  Future<int> connect(String currentUserId, ApiClient apiClient) async {
    print("======= INI MULAI CONNECT: " + currentUserId);

    // Ambil token & role dari ApiClient
    final token = await apiClient.getIdToken();
    final role =
        apiClient.getRole() ?? 'customer'; // default vendor kalau belum diset

    // Pastikan token ada
    if (token == null || token.isEmpty) {
      print("[SignalR] ❌ Gagal connect: token kosong");
      return -1;
    }

    // Buat URL hub dengan query string supaya backend bisa baca
    final hubUri = Uri.parse(hubUrl).replace(queryParameters: {
      'access_token': token, // untuk Authorization
      'role': role, // untuk X-Jenis-User
    });

    if (_connection == null) {
      _connection = HubConnectionBuilder()
          .withUrl(
        '${Constants.baseUrl}/api/chathub?role=$role',
        options: HttpConnectionOptions(
          accessTokenFactory: () async => token,
          transport: HttpTransportType.WebSockets, // paksa langsung WS
          requestTimeout: 10000, // ✅ naikkan timeout
        ),
      )
          .withAutomaticReconnect(
              retryDelays: [1, 2, 5, 10]) // coba lagi 1s, 2s, 5s, 10s
          .build();

      // Listener untuk pesan masuk
      _connection!.on("ReceiveMessage", (args) {
        try {
          if (args == null || args.isEmpty) return;

          final msg = safeParse(args[0]);

          final roomId = msg["roomId"]?.toString() ?? "";
          final sender = msg["sender"]?.toString() ?? "";
          final text = msg["message"]?.toString() ?? "";

          final sentAt = msg["sentAt"] != null
              ? DateTime.tryParse(msg["sentAt"].toString())?.toLocal() ??
                  DateTime.now()
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
              ? DateTime.tryParse(payload["createdAt"].toString()) ??
                  DateTime.now()
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

  // Future<void> sendMessage(
  //     String roomId, String senderUserId, String message) async {
  //       print("======= MASUK ATAS");

  //   if (_connection?.state == HubConnectionState.Connected) {

  //        print("======= MASUK BAWAH");
  //     await _connection!
  //         .invoke("SendMessageToRoom", args: [roomId, senderUserId, message]);
  //     print("================ [SignalR] Sent message to $roomId: $message");
  //   }
  // }
  Future<void> sendMessage(
    String roomId,
    String senderUserId,
    String tipeUser,
    String message,
    String? idPaket,
    String? noInvoice,
    List<String> userIds,
  ) async {
    final payload = {
      "chat": {
        "sender_Id": senderUserId,
        "tipe_User": tipeUser,
        "id_Paket": idPaket,
        "no_Invoice": noInvoice,
        "message": message,
      },
      "room_Id": roomId,
      "user_Ids": userIds,
    };

    print("====== MASUK CHAT SERVICE");

    final response = await _client.post(
      '/$controller/create',
      body: jsonEncode(payload),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengirim pesan ke room $roomId');
    }

    print("[API] ✅ Pesan terkirim ke $roomId: $message");
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

  Future<List<RoomChatModel>> fetchRoomsForUser(
    String userId, {
    String? roomId,
    String? idLawan,
  }) async {
    debugPrint('==== GET ROOMS for user: $userId');

    try {
      // Build query
      final queryParams = <String, dynamic>{
        'user_id': userId,
        if (idLawan != null && idLawan.isNotEmpty) 'id_lawan': idLawan,
        if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
      };

      final response = await _client.get(
        '/$controller/getRooms',
        queryParameters: queryParams,
      );

      // Validate status
      if (response.statusCode != 200) {
        debugPrint('⚠️ fetchRoomsForUser: status ${response.statusCode}');
        debugPrint('⚠️ Response text: ${response.body}');
        return [];
      }

      final body = jsonDecode(response.body);

      // Body validation
      if (body is! Map<String, dynamic>) {
        debugPrint("⚠️ Response is NOT a Map. Value: $body");
        return [];
      }

      // Validate 'Data' field
      if (body['Data'] is! List) {
        debugPrint("⚠️ 'Data' is not a List. Value: ${body['Data']}");
        return [];
      }

      final List rawData = body['Data'] ?? [];

      // Convert ke model
      final List<RoomChatModel> rooms = rawData
          .map((e) {
            if (e is Map<String, dynamic>) {
              return RoomChatModel.fromJson(e);
            } else {
              debugPrint("⚠️ Data item bukan Map: $e");
              return null;
            }
          })
          .whereType<RoomChatModel>() // buang null
          .toList();

      return rooms;
    } catch (e, st) {
      debugPrint("❌ Error fetchRoomsForUser: $e");
      debugPrintStack(stackTrace: st);
      return [];
    }
  }

  Future<List<ChatModel>> fetchMessagesForRoom(String roomId) async {
    final response = await _client.get(
      '/$controller/getAll',
      queryParameters: {'room_id': roomId},
    );

    if (response.statusCode != 200) return [];

    final Map<String, dynamic> json = jsonDecode(response.body);
    final List<dynamic> data = json['Data'] ?? [];

    return data.map((item) => ChatModel.fromJson(item)).toList();

    // if (response.statusCode == 200) {
    //   final Map<String, dynamic> json = jsonDecode(response.body);
    //   final List<dynamic> data = json['Data'] ?? [];
    //   print(data);

    //   return data.map((m) {
    //     final rawSentAt = m['Sent_At']?.toString();
    //     DateTime sentAt;

    //     if (rawSentAt != null) {
    //       try {
    //         sentAt = DateTime.parse(rawSentAt).toLocal(); // pastikan ke local
    //       } catch (_) {
    //         sentAt = DateTime.now();
    //       }
    //     } else {
    //       sentAt = DateTime.now();
    //     }

    //     return {
    //       'Sender': m['Sender_Id']?.toString() ?? '',
    //       'Text': m['Message']?.toString() ?? '',
    //       'SentAt': sentAt,
    //     };
    //   }).toList();
    // }

    // return [];
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
