import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/isar/data/chat_message_entity.dart';
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

/// Koordinator sync antara API, Isar, dan offline queue.
///
/// ─── Strategi Penyimpanan ────────────────────────────────────────────────
///
///   REPLACE rooms  → pull-to-refresh ChatListPage (forceRefresh=true)
///                    Room yang tidak ada di API → dihapus dari Isar
///                    Unread count lokal dipertahankan untuk room yang masih ada
///
///   UPSERT rooms   → initial load, background sync (forceRefresh=false)
///                    Room lokal tetap ada meski tidak ada di response API
///
///   REPLACE msgs   → pull-to-refresh RoomChatPage (forceRefresh=true)
///                    Timpa semua pesan lokal + hapus local-xxx obsolete
///
///   UPSERT msgs    → incremental sync (app resume), initial load tanpa cache
///                    Local-xxx pending tidak terganggu
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

  // =========================================
  // CONNECTIVITY LISTENER
  // =========================================

  void startConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final isConnected = results.any((r) => r != ConnectivityResult.none);
      if (isConnected) {
        debugPrint(
            '[ChatSync] 📶 Network restored — retrying offline queue...');
        retryOfflineQueue();
      }
    });
    debugPrint('[ChatSync] 📡 Connectivity listener started');
  }

  void stopConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  // =========================================
  // OFFLINE QUEUE
  // =========================================

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
      debugPrint(
          '[ChatSync] 📦 Offline queued: ${message.localId} (${trimmed.length})');
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
        } catch (e) {
          debugPrint('[ChatSync] ⚠️ Dequeue parse error: $e');
        }
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
        final serverMessage = await _api.sendMessage(message: message);
        if (serverMessage != null && message.localId != null) {
          await _storage.confirmOptimisticMessage(
            localId: message.localId!,
            serverMessage: serverMessage,
          );
        } else if (serverMessage == null) {
          await _enqueueOffline(message);
        }
      } catch (e) {
        await _enqueueOffline(message);
      }
    }

    _isRetrying = false;
    debugPrint('[ChatSync] 🔁 Retry offline queue done');
  }

  // =========================================
  // ROOM SYNC
  //
  // forceRefresh=false → UPSERT (initial load, background sync)
  //   Room lokal yang tidak ada di API tetap ada
  //
  // forceRefresh=true  → REPLACE (pull-to-refresh)
  //   Room yang tidak ada di API → dihapus dari Isar
  //   Unread count lokal dipertahankan untuk room yang masih ada
  // =========================================

  Future<List<RoomChatModel>> syncRooms({
    required String userId,
    bool forceRefresh = false,
  }) async {
    try {
      // Jika tidak forceRefresh dan ada cache, return cache langsung
      if (!forceRefresh) {
        final cached = await _isar.getAllRooms();
        if (cached.isNotEmpty) {
          return cached.map((e) => e.toRoomChatModel()).toList();
        }
      }

      // Guard: jangan double sync
      if (_syncingAllRooms) {
        final cached = await _isar.getAllRooms();
        return cached.map((e) => e.toRoomChatModel()).toList();
      }

      _syncingAllRooms = true;
      try {
        final rooms = await _api.fetchRooms(userId: userId);

        if (rooms.isNotEmpty) {
          // ✅ forceRefresh=true  → REPLACE (hapus room yang tidak ada di API)
          // ✅ forceRefresh=false → UPSERT (pertahankan room lokal)
          await _storage.persistRoomsFromApi(
            rooms,
            replace: forceRefresh,
          );
        } else if (forceRefresh) {
          // API return kosong saat forceRefresh → hapus semua room lokal
          // Ini terjadi jika user belum pernah chat atau semua room dihapus
          await _storage.persistRoomsFromApi([], replace: true);
        }

        final synced = await _isar.getAllRooms();
        return synced.map((e) => e.toRoomChatModel()).toList();
      } finally {
        _syncingAllRooms = false;
      }
    } catch (e, st) {
      debugPrint('[ChatSync] ❌ syncRooms: $e\n$st');
      // Fallback ke cache
      final cached = await _isar.getAllRooms();
      return cached.map((e) => e.toRoomChatModel()).toList();
    }
  }

  // =========================================
  // MESSAGE LOAD
  //
  // forceRefresh=false → tampilkan cache + background REPLACE sync
  // forceRefresh=true  → fetch API + REPLACE data lokal
  // =========================================

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
          roomId: roomId,
          offset: 0,
          limit: limit,
        );

        if (cached.isNotEmpty) {
          debugPrint('[ChatSync] 📋 From cache: ${cached.length}');
          _backgroundFreshSync(
            roomId: roomId,
            tipeUser: tipeUser,
            roomType: roomType,
            userIds: userIds,
          );
          return (
            cached
                .map((e) => e.toChatModel(
                      tipeUser: tipeUser,
                      roomType: roomType,
                      userIds: userIds,
                    ))
                .toList(),
            true,
          );
        }
      }

      debugPrint('[ChatSync] 🔄 ${forceRefresh ? "Force replace" : "No cache"} '
          '— fetching from API...');

      final messages = await _api.fetchMessages(roomId: roomId);

      if (messages.isEmpty) {
        if (forceRefresh) {
          await _isar.replaceRoomMessages(
            roomId: roomId,
            newEntities: [],
          );
        }
        return (<ChatModel>[], false);
      }

      final entities = await _buildEntitiesWithEmbedded(messages);

      if (forceRefresh) {
        // ✅ REPLACE — timpa semua data lokal
        await _isar.replaceRoomMessages(
          roomId: roomId,
          newEntities: entities,
        );
        debugPrint('[ChatSync] ✅ Full replace: ${entities.length} for $roomId');
      } else {
        // ✅ UPSERT — initial load tanpa cache
        await _isar.saveAllMessages(entities);
      }

      final saved = await _isar.getMessagesByRoom(roomId);
      return (
        saved
            .map((e) => e.toChatModel(
                  tipeUser: tipeUser,
                  roomType: roomType,
                  userIds: userIds,
                ))
            .toList(),
        false,
      );
    } catch (e, st) {
      debugPrint('[ChatSync] ❌ loadMessages: $e\n$st');
      final cached = await _isar.getMessagesByRoom(roomId);
      return (
        cached
            .map((e) => e.toChatModel(
                  tipeUser: tipeUser,
                  roomType: roomType,
                  userIds: userIds,
                ))
            .toList(),
        true,
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
        roomId: roomId,
        offset: offset,
        limit: limit,
      );
      return paged
          .map((e) => e.toChatModel(
                tipeUser: tipeUser,
                roomType: roomType,
                userIds: userIds,
              ))
          .toList();
    } catch (e, st) {
      debugPrint('[ChatSync] ❌ loadMoreMessages: $e\n$st');
      return [];
    }
  }

  /// Incremental sync — hanya pesan baru (UPSERT).
  /// Dipakai saat app resume. Local-xxx pending tidak terganggu.
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
          roomId: roomId,
          offset: 0,
          limit: 1,
        );
        final since =
            lastMessages.isNotEmpty ? lastMessages.first.sentAt : null;

        final newMessages =
            await _api.fetchMessages(roomId: roomId, since: since);
        if (newMessages.isEmpty) return 0;

        // UPSERT — jangan hapus local-xxx yang mungkin masih pending
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

  // =========================================
  // STATUS SYNC
  // =========================================

  Future<bool> updateMessageStatus({
    required String messageId,
    required String newStatus,
  }) async {
    try {
      await _storage.updateLocalStatus(messageId, newStatus);
      return await _api.updateMessageStatus(
          messageId: messageId, status: newStatus);
    } catch (e, st) {
      debugPrint('[ChatSync] ❌ updateMessageStatus: $e\n$st');
      return false;
    }
  }

  Future<void> markRoomMessagesAsRead({
    required String roomId,
    required String userId,
  }) async {
    try {
      await _storage.markRoomAsRead(roomId);
      await _api.clearRoomUnread(roomId: roomId, userId: userId);
    } catch (e, st) {
      debugPrint('[ChatSync] ❌ markRoomMessagesAsRead: $e\n$st');
    }
  }

  // =========================================
  // SEND MESSAGE — Offline-first
  // =========================================

  Future<ChatModel?> sendMessage({required ChatModel message}) async {
    assert(message.localId != null, 'Message harus punya localId');
    assert(message.sendStatus == 'sent', 'Local echo harus status sent');

    try {
      await _storage.persistOptimisticMessage(message);
      debugPrint('[ChatSync] ⏳ Local echo saved: ${message.localId}');

      await _updateRoomOptimistic(message);

      final online = await _isOnline();
      if (!online) {
        await _enqueueOffline(message);
        debugPrint('[ChatSync] 📵 Offline → queued: ${message.localId}');
        return message;
      }

      ChatModel? serverMessage;
      try {
        serverMessage = await _api.sendMessage(message: message);
      } on SocketException catch (e) {
        await _enqueueOffline(message);
        debugPrint(
            '[ChatSync] 📵 SocketException → queued: ${message.localId} ($e)');
        return message;
      } on TimeoutException catch (e) {
        final stillOnline = await _isOnline();
        if (!stillOnline) {
          await _enqueueOffline(message);
          return message;
        }
        await _storage.markOptimisticAsFailed(message.localId!);
        debugPrint('[ChatSync] ❌ Timeout → failed: ${message.localId} ($e)');
        return null;
      } catch (e) {
        if (_isNetworkError(e)) {
          await _enqueueOffline(message);
          return message;
        }
        await _storage.markOptimisticAsFailed(message.localId!);
        return null;
      }

      if (serverMessage == null) {
        await _storage.markOptimisticAsFailed(message.localId!);
        return null;
      }

      await _storage.confirmOptimisticMessage(
        localId: message.localId!,
        serverMessage: serverMessage,
      );
      debugPrint(
          '[ChatSync] ✅ Sent: ${message.localId} → ${serverMessage.messageId}');
      return serverMessage;
    } catch (e, st) {
      debugPrint('[ChatSync] ❌ sendMessage: $e\n$st');
      if (_isNetworkError(e)) {
        await _enqueueOffline(message);
        return message;
      }
      if (message.localId != null) {
        await _storage.markOptimisticAsFailed(message.localId!);
      }
      return null;
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

  // =========================================
  // BACKGROUND FRESH SYNC — REPLACE strategy
  // =========================================

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

        debugPrint('[ChatSync] 🔄 BG fresh sync (REPLACE): $roomId');

        final messages = await _api.fetchMessages(roomId: roomId);
        if (messages.isEmpty) {
          _syncingRooms.remove(roomId);
          return;
        }

        final entities = await _buildEntitiesWithEmbedded(messages);

        // ✅ REPLACE — hapus local-xxx yang sudah dikonfirmasi server
        await _isar.replaceRoomMessages(
          roomId: roomId,
          newEntities: entities,
        );

        debugPrint(
            '[ChatSync] ✅ BG replace done: ${entities.length} for $roomId');
      } catch (e) {
        debugPrint('[ChatSync] ⚠️ BG fresh sync error: $e');
      } finally {
        _syncingRooms.remove(roomId);
      }
    });
  }

  // =========================================
  // BATCH ENRICH
  // =========================================

  Future<List<ChatMessageEntity>> _buildEntitiesWithEmbedded(
    List<ChatModel> messages,
  ) async {
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

    debugPrint('[ChatSync] 🔍 Batch enrich: '
        '${paketIds.length} paket, '
        '${penawaranIds.length} penawaran, '
        '${pesananIds.length} pesanan');

    final results = await Future.wait([
      _batchFetchPaket(paketIds.toList()),
      _batchFetchPenawaran(penawaranIds.toList()),
      _batchFetchPesanan(pesananIds.toList()),
    ]);

    final paketMap = results[0] as Map<String, PaketModel>;
    final penawaranMap = results[1] as Map<String, PenawaranModel>;
    final pesananMap = results[2] as Map<String, PesananModel>;

    return messages.map((m) {
      if (m.messageId.startsWith('local-')) {
        return ChatMessageEntity.fromChatModel(m);
      }

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
      await Future.wait(
        ids.map((id) async {
          try {
            final list =
                await PesananService().getAll(noBukti: id, status: 'aktif');
            if (list.isNotEmpty) result[id] = list.first;
          } catch (e) {
            debugPrint('[ChatSync] ⚠️ Pesanan $id error: $e');
          }
        }),
        eagerError: false,
      );
      return result;
    } catch (e) {
      debugPrint('[ChatSync] ⚠️ _batchFetchPesanan: $e');
      return {};
    }
  }
}
