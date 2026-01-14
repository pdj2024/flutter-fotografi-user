import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';

/// Konfigurasi untuk ChatService
class ChatServiceConfig {
  final String hubUrl;
  final String role; // 'customer' atau 'vendor'
  final Future<String?> Function() getToken;
  final int requestTimeout;
  final List<int> retryDelays;

  const ChatServiceConfig({
    required this.hubUrl,
    required this.role,
    required this.getToken,
    this.requestTimeout = 15000,
    this.retryDelays = const [1000, 2000, 5000, 10000, 30000],
  });
}

/// Service untuk koneksi SignalR chat
class ChatService {
  final String controller = 'chat';
  HubConnection? _connection;
  ChatServiceConfig? _config;
  String _currentUserId = '';
  bool _isConnecting = false;

  // Tracking joined rooms/channels
  final Set<String> _joinedRooms = {};
  final Set<String> _joinedUserChannels = {};

  // =========================================
  // CALLBACKS
  // =========================================

  /// Callback ketika menerima pesan baru
  Function(ChatModel message)? onMessageReceived;

  /// Callback ketika room baru dibuat
  Function(String roomId, String roomName, DateTime createdAt)? onRoomCreated;

  /// Callback ketika status koneksi berubah
  Function(bool isConnected, String? error)? onConnectionChanged;

  /// Callback ketika reconnect berhasil (untuk rejoin rooms)
  Function()? onReconnected;

  // =========================================
  // GETTERS
  // =========================================

  bool get isConnected => _connection?.state == HubConnectionState.Connected;
  bool get isConnecting => _isConnecting;
  String get currentUserId => _currentUserId;
  Set<String> get joinedRooms => Set.unmodifiable(_joinedRooms);

  // =========================================
  // CONNECTION
  // =========================================

  /// Connect ke SignalR hub
  Future<bool> connect({
    required ChatServiceConfig config,
    required String userId,
  }) async {
    if (_isConnecting) {
      debugPrint('[ChatService] ⏸️ Already connecting, skip');
      return false;
    }

    if (isConnected && _currentUserId == userId) {
      debugPrint('[ChatService] ✅ Already connected for user $userId');
      return true;
    }

    _isConnecting = true;
    _config = config;
    _currentUserId = userId;

    try {
      // Get token
      final token = await config.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[ChatService] ❌ No token available');
        return false;
      }

      // Disconnect existing if any
      if (_connection != null) {
        await disconnect();
      }

      // Build connection
      debugPrint('[ChatService] 🔧 Building connection (role=${config.role})');

      _connection = HubConnectionBuilder()
          .withUrl(
            '${config.hubUrl}?role=${config.role}',
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token,
              requestTimeout: config.requestTimeout,
            ),
          )
          .withAutomaticReconnect(retryDelays: config.retryDelays)
          .build();

      // Setup listeners
      _setupListeners();

      // Start connection
      await _connection!.start();

      debugPrint('[ChatService] ✅ Connected successfully');
      onConnectionChanged?.call(true, null);

      // Auto join user channel
      await joinUserChannel(userId);

