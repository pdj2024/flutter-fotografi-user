import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/fcm_chat_message.dart';
import 'package:mpjnew/src/core/services/fcm_chat_queue.dart';

/// ═══════════════════════════════════════════════════════════════
/// FCM CHAT PROVIDER
///
/// State management utama untuk chat berbasis FCM.
///
/// Tanggung jawab:
///   1. Menyimpan pesan per-room di memory (Map<roomId, List<msg>>)
///   2. Expose stream per-room untuk RoomChatPage
///   3. Memproses pesan masuk dari foreground FCM
///   4. Drain antrian background saat app resume
///   5. Mengelola unread count per room
///
/// Tidak bergantung pada Hive — murni in-memory + SharedPreferences queue.
/// Integrasikan dengan Hive/storage service Anda sendiri lewat callback.
/// ═══════════════════════════════════════════════════════════════
class FcmChatProvider extends ChangeNotifier {
  // =========================================
  // STATE
  // =========================================

  /// Pesan per room: roomId → list pesan (terbaru di index 0)
  final Map<String, List<FcmChatMessage>> _messagesByRoom = {};

  /// Stream controllers per room
  final Map<String, StreamController<List<FcmChatMessage>>>
      _controllersByRoom = {};

  /// Unread count per room
  final Map<String, int> _unreadByRoom = {};

  /// Room yang sedang aktif (dibuka user)
  String? _activeRoomId;

  /// ID user yang sedang login
  String? _currentUserId;

  /// Status drain queue
  bool _isDraining = false;

  // =========================================
  // EXTERNAL CALLBACKS
  // Isi ini untuk integrasi dengan storage/API Anda
  // =========================================

  /// Dipanggil setiap ada pesan baru masuk (untuk persist ke Hive dll)
  /// Bisa di-set via constructor atau setter (setelah context ready)
  Future<void> Function(FcmChatMessage message)? onMessagePersist;

  /// Dipanggil untuk update status pesan ke API (received/read)
  Future<void> Function(String messageId, String roomId, String status)?
      onUpdateStatus;

  /// Dipanggil untuk mendapatkan nama sender dari data lokal
  String Function(String roomId, String senderId)? getSenderName;

  FcmChatProvider({
    this.onMessagePersist,
    this.onUpdateStatus,
    this.getSenderName,
  });

  // =========================================
  // SETTERS — untuk di-wire setelah context tersedia (di main.dart)
  // =========================================

  set onMessagePersistCallback(
      Future<void> Function(FcmChatMessage message) cb) {
    onMessagePersist = cb;
  }

  set onUpdateStatusCallback(
      Future<void> Function(String messageId, String roomId, String status)
          cb) {
    onUpdateStatus = cb;
  }

  set getSenderNameCallback(
      String Function(String roomId, String senderId) cb) {
    getSenderName = cb;
  }

  // =========================================
  // GETTERS
  // =========================================

  String? get activeRoomId => _activeRoomId;
  String? get currentUserId => _currentUserId;
  bool get isDraining => _isDraining;

  List<FcmChatMessage> messagesForRoom(String roomId) =>
      List.unmodifiable(_messagesByRoom[roomId] ?? []);

  int unreadCountForRoom(String roomId) => _unreadByRoom[roomId] ?? 0;

  int get totalUnread =>
      _unreadByRoom.values.fold(0, (sum, count) => sum + count);

  // =========================================
  // SETUP
  // =========================================

  void setCurrentUser(String userId) {
    _currentUserId = userId;
    debugPrint('[FcmChatProvider] 👤 Current user: $userId');
  }

  void setActiveRoom(String? roomId) {
    if (_activeRoomId == roomId) return;

    final previous = _activeRoomId;
    _activeRoomId = roomId;

    debugPrint(
        '[FcmChatProvider] 🏠 Active room: $previous → $roomId');

    // Reset unread untuk room yang baru dibuka
    if (roomId != null) {
      _clearUnread(roomId);
    }

    notifyListeners();
  }

  // =========================================
  // STREAM - untuk RoomChatPage StreamBuilder
  // =========================================

  /// Dapatkan stream pesan untuk room tertentu.
  /// Stream ini akan emit setiap kali ada pesan baru masuk.
  /// RoomChatPage harus cache stream ini agar tidak rebuild.
  Stream<List<FcmChatMessage>> getStream(String roomId) {
    if (!_controllersByRoom.containsKey(roomId)) {
      _controllersByRoom[roomId] =
          StreamController<List<FcmChatMessage>>.broadcast();
      debugPrint(
          '[FcmChatProvider] 🎛️ Stream created for room: $roomId');
    }
    return _controllersByRoom[roomId]!.stream;
  }

  /// Seed stream dengan data awal (dari Hive/API load).
  /// Panggil ini saat RoomChatPage init selesai load pesan lama.
  void seedRoom(String roomId, List<FcmChatMessage> messages) {
    final sorted = [...messages]
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

    _messagesByRoom[roomId] = sorted;
    _emitToStream(roomId);

    debugPrint(
        '[FcmChatProvider] 🌱 Seeded room $roomId with ${messages.length} messages');
  }

