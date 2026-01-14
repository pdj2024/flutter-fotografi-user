import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';

/// Service untuk REST API calls terkait chat
class ChatApiService {
  final ApiClient _client = apiClient;
  final String _controller = 'chat';

  // =========================================
  // ROOMS
  // =========================================

  /// Fetch rooms untuk user
  Future<List<RoomChatModel>> fetchRooms({
    required String userId,
    String? roomId,
    String? partnerId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'user_id': userId,
        if (partnerId != null && partnerId.isNotEmpty) 'id_lawan': partnerId,
        if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
      };

      final response = await _client.get(
        '/$_controller/getRooms',
        queryParameters: queryParams,
      );

      if (response.statusCode != 200) {
        debugPrint('[ChatApi] ❌ fetchRooms failed: ${response.statusCode}');
        return [];
      }

      final body = jsonDecode(response.body);
      final raw = body['Data'] ?? [];

      if (raw is! List) return [];

      final rooms = raw
          .map((e) =>
              e is Map<String, dynamic> ? RoomChatModel.fromJson(e) : null)
          .whereType<RoomChatModel>()
          .toList();

      debugPrint('[ChatApi] ✅ Fetched ${rooms.length} rooms');
      return rooms;
    } catch (e, st) {
      debugPrint('[ChatApi] ❌ fetchRooms error: $e\n$st');
      return [];
    }
  }

  // =========================================
  // MESSAGES
  // =========================================

  /// Fetch messages untuk room
  Future<List<ChatModel>> fetchMessages({
    required String roomId,
    DateTime? since,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'room_id': roomId,
        'status': 'aktif',
        if (since != null) 'since': since.toUtc().toIso8601String(),
        if (limit != null) 'limit': limit.toString(),
      };

      final response = await _client.get(
        '/$_controller/getAll',
        queryParameters: queryParams,
      );

      if (response.statusCode != 200) {
        debugPrint('[ChatApi] ❌ fetchMessages failed: ${response.statusCode}');
        return [];
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = body['Data'] as List<dynamic>? ?? [];

      final messages = raw
          .map((e) => e is Map<String, dynamic> ? ChatModel.fromJson(e) : null)
          .whereType<ChatModel>()
          .toList();

      debugPrint(
          '[ChatApi] ✅ Fetched ${messages.length} messages for room $roomId');
      return messages;
    } catch (e, st) {
      debugPrint('[ChatApi] ❌ fetchMessages error: $e\n$st');
      return [];
    }
  }

  /// Send message
  Future<ChatModel?> sendMessage({
    required ChatModel message,
  }) async {
    try {
      final payload = {
        'chat': message.toJson(),
        'room_id': message.roomId,
        'user_ids': message.userIds,
      };

      final response = await _client.post(
        '/$_controller/create',
        body: jsonEncode(payload),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('[ChatApi] ❌ sendMessage failed: ${response.statusCode}');
        return null;
      }

      debugPrint('[ChatApi] ✅ Message sent');

      // Parse response jika backend return data
      final body = jsonDecode(response.body);
      final data = body['Data'];

      if (data != null && data is Map<String, dynamic>) {
        return ChatModel.fromJson(data);
      }

      // Return message dengan status sent
      return message.copyWith(sendStatus: 'sent');
    } catch (e, st) {
      debugPrint('[ChatApi] ❌ sendMessage error: $e\n$st');
      return null;
    }
  }

  /// Update message status
  Future<bool> updateMessageStatus({
    required String messageId,
    required String status,
  }) async {
    try {
      print("updaatteee statuss ${messageId} ${status}");
      final response = await _client.put(
        '/$_controller/update-send-status?message_id=$messageId&send_status=$status',
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ChatApi] ❌ updateMessageStatus error: $e');
      return false;
    }
  }

  /// Clear unread untuk room
  Future<bool> clearRoomUnread({
    required String roomId,
    required String userId,
  }) async {
    try {
      final response = await _client.put(
        '/$_controller/clear-unread/$roomId',
        body: jsonEncode({'user_id': userId}),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ChatApi] ❌ clearRoomUnread error: $e');
      return false;
    }
  }
}
