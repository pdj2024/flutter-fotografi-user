import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/hive_entity/chat_message_entity.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';

/// ✅ CLEANED UP RoomChatProvider
///
/// Changes:
/// - ✅ Simplified: fokus pada UI state management saja
/// - ✅ Cleaner: less code, less complexity
class RoomChatProvider extends ChangeNotifier {
  final ChatProvider chatProv;

  RoomChatProvider({required this.chatProv});

  // Controllers
  final TextEditingController messageController = TextEditingController();

  // Current room state
  String? vendorId;
  String? activeRoomId;
  RoomChatModel? roomInfo;

  // Attachment (untuk send message)
  PaketModel? tawaranPaket;

  // Loading states
  bool isLoading = false;
  bool isSending = false;

  // =========================================
  // GETTERS
  // =========================================

  /// ✅ Get messages stream dari Hive (reactive)
  Stream<List<ChatMessageEntity>> get messagesStream {
    if (activeRoomId == null) return Stream.value([]);
    return chatProv.repository.getMessagesStream(activeRoomId!);
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
      debugPrint('═══════════════════════════════════════');
      debugPrint('[RoomChatProvider] 🚀 INIT ROOM CHAT');
      debugPrint('RoomId: $roomId');
      debugPrint('PartnerId: $partnerId');
      debugPrint('═══════════════════════════════════════');

      // Reset state
      vendorId = partnerId;
      tawaranPaket = null;
      activeRoomId = null;
      roomInfo = null;

      // ════════════════════════════════════════════════════════
      // CASE 1: Room ID sudah ada
      // ════════════════════════════════════════════════════════
      if (roomId != null && roomId.isNotEmpty) {
        debugPrint('→ Using existing roomId: $roomId');
        activeRoomId = roomId;

        // Set active room silently dulu
        chatProv.setActiveRoomSilently(activeRoomId);

        // Fetch room info dari API
        final rooms = await chatProv.fetchRooms(roomId: roomId);
        if (rooms.isNotEmpty) {
          roomInfo = rooms.first;
          vendorId = roomInfo!.idLawan;
        }

        // Load messages (akan otomatis enrich dengan full models)
        await chatProv.loadMessages(roomId);

        // Set active room dengan notify (untuk mark as read)
        chatProv.setActiveRoom(activeRoomId);
      }
      // ════════════════════════════════════════════════════════
      // CASE 2: Cari room by partnerId
      // ════════════════════════════════════════════════════════
      else if (partnerId != null && partnerId.isNotEmpty) {
        debugPrint('→ Finding room for partner: $partnerId');

        final rooms = await chatProv.fetchRooms(idLawan: partnerId);

        if (rooms.isNotEmpty) {
          activeRoomId = rooms.first.roomId;
          roomInfo = rooms.first;

          // Load messages
          await chatProv.loadMessages(activeRoomId!);

          // Set active room
          chatProv.setActiveRoom(activeRoomId);
        } else {
          debugPrint('→ No room found, will create on first message');
        }
      }

      debugPrint('═══════════════════════════════════════');
      debugPrint('[RoomChatProvider] ✅ INIT COMPLETE');
      debugPrint('ActiveRoomId: $activeRoomId');
      debugPrint('═══════════════════════════════════════');
    } catch (e, st) {
      debugPrint('[RoomChatProvider] ❌ initChat error: $e\n$st');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =========================================
  // ✅ HELPER: Get Models from Entities
  // =========================================

  /// Get paket dari entity (sudah tersimpan full model di Hive)
  PaketModel? getPaket(ChatMessageEntity entity) {
    return entity.paket;
  }

  /// Get penawaran dari entity
  PenawaranModel? getPenawaran(ChatMessageEntity entity) {
    return entity.penawaran;
  }

  /// Get pesanan dari entity
  PesananModel? getPesanan(ChatMessageEntity entity) {
    return entity.pesanan;
  }

  // =========================================
  // SEND MESSAGE
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
      debugPrint('═══════════════════════════════════════');
      debugPrint('[RoomChatProvider] 📤 SEND MESSAGE');
      debugPrint('CurrentUserId: $currentUserId');
      debugPrint('VendorId: $vendorId');
      debugPrint('ActiveRoomId: $activeRoomId');
      debugPrint('═══════════════════════════════════════');

      if (vendorId == null) {
        throw Exception('vendorId is null');
      }

      // Determine room & userIds
      String resolvedRoomId;
      List<String> resolvedUserIds;

      if (activeRoomId != null && activeRoomId!.isNotEmpty) {
        // Case A: Ada activeRoomId
        debugPrint('→ Using activeRoomId: $activeRoomId');
        resolvedRoomId = activeRoomId!;
        resolvedUserIds = roomInfo?.userIds ?? [currentUserId, vendorId!];
      } else {
        // Case B: Tidak ada activeRoomId, cari existing room
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
          chatProv.setActiveRoomSilently(activeRoomId);
        } else {
          debugPrint('→ No existing room, will create new');
          resolvedRoomId = '';
          resolvedUserIds = [currentUserId, vendorId!];
        }
      }

