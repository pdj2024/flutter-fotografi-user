import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/paket_model.dart';
import 'package:mpjnew/src/data/models/penawaran_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';

// Import providers yang sudah ada di project
// import 'package:mpjnew/src/features/customer/viewmodels/paket_provider.dart';
// import 'package:mpjnew/src/features/customer/viewmodels/penawaran_provider.dart';

/// Provider untuk mengelola single chat room
///
/// Kompatibel dengan struktur yang sudah ada
class RoomChatProvider extends ChangeNotifier {
  // Dependencies - gunakan dynamic untuk fleksibilitas
  dynamic paketProv;
  dynamic penawaranProv;
  ChatProvider chatProv;

  RoomChatProvider({
    required this.paketProv,
    required this.penawaranProv,
    required this.chatProv,
  }) {
    // ✅ Setup callback listener saat initialization
    _setupCallbacks();
  }

  // Controllers
  final TextEditingController messageController = TextEditingController();

  // Current room state
  String? vendorId;
  String? activeRoomId;
  RoomChatModel? roomInfo;

  // Related data lists
  List<PaketModel> paketList = [];
  List<PenawaranModel> penawaranList = [];

  // Attachment
  PaketModel? tawaranPaket;
  PenawaranModel? tawaranPenawaran;

  // Loading states
  bool isLoading = false;
  bool isSending = false;
  bool isLoadingOfferData = false;

  /// Setup callbacks dari ChatProvider
  void _setupCallbacks() {
    debugPrint('[RoomChatProvider] Setting up callbacks');

    // ✅ Listen untuk offer data needed
    chatProv.onOfferDataNeeded = (roomId) {
      debugPrint(
          '[RoomChatProvider] 🔔 onOfferDataNeeded triggered for room: $roomId');

      // Hanya load jika ini adalah active room kita
      if (activeRoomId == roomId) {
        debugPrint('[RoomChatProvider] → Loading offer data for active room');
        _autoLoadOfferData();
      } else {
        debugPrint('[RoomChatProvider] → Room $roomId is not active, skipping');
      }
    };
  }

  // Auto load offer data (dipanggil dari callback)

  Future<void> _autoLoadOfferData() async {
    // Prevent multiple simultaneous loads
    if (isLoadingOfferData) {
      debugPrint('[RoomChatProvider] ⚠️ Already loading offer data, skipping');
      return;
    }

    try {
      isLoadingOfferData = true;
      await loadOfferData();
    } finally {
      isLoadingOfferData = false;
    }
  }

  // =========================================
  // UPDATE DEPENDENCIES
  // =========================================

  void updateDependencies({
    required dynamic paketProv,
    required dynamic penawaranProv,
    required ChatProvider chatProv,
  }) {
    this.paketProv = paketProv;
    this.penawaranProv = penawaranProv;
    this.chatProv = chatProv;

    // ✅ Re-setup callbacks saat dependencies di-update
    _setupCallbacks();
  }

  // =========================================
  // GETTERS
  // =========================================

  /// Get messages dari ChatProvider (reactive)
  List<ChatModel> get messages {
    if (activeRoomId == null) return [];
    return chatProv.getMessages(activeRoomId!);
  }

  // =========================================
  // INITIALIZATION
  // =========================================

