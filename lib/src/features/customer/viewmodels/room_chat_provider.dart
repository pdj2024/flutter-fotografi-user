import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/isar/data/chat_message_entity.dart';
import 'package:mpjnew/src/data/isar/service/chat_storage_service.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/core/services/fcm_chat_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ROOM CHAT PROVIDER — Customer Edition (Isar)
//
// Perbedaan dari versi lama (Hive/in-memory):
//   - Stream pesan: dari ChatProvider.getMessagesStream (Isar native)
//     → di-cache di _messagesStream (SEKALI, tidak dibuat ulang)
//   - initChat: set activeRoomPref + trackRoom + markRoomAsRead
//   - onAppResumed: drain background queue + markRoomAsRead + API sync
//   - disposeRoom: clear activeRoomPref
//   - Tidak ada _instantLoadFromHive / _backgroundSyncAllMessages
//     (Isar stream sudah handle keduanya secara otomatis)
//   - _findRoomByUserId: dari ChatProvider.rooms (bukan in-memory list)
//
// Kompatibilitas dengan kode lama:
//   - messagesStream getter → tetap ada, dari Isar
//   - sendMessage() → tetap ada, delegasi ke ChatProvider
//   - attachPaket / clearAttachment → tetap ada
//   - reset() / resetSilently() → tetap ada
// ═══════════════════════════════════════════════════════════════════════════

class RoomChatProvider extends ChangeNotifier {
  final ChatProvider chatProv;
  final FcmChatProvider fcmChatProv;

  RoomChatProvider({
    required this.chatProv,
    required FcmChatProvider fcmChatProv,
  }) : fcmChatProv = fcmChatProv;

  // Controllers
  final TextEditingController messageController = TextEditingController();

  // ── Room state ────────────────────────────────────────────────
  String? vendorId;         // partnerId (id lawan chat)
  String? _activeRoomId;   // roomId yang sedang aktif
  RoomChatModel? roomInfo;

  String? get activeRoomId => _activeRoomId;

  // ── Attachment ────────────────────────────────────────────────
  PaketModel? tawaranPaket;

  // ── Loading ───────────────────────────────────────────────────
  bool isLoading = false;
  bool isSending = false;
  bool isLoadingMoreDisplay = false;

  // ── Stream cache ──────────────────────────────────────────────
  // ✅ Di-cache SEKALI agar StreamBuilder di RoomChatPage tidak
  // cancel+resubscribe setiap setState. Isar broadcast stream aman untuk ini.
  Stream<List<ChatMessageEntity>>? _messagesStream;
  StreamSubscription<List<ChatMessageEntity>>? _messagesSub;

  // ── Isar subscription untuk mark read ─────────────────────────
  bool _isInitializing = false;

  // =========================================
  // GETTERS
  // =========================================

