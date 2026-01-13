// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:mpjnew/src/data/models/chat_model.dart';
// import 'package:mpjnew/src/data/models/room_chat_model.dart';
// import 'package:mpjnew/src/features/customer/view/chat/data/message_status.dart';
// import 'package:signalr_netcore/http_connection_options.dart';
// import 'package:signalr_netcore/hub_connection.dart';
// import 'package:signalr_netcore/hub_connection_builder.dart';
// import 'dart:convert';

// /// Konfigurasi SignalR
// class SignalRConfig {
//   final String hubUrl;
//   final String role; // 'customer' atau 'vendor'
//   final Future<String?> Function() tokenFactory;
//   final int requestTimeout;
//   final List<int> retryDelays;

//   const SignalRConfig({
//     required this.hubUrl,
//     required this.role,
//     required this.tokenFactory,
//     this.requestTimeout = 15000,
//     this.retryDelays = const [1000, 2000, 5000, 10000, 30000],
//   });
// }

// /// Event types dari SignalR
// enum SignalREventType {
//   messageReceived,
//   messageStatusUpdated,
//   roomCreated,
//   roomUpdated,
//   userTyping,
//   userOnline,
//   userOffline,
//   connected,
//   disconnected,
//   reconnecting,
//   reconnected,
//   error,
// }

// /// Event data dari SignalR
// class SignalREvent {
//   final SignalREventType type;
//   final dynamic data;
//   final String? roomId;
//   final String? errorMessage;

//   SignalREvent({
//     required this.type,
//     this.data,
//     this.roomId,
//     this.errorMessage,
//   });
// }

// /// Service untuk koneksi SignalR real-time
// class SignalRService {
//   HubConnection? _connection;
//   SignalRConfig? _config;
//   String? _currentUserId;
  
//   // Connection state
//   bool _isConnecting = false;
//   bool _isInitialized = false;
  
//   // Joined rooms/channels tracking
//   final Set<String> _joinedRooms = {};
//   final Set<String> _joinedUserChannels = {};
  
//   // Stream controller untuk events
//   final _eventController = StreamController<SignalREvent>.broadcast();
  
//   // Callbacks (alternatif dari streams)
//   Function(ChatMessageModel message)? onMessageReceived;
//   Function(String roomId, String messageId, MessageStatus status)? onMessageStatusUpdated;
//   Function(ChatRoomModel room)? onRoomCreated;
//   Function(String roomId, String userId)? onUserTyping;
//   Function(String userId, bool isOnline)? onUserPresenceChanged;
//   Function(String? error)? onConnectionStateChanged;

//   // Getters
//   bool get isConnected => _connection?.state == HubConnectionState.Connected;
//   bool get isConnecting => _isConnecting;
//   bool get isInitialized => _isInitialized;
//   Stream<SignalREvent> get eventStream => _eventController.stream;
//   Set<String> get joinedRooms => Set.unmodifiable(_joinedRooms);
//   String? get currentUserId => _currentUserId;

//   // =========================================
//   // CONNECTION MANAGEMENT
//   // =========================================

//   /// Initialize dan connect ke SignalR hub
//   Future<bool> connect({
//     required SignalRConfig config,
//     required String userId,
//   }) async {
//     if (_isConnecting) {
//       debugPrint('[SignalR] Already connecting, skipping...');
//       return false;
//     }

//     if (isConnected && _currentUserId == userId) {
//       debugPrint('[SignalR] Already connected for user $userId');
//       return true;
//     }

//     _isConnecting = true;
//     _config = config;
//     _currentUserId = userId;

//     try {
//       // Get token
//       final token = await config.tokenFactory();
//       if (token == null || token.isEmpty) {
//         debugPrint('[SignalR] ❌ No token available');
//         return false;
//       }

//       // Disconnect existing connection if any
//       if (_connection != null) {
//         await disconnect();
//       }

//       // Build connection
//       _connection = HubConnectionBuilder()
//           .withUrl(
//             '${config.hubUrl}?role=${config.role}',
//             options: HttpConnectionOptions(
//               accessTokenFactory: () async => token,
//               requestTimeout: config.requestTimeout,
//             ),
//           )
//           .withAutomaticReconnect(retryDelays: config.retryDelays)
//           .build();

//       // Setup listeners
//       _setupEventListeners();

//       // Start connection
//       await _connection!.start();
//       _isInitialized = true;

