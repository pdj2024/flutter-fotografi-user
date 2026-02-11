import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/data/hive_entity/chat_message_entity.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';

/// ✅ SIMPLIFIED: Progressive Loading WITHOUT API Pagination
///
/// Strategy (No API pagination support):
/// 1. Instantly show Hive data (< 50ms) - 100 latest messages
/// 2. Background sync ALL messages from API (silent)
/// 3. Store ALL in memory, latest 100 in Hive
/// 4. User can scroll through all 100 messages smoothly
///
/// Note: API fetches ALL messages at once, no pagination needed
class RoomChatProvider extends ChangeNotifier {
  final ChatProvider chatProv;

  RoomChatProvider({required this.chatProv});

  // Controllers
  final TextEditingController messageController = TextEditingController();

  // Current room state
  String? vendorId;
  String? activeRoomId;
  RoomChatModel? roomInfo;

  // Attachment
  PaketModel? tawaranPaket;

  // Loading states
  bool isLoading = false;
  bool isSending = false;
  bool isLoadingMoreDisplay = false;

  // ✅ NO pagination flags needed (API fetches all at once)

  // =========================================
  // GETTERS
  // =========================================

  Stream<List<ChatMessageEntity>> get messagesStream {
    if (activeRoomId == null) return Stream.value([]);
    return chatProv.getMessagesStream(activeRoomId!);
  }

  String getDisplayStats() {
    if (activeRoomId == null) return 'No active room';

    final total = chatProv.getTotalMessagesCount(activeRoomId!);
    final displayed = chatProv.getDisplayedMessagesCount(activeRoomId!);
    final hasMore = chatProv.hasMoreToDisplay(activeRoomId!);

    return 'Displayed: $displayed / $total (hasMore: $hasMore)';
  }

  bool get hasMoreToDisplay {
    if (activeRoomId == null) return false;
    return chatProv.hasMoreToDisplay(activeRoomId!);
  }

  // =========================================
  // INITIALIZATION (SIMPLIFIED PROGRESSIVE)
  // =========================================

  /// ✅ SIMPLIFIED: Initialize with instant Hive display + background sync
  Future<void> initChat({
    String? roomId,
    String? partnerId,
  }) async {
    if (isLoading) {
      debugPrint('[RoomChatProvider] ⚠️ Already loading, skipping...');
      return;
    }

    // ✅ DON'T set isLoading = true initially
    // We want instant display from Hive!

    try {
      debugPrint('═══════════════════════════════════════');
      debugPrint('[RoomChatProvider] 🚀 INIT (Simplified Progressive)');
      debugPrint('[RoomChatProvider] RoomId: $roomId');
      debugPrint('[RoomChatProvider] PartnerId: $partnerId');
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
        debugPrint('[RoomChatProvider] → Case 1: Using existing roomId');

        activeRoomId = roomId;

        // ✅ PHASE 1: Instantly load from Hive (NO LOADING STATE!)
        await _instantLoadFromHive(roomId);

        // Get room info from cache
        roomInfo = chatProv.getRoom(roomId);

        if (roomInfo != null) {
          debugPrint('[RoomChatProvider] ✅ Room found in cache');
          vendorId = roomInfo!.idLawan;
        } else {
          debugPrint('[RoomChatProvider] 🔍 Room info not cached');
        }

        // ✅ PHASE 2: Background sync ALL messages (silent)
        _backgroundSyncAllMessages(roomId);
      }
      // ════════════════════════════════════════════════════════
      // CASE 2: Find/create room by partnerId
      // ════════════════════════════════════════════════════════
      else if (partnerId != null && partnerId.isNotEmpty) {
        debugPrint('[RoomChatProvider] → Case 2: Finding/creating room');

        // Set loading only for this case (new room)
        isLoading = true;
        notifyListeners();

        final existingRoom = await chatProv.findOrCreateRoom(partnerId);

        if (existingRoom != null) {
          activeRoomId = existingRoom.roomId;
          roomInfo = existingRoom;
          vendorId = partnerId;

          // ✅ Instantly load from Hive
          await _instantLoadFromHive(activeRoomId!);

          // ✅ Background sync
          _backgroundSyncAllMessages(activeRoomId!);
        } else {
          debugPrint(
              '[RoomChatProvider] ℹ️ No room found, will create on first message');
          vendorId = partnerId;
        }

        isLoading = false;
        notifyListeners();
      }
      // ════════════════════════════════════════════════════════
      // CASE 3: Invalid
      // ════════════════════════════════════════════════════════
      else {
        throw Exception('Either roomId or partnerId must be provided');
      }

      debugPrint('═══════════════════════════════════════');
      debugPrint('[RoomChatProvider] ✅ INIT COMPLETE (Simplified)');
      debugPrint('[RoomChatProvider] ActiveRoomId: $activeRoomId');
      debugPrint('[RoomChatProvider] Instant load: ✓');
      debugPrint('[RoomChatProvider] Background sync: In progress...');
      debugPrint('[RoomChatProvider] Strategy: Show 100 latest, sync ALL');
      debugPrint('═══════════════════════════════════════');
    } catch (e, st) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('[RoomChatProvider] ❌ INIT ERROR');
      debugPrint('[RoomChatProvider] Error: $e');
      debugPrint('[RoomChatProvider] Stack: $st');
      debugPrint('═══════════════════════════════════════');

      isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ PHASE 1: Instant load from Hive (< 50ms)
  /// Shows up to 100 latest messages from cache
  Future<void> _instantLoadFromHive(String roomId) async {
    try {
      final cachedMessages = await chatProv.repository.getMessages(roomId);

      if (cachedMessages.isNotEmpty) {
        debugPrint(
            '[RoomChatProvider] ⚡ Showing ${cachedMessages.length} cached messages (< 50ms)');
        // Stream will emit automatically via Hive watcher
        // No need to call notifyListeners() - stream handles it!
      } else {
        debugPrint('[RoomChatProvider] ℹ️ No cached messages');
        debugPrint('[RoomChatProvider] ℹ️ Will load from API in background...');
      }
    } catch (e) {
      debugPrint('[RoomChatProvider] ⚠️ Instant load error: $e');
    }
  }

  Future<void> loadMoreMessages() async {
    if (activeRoomId == null || isLoadingMoreDisplay) {
      return;
    }

    // Check if has more
    if (!chatProv.hasMoreToDisplay(activeRoomId!)) {
      debugPrint('[RoomChatProvider] ℹ️ All messages already displayed');
      return;
    }

    debugPrint(
        '[RoomChatProvider] 📥 Loading more for display (from memory)...');
    debugPrint('[RoomChatProvider] ${getDisplayStats()}');

    isLoadingMoreDisplay = true;
    notifyListeners();

    try {
      // Small delay for UX
      await Future.delayed(const Duration(milliseconds: 200));

      // Load more from MEMORY (instant!)
      final hasMore = chatProv.loadMoreDisplayedMessages(activeRoomId!);

      if (!hasMore) {
        debugPrint('[RoomChatProvider] ✅ All messages now displayed');
      } else {
        final total = chatProv.getTotalMessagesCount(activeRoomId!);
        final displayed = chatProv.getDisplayedMessagesCount(activeRoomId!);

        debugPrint('[RoomChatProvider] ✅ Now displaying: $displayed of $total');
      }
    } catch (e) {
      debugPrint('[RoomChatProvider] ❌ Load more error: $e');
    } finally {
      isLoadingMoreDisplay = false;
      notifyListeners();
    }
  }

  /// ✅ PHASE 2: Background sync ALL messages (silent, no UI blocking)
  /// Fetches ALL messages from API and stores:
  /// - ALL messages in memory (for search, etc.)
  /// - Latest 100 in Hive (for instant display next time)
  void _backgroundSyncAllMessages(String roomId) {
    debugPrint('[RoomChatProvider] 🔄 Starting background sync...');
    debugPrint('[RoomChatProvider] ℹ️ API will fetch ALL messages at once');

    // Fire and forget - don't await
    chatProv
        .loadMessages(
      roomId,
      forceRefresh: true,
      silent: true, // ✅ No loading indicator!
    )
        .then((messages) {
      debugPrint('[RoomChatProvider] ✅ Background sync complete');
      debugPrint('[RoomChatProvider] 📊 Total messages: ${messages.length}');
      debugPrint(
          '[RoomChatProvider] 💾 Stored in memory: ${messages.length} (ALL)');
      debugPrint(
          '[RoomChatProvider] 💾 Stored in Hive: ${messages.length > 100 ? 100 : messages.length} (latest)');
      // Stream will auto-update UI via Hive watcher if new messages
    }).catchError((e) {
      debugPrint('[RoomChatProvider] ⚠️ Background sync error: $e');
      // Silent failure - user already sees cached data
    });
  }

