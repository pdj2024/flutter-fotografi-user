import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/fcm/fcm_service.dart';
import 'package:mpjnew/src/data/isar/data/chat_message_entity.dart';
import 'package:mpjnew/src/data/isar/data/room_chat_entity.dart';
import 'package:mpjnew/src/data/isar/service/chat_isar_service.dart';
import 'package:mpjnew/src/data/isar/service/chat_storage_service.dart';
import 'package:mpjnew/src/data/isar/service/chat_sync_service.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';
import 'package:mpjnew/src/features/customer/view/chat/data/service/chat_api_service.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Embedded model helpers ─────────────────────────────────────
// Import sesuai path project customer
import 'package:mpjnew/src/data/isar/data/chat_message_entity.dart'
    show EmbeddedPaket, EmbeddedPenawaran, EmbeddedPesanan;
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/services/penawaran_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';

/// ✅ ChatProvider — Customer Edition (Isar)
///
/// Migrasi dari Hive/in-memory ke Isar:
///   - Stream pesan & room: Isar native (broadcast, reactive)
///   - Penyimpanan: ChatStorageService (satu jalur untuk FCM + API)
///   - Sync: ChatSyncService (incremental, background)
///   - Tidak ada in-memory list pesan — Isar yang jadi source of truth
///   - Pagination via _displayedCount (sama dengan vendor)
///
/// Kompatibilitas dengan kode lama:
///   - getMessagesStream(roomId) → Isar stream (bukan StreamController manual)
///   - loadMessages() → tetap ada, delegasi ke _sync
///   - sendMessage() → optimistic via ChatSyncService
///   - markRoomAsRead() → via ChatStorageService
///   - rooms getter → dari Isar stream subscription
///   - totalUnreadCount → dari rooms
class ChatProvider extends ChangeNotifier {
  final ChatApiService _apiService = ChatApiService();
  final ChatIsarService _isar = ChatIsarService.instance;
  final ChatStorageService _storage = ChatStorageService.instance;
  final ChatSyncService _sync = ChatSyncService.instance;

  // ── State ─────────────────────────────────────────────────────
  String? _currentUserId;
  String? _userType;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  String? _activeRoomId;

  // ── Isar stream subscriptions ─────────────────────────────────
  StreamSubscription<List<RoomChatEntity>>? _roomStreamSub;

  // ── Derived room list (dari Isar stream) ──────────────────────
  List<RoomChatModel> _rooms = [];

  // ── Room info cache ───────────────────────────────────────────
  final Map<String, RoomChatModel> _roomInfoCache = {};

  // ── Pagination ────────────────────────────────────────────────
  final Map<String, int> _displayedCount = {};
  static const int _initialDisplayCount = 100;
  static const int _loadMoreIncrement = 100;

  // ── Tracked rooms ─────────────────────────────────────────────
  final Set<String> _trackedRooms = {};

  // ── Callbacks ─────────────────────────────────────────────────
  Function(ChatModel message)? onNewMessageFromOther;
  Function(String roomId)? onRoomUpdated;

  // =========================================
  // GETTERS
  // =========================================

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;
  String? get userType => _userType;
  String? get error => _error;
  String? get activeRoomId => _activeRoomId;

  List<RoomChatModel> get rooms => _rooms;

  RoomChatModel? getRoom(String roomId) =>
      _roomInfoCache[roomId] ??
      _rooms.firstWhereOrNull((r) => r.roomId == roomId);

  int get totalUnreadCount =>
      _rooms.fold(0, (sum, r) => sum + r.actualUnreadCount);

  bool isRoomTracked(String roomId) => _trackedRooms.contains(roomId);
  Set<String> get trackedRooms => Set.unmodifiable(_trackedRooms);

  String getSenderName(String roomId, String senderId) {
    final room = _roomInfoCache[roomId] ?? getRoom(roomId);
    return room?.usernameLawan ?? 'Pesan baru';
  }

  // =========================================
  // STREAMS
  // =========================================

  /// ✅ Isar native stream — reactive, broadcast, tidak perlu StreamController.
  /// WAJIB di-cache di caller (RoomChatPage.initState) — jangan buat ulang di build().
  Stream<List<ChatMessageEntity>> getMessagesStream(String roomId) {
    _displayedCount.putIfAbsent(roomId, () => _initialDisplayCount);

    return _isar.watchMessages(roomId).map((allMessages) {
      final count = _displayedCount[roomId] ?? _initialDisplayCount;
      if (allMessages.length <= count) return allMessages;
      return allMessages.sublist(allMessages.length - count);
    });
  }