      debugPrint('ResolvedRoomId: $resolvedRoomId');
      debugPrint('ResolvedUserIds: $resolvedUserIds');

      // Send message
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

        // Jika room baru dibuat, fetch room info
        if (resolvedRoomId.isEmpty) {
          debugPrint('→ Fetching newly created room...');
          await Future.delayed(const Duration(milliseconds: 400));

          final rooms = await chatProv.fetchRooms(idLawan: vendorId);
          if (rooms.isNotEmpty) {
            activeRoomId = rooms.first.roomId;
            roomInfo = rooms.first;
            chatProv.setActiveRoomSilently(activeRoomId);
            await chatProv.loadMessages(activeRoomId!);
          }
        }

        debugPrint('✅ Message sent successfully');
      } else {
        debugPrint('❌ Failed to send message');
      }
    } catch (e, st) {
      debugPrint('[RoomChatProvider] ❌ sendMessage error: $e\n$st');
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  /// Send message dengan explicit partnerId
  Future<void> sendMessageToPartner({
    required String currentUserId,
    required String partnerId,
    String? message,
    PaketModel? paket,
  }) async {
    vendorId = partnerId;

    if (message != null && message.isNotEmpty) {
      messageController.text = message;
    }
    if (paket != null) {
      tawaranPaket = paket;
    }

    await sendMessage(currentUserId: currentUserId);
  }

  // =========================================
  // HELPERS
  // =========================================

  RoomChatModel? _findRoomByUserId({
    required String currentUserId,
    required String targetUserId,
  }) {
    if (currentUserId.isEmpty || targetUserId.isEmpty) {
      debugPrint('[RoomChatProvider] ⚠️ Invalid user IDs');
      return null;
    }

    try {
      if (chatProv.rooms.isEmpty) {
        debugPrint('[RoomChatProvider] ⚠️ No rooms available');
        return null;
      }

      final room = chatProv.rooms.firstWhere(
        (room) =>
            room.userIds.contains(currentUserId) &&
            room.userIds.contains(targetUserId),
      );

      debugPrint('[RoomChatProvider] ✅ Found room: ${room.roomId}');
      return room;
    } catch (e) {
      debugPrint('[RoomChatProvider] ⚠️ Room not found');
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
    if (activeRoomId == null) {
      debugPrint('[RoomChatProvider] ⚠️ Cannot refresh: no activeRoomId');
      return;
    }

    debugPrint('[RoomChatProvider] 🔄 Refreshing room: $activeRoomId');

    try {
      await chatProv.loadMessages(activeRoomId!);
      debugPrint('[RoomChatProvider] ✅ Room refreshed');
    } catch (e) {
      debugPrint('[RoomChatProvider] ❌ Refresh error: $e');
    }
  }



  // =========================================
  // CLEANUP
  // =========================================

  void reset() {
    debugPrint('[RoomChatProvider] 🧹 Resetting');

    messageController.clear();
    vendorId = null;
    activeRoomId = null;
    roomInfo = null;
    tawaranPaket = null;
    isLoading = false;
    isSending = false;

    notifyListeners();
  }

  void resetSilently() {
    messageController.clear();
    vendorId = null;
    activeRoomId = null;
    roomInfo = null;
    tawaranPaket = null;
    isLoading = false;
    isSending = false;
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
