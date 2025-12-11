import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'package:signalr_netcore/itransport.dart';

/// ChatService
/// - Mengelola koneksi SignalR (hub)
/// - Parsing event "ReceiveMessage", "RoomCreated", "SendMessageToRoom"
/// - Menyediakan fungsi API untuk fetch room / messages / post message
///
/// Compatible: semua nama public (connect, joinRoom, sendMessage, disconnect, fetchRoomsForUser, fetchMessagesForRoom, postChat)
class ChatService {
  // -------------------------
  // Config & dependencies
  // -------------------------
  final String controller = 'chat';
  final ApiClient _client = apiClient;
  bool _isConnecting = false;

  // gunakan endpoint chathub yang sesuai
  final String hubUrl = "${Constants.baseUrl}/api/chathub";

  // -------------------------
  // SignalR internals
  // -------------------------
  HubConnection? _connection;
  final List<String> _joinedRooms = [];
  final Set<String> _joinedUserChannels = {};

  String _lastConnectedUserId = "";

  /// Callback events (public)
  Function(String sender, String message, DateTime sentAt)? onMessageReceived;
  Function(String roomId, String sender, String message, DateTime sentAt)?
      onRoomMessageReceived;
  Function(String roomId)? onNewRoomDetected;
  Function(String roomId, String roomName, DateTime createdAt)? onRoomCreated;

  ChatService();

