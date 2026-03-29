import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/services/fcm/fcm_service.dart';
import 'package:mpjnew/src/data/isar/data/chat_message_entity.dart';
import 'package:mpjnew/src/data/isar/service/chat_isar_service.dart';
import 'package:mpjnew/src/data/isar/service/chat_storage_service.dart';
import 'package:collection/collection.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';

/// RoomChatProvider — Room-level state untuk RoomChatPage.
///
/// Tanggung jawab:
///   - Menyimpan state room yang sedang aktif (activeRoomId, roomInfo)
///   - Meng-cache Isar stream (SEKALI) agar StreamBuilder tidak resubscribe
///   - Delegasi send/load ke ChatProvider
///   - Handle app lifecycle (resume, drain background queue)
///   - Attachment (paket yang akan dikirim)
///
/// TIDAK bertanggung jawab untuk:
///   - Business logic pesan (ada di ChatSyncService)
///   - Penyimpanan ke Isar (ada di ChatStorageService)
///   - FCM handling (ada di FCMService → ChatProvider)
class RoomChatProvider extends ChangeNotifier {
  final ChatProvider chatProv;

  RoomChatProvider({required this.chatProv});

  // Controllers
  final TextEditingController messageController = TextEditingController();

  // ── Room state ────────────────────────────────────────────────
  String? vendorId;
  String? _activeRoomId;
  RoomChatModel? roomInfo;

  String? get activeRoomId => _activeRoomId;

  // ── Attachment ────────────────────────────────────────────────
  PaketModel? tawaranPaket;

  // ── Loading state ─────────────────────────────────────────────
  bool isLoading = false;
  bool isSending = false;
  bool isLoadingMoreDisplay = false;

  // ── Stream cache ──────────────────────────────────────────────
  // Di-cache SEKALI setelah initChat() sukses.
  // Isar broadcast stream aman untuk multi-listener.
  // Tidak boleh dibuat ulang di build() atau setState().
  StreamSubscription<List<ChatMessageEntity>>? _messagesSub;
  Stream<List<ChatMessageEntity>>? _mergedStream;
  StreamSubscription<List<ChatMessageEntity>>? _pendingStreamSub;

  bool _isInitializing = false;
  bool _disposed = false;

  // =========================================
  // GETTERS
  // =========================================

  /// Stream pesan dari Isar — di-cache, tidak dibuat ulang.
  /// Ambil setelah initChat() sukses.
  ///
  /// Jika room sudah ada: merged stream (room + pending sisa)
  /// Jika belum ada room (pesan pertama): hanya pending stream (roomId='')
  Stream<List<ChatMessageEntity>> get messagesStream {
    if (_mergedStream != null) return _mergedStream!;

    final roomId = _activeRoomId;
    final userId = chatProv.currentUserId ?? '';

    if (roomId != null && roomId.isNotEmpty) {
      // Room sudah ada — gabungkan stream room + pending (jaga-jaga ada sisa pending)
      final roomStream = chatProv.getMessagesStream(roomId);
      final pendingStream =
          ChatIsarService.instance.watchPendingMessages(userId);

      _mergedStream =
          _mergeMessageStreams(roomStream, pendingStream).asBroadcastStream();
    } else if (userId.isNotEmpty) {
      // Room belum ada (pesan pertama) — hanya pending stream (roomId='')
      _mergedStream = ChatIsarService.instance
          .watchPendingMessages(userId)
          .asBroadcastStream();
    } else {
      return const Stream.empty();
    }

    return _mergedStream!;
  }

  bool get hasMoreToDisplay {
    if (_activeRoomId == null) return false;
    return chatProv.hasMoreToDisplay(_activeRoomId!);
  }

  // =========================================
  // INITIALIZATION
  // =========================================

  Future<void> initChat({
    String? roomId,
    String? partnerId,
  }) async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      // Clear stale callback dari sesi sebelumnya
      ChatStorageService.instance.onRoomResolved = null;

      vendorId = partnerId;
      tawaranPaket = null;
      _activeRoomId = null;
      roomInfo = null;
      _mergedStream = null;
      await _messagesSub?.cancel();
      _messagesSub = null;

