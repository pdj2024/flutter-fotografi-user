import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/isar/data/chat_message_entity.dart';
import 'package:mpjnew/src/data/isar/data/room_chat_entity.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';
import 'package:mpjnew/src/features/customer/view/chat/data/service/chat_api_service.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/services/penawaran_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_isar_service.dart';
import 'chat_storage_service.dart';
// ignore: depend_on_referenced_packages
import 'package:connectivity_plus/connectivity_plus.dart';

const _kOfflineQueueKey = 'chat_offline_send_queue';
const _kCancelledPenawaranKey = 'chat_cancelled_penawaran_ids';

class ChatSyncService {
  static final ChatSyncService instance = ChatSyncService._internal();
  factory ChatSyncService() => instance;
  ChatSyncService._internal();

  final ChatIsarService _isar = ChatIsarService.instance;
  final ChatStorageService _storage = ChatStorageService.instance;
  final ChatApiService _api = ChatApiService();

  final Map<String, bool> _syncingRooms = {};
  bool _syncingAllRooms = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isRetrying = false;

  void startConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final isConnected = results.any((r) => r != ConnectivityResult.none);
      if (isConnected) retryOfflineQueue();
    });
    debugPrint('[ChatSync] 📡 Connectivity listener started');
  }

  void stopConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  static Future<void> _enqueueOffline(ChatModel message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kOfflineQueueKey) ?? [];
      final isDuplicate = raw.any((item) {
        try {
          return (jsonDecode(item) as Map<String, dynamic>)['Local_Id'] ==
              message.localId;
        } catch (_) {
          return false;
        }
      });
      if (isDuplicate) return;
      raw.add(jsonEncode(message.toJsonQueue()));
      final trimmed = raw.length > 50 ? raw.sublist(raw.length - 50) : raw;
      await prefs.setStringList(_kOfflineQueueKey, trimmed);
      debugPrint('[ChatSync] 📦 Offline queued: ${message.localId}');
    } catch (e) {
      debugPrint('[ChatSync] ❌ _enqueueOffline: $e');
    }
  }

  static Future<List<ChatModel>> _dequeueAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kOfflineQueueKey) ?? [];
      final result = <ChatModel>[];
      for (final item in raw) {
        try {
          result.add(ChatModel.fromJson(jsonDecode(item)));
        } catch (_) {}
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _clearOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOfflineQueueKey);
  }

  static bool _isNetworkError(Object e) {
    if (e is SocketException) return true;
    if (e is TimeoutException) return true;
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('connection refused') ||
        msg.contains('network is unreachable') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection timed out') ||
        msg.contains('no route to host') ||
        msg.contains('os error') ||
        msg.contains('connection reset by peer');
  }

  Future<bool> _isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  Future<void> retryOfflineQueue() async {
    if (_isRetrying) return;
    final messages = await _dequeueAll();
    if (messages.isEmpty) return;
    _isRetrying = true;
    await _clearOfflineQueue();
    for (final message in messages) {
      try {
        final result = await _sendToApi(message);
        if (result != null && message.localId != null) {
          await _handleApiSendResult(localMessage: message, result: result);
        } else if (result == null) {
          await _enqueueOffline(message);
        }
      } catch (e) {
        await _enqueueOffline(message);
      }
    }
    _isRetrying = false;
    debugPrint('[ChatSync] 🔁 Retry offline queue done');
  }

  Future<List<RoomChatModel>> syncRooms({
    required String userId,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cached = await _isar.getAllRooms();
        if (cached.isNotEmpty)
          return cached.map((e) => e.toRoomChatModel()).toList();
      }
      if (_syncingAllRooms) {
        final cached = await _isar.getAllRooms();
        return cached.map((e) => e.toRoomChatModel()).toList();
      }
      _syncingAllRooms = true;
      try {
        final rooms = await _api.fetchRooms(userId: userId);
        if (rooms.isNotEmpty) {
          await _storage.persistRoomsFromApi(rooms, replace: forceRefresh);
        } else if (forceRefresh) {
          await _storage.persistRoomsFromApi([], replace: true);
        }
        final synced = await _isar.getAllRooms();
        return synced.map((e) => e.toRoomChatModel()).toList();
      } finally {
        _syncingAllRooms = false;
      }
    } catch (e, st) {
      debugPrint('[ChatSync] ❌ syncRooms: $e\n$st');
      final cached = await _isar.getAllRooms();
      return cached.map((e) => e.toRoomChatModel()).toList();
    }
  }

  Future<(List<ChatModel>, bool)> loadMessages({
    required String roomId,
    required String tipeUser,
    required String roomType,
    required List<String> userIds,
    int limit = 30,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cached = await _isar.getMessagesByRoomPaged(
            roomId: roomId, offset: 0, limit: limit);
        if (cached.isNotEmpty) {
          debugPrint('[ChatSync] 📋 From cache: ${cached.length}');
          _backgroundFreshSync(
              roomId: roomId,
              tipeUser: tipeUser,
              roomType: roomType,
              userIds: userIds);
          return (
            cached
                .map((e) => e.toChatModel(
                    tipeUser: tipeUser, roomType: roomType, userIds: userIds))
                .toList(),
            true
          );
        }
      }
      final messages = await _api.fetchMessages(roomId: roomId);
      if (messages.isEmpty) {
        if (forceRefresh)
          await _isar.replaceRoomMessages(roomId: roomId, newEntities: []);
        return (<ChatModel>[], false);
      }
      final entities = await _buildEntitiesWithEmbedded(messages);
      if (forceRefresh) {
        await _isar.replaceRoomMessages(roomId: roomId, newEntities: entities);
      } else {
        await _isar.saveAllMessages(entities);
      }
      final saved = await _isar.getMessagesByRoom(roomId);
      return (
        saved
            .map((e) => e.toChatModel(
                tipeUser: tipeUser, roomType: roomType, userIds: userIds))
            .toList(),
        false
      );
    } catch (e, st) {
      debugPrint('[ChatSync] ❌ loadMessages: $e\n$st');
      final cached = await _isar.getMessagesByRoom(roomId);
      return (
        cached
            .map((e) => e.toChatModel(
                tipeUser: tipeUser, roomType: roomType, userIds: userIds))
            .toList(),
        true
      );
    }
  }

  Future<List<ChatModel>> loadMoreMessages({
    required String roomId,
    required int offset,
    required String tipeUser,
    required String roomType,
    required List<String> userIds,
    int limit = 30,
  }) async {
    try {
      final paged = await _isar.getMessagesByRoomPaged(
          roomId: roomId, offset: offset, limit: limit);
      return paged
          .map((e) => e.toChatModel(
              tipeUser: tipeUser, roomType: roomType, userIds: userIds))
          .toList();
    } catch (e, st) {
      debugPrint('[ChatSync] ❌ loadMoreMessages: $e\n$st');
      return [];
    }
  }

  Future<int> incrementalSync({
    required String roomId,
    required String tipeUser,
    required String roomType,
    required List<String> userIds,
  }) async {
    try {
      if (_syncingRooms[roomId] == true) return 0;
      _syncingRooms[roomId] = true;
      try {
        final lastMessages = await _isar.getMessagesByRoomPaged(
            roomId: roomId, offset: 0, limit: 1);
        final since =
            lastMessages.isNotEmpty ? lastMessages.first.sentAt : null;
        final newMessages =
            await _api.fetchMessages(roomId: roomId, since: since);
        if (newMessages.isEmpty) return 0;
        final entities = await _buildEntitiesWithEmbedded(newMessages);
        await _isar.saveAllMessages(entities);
        debugPrint(
            '[ChatSync] ✅ Incremental: ${entities.length} new for $roomId');
        return entities.length;
      } finally {
        _syncingRooms.remove(roomId);
      }
    } catch (e, st) {
      debugPrint('[ChatSync] ❌ incrementalSync: $e\n$st');
      _syncingRooms.remove(roomId);
      return 0;
    }
  }

  Future<bool> updateMessageStatus(
      {required String messageId, required String newStatus}) async {
    try {
      await _storage.updateLocalStatus(messageId, newStatus);
      return await _api.updateMessageStatus(
          messageId: messageId, status: newStatus);
    } catch (e, st) {
      debugPrint('[ChatSync] ❌ updateMessageStatus: $e\n$st');
      return false;
    }
  }

  Future<void> markRoomMessagesAsRead(
      {required String roomId, required String userId}) async {
    try {
      await _storage.markRoomAsRead(roomId);
      await _api.clearRoomUnread(roomId: roomId, userId: userId);
    } catch (e, st) {
      debugPrint('[ChatSync] ❌ markRoomMessagesAsRead: $e\n$st');
    }
  }

  Future<ChatModel?> sendMessage({required ChatModel message}) async {
    assert(message.localId != null, 'Message harus punya localId');
    assert(message.sendStatus == 'sent', 'Local echo harus status sent');

    try {
      await _storage.persistOptimisticMessage(message);
      debugPrint('[ChatSync] ⏳ Local echo saved: ${message.localId}');

      if (message.roomId.isNotEmpty) await _updateRoomOptimistic(message);

      final online = await _isOnline();
      if (!online) {
        await _enqueueOffline(message);
        debugPrint('[ChatSync] 📵 Offline → queued: ${message.localId}');
        return message;
      }

      SendMessageResult? result;
      try {
        result = await _sendToApi(message);
      } on SocketException catch (e) {
        await _enqueueOffline(message);
        debugPrint('[ChatSync] 📵 Socket → queued: ${message.localId} ($e)');
        return message;
      } on TimeoutException catch (e) {
        if (!await _isOnline()) {
          await _enqueueOffline(message);
          return message;
        }
        await _storage.markOptimisticAsFailed(message.localId!);
        debugPrint('[ChatSync] ❌ Timeout: ${message.localId} ($e)');
        return null;
      } catch (e) {
        if (_isNetworkError(e)) {
          await _enqueueOffline(message);
          return message;
        }
        await _storage.markOptimisticAsFailed(message.localId!);
        return null;
      }

      if (result == null) {
        await _storage.markOptimisticAsFailed(message.localId!);
        return null;
      }

      return await _handleApiSendResult(localMessage: message, result: result);
    } catch (e, st) {
      debugPrint('[ChatSync] ❌ sendMessage: $e\n$st');
      if (_isNetworkError(e)) {
        await _enqueueOffline(message);
        return message;
      }
      if (message.localId != null)
        await _storage.markOptimisticAsFailed(message.localId!);
      return null;
    }
  }

  Future<SendMessageResult?> _sendToApi(ChatModel message) =>
      _api.sendMessageWithResult(message: message);

  Future<ChatModel?> _handleApiSendResult({
    required ChatModel localMessage,
    required SendMessageResult result,
  }) async {
    final isNewRoom = localMessage.roomId.isEmpty &&
        result.roomId.isNotEmpty &&
        !result.roomId.startsWith('temp-');

    final serverMessage = localMessage.copyWith(
      messageId: result.messageId,
      roomId: result.roomId,
      sendStatus: 'sent',
    );

    if (isNewRoom) {
      await _handleNewRoomFromApi(
        localMessage: localMessage,
        serverMessage: serverMessage,
        roomId: result.roomId,
        messageId: result.messageId,
      );
    } else {
      await _storage.confirmOptimisticMessage(
        localId: localMessage.localId!,
        serverMessage: serverMessage,
      );
    }

    debugPrint('[ChatSync] ✅ Send result handled: '
        '${localMessage.localId} → ${result.messageId} room=${result.roomId}');
    return serverMessage;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // _handleNewRoomFromApi
  //
  // Dipanggil saat create pesan pertama ke vendor baru (roomId kosong).
  // Response API return Room_Id + Message_Id baru.
  //
  // Urutan kerja:
  //   1. Replace local echo → messageId + roomId asli
  //   2. Fetch room LENGKAP dari API → dapat usernameLawan, idMediaLawan, dll
  //   3. Simpan room ke Isar (UPSERT)
  //   4. Fetch messages untuk room ini → history tersedia
  //   5. Update lastMessage room
  //   6. Notify onRoomResolved → RoomChatProvider redirect dengan data lengkap
  //
  // onRoomResolved HANYA dipanggil setelah langkah 2-5 selesai,
  // sehingga ketika RoomChatPage terbuka semua data sudah siap di Isar.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _handleNewRoomFromApi({
    required ChatModel localMessage,
    required ChatModel serverMessage,
    required String roomId,
    required String messageId,
  }) async {
    debugPrint('[ChatSync] 🆕 New room — fetching full data before redirect: '
        'roomId=$roomId messageId=$messageId');

    try {
      // ── 1. Replace local echo ──────────────────────────────────────────
      final localEntity =
          await _isar.getMessageByLocalId(localMessage.localId!);
      if (localEntity != null) {
        await _isar.replaceLocalMessage(
          localId: localMessage.localId!,
          serverEntity: ChatMessageEntity.fromChatModel(serverMessage),
        );
        debugPrint('[ChatSync] ✅ Local echo replaced: '
            '${localMessage.localId} → $messageId (room: $roomId)');
      } else {
        await _isar.saveMessage(ChatMessageEntity.fromChatModel(serverMessage));
        debugPrint('[ChatSync] ℹ️ No local echo found, saved new: $messageId');
      }

      // ── 2. Fetch room LENGKAP dari API ─────────────────────────────────
      final currentUserId = _storage.currentUserId;
      bool roomFetched = false;

      if (currentUserId != null && currentUserId.isNotEmpty) {
        debugPrint('[ChatSync] 🔄 Fetching full room data: $roomId');
        try {
          final rooms = await _api.fetchRooms(
            userId: currentUserId,
            roomId: roomId,
          );

          if (rooms.isNotEmpty) {
            // ── 3. Simpan room lengkap ke Isar (UPSERT) ──────────────────
            await _storage.persistRoomsFromApi(rooms, replace: false);
            roomFetched = true;
            debugPrint('[ChatSync] ✅ Full room saved: $roomId '
                '(partner: ${rooms.first.usernameLawan ?? "-"})');
          } else {
            debugPrint(
                '[ChatSync] ⚠️ fetchRooms empty for $roomId — using minimal');
          }
        } catch (e) {
          debugPrint('[ChatSync] ⚠️ fetchRooms error for $roomId: $e');
        }
      }

      // Fallback: simpan minimal room jika fetch gagal
      if (!roomFetched) {
        await _saveMinimalRoom(
          roomId: roomId,
          localMessage: localMessage,
          serverMessage: serverMessage,
        );
      }

      // ── 4. Fetch messages untuk room ini ──────────────────────────────
      try {
        debugPrint('[ChatSync] 🔄 Fetching messages for new room: $roomId');
        final messages = await _api.fetchMessages(roomId: roomId);
        if (messages.isNotEmpty) {
          final entities = await _buildEntitiesWithEmbedded(messages);
          // UPSERT — local echo yang sudah di-replace di step 1 tetap ada
          await _isar.saveAllMessages(entities);
          debugPrint('[ChatSync] ✅ ${messages.length} messages saved: $roomId');
        }
      } catch (e) {
        debugPrint('[ChatSync] ⚠️ fetchMessages failed for $roomId: $e');
      }

      // ── 5. Update lastMessage room ─────────────────────────────────────
      await _isar.updateRoomLastMessage(
        roomId: roomId,
        lastMessage: serverMessage.message.isNotEmpty
            ? serverMessage.message
            : _formatPreview(serverMessage.jenisPesan ?? 'text'),
        lastMessageAt: serverMessage.sentAt,
      );

      // ── 6. Notify — data lengkap sudah siap, redirect ─────────────────
      final onResolved = _storage.onRoomResolved;
      if (onResolved != null) {
        debugPrint('[ChatSync] 📣 onRoomResolved($roomId) — full data ready');
        onResolved(roomId);
      } else {
        await ChatStorageService.enqueuePendingRoomFetchPublic(roomId);
        debugPrint('[ChatSync] 📋 No listener — queued: $roomId');
      }
    } catch (e, st) {
      debugPrint('[ChatSync] ❌ _handleNewRoomFromApi: $e\n$st');
      // Fallback: tetap notify agar user tidak stuck di loading
      final onResolved = _storage.onRoomResolved;
      if (onResolved != null) {
        debugPrint('[ChatSync] ⚠️ Fallback notify after error: $roomId');
        onResolved(roomId);
      }
    }
  }

  Future<void> _saveMinimalRoom({
    required String roomId,
    required ChatModel localMessage,
    required ChatModel serverMessage,
  }) async {
    final existing = await _isar.getRoomById(roomId);
    if (existing != null) {
      debugPrint('[ChatSync] ℹ️ Minimal skip — room exists: $roomId');
      return;
    }

    final currentUserId = _storage.currentUserId;
    final idLawan = localMessage.userIds
        .firstWhere((id) => id != currentUserId, orElse: () => '');

    final minimalRoom = RoomChatEntity()
      ..roomId = roomId
      ..roomType = localMessage.roomType
      ..idLawan = idLawan
      ..lastMessage = serverMessage.message.isNotEmpty
          ? serverMessage.message
          : _formatPreview(serverMessage.jenisPesan ?? 'text')
      ..lastMessageAt = serverMessage.sentAt
      ..unread = 0
      ..countStatusReceived = 0
      ..listIdMessageReceived = []
      ..countStatusSent = 0
      ..listIdMessageSent = []
      ..userIds = localMessage.userIds;

    await _isar.saveRoom(minimalRoom);
    debugPrint('[ChatSync] 💾 Minimal room saved: $roomId (idLawan: $idLawan)');
  }

  static String _formatPreview(String jenisPesan) {
    switch (jenisPesan) {
      case 'image':
        return '🖼️ Gambar';
      case 'paket':
        return '📦 Paket';
      case 'penawaran':
        return '💼 Penawaran';
      case 'pesanan':
        return '🧾 Pesanan';
      default:
        return 'Pesan baru';
    }
  }

  Future<void> _updateRoomOptimistic(ChatModel message) async {
    try {
      final room = await _isar.getRoomById(message.roomId);
      if (room == null) return;
      await _isar.updateRoomLastMessage(
        roomId: message.roomId,
        lastMessage:
            message.message.isNotEmpty ? message.message : '⏳ Mengirim...',
        lastMessageAt: message.sentAt,
      );
    } catch (e) {
      debugPrint('[ChatSync] ⚠️ _updateRoomOptimistic: $e');
    }
  }

  Future<int> retryFailedMessages({
    required String roomId,
    required ChatModel Function(ChatMessageEntity) toMessage,
  }) async {
    try {
      final failed = await _isar.getFailedMessages(roomId);
      if (failed.isEmpty) return 0;
      int retried = 0;
      for (final entity in failed) {
        final result = await sendMessage(message: toMessage(entity));
        if (result != null) retried++;
      }
      return retried;
    } catch (e, st) {
      debugPrint('[ChatSync] ❌ retryFailedMessages: $e\n$st');
      return 0;
    }
  }

  void _backgroundFreshSync({
    required String roomId,
    required String tipeUser,
    required String roomType,
    required List<String> userIds,
  }) {
    Future(() async {
      try {
        if (_syncingRooms[roomId] == true) return;
        _syncingRooms[roomId] = true;
        final messages = await _api.fetchMessages(roomId: roomId);
        if (messages.isEmpty) {
          _syncingRooms.remove(roomId);
          return;
        }
        final entities = await _buildEntitiesWithEmbedded(messages);
        await _isar.saveAllMessages(entities);

        final activeIds = messages.map((m) => m.messageId).toSet();
        await _removeStaleMessages(roomId: roomId, activeMessageIds: activeIds);

        debugPrint('[ChatSync] ✅ BG sync done: ${entities.length} for $roomId');
      } catch (e) {
        debugPrint('[ChatSync] ⚠️ BG sync error: $e');
      } finally {
        _syncingRooms.remove(roomId);
      }
    });
  }

  Future<void> _removeStaleMessages({
    required String roomId,
    required Set<String> activeMessageIds,
  }) async {
    try {
      final localMessages = await _isar.getMessagesByRoom(roomId);
      final cancelledIds = await _loadCancelledPenawaranIds();

      for (final local in localMessages) {
        if (local.noPenawaran?.isEmpty != false) continue;
        if (local.messageId.startsWith('local-')) continue;
        if (activeMessageIds.contains(local.messageId)) continue;

        await _isar.deleteMessage(local.messageId);
        await markPenawaranCancelled(local.noPenawaran!);

        if (!cancelledIds.contains(local.noPenawaran)) {
          debugPrint('[ChatSync] 🗑 Stale penawaran msg removed: ${local.messageId} '
              '(no_penawaran: ${local.noPenawaran})');
        }
      }
    } catch (e) {
      debugPrint('[ChatSync] ⚠️ _removeStaleMessages: $e');
    }
  }

  Future<Set<String>> _loadCancelledPenawaranIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kCancelledPenawaranKey) ?? []).toSet();
  }

  Future<void> markPenawaranCancelled(String noPenawaran) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_kCancelledPenawaranKey) ?? [];
    if (!existing.contains(noPenawaran)) {
      existing.add(noPenawaran);
      await prefs.setStringList(_kCancelledPenawaranKey, existing);
    }
  }

  Future<List<ChatMessageEntity>> _buildEntitiesWithEmbedded(
      List<ChatModel> messages) async {
    if (messages.isEmpty) return [];
    final paketIds = <String>{};
    final penawaranIds = <String>{};
    final pesananIds = <String>{};
    for (final m in messages) {
      if (m.messageId.startsWith('local-')) continue;
      if (m.idPaket?.isNotEmpty == true) paketIds.add(m.idPaket!);
      if (m.noInvoice?.isNotEmpty == true) {
        pesananIds.add(m.noInvoice!);
      } else if (m.noPenawaran?.isNotEmpty == true) {
        penawaranIds.add(m.noPenawaran!);
      }
    }
    final results = await Future.wait([
      _batchFetchPaket(paketIds.toList()),
      _batchFetchPenawaran(penawaranIds.toList()),
      _batchFetchPesanan(pesananIds.toList()),
    ]);
    final paketMap = results[0] as Map<String, PaketModel>;
    final penawaranMap = results[1] as Map<String, PenawaranModel>;
    final pesananMap = results[2] as Map<String, PesananModel>;
    return messages.map((m) {
      if (m.messageId.startsWith('local-'))
        return ChatMessageEntity.fromChatModel(m);
      final hasPesanan = m.noInvoice?.isNotEmpty == true;
      return ChatMessageEntity.fromChatModelWithData(
        m,
        paket: m.idPaket != null ? paketMap[m.idPaket] : null,
        penawaran: (!hasPesanan && m.noPenawaran != null)
            ? penawaranMap[m.noPenawaran]
            : null,
        pesanan: m.noInvoice != null ? pesananMap[m.noInvoice] : null,
      );
    }).toList();
  }

  Future<Map<String, PaketModel>> _batchFetchPaket(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final list = await PaketService().getAll(idList: ids);
      return {for (final p in list) p.no_id: p};
    } catch (e) {
      debugPrint('[ChatSync] ⚠️ _batchFetchPaket: $e');
      return {};
    }
  }

  Future<Map<String, PenawaranModel>> _batchFetchPenawaran(
      List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final list = await PenawaranService().getAll(idList: ids);
      return {for (final p in list) p.noId: p};
    } catch (e) {
      debugPrint('[ChatSync] ⚠️ _batchFetchPenawaran: $e');
      return {};
    }
  }

  Future<Map<String, PesananModel>> _batchFetchPesanan(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final result = <String, PesananModel>{};
      await Future.wait(ids.map((id) async {
        try {
          final list =
              await PesananService().getAll(noBukti: id);
          if (list.isNotEmpty) result[id] = list.first;
        } catch (e) {
          debugPrint('[ChatSync] ⚠️ Pesanan $id: $e');
        }
      }), eagerError: false);
      return result;
    } catch (e) {
      debugPrint('[ChatSync] ⚠️ _batchFetchPesanan: $e');
      return {};
    }
  }
}

class SendMessageResult {
  final String messageId;
  final String roomId;

  const SendMessageResult({required this.messageId, required this.roomId});

  factory SendMessageResult.fromJson(Map<String, dynamic> json) {
    return SendMessageResult(
      messageId: json['Message_Id']?.toString() ?? '',
      roomId: json['Room_Id']?.toString() ?? '',
    );
  }

  @override
  String toString() =>
      'SendMessageResult(messageId: $messageId, roomId: $roomId)';
}
