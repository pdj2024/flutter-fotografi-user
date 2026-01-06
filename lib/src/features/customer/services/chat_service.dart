import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/paket_model.dart';
import 'package:mpjnew/src/data/models/penawaran_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/services/penawaran_service.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';

class ChatService {
  final String controller = 'chat';
  final ApiClient _client = apiClient;
  bool _isConnecting = false;

  final String hubUrl = "${Constants.baseUrlHub}/api/chathub";

  HubConnection? _connection;
  final List<String> _joinedRooms = [];
  final Set<String> _joinedUserChannels = {};
  String _lastConnectedUserId = "";

  // ✅ UPDATED CALLBACKS - Sesuai dengan data SignalR
  Function(ChatModel chat)? onFullMessageReceived;
  Function(String roomId, ChatModel chat)? onRoomMessageReceived;
  Function(String roomId)? onNewRoomDetected;
  Function(String roomId, String roomName, DateTime createdAt)? onRoomCreated;
  Function(PaketModel paket)? onPaketDataReceived;
  Function(PenawaranModel penawaran)? onPenawaranDataReceived;

  bool get isConnected => _connection?.state == HubConnectionState.Connected;
  HubConnection? get connection => _connection;

  final PaketService _paketService = PaketService();
  final PenawaranService _penawaranService = PenawaranService();