  // -------------------------
  // Properties
  // -------------------------
  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  // -------------------------
  // Utilities
  // -------------------------
  /// Safe parse: terima Map atau JSON string
  Map<String, Object?> safeParse(dynamic obj) {
    if (obj is Map) {
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

  // -------------------------
  // SIGNALR: CONNECT / SETUP
  // -------------------------

  /// Connect ke SignalR hub.
  /// - currentUserId: id user yang sedang login (digunakan untuk join user-channel)
  /// - apiClient: instance ApiClient untuk ambil token & role
  /// Return int: 99 = success, -1 = token missing
  Future<int> connect(String currentUserId, ApiClient apiClient) async {
    print("[ChatService] connect() start for userId: $currentUserId");

    // ⛔ Mencegah connect ganda
    if (_isConnecting) {
      print("[ChatService] 🚫 connect() ignored: still connecting...");
      return -1;
    }

    try {
      _isConnecting = true;

      // Ambil token & role
      final token = await apiClient.getIdToken();
      final role = apiClient.getRole() ?? 'customer';

      if (token == null || token.isEmpty) {
        print("[ChatService] ❌ token null/empty, abort connect");
        return -1;
      }

      // Init connection sekali
      await _ensureConnectionInitialized(token, role);

      // Start connection aman (punya state checking)
      final startResult = await _startConnectionIfNeeded();
      if (startResult == -1) {
        print("[ChatService] ❌ Failed to start connection");
        return -1;
      }

      // Join channel user bila perlu
      if (currentUserId != _lastConnectedUserId ||
          !_joinedUserChannels.contains(currentUserId)) {
        await joinUserChannel(currentUserId);
        _lastConnectedUserId = currentUserId;
      }

      print("[ChatService] connect() finished successfully");
      return 99;
    } catch (e, st) {
      print("[ChatService] ❌ connect failed: $e\n$st");
      return -1;
    } finally {
      _isConnecting = false;
    }
  }

  /// Inisialisasi HubConnection & setup listeners (hanya sekali)
  Future<void> _ensureConnectionInitialized(String token, String role) async {
    if (_connection != null) {
      print("[ChatService] _ensureConnectionInitialized: already exists");
      return;
    }

    print("[ChatService] Initializing HubConnection (role=$role)");

    _connection = HubConnectionBuilder()
        .withUrl(
      '$hubUrl?role=$role',
      options: HttpConnectionOptions(
        accessTokenFactory: () async => token,
        transport: HttpTransportType.WebSockets,
        requestTimeout: 15000,
      ),
    )
        .withAutomaticReconnect(
      retryDelays: const [1000, 2000, 5000, 10000],
    ).build();

    _setupListeners();

    print("[ChatService] HubConnection created");
  }

  /// Start connection bila perlu
  Future<int> _startConnectionIfNeeded() async {
    if (_connection == null) {
      print("[ChatService] ❌ _startConnectionIfNeeded: connection null");
      return -1;
    }

    final state = _connection!.state;
    print("[ChatService] Current connection state: $state");

    // Sudah connected → aman
    if (state == HubConnectionState.Connected) {
      print("[ChatService] _startConnectionIfNeeded: already connected");
      return 1;
    }

    // Jika sedang connect / reconnect → jangan start lagi
    if (state == HubConnectionState.Connecting ||
        state == HubConnectionState.Reconnecting) {
      print("[ChatService] ⏳ Connection is busy ($state), skip start()");
      return -1;
    }

    // Pastikan benar-benar Disconnected sebelum start
    if (state != HubConnectionState.Disconnected) {
      print(
          "[ChatService] 🚫 Cannot start. State is $state (not Disconnected)");
      return -1;
    }

    print("[ChatService] Starting connection...");

    try {
      await _connection!.start();
      print("[ChatService] ✅ Connected (state=${_connection!.state})");
      return 1;
    } catch (e) {
      print("[ChatService] ❌ start() failed: $e");
      return -1;
    }
  }

  /// Pasang semua listener SignalR
  void _setupListeners() {
    if (_connection == null) return;
    print("[ChatService] _setupListeners");

    // ReceiveMessage: pesan umum / room
    _connection!.on("ReceiveMessage", (args) {
      print("Ada Pesan Baru");
      try {
        if (args == null || args.isEmpty) return;
        _handleReceiveMessage(args);
      } catch (e, st) {
        print("[ChatService] Error in ReceiveMessage handler: $e\n$st");
      }
    });

    // RoomCreated: notifikasi kalau ada room baru
    _connection!.on("RoomCreated", (args) {
      try {
        if (args == null || args.isEmpty) return;
        _handleRoomCreated(args);
      } catch (e, st) {
        print("[ChatService] Error in RoomCreated handler: $e\n$st");
      }
    });

    // onclose: auto reconnect logic (bersih-bersih dulu)
    _connection!.onclose(({error}) async {
      print("[ChatService] Connection closed: $error");
      _resetJoinState();
      // wait then try reconnect (connect() di caller bisa dipanggil ulang,
      // atau implement auto-reconnect custom di sini)
      await Future.delayed(const Duration(seconds: 2));
      // Jangan panggil start otomatis tanpa token; caller harus panggil connect kembali
      print("[ChatService] Connection closed handler finished");
    });
  }

  // -------------------------
  // SIGNALR: HANDLERS
  // -------------------------
  void _handleReceiveMessage(List<Object?> args) {
    print(args);
    try {
      final dynamic raw = args[0];
      final Map<String, Object?> msg = safeParse(raw);

      final roomId = msg["roomId"]?.toString() ?? "";
      final sender = msg["sender"]?.toString() ?? "";
      final text = msg["message"]?.toString() ?? "";
      final sentAt = msg["sentAt"] != null
          ? DateTime.tryParse(msg["sentAt"].toString())?.toLocal() ??
              DateTime.now()
          : DateTime.now();

      // Cache joined rooms supaya UI tahu kita pernah gabung room ini
      if (roomId.isNotEmpty && !_joinedRooms.contains(roomId)) {
        _joinedRooms.add(roomId);
        print("[ChatService] Added to _joinedRooms: $roomId");
      }

      print(
          "[ChatService] ReceiveMessage -> room:$roomId sender:$sender text:$text time:$sentAt");

      // Emit callbacks
      try {
        onMessageReceived?.call(sender, text, sentAt);
        onRoomMessageReceived?.call(roomId, sender, text, sentAt);
      } catch (cbErr) {
        print("[ChatService] Callback error onMessage/onRoomMessage: $cbErr");
      }
    } catch (e, st) {
      print("[ChatService] Error parsing ReceiveMessage: $e\n$st");
    }
  }

  void _handleRoomCreated(List<Object?> args) {
    try {
      final dynamic raw = args[0];
      Map<String, Object?> payload;
      if (raw is Map) {
        payload = raw.map((k, v) => MapEntry(k.toString(), v as Object?));
      } else {
        payload = safeParse(raw);
      }

      final roomId = payload["roomId"]?.toString() ?? "";
      final roomName = payload["roomName"]?.toString() ?? "";
      final createdAt = payload["createdAt"] != null
          ? DateTime.tryParse(payload["createdAt"].toString()) ?? DateTime.now()
          : DateTime.now();

      print(
          "[ChatService] RoomCreated -> roomId:$roomId roomName:$roomName createdAt:$createdAt");

      try {
        onRoomCreated?.call(roomId, roomName, createdAt);
        onNewRoomDetected?.call(roomId);
      } catch (cbErr) {
        print(
            "[ChatService] Callback error onRoomCreated/onNewRoomDetected: $cbErr");
      }
    } catch (e, st) {
      print("[ChatService] Error parsing RoomCreated: $e\n$st");
    }
  }

  // -------------------------
  // JOIN / LEAVE / SEND
  // -------------------------

  /// Join single room (via SignalR invoke "JoinRoom")
  Future<void> joinRoom(String roomId) async {
    try {
      if (_connection?.state == HubConnectionState.Connected &&
          !_joinedRooms.contains(roomId)) {
        print("[ChatService] joinRoom -> invoking JoinRoom for $roomId");
        await _connection!.invoke("JoinRoom", args: [roomId]);
        _joinedRooms.add(roomId);
        print("[ChatService] Joined room $roomId");
      } else {
        print(
            "[ChatService] joinRoom skipped (already joined or not connected)");
      }
    } catch (e, st) {
      print("[ChatService] joinRoom error: $e\n$st");
    }
  }

  /// Join multiple rooms (helper)
  Future<void> joinMultipleRooms(List<String> roomIds) async {
    for (final r in roomIds) {
      await joinRoom(r);
    }
  }

  /// Join private channel user (invoke "JoinUserChannel")
  Future<void> joinUserChannel(String userId) async {
    try {
      if (_connection?.state == HubConnectionState.Connected &&
          !_joinedUserChannels.contains(userId)) {
        await _connection!.invoke("JoinUserChannel", args: [userId]);
        _joinedUserChannels.add(userId);
        print("✅ [ChatService] Joined user channel user-$userId");
      } else {
        print(
            "✅[ChatService] joinUserChannel skipped (already joined or not connected)");
      }
    } catch (e, st) {
      print("[ChatService] joinUserChannel error: $e\n$st");
    }
  }

  /// Send message: sebenarnya mengirim via REST API (backend yang akan broadcast via SignalR)
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

    print(
        "[ChatService] sendMessage -> room:$roomId sender:$senderUserId text:$message");

    try {
      final response = await _client.post(
        '/$controller/create',
        body: jsonEncode(payload),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        print(
            "[ChatService] sendMessage -> API responded ${response.statusCode}: ${response.body}");
        throw Exception('Gagal mengirim pesan ke room $roomId');
      }
      if (_connection?.state == HubConnectionState.Connected) {
        await _connection!
            .invoke("SendMessageToRoom", args: [roomId, senderUserId, message]);
        print("================ [SignalR] Sent message to $roomId: $message");

        print("[API] ✅ Pesan terkirim ke $roomId: $message");
      }
    } catch (e, st) {
      print("[ChatService] sendMessage error: $e\n$st");
      rethrow;
    }
  }

  /// Disconnect (stop HubConnection & clear caches)
  Future<void> disconnect() async {
    try {
      if (_connection != null &&
          _connection!.state == HubConnectionState.Connected) {
        print("[ChatService] disconnect -> stopping connection");
        await _connection!.stop();
        print("[ChatService] Disconnected");
      }
    } catch (e, st) {
      print("[ChatService] disconnect error: $e\n$st");
    } finally {
      _connection = null;
      _joinedRooms.clear();
      _joinedUserChannels.clear();
      _lastConnectedUserId = "";
      print("[ChatService] disconnect -> cleaned internal state");
    }
  }

  void _resetJoinState() {
    _joinedRooms.clear();
    _joinedUserChannels.clear();
    _lastConnectedUserId = "";
    print("[ChatService] _resetJoinState executed");
  }

  // -------------------------
  // API: fetch rooms / messages / post chat
  // -------------------------

  /// Fetch rooms for a user. Returns empty list on error.
  Future<List<RoomChatModel>> fetchRoomsForUser(
    String userId, {
    String? roomId,
    String? idLawan,
  }) async {
    debugPrint('[ChatService] fetchRoomsForUser user: $userId');

    try {
      final queryParams = <String, dynamic>{
        'user_id': userId,
        if (idLawan != null && idLawan.isNotEmpty) 'id_lawan': idLawan,
        if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
      };

      final response = await _client.get(
        '/$controller/getRooms',
        queryParameters: queryParams,
      );

      if (response.statusCode != 200) {
        debugPrint(
            '[ChatService] fetchRoomsForUser status ${response.statusCode}');
        debugPrint('[ChatService] body: ${response.body}');
        return [];
      }

      final body = jsonDecode(response.body);

      if (body is! Map<String, dynamic>) {
        debugPrint(
            "[ChatService] fetchRoomsForUser unexpected body type: ${body.runtimeType}");
        return [];
      }

      final raw = body['Data'] ?? [];
      if (raw is! List) {
        debugPrint(
            "[ChatService] fetchRoomsForUser Data is not List: ${raw.runtimeType}");
        return [];
      }

      final rooms = raw
          .map((e) {
            if (e is Map<String, dynamic>) {
              return RoomChatModel.fromJson(e);
            }
            debugPrint("[ChatService] fetchRoomsForUser skipped item: $e");
            return null;
          })
          .whereType<RoomChatModel>()
          .toList();

      debugPrint(
          '[ChatService] fetchRoomsForUser => found ${rooms.length} rooms');
      return rooms;
    } catch (e, st) {
      debugPrint('[ChatService] fetchRoomsForUser error: $e');
      debugPrintStack(stackTrace: st);
      return [];
    }
  }

  /// Fetch messages for a room (history)
  Future<List<ChatModel>> fetchMessagesForRoom(String roomId) async {
    print("[ChatService] fetchMessagesForRoom -> roomId: $roomId");
    try {
      final response = await _client.get(
        '/$controller/getAll',
        queryParameters: {'room_id': roomId},
      );

      if (response.statusCode != 200) {
        print(
            "[ChatService] fetchMessagesForRoom -> non-200: ${response.statusCode}");
        return [];
      }

      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> data = json['Data'] ?? [];

      final messages = data
          .map((item) {
            if (item is Map<String, dynamic>) {
              return ChatModel.fromJson(item);
            }
            return null;
          })
          .whereType<ChatModel>()
          .toList();

      print(
          "[ChatService] fetchMessagesForRoom -> loaded ${messages.length} messages");
      return messages;
    } catch (e, st) {
      print("[ChatService] fetchMessagesForRoom error: $e\n$st");
      return [];
    }
  }

  /// Post chat via API (helper, returns boolean)
  Future<bool> postChat(Map<String, dynamic> payload) async {
    try {
      final response = await _client.post(
        '/$controller/create',
        body: jsonEncode(payload),
        headers: {'Content-Type': 'application/json'},
      );
      print("[ChatService] postChat -> status ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e, st) {
      print("[ChatService] postChat error: $e\n$st");
      return false;
    }
  }
}