  /// ✅ Isar stream — di-cache, tidak dibuat ulang.
  /// Ambil setelah initChat() sukses.
  Stream<List<ChatMessageEntity>> get messagesStream {
    if (_activeRoomId == null) return const Stream.empty();
    _messagesStream ??= chatProv.getMessagesStream(_activeRoomId!);
    return _messagesStream!;
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
    if (_isInitializing) {
      debugPrint('[RoomChatProv] ⚠️ Already initializing, skip');
      return;
    }

    _isInitializing = true;

    try {
      debugPrint('[RoomChatProv] 🚀 initChat — roomId: $roomId, partnerId: $partnerId');

      // Reset state sebelumnya
      vendorId = partnerId;
      tawaranPaket = null;
      _activeRoomId = null;
      roomInfo = null;
      _messagesStream = null;
      await _messagesSub?.cancel();
      _messagesSub = null;

      // ── CASE 1: roomId sudah ada ────────────────────────────────
      if (roomId != null && roomId.isNotEmpty) {
        _activeRoomId = roomId;
        roomInfo = chatProv.getRoom(roomId);

        if (roomInfo != null) {
          vendorId = roomInfo!.idLawan;
        }

        await _setupRoom(roomId);
      }
      // ── CASE 2: Cari/buat room by partnerId ────────────────────
      else if (partnerId != null && partnerId.isNotEmpty) {
        isLoading = true;
        notifyListeners();

        final existingRoom = await chatProv.findOrCreateRoom(partnerId);

        if (existingRoom != null) {
          _activeRoomId = existingRoom.roomId;
          roomInfo = existingRoom;
          vendorId = partnerId;
          await _setupRoom(existingRoom.roomId);
        } else {
          debugPrint('[RoomChatProv] ℹ️ No room yet — will create on first message');
          vendorId = partnerId;
        }

        isLoading = false;
        notifyListeners();
      } else {
        throw Exception('Harus ada roomId atau partnerId');
      }

      debugPrint('[RoomChatProv] ✅ initChat complete — activeRoom: $_activeRoomId');
    } catch (e, st) {
      debugPrint('[RoomChatProv] ❌ initChat error: $e\n$st');
      isLoading = false;
      notifyListeners();
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _setupRoom(String roomId) async {
    // ✅ Simpan activeRoomId ke SharedPreferences agar background drain tahu
    await ChatStorageService.setActiveRoomPref(roomId);

    // ✅ Track room di ChatProvider (trigger background sync)
    await chatProv.trackRoom(roomId);

    // ✅ Set active room di ChatProvider & FCMService
    chatProv.setActiveRoom(roomId);
    fcmChatProv.setActiveRoom(roomId);

    // ✅ Cache stream SEKALI — tidak dibuat ulang
    _messagesStream = chatProv.getMessagesStream(roomId);

    // ✅ Mark semua pesan sebagai read (Isar lokal + API per pesan)
    unawaited(ChatStorageService.instance.markRoomAsRead(roomId));

    // ✅ Load messages dari API (silent, Isar stream update UI otomatis)
    chatProv.loadMessages(roomId, silent: true);

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

  /// Dipanggil saat app resume dari background (RoomChatPage.didChangeAppLifecycleState).
  ///
  ///   _activeRoomId != null → drain queue (→ read) + markRoomAsRead + API sync
  ///   _activeRoomId == null → drain queue (→ received) saja
  Future<void> onAppResumed() async {
    final roomId = _activeRoomId;

    debugPrint('[RoomChatProv] 🔄 App resumed — activeRoom: $roomId');

    try {
      if (roomId != null) {
        // Step 1: Drain background queue
        //   - Pesan room INI → 'read' (Isar + API)
        //   - Pesan room LAIN → 'received'
        final drained = await ChatStorageService.instance.drainBackgroundQueue(
          activeRoomId: roomId,
        );
        debugPrint('[RoomChatProv] 📬 Drained $drained messages');

        // Step 2: Mark semua yang sudah ada di Isar → 'read'
        await ChatStorageService.instance.markRoomAsRead(roomId);
        debugPrint('[RoomChatProv] 👁️ Room marked as read: $roomId');

        // Step 3: Incremental sync dari API
        await chatProv.syncRoomFromHiveAndNotify(roomId);

        debugPrint('[RoomChatProv] ✅ Resume sync complete');
      } else {
        // Tidak ada room aktif — semua pesan queue → 'received'
        final drained = await ChatStorageService.instance.drainBackgroundQueue(
          activeRoomId: null,
        );
        debugPrint('[RoomChatProv] 📬 Drained $drained messages (no active room → received)');
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
        resolvedRoomId = _activeRoomId!;
        resolvedUserIds = roomInfo?.userIds ?? [currentUserId, vendorId!];
      } else {
        final existingRoom = _findRoomByUserId(
          currentUserId: currentUserId,
          targetUserId: vendorId!,
        );

        if (existingRoom != null) {
          resolvedRoomId = existingRoom.roomId;
          resolvedUserIds = existingRoom.userIds;
          _activeRoomId = existingRoom.roomId;
          roomInfo = existingRoom;
        } else {
          resolvedRoomId = '';
          resolvedUserIds = [currentUserId, vendorId!];
        }
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

        // Jika room baru (belum ada roomId)
        if (resolvedRoomId.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 500));
          final newRoom = await chatProv.findOrCreateRoom(vendorId!);
          if (newRoom != null) {
            _activeRoomId = newRoom.roomId;
            roomInfo = newRoom;
            _messagesStream = null; // Reset agar dibuat ulang dengan roomId baru
            await _setupRoom(newRoom.roomId);
          }
        }

        notifyListeners();
      } else {
        debugPrint('[RoomChatProv] ❌ Send failed');
      }
    } catch (e, st) {
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

  RoomChatModel? _findRoomByUserId({
    required String currentUserId,
    required String targetUserId,
  }) {
    if (currentUserId.isEmpty || targetUserId.isEmpty) return null;
    try {
      return chatProv.rooms.firstWhere(
        (room) =>
            room.userIds.contains(currentUserId) &&
            room.userIds.contains(targetUserId),
      );
    } catch (_) {
      return null;
    }
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
    await chatProv.loadMessages(_activeRoomId!, forceRefresh: true, silent: false);
    notifyListeners();
  }

  // =========================================
  // CLEANUP
  // =========================================

  /// Dipanggil saat RoomChatPage di-dispose atau pindah ke room lain
  Future<void> disposeRoom() async {
    debugPrint('[RoomChatProv] 🧹 disposeRoom: $_activeRoomId');

    await _messagesSub?.cancel();
    _messagesSub = null;
    _messagesStream = null;

    if (_activeRoomId != null) {
      chatProv.setActiveRoom(null);
      fcmChatProv.setActiveRoom(null);
    }

    // Hapus activeRoomPref agar background drain tidak salah target
    await ChatStorageService.setActiveRoomPref(null);

    _activeRoomId = null;
    roomInfo = null;
    notifyListeners();
  }

  void reset() {
    messageController.clear();
    vendorId = null;
    _activeRoomId = null;
    roomInfo = null;
    tawaranPaket = null;
    isLoading = false;
    isSending = false;
    isLoadingMoreDisplay = false;
    _messagesStream = null;
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
    _messagesStream = null;
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    messageController.dispose();
    super.dispose();
  }
}