  // =========================================
  // INCOMING MESSAGE - dari FCM foreground
  // =========================================

  /// Entry point utama untuk pesan FCM yang diterima di foreground.
  /// Dipanggil dari FCMService saat onMessage.listen
  Future<void> handleIncoming(FcmChatMessage message) async {
    debugPrint('[FcmChatProvider] 📨 Incoming: ${message.messageId}');
    debugPrint(
        '[FcmChatProvider]   Room: ${message.roomId}, Sender: ${message.senderId}');
    debugPrint('[FcmChatProvider]   Status: ${message.sendStatus}');

    final isOwnMessage = message.senderId == _currentUserId;
    final isActiveRoom = _activeRoomId == message.roomId;

    if (isOwnMessage) {
      // Pesan sendiri yang echo balik dari server
      // Gunakan untuk konfirmasi pending → sent
      debugPrint('[FcmChatProvider] 📤 Own message echo');
      _addOrReplace(message);
    } else {
      // Pesan dari orang lain
      _addOrReplace(message);

      // Tentukan status target
      final targetStatus = isActiveRoom ? 'read' : 'received';

      // Update unread jika bukan active room
      if (!isActiveRoom) {
        _incrementUnread(message.roomId);
      }

      // Persist ke storage (Hive dll) via callback
      await onMessagePersist?.call(message);

      // Update status ke API jika perlu
      if (message.sendStatus != targetStatus) {
        debugPrint(
            '[FcmChatProvider] 🔄 ${message.sendStatus} → $targetStatus');
        await onUpdateStatus?.call(
          message.messageId,
          message.roomId,
          targetStatus,
        );
      }
    }

    // Emit ke stream
    _emitToStream(message.roomId);
    notifyListeners();
  }

  // =========================================
  // BACKGROUND QUEUE DRAIN
  // Dipanggil saat app resume dari background/terminated
  // =========================================

  /// Drain semua pesan yang terakumulasi di background.
  /// Panggil ini di AppLifecycleState.resumed atau didChangeAppLifecycleState.
  Future<void> drainBackgroundQueue() async {
    if (_isDraining) {
      debugPrint('[FcmChatProvider] ⚠️ Already draining, skip');
      return;
    }

    final hasPending = await FcmChatQueue.hasPending();
    if (!hasPending) {
      debugPrint('[FcmChatProvider] ✅ No pending background messages');
      return;
    }

    _isDraining = true;
    notifyListeners();

    try {
      final messages = await FcmChatQueue.dequeueAll();
      debugPrint(
          '[FcmChatProvider] 📦 Draining ${messages.length} background messages');

      // Group by room untuk efisiensi emit
      final byRoom = <String, List<FcmChatMessage>>{};
      for (final msg in messages) {
        byRoom.putIfAbsent(msg.roomId, () => []).add(msg);
      }

      for (final entry in byRoom.entries) {
        final roomId = entry.key;
        final roomMessages = entry.value;

        for (final msg in roomMessages) {
          _addOrReplace(msg);
        }

        // Tambah unread untuk room yang tidak aktif
        if (roomId != _activeRoomId) {
          _incrementUnreadBy(roomId, roomMessages.length);
        }

        // Persist semua via callback
        for (final msg in roomMessages) {
          await onMessagePersist?.call(msg);
        }

        _emitToStream(roomId);
      }

      debugPrint('[FcmChatProvider] ✅ Drain complete');
      notifyListeners();
    } catch (e) {
      debugPrint('[FcmChatProvider] ❌ Drain error: $e');
    } finally {
      _isDraining = false;
      notifyListeners();
    }
  }

  // =========================================
  // LOCAL SEND (Optimistic UI)
  // =========================================

  /// Tambah pesan lokal sebelum API response (optimistic UI).
  /// messageId sebaiknya pakai format 'local-{timestamp}-{random}'
  FcmChatMessage addLocalMessage({
    required String localId,
    required String roomId,
    required String senderId,
    required String message,
    String jenisPesan = 'text',
    String? idPaket,
    String? noPenawaran,
    List<String> userIds = const [],
    List<String> receiverIds = const [],
  }) {
    final localMsg = FcmChatMessage(
      messageId: localId,
      roomId: roomId,
      senderId: senderId,
      senderName: 'Me',
      message: message,
      jenisPesan: jenisPesan,
      sendStatus: 'pending',
      tipeUser: 'vendor',
      sentAt: DateTime.now(),
      idPaket: idPaket,
      noPenawaran: noPenawaran,
      userIds: userIds,
      receiverIds: receiverIds,
    );

    _addOrReplace(localMsg);
    _emitToStream(roomId);
    notifyListeners();

    debugPrint('[FcmChatProvider] 📝 Local message added: $localId');
    return localMsg;
  }