      if (roomId != null && roomId.isNotEmpty) {
        // ── Room sudah ada ───────────────────────────────────────────────
        _activeRoomId = roomId;
        roomInfo = chatProv.getRoom(roomId);
        if (roomInfo != null) vendorId = roomInfo!.idLawan;
        await _setupRoom(roomId);
      } else if (partnerId != null && partnerId.isNotEmpty) {
        isLoading = true;
        notifyListeners();

        // Cek apakah sudah ada room dengan partner ini di memory/Isar
        final existingRoom =
            chatProv.rooms.firstWhereOrNull((r) => r.idLawan == partnerId);

        if (existingRoom != null) {
          _activeRoomId = existingRoom.roomId;
          roomInfo = existingRoom;
          await _setupRoom(existingRoom.roomId);
        } else {
          // Belum ada room — stream pending akan menampilkan local echo
          // saat user mengirim pesan pertama (roomId='')
          debugPrint('[RoomChatProv] ℹ️ Belum ada room dengan: $partnerId');
          debugPrint('[RoomChatProv]    Kirim pesan pertama untuk memulai');
        }

        isLoading = false;
        notifyListeners();
      }
    } catch (e, st) {
      debugPrint('[RoomChatProv] ❌ initChat: $e\n$st');
      isLoading = false;
      notifyListeners();
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _setupRoom(String roomId) async {
    // Reset merged stream cache agar dibuat ulang dengan roomId baru
    _mergedStream = null;

    await ChatStorageService.setActiveRoomPref(roomId);
    await chatProv.trackRoom(roomId);
    chatProv.setActiveRoom(roomId);
    FCMService.instance.setActiveRoom(roomId);

    unawaited(ChatStorageService.instance.markRoomAsRead(roomId));
    chatProv.loadMessages(roomId, silent: true, forceRefresh: false);

    notifyListeners();
  }

  // =========================================
  // LOAD MORE
  // =========================================

  Future<void> loadMoreMessages() async {
    if (_activeRoomId == null || isLoadingMoreDisplay) return;
    if (!chatProv.hasMoreToDisplay(_activeRoomId!)) return;

    isLoadingMoreDisplay = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 200));
      chatProv.loadMoreDisplayedMessages(_activeRoomId!);
    } catch (e) {
      debugPrint('[RoomChatProv] ❌ loadMore: $e');
    } finally {
      isLoadingMoreDisplay = false;
      notifyListeners();
    }
  }

  // =========================================
  // APP LIFECYCLE — RESUME
  // =========================================

  /// Dipanggil dari RoomChatPage.didChangeAppLifecycleState saat app resume.
  Future<void> onAppResumed() async {
    final roomId = _activeRoomId;
    debugPrint('[RoomChatProv] 🔄 App resumed — activeRoom: $roomId');

    try {
      if (roomId != null) {
        final drained = await ChatStorageService.instance.drainBackgroundQueue(
          activeRoomId: roomId,
        );
        debugPrint('[RoomChatProv] 📬 Drained $drained messages');

        await ChatStorageService.instance.markRoomAsRead(roomId);
        debugPrint('[RoomChatProv] 👁️ Room marked as read: $roomId');

        await chatProv.syncRoomFromHiveAndNotify(roomId);
        debugPrint('[RoomChatProv] ✅ Resume sync complete');
      } else {
        final drained = await ChatStorageService.instance.drainBackgroundQueue(
          activeRoomId: null,
        );
        debugPrint(
            '[RoomChatProv] 📬 Drained $drained messages (no active room → received)');
      }
    } catch (e) {
      debugPrint('[RoomChatProv] ❌ onAppResumed: $e');
    }
  }

  // =========================================
  // SEND MESSAGE
  // =========================================

  Future<void> sendMessage({required String currentUserId}) async {
    final text = messageController.text.trim();

    if (text.isEmpty && tawaranPaket == null) return;
    if (isSending) return;

    isSending = true;
    notifyListeners();

    try {
      if (vendorId == null || vendorId!.isEmpty) {
        throw Exception('vendorId kosong');
      }

      String resolvedRoomId;
      List<String> resolvedUserIds;

      if (_activeRoomId != null && _activeRoomId!.isNotEmpty) {
        // ── Room sudah ada — normal flow ─────────────────────────────────
        resolvedRoomId = _activeRoomId!;
        resolvedUserIds = roomInfo?.userIds ?? [currentUserId, vendorId!];
      } else {
        // ── Pesan pertama — room belum ada ───────────────────────────────
        // Local echo disimpan ke Isar dengan roomId='' dan langsung
        // muncul di UI via watchPendingMessages (pending stream).
        // Backend membuat room baru dan mengirim FCM ke semua userIds.
        // FCM own echo → _handleFirstMessageEcho → onRoomResolved → _setupRoom.
        debugPrint('[RoomChatProv] ✉️ Pesan pertama ke partner: $vendorId');
        resolvedRoomId = '';
        resolvedUserIds = [currentUserId, vendorId!];

        // Daftarkan callback SEBELUM API call untuk cegah race condition:
        // jika API response datang sebelum FCM, confirmOptimisticMessage
        // juga akan memanggil onRoomResolved via _handleFirstMessageEcho.
        _listenForRoomResolution();
      }

      final success = await chatProv.sendMessage(
        roomId: resolvedRoomId,
        message: text,
        idPaket: tawaranPaket?.no_id,
        noPenawaran: null,
        userIds: resolvedUserIds,
      );

      if (success) {
        messageController.clear();
        tawaranPaket = null;
        notifyListeners();
        debugPrint('[RoomChatProv] ✅ Message sent '
            '(${resolvedRoomId.isEmpty ? "awaiting room from FCM" : resolvedRoomId})');
      } else {
        ChatStorageService.instance.onRoomResolved = null;
        debugPrint('[RoomChatProv] ❌ Send failed');
      }
    } catch (e, st) {
      ChatStorageService.instance.onRoomResolved = null;
      debugPrint('[RoomChatProv] ❌ sendMessage: $e\n$st');
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> sendMessageToPartner({
    required String currentUserId,
    required String partnerId,
    String? message,
    PaketModel? paket,
  }) async {
    vendorId = partnerId;
    if (message != null && message.isNotEmpty) messageController.text = message;
    if (paket != null) tawaranPaket = paket;
    await sendMessage(currentUserId: currentUserId);
  }

  // =========================================
  // HELPERS
  // =========================================

  Stream<List<ChatMessageEntity>> _mergeMessageStreams(
    Stream<List<ChatMessageEntity>> roomStream,
    Stream<List<ChatMessageEntity>> pendingStream,
  ) async* {
    List<ChatMessageEntity> latestRoom = [];
    List<ChatMessageEntity> latestPending = [];

    final controller = StreamController<List<ChatMessageEntity>>.broadcast();

    void emit() {
      if (controller.isClosed) return;

      // Gabungkan dan deduplikasi by messageId
      final allMessages = <String, ChatMessageEntity>{};
      for (final e in latestRoom) {
        allMessages[e.messageId] = e;
      }
      for (final e in latestPending) {
        // Hanya tambahkan pending jika belum ada di room stream
        if (!allMessages.containsKey(e.messageId)) {
          allMessages[e.messageId] = e;
        }
      }

      final merged = allMessages.values.toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

      controller.add(merged);
    }

    final roomSub = roomStream.listen(
      (data) {
        latestRoom = data;
        emit();
      },
      onError: controller.addError,
    );

    final pendingSub = pendingStream.listen(
      (data) {
        latestPending = data;
        emit();
      },
      onError: controller.addError,
    );

    emit();

    yield* controller.stream;

    await roomSub.cancel();
    await pendingSub.cancel();
    await controller.close();
  }

  void _listenForRoomResolution() {
    ChatStorageService.instance.onRoomResolved = (String newRoomId) async {
      debugPrint('[RoomChatProv] 📣 Room resolved: $newRoomId');

      ChatStorageService.instance.onRoomResolved = null;

      if (_disposed) return;

      _activeRoomId = newRoomId;
      roomInfo = chatProv.getRoom(newRoomId);

      // _mergedStream di-reset di dalam _setupRoom, tidak perlu di sini
      await _setupRoom(newRoomId);

      debugPrint('[RoomChatProv] ✅ Room setup selesai: $newRoomId');
    };
  }

  // =========================================
  // ATTACHMENT
  // =========================================

  void attachPaket(String idPaket, PaketModel paket) {
    tawaranPaket = paket;
    notifyListeners();
  }

  void setTawaranPaket(PaketModel? value) {
    tawaranPaket = value;
    notifyListeners();
  }

  void clearAttachment() {
    tawaranPaket = null;
    notifyListeners();
  }

  // =========================================
  // REFRESH
  // =========================================

  Future<void> refreshRoom() async {
    if (_activeRoomId == null) return;
    await chatProv.loadMessages(
      _activeRoomId!,
      forceRefresh: true,
      silent: false,
    );
    notifyListeners();
  }

  // =========================================
  // CLEANUP
  // =========================================

  void reset() {
    messageController.clear();
    vendorId = null;
    _activeRoomId = null;
    roomInfo = null;
    tawaranPaket = null;
    isLoading = false;
    isSending = false;
    isLoadingMoreDisplay = false;
    _mergedStream = null;
    notifyListeners();
  }

  void resetSilently() {
    messageController.clear();
    vendorId = null;
    _activeRoomId = null;
    roomInfo = null;
    tawaranPaket = null;
    isLoading = false;
    isSending = false;
    isLoadingMoreDisplay = false;
    _mergedStream = null;
  }

  Future<void> disposeRoom() async {
    debugPrint('[RoomChatProv] 🧹 disposeRoom: $_activeRoomId');

    await _messagesSub?.cancel();
    await _pendingStreamSub?.cancel();
    _messagesSub = null;
    _pendingStreamSub = null;
    _mergedStream = null;

    if (_activeRoomId != null) {
      chatProv.setActiveRoom(null);
      FCMService.instance.setActiveRoom(null);
    }

    await ChatStorageService.setActiveRoomPref(null);

    _activeRoomId = null;
    roomInfo = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ChatStorageService.instance.onRoomResolved = null;
    _messagesSub?.cancel();
    messageController.dispose();
    super.dispose();
  }
}