  /// Initialize chat room
  Future<void> initChat({
    required String? roomId,
    required String? partnerId,
  }) async {
    if (isLoading) return;

    isLoading = true;
    notifyListeners();

    try {
      debugPrint('=== INIT ROOM CHAT ===');
      debugPrint('RoomId: $roomId');
      debugPrint('PartnerId: $partnerId');

      // Reset state
      vendorId = partnerId;
      tawaranPaket = null;
      tawaranPenawaran = null;
      activeRoomId = null;
      chatProv.setActiveRoom(null);

      roomInfo = null;

      // ================================
      // CASE 1: Room ID sudah ada
      // ================================
      if (roomId != null && roomId.isNotEmpty) {
        debugPrint('→ Using existing roomId: $roomId');
        activeRoomId = roomId;
        // ✅ Set active room silently dulu
        chatProv.setActiveRoomSilently(activeRoomId);

        // Fetch room info
        final rooms = await chatProv.fetchRooms(roomId: roomId);
        if (rooms.isNotEmpty) {
          roomInfo = rooms.first;
          vendorId = roomInfo!.idLawan;
        }

        // Load messages
        await chatProv.fetchMessages(roomId);

        // Load related data
        await loadOfferData();

        // ✅ Set active room dengan notify (untuk mark as read)
        chatProv.setActiveRoom(activeRoomId);
      }
      // ================================
      // CASE 2: Cari room by partnerId
      // ================================
      else if (partnerId != null && partnerId.isNotEmpty) {
        debugPrint('→ Finding room for partner: $partnerId');

        final rooms = await chatProv.fetchRooms(idLawan: partnerId);

        if (rooms.isNotEmpty) {
          activeRoomId = rooms.first.roomId;
          chatProv.setActiveRoom(activeRoomId);

          roomInfo = rooms.first;

          // Load messages
          await chatProv.fetchMessages(activeRoomId!);

          // Load related data
          await loadOfferData();

          // ✅ Set active room dengan notify
          chatProv.setActiveRoom(activeRoomId);
        } else {
          debugPrint('→ No room found, will create on first message');
        }
      }

      debugPrint('=== INIT COMPLETE ===');
      debugPrint('ActiveRoomId: $activeRoomId');
      debugPrint('Messages: ${messages.length}');
    } catch (e, st) {
      debugPrint('❌ initChat error: $e\n$st');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  RoomChatModel? _findRoomByUserId({
    required String currentUserId,
    required String targetUserId,
  }) {
    // ✅ Null checks
    if (currentUserId.isEmpty || targetUserId.isEmpty) {
      debugPrint('⚠️ _findRoomByUserId: Invalid user IDs');
      return null;
    }

    try {
      // ✅ Pastikan chatProv dan rooms tidak null
      if (chatProv.rooms.isEmpty) {
        debugPrint('⚠️ _findRoomByUserId: No rooms available');
        return null;
      }

      final room = chatProv.rooms.firstWhere(
        (room) =>
            room.userIds.contains(currentUserId) &&
            room.userIds.contains(targetUserId),
      );

      debugPrint('✅ Found room: ${room.roomId}');
      return room;
    } catch (e) {
      debugPrint('⚠️ _findRoomByUserId: Room not found');
      return null;
    }
  }

  // =========================================
  // LOAD RELATED DATA
  // =========================================

  /// Load paket & penawaran untuk semua messages
  /// Load paket & penawaran untuk semua messages
  Future<void> loadOfferData() async {
    debugPrint('=== LOAD OFFER DATA ===');

    try {
      // ✅ Early return jika activeRoomId null
      if (activeRoomId == null || activeRoomId!.isEmpty) {
        debugPrint('⚠️ No activeRoomId, skipping loadOfferData');
        paketList = [];
        penawaranList = [];
        return;
      }

      final msgs = messages;

      // ✅ Early return jika tidak ada messages
      if (msgs.isEmpty) {
        debugPrint('⚠️ No messages, skipping loadOfferData');
        paketList = [];
        penawaranList = [];
        return;
      }

      // Collect unique IDs
      final paketIds = <String>{};
      final penawaranNos = <String>{};

      for (final msg in msgs) {
        // ✅ Null safe checks
        if (msg.hasPaket && msg.idPaket != null && msg.idPaket!.isNotEmpty) {
          paketIds.add(msg.idPaket!);
        }
        if (msg.hasPenawaran &&
            msg.noPenawaran != null &&
            msg.noPenawaran!.isNotEmpty) {
          penawaranNos.add(msg.noPenawaran!);
        }
      }

      debugPrint('Paket IDs to fetch: $paketIds');
      debugPrint('Penawaran Nos to fetch: $penawaranNos');

      // Fetch paket
      if (paketIds.isNotEmpty && paketProv != null) {
        try {
          debugPrint('Fetching paket from room...');
          final result = await paketProv.fetchPaketFromRoom(msgs);
          paketList = result ?? [];
          debugPrint('✅ Fetched ${paketList.length} paket');
        } catch (e, st) {
          debugPrint('❌ Error fetching paket: $e\n$st');
          paketList = [];
        }
      } else {
        debugPrint('⚠️ No paket to fetch or paketProv is null');
        paketList = [];
      }

      // Fetch penawaran
      if (penawaranNos.isNotEmpty && penawaranProv != null) {
        try {
          debugPrint('Fetching penawaran from room...');
          final result = await penawaranProv.fetchPenawaranFromRoom(msgs);
          penawaranList = result ?? [];
          debugPrint('✅ Fetched ${penawaranList.length} penawaran');
        } catch (e, st) {
          debugPrint('❌ Error fetching penawaran: $e\n$st');
          penawaranList = [];
        }
      } else {
        debugPrint('⚠️ No penawaran to fetch or penawaranProv is null');
        penawaranList = [];
      }

      // Cek apakah ada penawaran yang sudah jadi pesanan dan update cache
      if (penawaranList.isNotEmpty && activeRoomId != null) {
        for (final penawaran in penawaranList) {
          // ✅ Null safe checks
          if (penawaran.noPesanan != null &&
              penawaran.noPesanan!.isNotEmpty &&
              penawaran.noTrackingPenawaran != null &&
              penawaran.noTrackingPenawaran.isNotEmpty) {
            try {
              // Update message di cache
              chatProv.updatePenawaranToPesanan(
                activeRoomId!,
                penawaran.noTrackingPenawaran,
                penawaran.noPesanan!,
              );
              debugPrint(
                  '✅ Updated penawaran ${penawaran.noTrackingPenawaran} -> pesanan ${penawaran.noPesanan}');
            } catch (e) {
              debugPrint('❌ Error updating penawaran to pesanan: $e');
            }
          }
        }
      }

      debugPrint(
          '✅ Load offer data complete: ${paketList.length} paket, ${penawaranList.length} penawaran');
    } catch (e, st) {
      debugPrint('❌ loadOfferData error: $e\n$st');
      paketList = [];
      penawaranList = [];
    } finally {
      notifyListeners();
    }
  }

  /// Get paket by ID
  PaketModel? getPaket(String? idPaket) {
    if (idPaket == null) return null;
    try {
      return paketList.firstWhere(
        (p) => p.no_id == idPaket && p.status == 'aktif',
      );
    } catch (_) {
      return null;
    }
  }

  /// Get penawaran by No
  PenawaranModel? getPenawaran(String? noPenawaran) {
    if (noPenawaran == null) return null;
    try {
      return penawaranList.firstWhere(
        (p) => p.noId == noPenawaran && p.status == 'aktif',
      );
    } catch (_) {
      return null;
    }
  }

  // =========================================
// SEND MESSAGE - IMPROVED VERSION
// =========================================

  /// Send message dengan smart room detection
  Future<void> sendMessage({
    required String currentUserId,
  }) async {
    final text = messageController.text.trim();

    if (text.isEmpty && tawaranPaket == null) return;
    if (isSending) return;

    isSending = true;
    notifyListeners();

    try {
      debugPrint('=== SEND MESSAGE ===');
      debugPrint('CurrentUserId: $currentUserId');
      debugPrint('VendorId: $vendorId');
      debugPrint('ActiveRoomId: $activeRoomId');

      if (vendorId == null) {
        throw Exception('vendorId is null');
      }

      // 1️⃣ Tentukan room yang akan digunakan
      String resolvedRoomId;
      List<String> resolvedUserIds;

      if (activeRoomId != null && activeRoomId!.isNotEmpty) {
        // Case A: Ada activeRoomId (sedang di dalam room chat)
        debugPrint('→ Using activeRoomId: $activeRoomId');
        resolvedRoomId = activeRoomId!;
        resolvedUserIds = roomInfo?.userIds ?? [currentUserId, vendorId!];
      } else {
        // Case B: Tidak ada activeRoomId (kirim dari luar room, misal dari OfferCard)
        debugPrint('→ No activeRoomId, finding room...');

        final existingRoom = _findRoomByUserId(
          currentUserId: currentUserId,
          targetUserId: vendorId!,
        );

        if (existingRoom != null) {
          debugPrint('→ Found existing room: ${existingRoom.roomId}');
          resolvedRoomId = existingRoom.roomId;
          resolvedUserIds = existingRoom.userIds;

          // Update local state
          activeRoomId = existingRoom.roomId;
          roomInfo = existingRoom;
          chatProv.setActiveRoomSilently(
              activeRoomId); // ✅ Set tapi jangan mark as read
        } else {
          debugPrint('→ No existing room, will create new');
          resolvedRoomId = '';
          resolvedUserIds = [currentUserId, vendorId!];
        }
      }

      debugPrint('ResolvedRoomId: $resolvedRoomId');
      debugPrint('ResolvedUserIds: $resolvedUserIds');

      // 2️⃣ Send message
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

        // 3️⃣ Jika room baru dibuat, fetch room info
        if (resolvedRoomId.isEmpty) {
          debugPrint('→ Fetching newly created room...');
          await Future.delayed(const Duration(milliseconds: 400));

          final rooms = await chatProv.fetchRooms(idLawan: vendorId);
          if (rooms.isNotEmpty) {
            activeRoomId = rooms.first.roomId;
            roomInfo = rooms.first;
            chatProv.setActiveRoomSilently(activeRoomId);
            await chatProv.fetchMessages(activeRoomId!);
          }
        } else {
          // Room sudah ada, refresh messages
          await chatProv.fetchMessages(resolvedRoomId);
        }

        await loadOfferData();

        debugPrint('✅ Message sent successfully');
      } else {
        debugPrint('❌ Failed to send message');
      }
    } catch (e, st) {
      debugPrint('❌ sendMessage error: $e\n$st');
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  /// Send message dengan explicit partnerId (untuk kirim dari luar room)
  Future<void> sendMessageToPartner({
    required String currentUserId,
    required String partnerId,
    String? message,
    PaketModel? paket,
  }) async {
    // Set vendor ID dulu
    vendorId = partnerId;

    // Set message dan paket jika ada
    if (message != null && message.isNotEmpty) {
      messageController.text = message;
    }
    if (paket != null) {
      tawaranPaket = paket;
    }

    // Kirim message
    await sendMessage(currentUserId: currentUserId);
  }

  // =========================================
  // ATTACHMENT
  // =========================================

  /// Set paket attachment
  void attachPaket(String idPaket, PaketModel paket) {
    tawaranPaket = paket;
    notifyListeners();
  }

  /// Alias untuk setTawaranPaket (kompatibilitas)
  void setTawaranPaket(PaketModel? value) {
    tawaranPaket = value;
    notifyListeners();
  }

  /// Clear attachment
  void clearAttachment() {
    tawaranPaket = null;
    tawaranPenawaran = null;
    notifyListeners();
  }

  // =========================================
  // REFRESH
  // =========================================

  /// Refresh room
  Future<void> refreshRoom() async {
    if (activeRoomId == null) {
      debugPrint('⚠️ Cannot refresh: no activeRoomId');
      return;
    }

    debugPrint('🔄 Refreshing room: $activeRoomId');

    try {
      await chatProv.fetchMessages(activeRoomId!);
      await loadOfferData();
      debugPrint('✅ Room refreshed');
    } catch (e) {
      debugPrint('❌ Refresh error: $e');
    }
  }

  // =========================================
  // CLEANUP
  // =========================================

  /// Reset state
  void reset() {
    debugPrint('🧹 Resetting RoomChatProvider');

    messageController.clear();
    vendorId = null;
    activeRoomId = null;

    roomInfo = null;
    paketList = [];
    penawaranList = [];
    tawaranPaket = null;
    tawaranPenawaran = null;
    isLoading = false;
    isSending = false;
    isLoadingOfferData = false;

    // ✅ Clear callbacks
    chatProv.onOfferDataNeeded = null;

    notifyListeners();
  }

  void resetSilently() {
    messageController.clear();
    vendorId = null;
    activeRoomId = null;
    roomInfo = null;
    paketList = [];
    penawaranList = [];
    tawaranPaket = null;
    tawaranPenawaran = null;
    isLoading = false;
    isSending = false;
    isLoadingOfferData = false;

    // ✅ Clear callbacks
    chatProv.onOfferDataNeeded = null;
  }

  @override
  void dispose() {
    // ✅ Clear callbacks sebelum dispose
    chatProv.onOfferDataNeeded = null;
    messageController.dispose();
    super.dispose();
  }
}