  /// Stream room list dari Isar (untuk RoomListPage)
  Stream<List<RoomChatEntity>> get roomsStream => _isar.watchAllRooms();

  // =========================================
  // INITIALIZATION
  // =========================================

  ChatProvider();

  Future<bool> initialize({
    required String userId,
    required String userType,
  }) async {
    if (_isInitialized && _currentUserId == userId) {
      debugPrint('[ChatProvider] ℹ️ Already initialized: $userId');
      return true;
    }

    if (_isInitialized && _currentUserId != userId) {
      debugPrint('[ChatProvider] 🔄 User changed, clearing...');
      await clearAll();
    }

    debugPrint('[ChatProvider] 🚀 Initializing: $userId ($userType)');
    _currentUserId = userId;
    _userType = userType;

    // Simpan userId ke SharedPreferences (untuk background drain)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);

    // Set current user di ChatStorageService
    _storage.setCurrentUser(userId);

    // Inject ChatProvider ke FCMService agar handler bisa langsung panggil ini
    FCMService.instance.setChatProvider(this);

    try {
      if (!_isar.isInitialized) {
        await _isar.initialize();
      }

      _subscribeToRoomStream();
      _sync.startConnectivityListener();

      _isInitialized = true;
      _error = null;
      notifyListeners();

      // Load rooms dari API di background
      _backgroundSyncRooms();

      return true;
    } catch (e, st) {
      debugPrint('[ChatProvider] ❌ Init error: $e\n$st');
      _error = e.toString();
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }

  void _subscribeToRoomStream() {
    _roomStreamSub?.cancel();
    _roomStreamSub = _isar.watchAllRooms().listen((entities) {
      _rooms = entities.map((e) => e.toRoomChatModel()).toList();
      for (final room in _rooms) {
        _roomInfoCache[room.roomId] = room;
      }
      notifyListeners();
    });
    debugPrint('[ChatProvider] 📡 Room stream subscribed');
  }

  // =========================================
  // LOGOUT / CLEAR
  // =========================================

  Future<void> clearAll() async {
    debugPrint('[ChatProvider] 🚪 Clearing: $_currentUserId');

    await _roomStreamSub?.cancel();
    _roomStreamSub = null;

    _rooms = [];
    _roomInfoCache.clear();
    _displayedCount.clear();
    _trackedRooms.clear();
    _activeRoomId = null;
    _currentUserId = null;
    _userType = null;
    _isInitialized = false;
    _isLoading = false;
    _error = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');

    // Bersihkan Isar data saat logout
    await _storage.clearAll();
    _sync.stopConnectivityListener();
    debugPrint('[ChatProvider] ✅ Cleared');
    notifyListeners();
  }

  /// Alias untuk kompatibilitas dengan kode lama
  Future<void> closeAndClearInMemory() => clearAll();
  Future<void> clearInMemory() => clearAll();

  // =========================================
  // FCM INTEGRATION
  // =========================================

  /// Entry point untuk pesan dari FCM (foreground).
  /// Dipanggil dari FCMService.instance._chatHandler.onMessageReceived.
  ///
  /// ✅ Delegasi ke ChatStorageService — satu jalur untuk semua pesan.
  /// ✅ Isar stream otomatis notify UI — tidak perlu notifyListeners manual.
  Future<void> handleMessageFromFCM(ChatModel message) async {
    if (!_isInitialized || _currentUserId == null) {
      debugPrint('[ChatProvider] ⚠️ Not initialized, skip FCM');
      return;
    }

    debugPrint('[ChatProvider] 📨 FCM: ${message.messageId} | '
        'sender: ${message.senderId}');

    try {
      final saved = await _storage.persistForegroundMessage(message);

      // Notify untuk pesan dari orang lain
      if (message.senderId != _currentUserId) {
        onNewMessageFromOther?.call(message);
      }

      // ✅ FIX: Trigger enrich jika punya embedded data
      // Dipanggil regardless saved status karena:
      // - saved=true: pesan baru, embedded belum ada di Isar
      // - saved=false: own echo confirmed, embedded mungkin belum ada
      //   (confirmOptimistic hanya replace messageId, tidak fetch embedded)
      final hasEmbedded = (message.idPaket?.isNotEmpty == true) ||
          (message.noPenawaran?.isNotEmpty == true) ||
          (message.noInvoice?.isNotEmpty == true);

      if (hasEmbedded) {
        // Kecil kemungkinan messageId masih local- di sini, tapi guard saja
        if (!message.messageId.startsWith('local-')) {
          _triggerEmbeddedEnrichForMessage(message);
        }
      }
    } catch (e, st) {
      debugPrint('[ChatProvider] ❌ handleMessageFromFCM: $e\n$st');
    }
  }

  void triggerEmbeddedEnrichForMessage(ChatModel message) {
    _triggerEmbeddedEnrichForMessage(message);
  }

  void _triggerEmbeddedEnrichForMessage(ChatModel message) {
    Future(() async {
      try {
        final entity = await _isar.getMessageById(message.messageId);
        if (entity == null) return;

        final paket = (message.idPaket?.isNotEmpty == true)
            ? await _loadPaketModel(message.idPaket!)
            : null;

        // ── Prioritas: noInvoice (pesanan) > noPenawaran ────────────
        // Jika sudah ada noInvoice, skip fetch penawaran.
        final hasPesanan = message.noInvoice?.isNotEmpty == true;
        final pesanan =
            hasPesanan ? await _loadPesananModel(message.noInvoice!) : null;
        final penawaran =
            (!hasPesanan && message.noPenawaran?.isNotEmpty == true)
                ? await _loadPenawaranModel(message.noPenawaran!)
                : null;

        final needsUpdate = (paket != null && entity.paket == null) ||
            (penawaran != null && entity.penawaran == null) ||
            (pesanan != null && entity.pesanan == null);

        if (needsUpdate) {
          await _isar.saveMessage(entity.copyWith(
            paket:
                paket != null ? EmbeddedPaket.fromModel(paket) : entity.paket,
            // Jika hasPesanan, clear embedded penawaran agar tidak tampil dobel
            penawaran: hasPesanan
                ? null
                : (penawaran != null
                    ? EmbeddedPenawaran.fromModel(penawaran)
                    : entity.penawaran),
            pesanan: pesanan != null
                ? EmbeddedPesanan.fromModel(pesanan)
                : entity.pesanan,
          ));
          debugPrint(
              '[ChatProvider] ✅ FCM message enriched: ${message.messageId}');
        }
      } catch (e) {
        debugPrint('[ChatProvider] ⚠️ _triggerEmbeddedEnrichForMessage: $e');
      }
    });
  }

  // =========================================
  // UPDATE MESSAGE STATUS
  // =========================================

  Future<void> updateMessageStatus(String messageId, String status) async {
    try {
      await _sync.updateMessageStatus(
        messageId: messageId,
        newStatus: status,
      );
    } catch (e) {
      debugPrint('[ChatProvider] ❌ updateMessageStatus: $e');
    }
  }

  // =========================================
  // ROOM MANAGEMENT
  // =========================================

  Future<void> trackRoom(String roomId) async {
    if (_trackedRooms.contains(roomId)) return;
    _trackedRooms.add(roomId);
    debugPrint('[ChatProvider] 📌 Tracking: $roomId');
    if (_currentUserId != null) _backgroundSyncMessages(roomId);
  }

  void untrackRoom(String roomId) {
    _trackedRooms.remove(roomId);
    debugPrint('[ChatProvider] 📌 Untracking: $roomId');
  }

  Future<List<RoomChatModel>> loadRooms({
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    if (_currentUserId == null) return [];
    if (!silent) _setLoading(true);

    try {
      final rooms = await _sync.syncRooms(
        userId: _currentUserId!,
        forceRefresh: forceRefresh,
      );
      for (final room in rooms) {
        _roomInfoCache[room.roomId] = room;
      }
      if (!silent) notifyListeners();
      return rooms;
    } catch (e) {
      debugPrint('[ChatProvider] ❌ loadRooms: $e');
      return _rooms;
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  Future<RoomChatModel?> findOrCreateRoom(String partnerId) async {
    if (_currentUserId == null) return null;

    final cached = _rooms.firstWhereOrNull((r) => r.idLawan == partnerId);
    if (cached != null) {
      _roomInfoCache[cached.roomId] = cached;
      return cached;
    }

    final roomModels = await _apiService.fetchRooms(
      userId: _currentUserId!,
      partnerId: partnerId,
    );

    if (roomModels.isNotEmpty) {
      await _storage.persistRoomsFromApi([roomModels.first]);
      _roomInfoCache[roomModels.first.roomId] = roomModels.first;
      return roomModels.first;
    }

    return null;
  }

  // =========================================
  // MESSAGES MANAGEMENT
  // =========================================

  Future<List<ChatModel>> loadMessages(
    String roomId, {
    bool forceRefresh = false,
    bool silent = true,
  }) async {
    if (_currentUserId == null) return [];
    if (!silent) _setLoading(true);

    try {
      final roomInfo = getRoom(roomId);

      final (messages, _) = await _sync.loadMessages(
        roomId: roomId,
        tipeUser: _userType ?? 'customer',
        roomType: roomInfo?.roomType ?? 'direct',
        userIds: roomInfo?.userIds ?? [],
        limit: _initialDisplayCount,
        forceRefresh: forceRefresh, // ✅ FIX: teruskan ke sync service
      );

      await markRoomAsRead(roomId);
      return messages;
    } catch (e) {
      debugPrint('[ChatProvider] ❌ loadMessages: $e');
      return [];
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  /// Pagination — tambah jumlah pesan yang ditampilkan
  bool loadMoreDisplayedMessages(String roomId) {
    final current = _displayedCount[roomId] ?? _initialDisplayCount;
    _displayedCount[roomId] = current + _loadMoreIncrement;
    notifyListeners();
    return true;
  }

  int getTotalMessagesCount(String roomId) => _displayedCount[roomId] ?? 0;
  int getDisplayedMessagesCount(String roomId) =>
      _displayedCount[roomId] ?? _initialDisplayCount;
  bool hasMoreToDisplay(String roomId) => true; // Isar stream handle ini

  /// Incremental sync dari API — dipanggil saat app resume
  Future<void> syncRoomFromHiveAndNotify(String roomId) async {
    if (_currentUserId == null) return;
    final roomInfo = getRoom(roomId);
    await _sync.incrementalSync(
      roomId: roomId,
      tipeUser: _userType ?? 'customer',
      roomType: roomInfo?.roomType ?? 'direct',
      userIds: roomInfo?.userIds ?? [],
    );
    // Isar stream otomatis notify UI
  }

  // =========================================
  // SEND MESSAGE
  // =========================================

  Future<bool> sendMessage({
    required String roomId,
    required String message,
    String? idPaket,
    String? noPenawaran,
    required List<String> userIds,
  }) async {
    if (_currentUserId == null) return false;
    if (message.trim().isEmpty && idPaket == null && noPenawaran == null) {
      return false;
    }

    final localId =
        'local-${DateTime.now().millisecondsSinceEpoch}-${_currentUserId!.hashCode}';
    final now = DateTime.now();

    String jenisPesan = 'text';
    if (idPaket != null && idPaket.isNotEmpty) {
      jenisPesan = 'paket';
    } else if (noPenawaran != null && noPenawaran.isNotEmpty) {
      jenisPesan = 'penawaran';
    }

    final localMessage = ChatModel(
      messageId: localId,
      roomId: roomId,
      senderId: _currentUserId!,
      tipeUser: _userType ?? 'customer',
      message: message,
      jenisPesan: jenisPesan,
      idPaket: idPaket,
      noPenawaran: noPenawaran,
      status: 'aktif',
      sendStatus: 'sent', // ✅ Langsung sent — tidak perlu update status lagi
      roomType: 'direct',
      sentAt: now,
      userIds: userIds,
      receiverIds: [],
      localId: localId,
      noInvoice: null,
      editedAt: null,
      receivedAt: null,
      readAt: null,
    );

    // ChatSyncService handle: optimistic save → API → replace echo
    // Isar stream otomatis update UI di setiap langkah
    final result = await _sync.sendMessage(message: localMessage);
    return result != null;
  }

  Future<bool> retryMessage(String roomId, String localId) async {
    final entity = await _isar.getMessageById(localId);
    if (entity == null) return false;
    await _isar.deleteMessage(localId);
    return sendMessage(
      roomId: roomId,
      message: entity.message,
      idPaket: entity.paket?.noId,
      noPenawaran: entity.penawaran?.noId,
      userIds: entity.receiverIds ?? [],
    );
  }

  Future<void> removeFailedMessage(String roomId, String localId) async {
    await _isar.deleteMessage(localId);
    // Isar stream otomatis update UI
  }

  // =========================================
  // MESSAGE ACTIONS
  // =========================================

  Future<void> markRoomAsRead(String roomId) async {
    if (_currentUserId == null) return;
    try {
      await _storage.markRoomAsRead(roomId);
      // Isar stream otomatis update UI
    } catch (e) {
      debugPrint('[ChatProvider] ❌ markRoomAsRead: $e');
    }
  }

  Future<bool> updatePenawaranToPesanan({
    required ChatModel message,
    required String pesananId,
  }) async {
    try {
      if (pesananId.isEmpty) return false;

      final result =
          await _apiService.update(message.copyWith(noInvoice: pesananId));
      if (result.isEmpty) return false;

      final entity = await _isar.getMessageById(message.messageId);
      if (entity == null) return false;

      final pesanan = await _loadPesananModel(pesananId);
      if (pesanan != null) {
        final updated = entity.copyWith(
          pesanan: EmbeddedPesanan.fromModel(pesanan),
        );
        await _isar.saveMessage(updated);
        // Isar stream otomatis update UI
      }

      return true;
    } catch (e) {
      debugPrint('[ChatProvider] ❌ updatePenawaranToPesanan: $e');
      return false;
    }
  }

  // =========================================
  // ACTIVE ROOM
  // =========================================

  void setActiveRoom(String? roomId) {
    if (_activeRoomId != roomId) {
      _activeRoomId = roomId;
      if (roomId != null && roomId.isNotEmpty) markRoomAsRead(roomId);
      notifyListeners();
    }
  }

  bool isRoomActive(String roomId) => _activeRoomId == roomId;

  // =========================================
  // BACKGROUND HELPERS
  // =========================================

  void _backgroundSyncRooms() {
    if (_currentUserId == null) return;
    loadRooms(forceRefresh: true, silent: true)
        .then((r) => debugPrint('[ChatProvider] ✅ ${r.length} rooms synced'))
        .catchError((e) => debugPrint('[ChatProvider] ⚠️ Room sync: $e'));
  }

  void _backgroundSyncMessages(String roomId) {
    final roomInfo = getRoom(roomId);
    _sync
        .incrementalSync(
      roomId: roomId,
      tipeUser: _userType ?? 'customer',
      roomType: roomInfo?.roomType ?? 'direct',
      userIds: roomInfo?.userIds ?? [],
    )
        .then((count) {
      if (count > 0) debugPrint('[ChatProvider] ✅ $count new for $roomId');
    }).catchError((e) => debugPrint('[ChatProvider] ⚠️ Sync: $e'));
  }

  void _backgroundEnrichMessage(ChatModel message) {
    Future(() async {
      try {
        final entity = await _isar.getMessageById(message.messageId);
        if (entity == null) return;

        bool changed = false;
        EmbeddedPaket? paket = entity.paket;
        EmbeddedPenawaran? penawaran = entity.penawaran;
        EmbeddedPesanan? pesanan = entity.pesanan;

        if (message.idPaket?.isNotEmpty == true && entity.paket == null) {
          final p = await _loadPaketModel(message.idPaket!);
          if (p != null) {
            paket = EmbeddedPaket.fromModel(p);
            changed = true;
          }
        }
        if (message.noPenawaran?.isNotEmpty == true &&
            entity.penawaran == null) {
          final p = await _loadPenawaranModel(message.noPenawaran!);
          if (p != null) {
            penawaran = EmbeddedPenawaran.fromModel(p);
            changed = true;
          }
        }
        if (message.noInvoice?.isNotEmpty == true && entity.pesanan == null) {
          final p = await _loadPesananModel(message.noInvoice!);
          if (p != null) {
            pesanan = EmbeddedPesanan.fromModel(p);
            changed = true;
          }
        }

        if (changed) {
          await _isar.saveMessage(entity.copyWith(
              paket: paket, penawaran: penawaran, pesanan: pesanan));
        }
      } catch (e) {
        debugPrint('[ChatProvider] ⚠️ Enrich error: $e');
      }
    });
  }

  void _backgroundEnrichMessages(List<ChatModel> messages) {
    if (messages.isEmpty) return;
    Future(() async {
      try {
        final needsEnrich = messages
            .where((m) =>
                m.idPaket?.isNotEmpty == true ||
                m.noPenawaran?.isNotEmpty == true ||
                m.noInvoice?.isNotEmpty == true)
            .toList();
        if (needsEnrich.isEmpty) return;

        final paketIds = needsEnrich
            .where((m) => m.idPaket?.isNotEmpty == true)
            .map((m) => m.idPaket!)
            .toSet()
            .toList();

        // ── Prioritas: noInvoice (pesanan) > noPenawaran ────────────
        // Hanya fetch penawaran untuk pesan yang BELUM jadi pesanan.
        final penawaranIds = needsEnrich
            .where((m) =>
                m.noInvoice?.isEmpty != false && // tidak punya noInvoice
                m.noPenawaran?.isNotEmpty == true)
            .map((m) => m.noPenawaran!)
            .toSet()
            .toList();
        final pesananIds = needsEnrich
            .where((m) => m.noInvoice?.isNotEmpty == true)
            .map((m) => m.noInvoice!)
            .toSet()
            .toList();

        final paketMap = await _batchFetchPaket(paketIds);
        final penawaranMap = await _batchFetchPenawaran(penawaranIds);
        final pesananMap = await _batchFetchPesanan(pesananIds);

        for (final m in needsEnrich) {
          final entity = await _isar.getMessageById(m.messageId);
          if (entity == null) continue;

          final hasPesanan = m.noInvoice?.isNotEmpty == true;
          final paket = paketMap[m.idPaket];
          // Jika sudah ada pesanan, skip penawaran
          final penawaran = (!hasPesanan) ? penawaranMap[m.noPenawaran] : null;
          final pesanan = pesananMap[m.noInvoice];

          final needsUpdate = (paket != null && entity.paket == null) ||
              (penawaran != null && entity.penawaran == null) ||
              (pesanan != null && entity.pesanan == null);

          if (needsUpdate) {
            await _isar.saveMessage(entity.copyWith(
              paket:
                  paket != null ? EmbeddedPaket.fromModel(paket) : entity.paket,
              // Jika hasPesanan, clear embedded penawaran agar tidak tampil dobel
              penawaran: hasPesanan
                  ? null
                  : (penawaran != null
                      ? EmbeddedPenawaran.fromModel(penawaran)
                      : entity.penawaran),
              pesanan: pesanan != null
                  ? EmbeddedPesanan.fromModel(pesanan)
                  : entity.pesanan,
            ));
          }
        }
        debugPrint('[ChatProvider] ✅ Batch enrich done');
      } catch (e) {
        debugPrint('[ChatProvider] ⚠️ Batch enrich: $e');
      }
    });
  }

  // ── Fetch helpers ─────────────────────────────────────────────

  Future<Map<String, PaketModel>> _batchFetchPaket(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final list = await PaketService().getAll(idList: ids);
      return {for (var p in list) p.no_id: p};
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, PenawaranModel>> _batchFetchPenawaran(
      List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final list = await PenawaranService().getAll(idList: ids);
      return {for (var p in list) p.noId: p};
    } catch (_) {
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
              await PesananService().getAll(noBukti: id, status: 'aktif');
          if (list.isNotEmpty) result[id] = list.first;
        } catch (_) {}
      }));
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<PaketModel?> _loadPaketModel(String id) async {
    try {
      return await PaketService().getPaketById(noId: id);
    } catch (_) {
      return null;
    }
  }

  Future<PenawaranModel?> _loadPenawaranModel(String id) async {
    try {
      final list = await PenawaranService().getAll(noId: id);
      return list.isNotEmpty ? list.first : null;
    } catch (_) {
      return null;
    }
  }

  Future<PesananModel?> _loadPesananModel(String id) async {
    try {
      final list = await PesananService().getAll(noBukti: id);
      return list.isNotEmpty ? list.first : null;
    } catch (_) {
      return null;
    }
  }

  // =========================================
  // UTILITIES
  // =========================================

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _roomStreamSub?.cancel();
    _roomInfoCache.clear();
    _displayedCount.clear();
    _trackedRooms.clear();
    super.dispose();
  }
}
