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

import 'package:mpjnew/src/data/isar/data/chat_message_entity.dart'
    show EmbeddedPaket, EmbeddedPenawaran, EmbeddedPesanan;
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/services/penawaran_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';

/// ChatProvider — Customer Edition (Isar Offline-First)
///
/// Arsitektur:
///   UI → ChatProvider → ChatSyncService → ChatIsarService (source of truth)
///                    ↗ ChatStorageService (FCM bridge)
///   FCM → ChatStorageService → ChatIsarService → stream → UI (otomatis)
///
/// Key principles:
///   - Isar stream = source of truth, UI tidak perlu notifyListeners manual
///   - ChatProvider hanya expose stream + action methods
///   - Semua write ke Isar lewat ChatStorageService atau ChatSyncService
///   - notifyListeners() hanya untuk state non-Isar (isLoading, rooms list cache)
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
  // STREAMS — Isar native (broadcast, reactive)
  // =========================================

  /// Stream pesan untuk room tertentu.
  /// WAJIB di-cache di caller (initState) — jangan buat ulang di build().
  /// Menggunakan pagination via _displayedCount.
  Stream<List<ChatMessageEntity>> getMessagesStream(String roomId) {
    _displayedCount.putIfAbsent(roomId, () => _initialDisplayCount);

    return _isar.watchMessages(roomId).map((allMessages) {
      final count = _displayedCount[roomId] ?? _initialDisplayCount;
      if (allMessages.length <= count) return allMessages;
      return allMessages.sublist(allMessages.length - count);
    });
  }

  /// Stream room list (untuk ChatListPage).
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);

    _storage.setCurrentUser(userId);

    // Inject ChatProvider ke FCMService
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

      // Sync rooms dari API di background
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

  void _drainPendingRoomFetchIfNeeded() {
    if (_currentUserId == null) return;

    Future(() async {
      try {
        final pendingIds = await ChatStorageService.getPendingRoomFetchIds();
        if (pendingIds.isEmpty) return;

        debugPrint(
            '[ChatProvider] 🔄 ${pendingIds.length} pending room(s) to fetch...');

        await ChatStorageService.instance.drainPendingRoomFetch(
          userId: _currentUserId!,
        );

        // Isar stream otomatis emit setelah rooms + messages di-save
        // ChatListPage akan rebuild dengan data lengkap (nama, avatar vendor)
        debugPrint('[ChatProvider] ✅ Pending room fetch done');
      } catch (e) {
        debugPrint('[ChatProvider] ⚠️ _drainPendingRoomFetchIfNeeded: $e');
      }
    });
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

    await _storage.clearAll();
    _sync.stopConnectivityListener();

    debugPrint('[ChatProvider] ✅ Cleared');
    notifyListeners();
  }

  Future<void> closeAndClearInMemory() => clearAll();
  Future<void> clearInMemory() => clearAll();

  // =========================================
  // FCM INTEGRATION
  // =========================================

  /// Entry point untuk pesan dari FCM (foreground).
  /// Dipanggil dari FCMService via ChatNotificationHandler.
  ///
  /// Delegasi ke ChatStorageService → satu jalur untuk semua pesan.
  /// Isar stream otomatis notify UI → tidak perlu notifyListeners manual.
  Future<void> handleMessageFromFCM(ChatModel message) async {
    debugPrint(
        '[ChatProvider] 📨 FCM: ${message.messageId} | sender: ${message.senderId}');
 
    try {
      final saved = await _storage.persistForegroundMessage(message);
 
      if (saved) {
        if (message.senderId != _currentUserId) {
          onNewMessageFromOther?.call(message);
        }
 
        final hasEmbedded = (message.idPaket?.isNotEmpty == true) ||
            (message.noPenawaran?.isNotEmpty == true) ||
            (message.noInvoice?.isNotEmpty == true);
 
        if (hasEmbedded) {
          _triggerEmbeddedEnrich(message);
        }
      }
 
      // ✅ Cek pending room fetch setiap kali FCM masuk
      // Kasus: pesan dari vendor baru → _handleIncoming buat minimal room
      // → enqueue roomId → drain di sini → fetch data lengkap → Isar update
      _drainPendingRoomFetchIfNeeded();
    } catch (e, st) {
      debugPrint('[ChatProvider] ❌ handleMessageFromFCM: $e\n$st');
    }
  }

  void _triggerEmbeddedEnrich(ChatModel message) {
    Future(() async {
      try {
        final entity = await _isar.getMessageById(message.messageId);
        if (entity == null) return;

        final paket = (message.idPaket?.isNotEmpty == true)
            ? await _loadPaketModel(message.idPaket!)
            : null;

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
        debugPrint('[ChatProvider] ⚠️ _triggerEmbeddedEnrich: $e');
      }
    });
  }

  // =========================================
  // UPDATE MESSAGE STATUS
  // =========================================

  Future<void> updateMessageStatus(String messageId, String status) async {
    try {
      await _sync.updateMessageStatus(messageId: messageId, newStatus: status);
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

  /// Load messages untuk room.
  ///
  /// forceRefresh=false (default): tampilkan cache dulu + background sync
  /// forceRefresh=true: fetch dari API dan REPLACE data lokal
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
        forceRefresh: forceRefresh,
      );

      // Mark room sebagai read setelah load
      await markRoomAsRead(roomId);
      return messages;
    } catch (e) {
      debugPrint('[ChatProvider] ❌ loadMessages: $e');
      return [];
    } finally {
      if (!silent) _setLoading(false);
    }
  }

  bool loadMoreDisplayedMessages(String roomId) {
    final current = _displayedCount[roomId] ?? _initialDisplayCount;
    _displayedCount[roomId] = current + _loadMoreIncrement;
    notifyListeners();
    return true;
  }

  int getTotalMessagesCount(String roomId) => _displayedCount[roomId] ?? 0;
  int getDisplayedMessagesCount(String roomId) =>
      _displayedCount[roomId] ?? _initialDisplayCount;
  bool hasMoreToDisplay(String roomId) => true;

  /// Incremental sync (app resume) — UPSERT, jangan REPLACE
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

    // Local echo dengan status "sent"
    // Status ini benar: user sudah "mengirim" dari sisi UI
    // Akan di-replace dengan messageId dari server saat FCM echo diterima
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
      sendStatus: 'sent',
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
      userIds: entity.receiverIds,
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

  // =========================================
  // UTILITIES
  // =========================================

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
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

  @override
  void dispose() {
    _roomStreamSub?.cancel();
    _roomInfoCache.clear();
    _displayedCount.clear();
    _trackedRooms.clear();
    super.dispose();
  }
}