      return true;
    } catch (e, st) {
      debugPrint('[ChatService] ❌ Connection failed: $e\n$st');
      onConnectionChanged?.call(false, e.toString());
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  /// Disconnect dari SignalR
  Future<void> disconnect() async {
    try {
      if (_connection != null) {
        await _connection!.stop();
        debugPrint('[ChatService] 🔌 Disconnected');
      }
    } catch (e) {
      debugPrint('[ChatService] ❌ Disconnect error: $e');
    } finally {
      _connection = null;
      _resetJoinState();
      onConnectionChanged?.call(false, null);
    }
  }

  void _resetJoinState() {
    _joinedRooms.clear();
    _joinedUserChannels.clear();
  }

  // =========================================
  // LISTENERS SETUP
  // =========================================

  void _setupListeners() {
    if (_connection == null) return;

    // ✅ LISTENER: Pesan baru
    _connection!.on('ReceiveMessage', (args) {
      debugPrint('[ChatService] 📨 ReceiveMessage => $args');
      if (args == null || args.isEmpty) return;
      _handleReceiveMessage(args);
    });

    // ✅ LISTENER: Room baru
    _connection!.on('RoomCreated', (args) {
      debugPrint('[ChatService] 🆕 RoomCreated => $args');
      if (args == null || args.isEmpty) return;
      _handleRoomCreated(args);
    });

    // Connection lifecycle
    _connection!.onclose(({error}) {
      debugPrint('[ChatService] 🔌 Connection closed: $error');
      onConnectionChanged?.call(false, error?.toString());
    });

    _connection!.onreconnecting(({error}) {
      debugPrint('[ChatService] 🔄 Reconnecting: $error');
      onConnectionChanged?.call(false, 'reconnecting');
    });

    _connection!.onreconnected(({connectionId}) async {
      debugPrint('[ChatService] ✅ Reconnected: $connectionId');
      onConnectionChanged?.call(true, null);
      await _rejoinAfterReconnect();
      onReconnected?.call();
    });
  }

  // =========================================
  // EVENT HANDLERS
  // =========================================

  void _handleReceiveMessage(List<Object?> args) {
    try {
      final raw = args[0];
      final data = _parseData(raw);

      debugPrint('[ChatService] 📦 Parsed message: $data');

      final message = ChatModel.fromSignalR(data, _currentUserId);
      onMessageReceived?.call(message);
    } catch (e, st) {
      debugPrint('[ChatService] ❌ Parse ReceiveMessage error: $e\n$st');
    }
  }

  void _handleRoomCreated(List<Object?> args) {
    try {
      final raw = args[0];
      final data = _parseData(raw);

      final roomId = data['roomId']?.toString() ?? '';
      final roomName = data['roomName']?.toString() ?? '';
      final createdAt = _parseDateTime(data['createdAt']);

      debugPrint('[ChatService] 🆕 Room: $roomId ($roomName)');
      onRoomCreated?.call(roomId, roomName, createdAt);
    } catch (e, st) {
      debugPrint('[ChatService] ❌ Parse RoomCreated error: $e\n$st');
    }
  }

  // =========================================
  // ROOM MANAGEMENT
  // =========================================

  /// Join room
  Future<bool> joinRoom(String roomId) async {
    if (!isConnected) {
      debugPrint('[ChatService] ⚠️ Cannot join: not connected');
      return false;
    }

    if (roomId.isEmpty) return false;

    if (_joinedRooms.contains(roomId)) {
      debugPrint('[ChatService] ℹ️ Already in room: $roomId');
      return true;
    }

    try {
      await _connection!.invoke('JoinRoom', args: [roomId]);
      _joinedRooms.add(roomId);
      debugPrint('[ChatService] ✅ Joined room: $roomId');
      return true;
    } catch (e) {
      debugPrint('[ChatService] ❌ Join room error: $e');
      return false;
    }
  }

  /// Join multiple rooms
  Future<void> joinRooms(List<String> roomIds) async {
    for (final roomId in roomIds) {
      if (roomId.isNotEmpty) {
        await joinRoom(roomId);
      }
    }
  }

  /// Leave room
  Future<void> leaveRoom(String roomId) async {
    if (!isConnected) return;

    try {
      await _connection!.invoke('LeaveRoom', args: [roomId]);
      _joinedRooms.remove(roomId);
      debugPrint('[ChatService] 👋 Left room: $roomId');
    } catch (e) {
      debugPrint('[ChatService] ❌ Leave room error: $e');
    }
  }

  /// Join user channel
  Future<bool> joinUserChannel(String userId) async {
    if (!isConnected) return false;
    if (_joinedUserChannels.contains(userId)) return true;

    try {
      await _connection!.invoke('JoinUserChannel', args: [userId]);
      _joinedUserChannels.add(userId);
      debugPrint('[ChatService] ✅ Joined user channel: $userId');
      return true;
    } catch (e) {
      debugPrint('[ChatService] ❌ Join user channel error: $e');
      return false;
    }
  }

  /// Rejoin setelah reconnect
  Future<void> _rejoinAfterReconnect() async {
    debugPrint('[ChatService] 🔄 Rejoining ${_joinedRooms.length} rooms...');

    final rooms = List<String>.from(_joinedRooms);
    final channels = List<String>.from(_joinedUserChannels);

    _joinedRooms.clear();
    _joinedUserChannels.clear();

    for (final roomId in rooms) {
      await joinRoom(roomId);
    }

    for (final channel in channels) {
      await joinUserChannel(channel);
    }
  }

  // =========================================
  // SEND ACTIONS (via SignalR)
  // =========================================

  /// Send typing indicator
  Future<void> sendTyping(String roomId) async {
    if (!isConnected) return;

    try {
      await _connection!.invoke('SendTyping', args: [roomId, _currentUserId]);
    } catch (e) {
      debugPrint('[ChatService] ❌ Send typing error: $e');
    }
  }

  // =========================================
  // UTILITIES
  // =========================================

  Map<String, dynamic> _parseData(dynamic obj) {
    if (obj is Map) {
      return obj.map((k, v) => MapEntry(k.toString(), v));
    }
    if (obj is String) {
      try {
        final decoded = jsonDecode(obj);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } catch (_) {}
    }
    return {};
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value.toLocal();
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Dispose
  void dispose() {
    _connection?.stop();
    _connection = null;
    _resetJoinState();
  }
}