  /// Update pesan lokal (pending → sent) setelah API berhasil.
  void confirmLocalMessage({
    required String localId,
    required String serverMessageId,
    required String roomId,
  }) {
    final roomMsgs = _messagesByRoom[roomId];
    if (roomMsgs == null) return;

    final idx = roomMsgs.indexWhere((m) => m.messageId == localId);
    if (idx == -1) return;

    final old = roomMsgs[idx];
    // Buat versi baru dengan messageId dari server dan status sent
    final confirmed = FcmChatMessage(
      messageId: serverMessageId,
      roomId: old.roomId,
      senderId: old.senderId,
      senderName: old.senderName,
      message: old.message,
      jenisPesan: old.jenisPesan,
      sendStatus: 'sent',
      tipeUser: old.tipeUser,
      sentAt: old.sentAt,
      idPaket: old.idPaket,
      noPenawaran: old.noPenawaran,
      noInvoice: old.noInvoice,
      userIds: old.userIds,
      receiverIds: old.receiverIds,
    );

    roomMsgs[idx] = confirmed;
    _emitToStream(roomId);
    notifyListeners();

    debugPrint(
        '[FcmChatProvider] ✅ Confirmed: $localId → $serverMessageId');
  }

  /// Tandai pesan lokal sebagai gagal
  void failLocalMessage(String localId, String roomId) {
    _updateStatus(localId, roomId, 'failed');
    debugPrint('[FcmChatProvider] ❌ Failed: $localId');
  }

  // =========================================
  // STATUS UPDATE
  // =========================================

  /// Update status pesan tertentu (misal setelah user membaca)
  void updateMessageStatus(
      String messageId, String roomId, String status) {
    _updateStatus(messageId, roomId, status);
    _emitToStream(roomId);
    notifyListeners();
  }

  // =========================================
  // UNREAD
  // =========================================

  void clearUnread(String roomId) {
    _clearUnread(roomId);
    notifyListeners();
  }

  // =========================================
  // CLEANUP
  // =========================================

  void disposeRoom(String roomId) {
    _controllersByRoom[roomId]?.close();
    _controllersByRoom.remove(roomId);
    // Jangan hapus _messagesByRoom — dibutuhkan kalau user buka lagi
    debugPrint('[FcmChatProvider] 🗑️ Stream disposed for: $roomId');
  }

  void clearRoom(String roomId) {
    _messagesByRoom.remove(roomId);
    _unreadByRoom.remove(roomId);
    disposeRoom(roomId);
    notifyListeners();
  }

  Future<void> clearAll() async {
    for (final controller in _controllersByRoom.values) {
      controller.close();
    }
    _controllersByRoom.clear();
    _messagesByRoom.clear();
    _unreadByRoom.clear();
    _activeRoomId = null;
    notifyListeners();
    debugPrint('[FcmChatProvider] 🗑️ All cleared');
  }

  // =========================================
  // INTERNAL HELPERS
  // =========================================

  void _addOrReplace(FcmChatMessage message) {
    final roomMsgs =
        _messagesByRoom.putIfAbsent(message.roomId, () => []);

    final existingIdx =
        roomMsgs.indexWhere((m) => m.messageId == message.messageId);

    if (existingIdx >= 0) {
      roomMsgs[existingIdx] = message; // Update existing
    } else {
      roomMsgs.insert(0, message); // Tambah di depan (terbaru dulu)
    }
  }

  void _updateStatus(String messageId, String roomId, String status) {
    final roomMsgs = _messagesByRoom[roomId];
    if (roomMsgs == null) return;

    final idx = roomMsgs.indexWhere((m) => m.messageId == messageId);
    if (idx == -1) return;

    final old = roomMsgs[idx];
    roomMsgs[idx] = FcmChatMessage(
      messageId: old.messageId,
      roomId: old.roomId,
      senderId: old.senderId,
      senderName: old.senderName,
      message: old.message,
      jenisPesan: old.jenisPesan,
      sendStatus: status,
      tipeUser: old.tipeUser,
      sentAt: old.sentAt,
      idPaket: old.idPaket,
      noPenawaran: old.noPenawaran,
      noInvoice: old.noInvoice,
      userIds: old.userIds,
      receiverIds: old.receiverIds,
    );
  }

  void _emitToStream(String roomId) {
    final controller = _controllersByRoom[roomId];
    if (controller == null || controller.isClosed) return;

    final messages = _messagesByRoom[roomId] ?? [];
    controller.add(List.unmodifiable(messages));
  }

  void _incrementUnread(String roomId) {
    _unreadByRoom[roomId] = (_unreadByRoom[roomId] ?? 0) + 1;
  }

  void _incrementUnreadBy(String roomId, int count) {
    _unreadByRoom[roomId] = (_unreadByRoom[roomId] ?? 0) + count;
  }

  void _clearUnread(String roomId) {
    if ((_unreadByRoom[roomId] ?? 0) == 0) return;
    _unreadByRoom[roomId] = 0;
  }

  @override
  void dispose() {
    for (final c in _controllersByRoom.values) {
      c.close();
    }
    super.dispose();
  }
}