//       debugPrint('[SignalR] ✅ Connected successfully for user $userId');
//       _emitEvent(SignalREvent(type: SignalREventType.connected));
//       onConnectionStateChanged?.call(null);

//       // Auto join user channel
//       await joinUserChannel(userId);

//       return true;
//     } catch (e, st) {
//       debugPrint('[SignalR] ❌ Connection failed: $e\n$st');
//       _emitEvent(SignalREvent(
//         type: SignalREventType.error,
//         errorMessage: e.toString(),
//       ));
//       onConnectionStateChanged?.call(e.toString());
//       return false;
//     } finally {
//       _isConnecting = false;
//     }
//   }

//   /// Disconnect dari SignalR
//   Future<void> disconnect() async {
//     try {
//       if (_connection != null) {
//         await _connection!.stop();
//         debugPrint('[SignalR] 🔌 Disconnected');
//       }
//     } catch (e) {
//       debugPrint('[SignalR] ❌ Disconnect error: $e');
//     } finally {
//       _connection = null;
//       _isInitialized = false;
//       _resetJoinState();
//       _emitEvent(SignalREvent(type: SignalREventType.disconnected));
//       onConnectionStateChanged?.call('disconnected');
//     }
//   }

//   void _resetJoinState() {
//     _joinedRooms.clear();
//     _joinedUserChannels.clear();
//   }

//   // =========================================
//   // EVENT LISTENERS SETUP
//   // =========================================

//   void _setupEventListeners() {
//     if (_connection == null) return;

//     // ✅ Receive new message
//     _connection!.on('ReceiveMessage', _handleReceiveMessage);

//     // ✅ Message status updated
//     _connection!.on('MessageStatusUpdated', _handleMessageStatusUpdated);

//     // ✅ Room created
//     _connection!.on('RoomCreated', _handleRoomCreated);

//     // ✅ Room updated
//     _connection!.on('RoomUpdated', _handleRoomUpdated);

//     // ✅ User typing indicator
//     _connection!.on('UserTyping', _handleUserTyping);

//     // ✅ User presence (online/offline)
//     _connection!.on('UserPresenceChanged', _handleUserPresence);

//     // ✅ Messages read (batch)
//     _connection!.on('MessagesRead', _handleMessagesRead);

//     // Connection lifecycle
//     _connection!.onclose(({error}) async {
//       debugPrint('[SignalR] 🔌 Connection closed: $error');
//       _emitEvent(SignalREvent(
//         type: SignalREventType.disconnected,
//         errorMessage: error?.toString(),
//       ));
//       onConnectionStateChanged?.call('closed: $error');
//     });

//     _connection!.onreconnecting(({error}) {
//       debugPrint('[SignalR] 🔄 Reconnecting: $error');
//       _emitEvent(SignalREvent(type: SignalREventType.reconnecting));
//       onConnectionStateChanged?.call('reconnecting');
//     });

//     _connection!.onreconnected(({connectionId}) async {
//       debugPrint('[SignalR] ✅ Reconnected: $connectionId');
//       _emitEvent(SignalREvent(type: SignalREventType.reconnected));
//       onConnectionStateChanged?.call(null);
//       await _rejoinAfterReconnect();
//     });
//   }

//   // =========================================
//   // EVENT HANDLERS
//   // =========================================

//   void _handleReceiveMessage(List<Object?>? args) {
//     if (args == null || args.isEmpty) return;

//     try {
//       final data = _parseEventData(args[0]);
//       debugPrint('[SignalR] 📨 ReceiveMessage: $data');

//       final message = ChatMessageModel.fromJson(data);
      
//       _emitEvent(SignalREvent(
//         type: SignalREventType.messageReceived,
//         data: message,
//         roomId: message.roomId,
//       ));
      
//       onMessageReceived?.call(message);
//     } catch (e, st) {
//       debugPrint('[SignalR] ❌ Parse ReceiveMessage error: $e\n$st');
//     }
//   }

//   void _handleMessageStatusUpdated(List<Object?>? args) {
//     if (args == null || args.isEmpty) return;

//     try {
//       final data = _parseEventData(args[0]);
//       debugPrint('[SignalR] 📬 MessageStatusUpdated: $data');

//       final roomId = data['roomId']?.toString() ?? data['room_id']?.toString() ?? '';
//       final messageId = data['messageId']?.toString() ?? data['message_id']?.toString() ?? '';
//       final status = MessageStatus.fromString(data['status']?.toString());