  // =========================================
  // HELPER: Get Models from Entities
  // =========================================

  PaketModel? getPaket(ChatMessageEntity entity) => entity.paket;
  PenawaranModel? getPenawaran(ChatMessageEntity entity) => entity.penawaran;
  PesananModel? getPesanan(ChatMessageEntity entity) => entity.pesanan;

  // =========================================
  // SEND MESSAGE
  // =========================================

  Future<void> sendMessage({required String currentUserId}) async {
    final text = messageController.text.trim();

    if (text.isEmpty && tawaranPaket == null) {
      debugPrint('[RoomChatProvider] ⚠️ Nothing to send');
      return;
    }

    if (isSending) {
      debugPrint('[RoomChatProvider] ⚠️ Already sending, skipping...');
      return;
    }

    isSending = true;
    notifyListeners();

    try {
      debugPrint('═══════════════════════════════════════');
      debugPrint('[RoomChatProvider] 📤 SEND MESSAGE');
      debugPrint(
          '[RoomChatProvider] Message: ${text.isEmpty ? "(paket)" : text}');
      debugPrint('═══════════════════════════════════════');

      if (vendorId == null || vendorId!.isEmpty) {
        throw Exception('vendorId is null or empty');
      }

      // Determine room & userIds
      String resolvedRoomId;
      List<String> resolvedUserIds;

      if (activeRoomId != null && activeRoomId!.isNotEmpty) {
        resolvedRoomId = activeRoomId!;
        resolvedUserIds = roomInfo?.userIds ?? [currentUserId, vendorId!];
      } else {
        final existingRoom = _findRoomByUserId(
          currentUserId: currentUserId,
          targetUserId: vendorId!,
        );

        if (existingRoom != null) {
          resolvedRoomId = existingRoom.roomId;
          resolvedUserIds = existingRoom.userIds;
          activeRoomId = existingRoom.roomId;
          roomInfo = existingRoom;
        } else {
          resolvedRoomId = '';
          resolvedUserIds = [currentUserId, vendorId!];
        }
      }

      // Send via ChatProvider
      final success = await chatProv.sendMessage(
        roomId: resolvedRoomId,
        message: text,
        idPaket: tawaranPaket?.no_id,
        noPenawaran: null,
        userIds: resolvedUserIds,
      );

      if (success) {
        debugPrint('[RoomChatProvider] ✅ Message sent successfully');

        // Clear input
        messageController.clear();
        tawaranPaket = null;

        // If new room, fetch room info
        if (resolvedRoomId.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 500));

          final newRoom = await chatProv.findOrCreateRoom(vendorId!);

          if (newRoom != null) {
            activeRoomId = newRoom.roomId;
            roomInfo = newRoom;

            // ✅ Instant load + background sync for new room
            await _instantLoadFromHive(activeRoomId!);
            _backgroundSyncAllMessages(activeRoomId!);
          }
        }

        notifyListeners();
      } else {
        debugPrint('[RoomChatProvider] ❌ Failed to send message');
      }

      debugPrint('═══════════════════════════════════════');
    } catch (e, st) {
      debugPrint('[RoomChatProvider] ❌ SEND MESSAGE ERROR: $e\n$st');
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
    if (currentUserId.isEmpty || targetUserId.isEmpty) return null;

    try {
      final allRooms = chatProv.rooms;
      if (allRooms.isEmpty) return null;

      return allRooms.firstWhere(
        (room) =>
            room.userIds.contains(currentUserId) &&
            room.userIds.contains(targetUserId),
      );
    } catch (e) {
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

    debugPrint('[RoomChatProvider] 🔄 Manual refresh room: $activeRoomId');

    try {
      await chatProv.loadMessages(
        activeRoomId!,
        forceRefresh: true,
        silent: false, // Show loading for manual refresh
      );
      debugPrint('[RoomChatProvider] ✅ Room refreshed');
      notifyListeners();
    } catch (e) {
      debugPrint('[RoomChatProvider] ❌ Refresh error: $e');
    }
  }

  // =========================================
  // CLEANUP
  // =========================================

  void reset() {
    messageController.clear();
    vendorId = null;
    activeRoomId = null;
    roomInfo = null;
    tawaranPaket = null;
    isLoading = false;
    isSending = false;
    isLoadingMoreDisplay = false; // ✅ ADD THIS
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
    isLoadingMoreDisplay = false; // ✅ ADD THIS
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
