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
        debugPrint('[ChatSync] 📶 Network restored — retrying queue...');
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
          '[ChatSync] 📦 Enqueued: ${message.localId} (${trimmed.length})');
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
        if (serverMessage != null) {
          if (message.localId != null) {
            await _storage.confirmOptimisticMessage(
              localId: message.localId!,
              serverMessage: serverMessage,
            );
          }
        } else {
          await _enqueueOffline(message);
        }
      } catch (e) {
        await _enqueueOffline(message);
      }
    }
    _isRetrying = false;
    debugPrint('[ChatSync] 🔁 Retry queue done');
  }

  // =========================================
  // ROOM SYNC
  // =========================================

  Future<List<RoomChatModel>> syncRooms({
    required String userId,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cached = await _isar.getAllRooms();
        if (cached.isNotEmpty) {
          return cached.map((e) => e.toRoomChatModel()).toList();
        }
      }
      if (_syncingAllRooms) {
        final cached = await _isar.getAllRooms();
        return cached.map((e) => e.toRoomChatModel()).toList();
      }
      _syncingAllRooms = true;
      try {
        final rooms = await _api.fetchRooms(userId: userId);
        if (rooms.isNotEmpty) await _storage.persistRoomsFromApi(rooms);
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

  // =========================================
  // MESSAGE LOAD — Fresh strategy
  //
  // Saat buka room:
  //   1. Tampilkan cache Isar dulu (instant)
  //   2. Fetch fresh dari API di background
  //   3. Enrich embedded (paket/penawaran/pesanan) — selalu fresh
  //   4. Save ke Isar → stream emit → UI update otomatis
  //
  // Kenapa selalu fresh untuk embedded:
  //   - Penawaran bisa berubah jadi pesanan kapan saja
  //   - Status pesanan berubah (menunggu bayar → persiapan → selesai)
  //   - Paket bisa diupdate vendornya
  // =========================================

  Future<(List<ChatModel>, bool)> loadMessages({
    required String roomId,
    required String tipeUser,
    required String roomType,
    required List<String> userIds,
    int limit = 30,
    bool forceRefresh = false, // ✅ FIX: tambah parameter ini
  }) async {
    try {
      // ✅ FIX: Jika forceRefresh, skip cache langsung ke API
      if (!forceRefresh) {
        final cached = await _isar.getMessagesByRoomPaged(
            roomId: roomId, offset: 0, limit: limit);

        if (cached.isNotEmpty) {
          debugPrint('[ChatSync] 📋 From cache: ${cached.length}');
          // Background fresh sync agar embedded selalu up-to-date
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

      // forceRefresh=true ATAU tidak ada cache → fetch dari API
      debugPrint(
          '[ChatSync] 🔄 ${forceRefresh ? "Force refresh" : "No cache"} — fetching from API...');
      final messages = await _fetchEnrichAndPersist(
        roomId: roomId,
        tipeUser: tipeUser,
        roomType: roomType,
        userIds: userIds,
      );
      return (messages, false);
    } catch (e, st) {
      debugPrint('[ChatSync] ❌ loadMessages: $e\n$st');
      return (<ChatModel>[], false);
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

  /// Incremental sync — hanya pesan baru (berdasarkan since)
  /// Dipakai saat app resume, bukan saat buka room pertama kali
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

        // Enrich embedded untuk pesan baru
        final entities = await _buildEntitiesWithEmbedded(newMessages);
        await _isar.saveAllMessages(entities);
        debugPrint(
            '[ChatSync] ✅ ${entities.length} new synced+enriched: $roomId');
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
  // SEND MESSAGE
  // =========================================

  Future<ChatModel?> sendMessage({required ChatModel message}) async {
    assert(message.localId != null, 'Message harus punya localId');
    assert(message.sendStatus == 'sent', 'Local echo harus status sent');

    try {
      await _storage.persistOptimisticMessage(message);
      debugPrint('[ChatSync] ⏳ Local echo saved: ${message.localId}');

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
  // CORE: FETCH + ENRICH + PERSIST
  // =========================================

  /// Fetch semua pesan dari API + enrich embedded + save ke Isar.
  ///
  /// ✅ SELALU fresh untuk embedded data karena:
  ///   - Penawaran bisa berubah status atau jadi pesanan
  ///   - Pesanan statusnya bisa berubah
  ///   - Paket bisa diupdate
  Future<List<ChatModel>> _fetchEnrichAndPersist({
    required String roomId,
    required String tipeUser,
    required String roomType,
    required List<String> userIds,
    DateTime? since,
  }) async {
    try {
      final messages = await _api.fetchMessages(roomId: roomId, since: since);
      if (messages.isEmpty) return [];

      final entities = await _buildEntitiesWithEmbedded(messages);
      await _isar.saveAllMessages(entities);

      debugPrint(
          '[ChatSync] 💾 ${entities.length} messages saved with fresh embedded');

      final saved = await _isar.getMessagesByRoom(roomId);
      return saved
          .map((e) => e.toChatModel(
                tipeUser: tipeUser,
                roomType: roomType,
                userIds: userIds,
              ))
          .toList();
    } catch (e, st) {
      debugPrint('[ChatSync] ❌ _fetchEnrichAndPersist: $e\n$st');
      return [];
    }
  }

  /// Background sync: fetch fresh + re-enrich semua embedded di room.
  ///
  /// Dipanggil setelah cache ditampilkan agar UI update tanpa loading.
  /// Penting untuk kasus penawaran → pesanan (noInvoice berubah).
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

        debugPrint('[ChatSync] 🔄 Background fresh sync: $roomId');

        // Fetch semua pesan (tidak pakai since — fresh full)
        final messages = await _api.fetchMessages(roomId: roomId);
        if (messages.isEmpty) {
          _syncingRooms.remove(roomId);
          return;
        }

        // Re-enrich semua embedded (paket/penawaran/pesanan selalu fresh)
        final entities = await _buildEntitiesWithEmbedded(messages);
        await _isar.saveAllMessages(entities);

        debugPrint(
            '[ChatSync] ✅ BG fresh sync done: ${entities.length} for $roomId');
      } catch (e) {
        debugPrint('[ChatSync] ⚠️ BG fresh sync error: $e');
      } finally {
        _syncingRooms.remove(roomId);
      }
    });
  }

  // =========================================
  // BATCH ENRICH — BUILD ENTITIES
  // =========================================

  /// Build entities dengan embedded data yang sudah di-fetch fresh.
  ///
  /// ✅ Parallel fetch: paket + penawaran + pesanan sekaligus
  /// ✅ Pesanan: satu per satu karena tidak ada batch endpoint
  /// ✅ Penawaran: batch via idList
  /// ✅ Paket: batch via idList
  Future<List<ChatMessageEntity>> _buildEntitiesWithEmbedded(
      List<ChatModel> messages) async {
    if (messages.isEmpty) return [];

    // Kumpulkan ID unik per tipe — skip local echo (local-xxx)
    final paketIds = <String>{};
    final penawaranIds = <String>{};
    final pesananIds = <String>{};

    for (final m in messages) {
      if (m.messageId.startsWith('local-')) continue;

      // ── Paket selalu di-fetch jika ada ──────────────────────────
      if (m.idPaket?.isNotEmpty == true) paketIds.add(m.idPaket!);

      // ── Prioritas: noInvoice (pesanan) > noPenawaran ────────────
      // Jika pesan sudah jadi pesanan (noInvoice ada), skip penawaran.
      // Jika belum ada pesanan, baru fetch penawaran.
      if (m.noInvoice?.isNotEmpty == true) {
        pesananIds.add(m.noInvoice!);
        // intentionally skip noPenawaran — sudah dikonversi ke pesanan
      } else if (m.noPenawaran?.isNotEmpty == true) {
        penawaranIds.add(m.noPenawaran!);
      }
    }
    debugPrint('[ChatSync] 🔍 Batch enrich: '
        '${paketIds.length} paket, '
        '${penawaranIds.length} penawaran, '
        '${pesananIds.length} pesanan');

    // ✅ Parallel fetch semua tipe sekaligus
    final results = await Future.wait([
      _batchFetchPaket(paketIds.toList()),
      _batchFetchPenawaran(penawaranIds.toList()),
      _batchFetchPesanan(pesananIds.toList()),
    ]);

    final paketMap = results[0] as Map<String, PaketModel>;
    final penawaranMap = results[1] as Map<String, PenawaranModel>;
    final pesananMap = results[2] as Map<String, PesananModel>;

    // Build entity dengan embedded
    return messages.map((m) {
      if (m.messageId.startsWith('local-')) {
        return ChatMessageEntity.fromChatModel(m);
      }

      // ── Terapkan prioritas yang sama saat mapping ke entity ──────
      final hasPesanan = m.noInvoice?.isNotEmpty == true;
      return ChatMessageEntity.fromChatModelWithData(
        m,
        paket: m.idPaket != null ? paketMap[m.idPaket] : null,
        // Jika sudah ada pesanan, penawaran tidak di-embed
        penawaran: (!hasPesanan && m.noPenawaran != null)
            ? penawaranMap[m.noPenawaran]
            : null,
        pesanan: m.noInvoice != null ? pesananMap[m.noInvoice] : null,
      );
    }).toList();
  }

  // =========================================
  // BATCH FETCH HELPERS
  // =========================================

  /// Paket: batch fetch via idList
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

  /// Penawaran: batch fetch via idList
  /// API format: /getAll?noidList=X&noidList=Y&noidList=Z
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

  /// Pesanan: fetch satu per satu karena tidak ada batch endpoint.
  /// Menggunakan Future.wait untuk parallel (tidak sequential).
  Future<Map<String, PesananModel>> _batchFetchPesanan(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final result = <String, PesananModel>{};

      // ✅ Parallel fetch — semua request jalan bersamaan
      await Future.wait(
        ids.map((id) async {
          try {
            final list =
                await PesananService().getAll(noBukti: id, status: 'aktif');
            if (list.isNotEmpty) {
              result[id] = list.first;
              debugPrint('[ChatSync] ✅ Pesanan fetched: $id');
            }
          } catch (e) {
            // Satu gagal tidak menghentikan yang lain
            debugPrint('[ChatSync] ⚠️ Pesanan $id error: $e');
          }
        }),
        eagerError: false, // Lanjut meski satu gagal
      );

      return result;
    } catch (e) {
      debugPrint('[ChatSync] ⚠️ _batchFetchPesanan: $e');
      return {};
    }
  }
}