//       _emitEvent(SignalREvent(
//         type: SignalREventType.messageStatusUpdated,
//         data: {'messageId': messageId, 'status': status},
//         roomId: roomId,
//       ));
      
//       onMessageStatusUpdated?.call(roomId, messageId, status);
//     } catch (e, st) {
//       debugPrint('[SignalR] ❌ Parse MessageStatusUpdated error: $e\n$st');
//     }
//   }

//   void _handleRoomCreated(List<Object?>? args) {
//     if (args == null || args.isEmpty) return;

//     try {
//       final data = _parseEventData(args[0]);
//       debugPrint('[SignalR] 🆕 RoomCreated: $data');

//       final room = ChatRoomModel.fromJson(data);
      
//       _emitEvent(SignalREvent(
//         type: SignalREventType.roomCreated,
//         data: room,
//         roomId: room.roomId,
//       ));
      
//       onRoomCreated?.call(room);
//     } catch (e, st) {
//       debugPrint('[SignalR] ❌ Parse RoomCreated error: $e\n$st');
//     }
//   }

//   void _handleRoomUpdated(List<Object?>? args) {
//     if (args == null || args.isEmpty) return;

//     try {
//       final data = _parseEventData(args[0]);
//       debugPrint('[SignalR] 🔄 RoomUpdated: $data');

//       final room = ChatRoomModel.fromJson(data);
      
//       _emitEvent(SignalREvent(
//         type: SignalREventType.roomUpdated,
//         data: room,
//         roomId: room.roomId,
//       ));
//     } catch (e, st) {
//       debugPrint('[SignalR] ❌ Parse RoomUpdated error: $e\n$st');
//     }
//   }

//   void _handleUserTyping(List<Object?>? args) {
//     if (args == null || args.isEmpty) return;

//     try {
//       final data = _parseEventData(args[0]);
//       final roomId = data['roomId']?.toString() ?? '';
//       final userId = data['userId']?.toString() ?? '';

//       _emitEvent(SignalREvent(
//         type: SignalREventType.userTyping,
//         data: userId,
//         roomId: roomId,
//       ));
      
//       onUserTyping?.call(roomId, userId);
//     } catch (e) {
//       debugPrint('[SignalR] ❌ Parse UserTyping error: $e');
//     }
//   }

//   void _handleUserPresence(List<Object?>? args) {
//     if (args == null || args.isEmpty) return;

//     try {
//       final data = _parseEventData(args[0]);
//       final userId = data['userId']?.toString() ?? '';
//       final isOnline = data['isOnline'] == true;

//       _emitEvent(SignalREvent(
//         type: isOnline ? SignalREventType.userOnline : SignalREventType.userOffline,
//         data: {'userId': userId, 'isOnline': isOnline},
//       ));
      
//       onUserPresenceChanged?.call(userId, isOnline);
//     } catch (e) {
//       debugPrint('[SignalR] ❌ Parse UserPresence error: $e');
//     }
//   }

//   void _handleMessagesRead(List<Object?>? args) {
//     if (args == null || args.isEmpty) return;

//     try {
//       final data = _parseEventData(args[0]);
//       final roomId = data['roomId']?.toString() ?? '';
//       final messageIds = (data['messageIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
//       final readBy = data['readBy']?.toString() ?? '';

//       debugPrint('[SignalR] 👁️ MessagesRead in $roomId by $readBy: ${messageIds.length} messages');

//       // Emit individual status updates for each message
//       for (final messageId in messageIds) {
//         onMessageStatusUpdated?.call(roomId, messageId, MessageStatus.read);
//       }
//     } catch (e) {
//       debugPrint('[SignalR] ❌ Parse MessagesRead error: $e');
//     }
//   }

//   // =========================================
//   // ROOM/CHANNEL MANAGEMENT
//   // =========================================

//   /// Join a chat room
//   Future<bool> joinRoom(String roomId) async {
//     if (!isConnected) {
//       debugPrint('[SignalR] ⚠️ Cannot join room: not connected');
//       return false;
//     }

//     if (_joinedRooms.contains(roomId)) {
//       debugPrint('[SignalR] ℹ️ Already joined room: $roomId');
//       return true;
//     }