  // =========================================
  // CONNECT
  // =========================================
  Future<int> connect(String currentUserId, ApiClient apiClient) async {
    debugPrint("[ChatService] 🔌 Connecting for userId: $currentUserId");

    if (_isConnecting) {
      debugPrint("[ChatService] ⏸️ Already connecting, skip");
      return -1;
    }

    try {
      _isConnecting = true;

      final token = await apiClient.getIdToken();
      final role = apiClient.getRole() ?? 'customer';

      if (token == null || token.isEmpty) {
        debugPrint("[ChatService] ❌ No token available");
        return -1;
      }

      await _ensureConnectionInitialized(token, role, currentUserId);
      final startResult = await _startConnectionIfNeeded();

      if (startResult == -1) {
        debugPrint("[ChatService] ❌ Failed to start connection");
        return -1;
      }

      if (currentUserId != _lastConnectedUserId ||
          !_joinedUserChannels.contains(currentUserId)) {
        await joinUserChannel(currentUserId);
        _lastConnectedUserId = currentUserId;
      }

      debugPrint("[ChatService] ✅ Connected successfully");
      return 99;
    } catch (e, st) {
      debugPrint("[ChatService] ❌ Connect error: $e\n$st");
      return -1;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _ensureConnectionInitialized(
    String token,
    String role,
    String currentUserId,
  ) async {
    if (_connection != null) return;

    debugPrint("[ChatService] 🔧 Initializing HubConnection (role=$role)");

    _connection = HubConnectionBuilder()
        .withUrl(
      '$hubUrl?role=$role',
      options: HttpConnectionOptions(
        accessTokenFactory: () async => token,
        requestTimeout: 15000,
      ),
    )
        .withAutomaticReconnect(
      retryDelays: const [1000, 2000, 5000, 10000],
    ).build();

    _setupListeners(currentUserId);
  }

  Future<int> _startConnectionIfNeeded() async {
    if (_connection == null) return -1;

    final state = _connection!.state;

    if (state == HubConnectionState.Connected) {
      debugPrint("[ChatService] ✅ Already connected");
      return 1;
    }

    if (state == HubConnectionState.Connecting ||
        state == HubConnectionState.Reconnecting) {
      debugPrint("[ChatService] ⏳ Connection busy ($state)");
      return -1;
    }

    if (state != HubConnectionState.Disconnected) {
      debugPrint("[ChatService] ⚠️ Invalid state: $state");
      return -1;
    }

    try {
      await _connection!.start();
      debugPrint("[ChatService] ✅ Started connection");
      return 1;
    } catch (e) {
      debugPrint("[ChatService] ❌ Start failed: $e");
      return -1;
    }
  }

  void _setupListeners(String currentUserId) {
    if (_connection == null) return;

    // ✅ LISTENER untuk pesan baru
    _connection!.on("ReceiveMessage", (args) {
      debugPrint("📨 ReceiveMessage event fired => $args");
      if (args == null || args.isEmpty) return;
      _handleReceiveMessage(args, currentUserId);
    });

    // ✅ LISTENER untuk room baru
    _connection!.on("RoomCreated", (args) {
      debugPrint("🆕 RoomCreated event fired => $args");
      if (args == null || args.isEmpty) return;
      _handleRoomCreated(args);
    });

    _connection!.onclose(({error}) async {
      debugPrint("[ChatService] 🔌 Connection closed: $error");
      _resetJoinState();
    });

    _connection!.onreconnecting(({error}) {
      debugPrint("[ChatService] 🔄 Reconnecting: $error");
    });

    _connection!.onreconnected(({connectionId}) async {
      debugPrint("[ChatService] ✅ Reconnected: $connectionId");

      // Re-join semua room yang sebelumnya joined
      final roomsToRejoin = List<String>.from(_joinedRooms);
      _joinedRooms.clear();

      for (final roomId in roomsToRejoin) {
        await joinRoom(roomId);
      }

      // Re-join user channel
      if (_lastConnectedUserId.isNotEmpty) {
        _joinedUserChannels.clear();
        await joinUserChannel(_lastConnectedUserId);
      }
    });
  }

  // =========================================
  // ✅ HANDLERS - UPDATED UNTUK LANGSUNG FETCH DATA
  // =========================================
  void _handleReceiveMessage(List<Object?> args, String currentUserId) {
    try {
      final raw = args[0];
      final msg = _safeParse(raw);

      debugPrint("[ChatService] 📦 Raw message data: $msg");

      // ✅ Parse SEMUA field yang dikirim SignalR
      final messageId = msg["messageId"]?.toString() ?? "";
      final roomId = msg["roomId"]?.toString() ?? "";
      final senderId = msg["senderId"]?.toString() ?? "";
      final text = msg["message"]?.toString() ?? "";
      final sentAt = _parseDateTime(msg["sentAt"]);
      final editedAt =
          msg["editedAt"] != null ? _parseDateTime(msg["editedAt"]) : null;
      final tipeUser = msg["tipeUser"]?.toString() ?? "";
      final noInvoice = msg["noPesanan"]?.toString() ?? "";
      final noPenawaran = msg["noPenawaran"]?.toString() ?? "";
      final idPaket = msg["idPaket"]?.toString() ?? "";
      final status = msg["status"]?.toString() ?? "";
      final jenisPesan = msg["jenisPesan"]?.toString() ?? "";
      final sendStatus = msg["sendStatus"]?.toString() ?? "";

      // ✅ Buat ChatModel lengkap
      final chatModel = ChatModel(
        messageId: messageId,
        roomId: roomId,
        senderId: senderId,
        message: text,
        sentAt: sentAt,
        editedAt: editedAt,
        tipeUser: tipeUser,
        noInvoice: noInvoice.isEmpty ? null : noInvoice,
        noPenawaran: noPenawaran.isEmpty ? null : noPenawaran,
        idPaket: idPaket.isEmpty ? null : idPaket,
        status: status,
        jenisPesan: jenisPesan,
        userIds: [senderId, currentUserId],
        sendStatus: 'receive',
        roomType: 'direct',
      );

      // ✅ Trigger callback untuk pesan
      onFullMessageReceived?.call(chatModel);
      onRoomMessageReceived?.call(roomId, chatModel);

      // ✅ LANGSUNG FETCH DATA JIKA ADA IDPAKET ATAU NOINVOICE
      if (idPaket.isNotEmpty) {
        _fetchPaketData(idPaket);
      }

      if (noPenawaran.isNotEmpty) {
        _fetchPenawaranData(noPenawaran);
      }
    } catch (e, st) {
      debugPrint("[ChatService] ❌ Parse message error: $e\n$st");
    }
  }

  // =========================================
  // ✅ METHOD UNTUK FETCH DATA PAKET
  // =========================================
  Future<void> _fetchPaketData(String idPaket) async {
    try {
      debugPrint("[ChatService] 📦 Fetching paket data for id: $idPaket");

      final paket = await _paketService.getAll(noId: idPaket, status: 'aktif');

      if (paket != null) {
        debugPrint(
            "[ChatService] ✅ Paket data received: ${paket.first.nama_paket}");
        onPaketDataReceived?.call(paket.first);
      } else {
        debugPrint("[ChatService] ⚠️ Paket not found for id: $idPaket");
      }
    } catch (e, st) {
      debugPrint("[ChatService] ❌ Error fetching paket: $e\n$st");
    }
  }

  // =========================================
  // ✅ METHOD UNTUK FETCH DATA PENAWARAN
  // =========================================
  Future<void> _fetchPenawaranData(String noPenawaran) async {
    try {
      debugPrint(
          "[ChatService] 📄 Fetching penawaran data for no: $noPenawaran");

      final penawaran = await _penawaranService.getAll(noId: noPenawaran, status: 'aktif');

      if (penawaran != null) {
        debugPrint(
            "[ChatService] ✅ Penawaran data received: ${penawaran.first.noTrackingPenawaran}");
        onPenawaranDataReceived?.call(penawaran.first);
      } else {
        debugPrint("[ChatService] ⚠️ Penawaran not found for no: $noPenawaran");
      }
    } catch (e, st) {
      debugPrint("[ChatService] ❌ Error fetching penawaran: $e\n$st");
    }
  }

  void _handleRoomCreated(List<Object?> args) {
    try {
      final raw = args[0];
      final payload = _safeParse(raw);

      final roomId = payload["roomId"]?.toString() ?? "";
      final roomName = payload["roomName"]?.toString() ?? "";
      final createdAt = _parseDateTime(payload["createdAt"]);

      debugPrint("[ChatService] 🆕 Room created: $roomId ($roomName)");

      onRoomCreated?.call(roomId, roomName, createdAt);
      onNewRoomDetected?.call(roomId);
    } catch (e, st) {
      debugPrint("[ChatService] ❌ Parse RoomCreated error: $e\n$st");
    }
  }

  // =========================================
  // SEND MESSAGE
  // =========================================
  Future<void> sendMessage({
    required ChatModel chat,
  }) async {
    debugPrint("[ChatService] 📤 Sending message to room: ${chat.roomId}");

    final payload = {
      "chat": chat.toJson(),
      "room_id": chat.roomId,
      "user_ids": chat.userIds,
    };

    try {
      final response = await _client.post(
        '/$controller/create',
        body: jsonEncode(payload),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception("API failed: ${response.statusCode}");
      }

      debugPrint("[ChatService] ✅ Message saved via API");

      // ✅ PostgreSQL trigger akan otomatis broadcast via SignalR
      // Tidak perlu manual invoke SignalR di sini
    } catch (e, st) {
      debugPrint("❌ ChatService sendMessage error: $e\n$st");
      rethrow;
    }
  }

  // =========================================
  // JOIN / LEAVE
  // =========================================
  Future<void> joinRoom(String roomId) async {
    if (_connection?.state != HubConnectionState.Connected) {
      debugPrint("[ChatService] ⚠️ Cannot join room: not connected");
      return;
    }

    if (_joinedRooms.contains(roomId)) {
      debugPrint("[ChatService] ℹ️ Already joined room: $roomId");
      return;
    }

    try {
      await _connection!.invoke("JoinRoom", args: [roomId]);
      _joinedRooms.add(roomId);
      debugPrint("[ChatService] ✅ Joined room: $roomId");
    } catch (e, st) {
      debugPrint("[ChatService] ❌ Join room error: $e\n$st");
    }
  }

  Future<void> joinMultipleRooms(List<String> roomIds) async {
    for (final roomId in roomIds) {
      await joinRoom(roomId);
    }
  }

  Future<void> leaveRoom(String roomId) async {
    if (_connection?.state != HubConnectionState.Connected) return;

    try {
      await _connection!.invoke("LeaveRoom", args: [roomId]);
      _joinedRooms.remove(roomId);
      debugPrint("[ChatService] 👋 Left room: $roomId");
    } catch (e, st) {
      debugPrint("[ChatService] ❌ Leave room error: $e\n$st");
    }
  }

  Future<void> joinUserChannel(String userId) async {
    if (_connection?.state != HubConnectionState.Connected) return;
    if (_joinedUserChannels.contains(userId)) return;

    try {
      await _connection!.invoke("JoinUserChannel", args: [userId]);
      _joinedUserChannels.add(userId);
      debugPrint("[ChatService] ✅ Joined user channel: $userId");
    } catch (e, st) {
      debugPrint("[ChatService] ❌ Join user channel error: $e\n$st");
    }
  }

  // =========================================
  // API METHODS
  // =========================================
  Future<List<RoomChatModel>> fetchRoomsForUser(
    String userId, {
    String? roomId,
    String? idLawan,
  }) async {
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

      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body);
      final raw = body['Data'] ?? [];

      if (raw is! List) return [];

      final rooms = raw
          .map((e) =>
              e is Map<String, dynamic> ? RoomChatModel.fromJson(e) : null)
          .whereType<RoomChatModel>()
          .toList();

      debugPrint('[ChatService] 📥 Fetched ${rooms.length} rooms');
      return rooms;
    } catch (e, st) {
      debugPrint('[ChatService] ❌ fetchRooms error: $e\n$st');
      return [];
    }
  }

