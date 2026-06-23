import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/isar/service/chat_sync_service.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';

/// Service untuk REST API calls terkait chat
class ChatApiService {
  final ApiClient _client = apiClient;
  final String _controller = 'chat';

  // =========================================
  // ROOMS
  // =========================================

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

  Future<List<ChatModel>> fetchMessages({
    required String roomId,
    DateTime? since,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'room_id': roomId,
        'status': 'aktif',
        'orderBy': 'Sent_at',
        'orderDir': 'desc',
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

  // ─────────────────────────────────────────────────────────────────────────
  // sendMessage — legacy, tetap ada agar tidak break code lain.
  // Untuk flow room baru, gunakan sendMessageWithResult().
  // ─────────────────────────────────────────────────────────────────────────
  Future<ChatModel?> sendMessage({
    required ChatModel message,
  }) async {
    final result = await sendMessageWithResult(message: message);
    if (result == null) return null;

    // Return ChatModel dengan messageId + roomId asli dari server
    return message.copyWith(
      messageId: result.messageId,
      roomId: result.roomId.isNotEmpty ? result.roomId : message.roomId,
      sendStatus: 'sent',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // sendMessageWithResult — method utama yang dipakai ChatSyncService.
  //
  // Parse Message_Id dan Room_Id dari response:
  // {
  //   "StatusCode": 200,
  //   "Message": "Chat berhasil ditambahkan",
  //   "Message_Id": "room_137_1",
  //   "Room_Id": "room_137"
  // }
  //
  // Dua skenario:
  //   A. Room sudah ada  → roomId di response == roomId yang dikirim
  //   B. Room baru       → roomId di response berbeda / kosong saat kirim
  //      Server assign roomId baru → ChatSyncService buat room di Isar.
  // ─────────────────────────────────────────────────────────────────────────
  Future<SendMessageResult?> sendMessageWithResult({
    required ChatModel message,
  }) async {
    try {
      // Temp roomId (format 'temp-...') hanya dipakai lokal — kirim '' ke API
      final apiRoomId =
          message.roomId.startsWith('temp-') ? '' : message.roomId;

      final payload = {
        'chat': message.toJson(),
        'room_id': apiRoomId,
        'user_ids': message.userIds,
      };

      debugPrint('[ChatApi] 📤 sendMessageWithResult: '
          'localId=${message.localId} '
          'roomId="$apiRoomId" '
          'jenis=${message.jenisPesan}');

      final response = await _client.post(
        '/$_controller/create',
        body: jsonEncode(payload),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('[ChatApi] ❌ sendMessageWithResult failed: '
            '${response.statusCode} — ${response.body}');
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      // ── Parse Message_Id dan Room_Id ──────────────────────────────────
      final messageId = body['Message_Id']?.toString() ?? '';
      final roomId = body['Room_Id']?.toString() ?? '';

      if (messageId.isEmpty) {
        debugPrint('[ChatApi] ⚠️ sendMessageWithResult: '
            'Message_Id kosong dari response. Body: $body');
        // Fallback: jika backend tidak return Message_Id,
        // coba parse dari Data.Message_Id
        final data = body['Data'];
        if (data is Map<String, dynamic>) {
          final fallbackId = data['Message_Id']?.toString() ??
              data['message_id']?.toString() ??
              '';
          final fallbackRoomId = data['Room_Id']?.toString() ??
              data['room_id']?.toString() ??
              message.roomId;
          if (fallbackId.isNotEmpty) {
            debugPrint('[ChatApi] ✅ sendMessageWithResult fallback: '
                'messageId=$fallbackId roomId=$fallbackRoomId');
            return SendMessageResult(
              messageId: fallbackId,
              roomId:
                  fallbackRoomId.isNotEmpty ? fallbackRoomId : message.roomId,
            );
          }
        }
        // Tidak bisa dapat messageId → return null, local echo tetap di Isar
        return null;
      }

      // ── Gunakan roomId dari response, fallback ke roomId yang dikirim ──
      final finalRoomId = roomId.isNotEmpty ? roomId : message.roomId;

      debugPrint('[ChatApi] ✅ sendMessageWithResult: '
          'messageId=$messageId roomId=$finalRoomId '
          '(${message.roomId.isEmpty ? "new room" : "existing room"})');

      debugPrint("Send Status: ${message.sendStatus}");

      return SendMessageResult(
        messageId: messageId,
        roomId: finalRoomId,
      );
    } catch (e, st) {
      debugPrint('[ChatApi] ❌ sendMessageWithResult error: $e\n$st');
      return null;
    }
  }

  // =========================================
  // STATUS
  // =========================================

  Future<bool> updateMessageStatus({
    required String messageId,
    required String status,
  }) async {
    try {
      debugPrint('[ChatApi] 📤 updateMessageStatus: $messageId → $status');
      final response = await _client.put(
        '/$_controller/update-send-status'
        '?message_id=$messageId&send_status=$status',
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ChatApi] ❌ updateMessageStatus error: $e');
      return false;
    }
  }

  Future<bool> updateMessage({
    required ChatModel model,
    required String status,
  }) async {
    try {
      debugPrint('[ChatApi] 📤 updateMessage: ${model.messageId} → $status');
      final response = await _client.put(
        '/$_controller/update?message_id=${model.messageId}',
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ChatApi] ❌ updateMessage error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> update(ChatModel model) async {
    try {
      final requestBody = apiClient.toJsonSafe(model.toJsonUpdate());

      final response = await apiClient.put(
        '/$_controller/update',
        queryParameters: {'message_id': model.messageId},
        body: jsonEncode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseData = jsonDecode(response.body);
          return responseData is Map<String, dynamic>
              ? responseData
              : {'success': true, 'data': responseData};
        } catch (e) {
          debugPrint('[ChatApi] ⚠️ update parse error: $e');
          return {'success': true, 'message': 'Update berhasil'};
        }
      } else {
        debugPrint('[ChatApi] ❌ update failed: ${response.statusCode}');
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ChatApi] ❌ update error: $e');
      rethrow;
    }
  }

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