//     try {
//       await _connection!.invoke('JoinRoom', args: [roomId]);
//       _joinedRooms.add(roomId);
//       debugPrint('[SignalR] ✅ Joined room: $roomId');
//       return true;
//     } catch (e) {
//       debugPrint('[SignalR] ❌ Join room error: $e');
//       return false;
//     }
//   }

//   /// Join multiple rooms
//   Future<void> joinRooms(List<String> roomIds) async {
//     for (final roomId in roomIds) {
//       if (roomId.isNotEmpty) {
//         await joinRoom(roomId);
//       }
//     }
//   }

//   /// Leave a chat room
//   Future<void> leaveRoom(String roomId) async {
//     if (!isConnected) return;

//     try {
//       await _connection!.invoke('LeaveRoom', args: [roomId]);
//       _joinedRooms.remove(roomId);
//       debugPrint('[SignalR] 👋 Left room: $roomId');
//     } catch (e) {
//       debugPrint('[SignalR] ❌ Leave room error: $e');
//     }
//   }

//   /// Join user channel (untuk notifikasi personal)
//   Future<bool> joinUserChannel(String userId) async {
//     if (!isConnected) return false;
//     if (_joinedUserChannels.contains(userId)) return true;

//     try {
//       await _connection!.invoke('JoinUserChannel', args: [userId]);
//       _joinedUserChannels.add(userId);
//       debugPrint('[SignalR] ✅ Joined user channel: $userId');
//       return true;
//     } catch (e) {
//       debugPrint('[SignalR] ❌ Join user channel error: $e');
//       return false;
//     }
//   }

//   /// Rejoin rooms after reconnect
//   Future<void> _rejoinAfterReconnect() async {
//     debugPrint('[SignalR] 🔄 Rejoining ${_joinedRooms.length} rooms...');
    
//     // Copy to avoid modification during iteration
//     final rooms = List<String>.from(_joinedRooms);
//     final channels = List<String>.from(_joinedUserChannels);
    
//     _joinedRooms.clear();
//     _joinedUserChannels.clear();

//     for (final roomId in rooms) {
//       await joinRoom(roomId);
//     }
    
//     for (final userId in channels) {
//       await joinUserChannel(userId);
//     }
//   }

//   // =========================================
//   // SEND EVENTS TO SERVER
//   // =========================================

//   /// Send typing indicator
//   Future<void> sendTyping(String roomId) async {
//     if (!isConnected) return;

//     try {
//       await _connection!.invoke('SendTyping', args: [roomId, {_currentUserId}]);
//     } catch (e) {
//       debugPrint('[SignalR] ❌ Send typing error: $e');
//     }
//   }

//   /// Mark messages as read
//   Future<void> markMessagesAsRead(String roomId, List<String> messageIds) async {
//     if (!isConnected || messageIds.isEmpty) return;

//     try {
//       await _connection!.invoke('MarkMessagesAsRead', args: [
//         roomId,
//         {_currentUserId},
//         messageIds,
//       ]);
//       debugPrint('[SignalR] ✅ Marked ${messageIds.length} messages as read');
//     } catch (e) {
//       debugPrint('[SignalR] ❌ Mark as read error: $e');
//     }
//   }

//   /// Update message status (sent, delivered, read)
//   Future<void> updateMessageStatus(
//     String roomId,
//     String messageId,
//     MessageStatus status,
//   ) async {
//     if (!isConnected) return;

//     try {
//       await _connection!.invoke('UpdateMessageStatus', args: [
//         roomId,
//         messageId,
//         status.value,
//       ]);
//     } catch (e) {
//       debugPrint('[SignalR] ❌ Update status error: $e');
//     }
//   }

//   // =========================================
//   // UTILITIES
//   // =========================================

//   Map<String, dynamic> _parseEventData(dynamic obj) {
//     if (obj is Map) {
//       return obj.map((k, v) => MapEntry(k.toString(), v));
//     }
//     if (obj is String) {
//       try {
//         final decoded = jsonDecode(obj);
//         if (decoded is Map) {
//           return decoded.map((k, v) => MapEntry(k.toString(), v));
//         }
//       } catch (_) {}
//     }
//     return {};
//   }

//   void _emitEvent(SignalREvent event) {
//     if (!_eventController.isClosed) {
//       _eventController.add(event);
//     }
//   }

//   /// Dispose resources
//   void dispose() {
//     _eventController.close();
//     _connection?.stop();
//     _connection = null;
//     _resetJoinState();
//   }
// }