  Future<List<ChatModel>> fetchMessagesForRoom(String roomId) async {
    try {
      final response = await _client.get(
        '/$controller/getAll',
        queryParameters: {'room_id': roomId, 'status': "aktif"},
      );

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['Data'] as List<dynamic>? ?? [];

      final messages = data
          .map((item) =>
              item is Map<String, dynamic> ? ChatModel.fromJson(item) : null)
          .whereType<ChatModel>()
          .toList();

      debugPrint('[ChatService] 📥 Fetched ${messages.length} messages');
      return messages;
    } catch (e, st) {
      debugPrint('[ChatService] ❌ fetchMessages error: $e\n$st');
      return [];
    }
  }

  Future<bool> updateMessageStatus(String messageId, String status) async {
    try {
      final response = await _client.put(
        '/$controller/update-send-status/$messageId',
        body: jsonEncode({'send_status': status}),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ChatService] ❌ updateStatus error: $e');
      return false;
    }
  }

  // =========================================
  // DISCONNECT
  // =========================================
  Future<void> disconnect() async {
    try {
      if (_connection?.state == HubConnectionState.Connected) {
        await _connection!.stop();
        debugPrint("[ChatService] 🔌 Disconnected");
      }
    } catch (e) {
      debugPrint("[ChatService] ❌ Disconnect error: $e");
    } finally {
      _connection = null;
      _resetJoinState();
    }
  }

  void _resetJoinState() {
    _joinedRooms.clear();
    _joinedUserChannels.clear();
    _lastConnectedUserId = "";
  }

  // =========================================
  // UTILITIES
  // =========================================
  Map<String, Object?> _safeParse(dynamic obj) {
    if (obj is Map) {
      return obj.map((k, v) => MapEntry(k.toString(), v as Object?));
    }
    if (obj is String) {
      try {
        final decoded = jsonDecode(obj);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v as Object?));
        }
      } catch (e) {
        debugPrint("[ChatService] ⚠️ Failed to parse string as JSON: $e");
      }
    }
    throw Exception("Unsupported type: ${obj.runtimeType}");
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value.toLocal();

    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (e) {
      debugPrint("[ChatService] ⚠️ Failed to parse date: $value");
      return DateTime.now();
    }
  }

  // =========================================
  // GETTERS
  // =========================================
  List<String> get joinedRooms => List.unmodifiable(_joinedRooms);
  Set<String> get joinedUserChannels => Set.unmodifiable(_joinedUserChannels);
  String get lastConnectedUserId => _lastConnectedUserId;
}
