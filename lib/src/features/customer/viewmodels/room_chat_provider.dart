import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/paket_model.dart';
import 'package:mpjnew/src/data/models/penawaran_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/paket_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/penawaran_provider.dart';

class RoomChatProvider with ChangeNotifier {
  PaketProvider paketProv;
  PenawaranProvider penawaranProv;
  ChatProvider chatProv;

  RoomChatProvider({
    required this.paketProv,
    required this.penawaranProv,
    required this.chatProv,
  });

  final messageController = TextEditingController();

  String? vendorId;
  String? activeRoomId;
  RoomChatModel? roomInfo;

  List<PaketModel> paketList = [];
  List<PenawaranModel> penawaranList = [];

  PaketModel? tawaranPaket;
  PenawaranModel? tawaranPenawaran;
  bool isLoading = false;
  bool isSending = false;

  //=============================
  // ✅ GETTER - Realtime messages dari ChatProvider
  //=============================
  List<ChatModel> get messages {
    if (activeRoomId == null) return [];
    return chatProv.getMessages(activeRoomId!);
  }

  //=============================
  // ✅ INIT CHAT - DENGAN LISTENER DATA REAL-TIME
  //=============================
  Future<void> initChat({
    required String? roomId,
    required String? partnerId,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      debugPrint("=== INIT CHAT START ===");
      debugPrint("📍 Input roomId: $roomId");
      debugPrint("👤 Input partnerId: $partnerId");

      // Reset state
      vendorId = partnerId;
      tawaranPaket = null;
      tawaranPenawaran = null;
      activeRoomId = null;
      roomInfo = null;

      // Setup listener untuk data paket/penawaran real-time
      _setupRealTimeDataListeners();

      // =============================================
      // SCENARIO 1: Room ID sudah ada
      // =============================================
      if (roomId != null && roomId.isNotEmpty) {
        debugPrint("➡️ Using existing roomId: $roomId");
        activeRoomId = roomId;

        // Fetch detail room
        final rooms = await chatProv.fetchRooms(roomId: roomId);
        if (rooms.isNotEmpty) {
          roomInfo = rooms.first;
          vendorId = roomInfo!.userIds
              .firstWhere(
                (id) => id != chatProv.currentUserId,
                orElse: () => partnerId ?? '',
              )
              .toString();

          debugPrint("✅ Room info loaded");
        }

        // Load messages
        debugPrint("➡️ Loading messages for room: $activeRoomId");
        await chatProv.fetchMessages(activeRoomId!);

        // Load offer data dari semua pesan yang ada
        await loadOfferData();

        // Load data khusus untuk pesan yang memiliki idPaket/noInvoice
        await _loadSpecificOfferData();
      }
      // =============================================
      // SCENARIO 2: Cari/buat room berdasarkan partnerId
      // =============================================
      else if (partnerId != null && partnerId.isNotEmpty) {
        debugPrint("➡️ Looking for room with partnerId: $partnerId");

        final rooms = await chatProv.fetchRooms(idLawan: partnerId);

        if (rooms.isNotEmpty) {
          // Room sudah ada
          activeRoomId = rooms.first.roomId;
          roomInfo = rooms.first;

          debugPrint("✅ Found existing room: $activeRoomId");

          // Load messages
          await chatProv.fetchMessages(activeRoomId!);

          // Load offer data
          await loadOfferData();
          await _loadSpecificOfferData();
        } else {
          debugPrint("ℹ️ No existing room found");
        }
      }

      debugPrint("=== INIT CHAT SUCCESS ===");
    } catch (e, st) {
      debugPrint("❌ Init chat error: $e\n$st");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  //=============================
  // ✅ SETUP REAL-TIME DATA LISTENERS
  //=============================
  void _setupRealTimeDataListeners() {
    // Reset listeners
    chatProv.onPaketDataReceived = null;
    chatProv.onPenawaranDataReceived = null;

    // Setup listener untuk paket data
    chatProv.onPaketDataReceived = (PaketModel paket) {
      debugPrint(
          "ROOM_CHAT_PROVIDER :: Paket data received real-time: ${paket.nama_paket}");

      // Tambahkan ke list jika belum ada
      final exists = paketList.any((p) => p.no_id == paket.no_id);
      if (!exists) {
        paketList.add(paket);
      }

      // Jika ini adalah tawaran paket yang sedang aktif, update
      if (tawaranPaket?.no_id == paket.no_id) {
        tawaranPaket = paket;
      }

      notifyListeners();
    };

    // Setup listener untuk penawaran data
    chatProv.onPenawaranDataReceived = (PenawaranModel penawaran) {
      debugPrint(
          "ROOM_CHAT_PROVIDER :: Penawaran data received real-time: ${penawaran.noTrackingPenawaran}");

      // Tambahkan ke list jika belum ada
      final exists = penawaranList.any((p) => p.noId == penawaran.noId);
      if (!exists) {
        penawaranList.add(penawaran);
      }

      // Jika ini adalah tawaran penawaran yang sedang aktif, update
      if (tawaranPenawaran?.noId == penawaran.noId) {
        tawaranPenawaran = penawaran;
      }

      notifyListeners();
    };
  }

  //=============================
  // ✅ LOAD SPECIFIC OFFER DATA
  //=============================
  Future<void> _loadSpecificOfferData() async {
    debugPrint("=== LOAD SPECIFIC OFFER DATA START ===");

    final msgs = messages;

    for (final msg in msgs) {
      // Jika pesan memiliki idPaket, fetch data paket
      if (msg.idPaket != null && msg.idPaket!.isNotEmpty) {
        debugPrint("➡️ Fetching paket for id: ${msg.idPaket}");

        final paket = await chatProv.fetchPaket(msg.idPaket!);
        if (paket != null) {
          final exists = paketList.any((p) => p.no_id == paket.no_id);
          if (!exists) {
            paketList.add(paket);
            debugPrint("✅ Paket added: ${paket.nama_paket}");
          }
        }
      }

      // Jika pesan memiliki noInvoice, fetch data penawaran
      if (msg.noInvoice != null && msg.noInvoice!.isNotEmpty) {
        debugPrint("➡️ Fetching penawaran for no: ${msg.noInvoice}");

        final penawaran = await chatProv.fetchPenawaran(msg.noInvoice!);
        if (penawaran != null) {
          final exists =
              penawaranList.any((p) => p.noPesanan == penawaran.noPesanan);
          if (!exists) {
            penawaranList.add(penawaran);
            debugPrint("✅ Penawaran added: ${penawaran.noPesanan}");
          }
        }
      }
    }

    debugPrint("=== LOAD SPECIFIC OFFER DATA SUCCESS ===");
    debugPrint("   - Paket count: ${paketList.length}");
    debugPrint("   - Penawaran count: ${penawaranList.length}");

    notifyListeners();
  }

  //=============================
  // ✅ LOAD OFFER DATA (existing method)
  //=============================
  Future<void> loadOfferData() async {
    debugPrint("=== LOAD OFFER DATA START ===");

    try {
      // Jika room belum ada, skip loading offer data
      if (activeRoomId == null) {
        debugPrint("⚠️ No activeRoomId, skip loading offer data");
        paketList = [];
        penawaranList = [];
        return;
      }

      final msgs = messages;

      debugPrint("➡️ Loading paket from ${msgs.length} messages");
      paketList = await paketProv.fetchPaketFromRoom(msgs);

      debugPrint("➡️ Loading penawaran from ${msgs.length} messages");
      penawaranList = await penawaranProv.fetchPenawaranFromRoom(msgs);

      debugPrint("=== LOAD OFFER DATA SUCCESS ===");
      debugPrint("   - Paket count: ${paketList.length}");
      debugPrint("   - Penawaran count: ${penawaranList.length}");
    } catch (e, st) {
      debugPrint("❌ loadOfferData error: $e\n$st");
      paketList = [];
      penawaranList = [];
    } finally {
      notifyListeners();
    }
  }

  //=============================
  // ✅ CLEANUP LISTENERS SAAT DISPOSE
  //=============================
  @override
  void dispose() {
    // Cleanup listeners
    chatProv.onPaketDataReceived = null;
    chatProv.onPenawaranDataReceived = null;

    messageController.dispose();
    super.dispose();
  }

  //=============================
  // ✅ SEND MESSAGE - FULLY UPDATED
  //=============================
  Future<void> sendMessage({
    required String currentUserId,
  }) async {
    final text = messageController.text.trim();

    // Validation
    if (text.isEmpty) {
      debugPrint("⚠️ sendMessage: text is empty");
      return;
    }

    if (isSending) {
      debugPrint("⚠️ sendMessage: already sending, please wait");
      return;
    }

    isSending = true;
    notifyListeners();

    debugPrint("=== SEND MESSAGE START ===");
    debugPrint("📝 Message: $text");
    debugPrint("🏠 Current roomId: $activeRoomId");
    debugPrint("👤 Current userId: $currentUserId");
    debugPrint("👥 Partner ID: $vendorId");
    debugPrint("📦 Offer paket: ${tawaranPaket?.no_id}");

    try {
      // =============================================
      // STEP 1: Pastikan ada roomId atau partnerId
      // =============================================
      if (activeRoomId == null && vendorId == null) {
        throw Exception("Cannot send message: no roomId or partnerId");
      }

      // =============================================
      // STEP 2: Jika belum ada room, coba cari dulu
      // =============================================
      if (activeRoomId == null || activeRoomId!.isEmpty) {
        debugPrint("➡️ No active room, looking for existing room...");

        if (vendorId == null || vendorId!.isEmpty) {
          throw Exception("Cannot find/create room: no customerId");
        }

        final rooms = await chatProv.fetchRooms(idLawan: vendorId);

        if (rooms.isNotEmpty) {
          // Room ditemukan
          activeRoomId = rooms.first.roomId;
          roomInfo = rooms.first;
          debugPrint("✅ Found existing room: $activeRoomId");

          // Load messages untuk room ini
          await chatProv.fetchMessages(activeRoomId!);
        } else {
          // Room belum ada
          debugPrint("ℹ️ No room found, will create on send");
          // activeRoomId tetap null, backend akan create
        }
      }

      // =============================================
      // STEP 3: Prepare userIds
      // =============================================
      List<String> userIds = [];

      if (roomInfo != null) {
        // Room sudah ada, ambil dari roomInfo
        userIds = roomInfo!.userIds.map((e) => e.toString()).toList();
        debugPrint("➡️ Using userIds from roomInfo: $userIds");
      } else if (vendorId != null) {
        // Room baru, set manual
        userIds = [currentUserId, vendorId!];
        debugPrint("➡️ Creating new userIds: $userIds");
      } else {
        throw Exception("Cannot determine userIds");
      }

      // =============================================
      // STEP 4: Prepare message data
      // =============================================
      final isOfferPaket = tawaranPaket != null;
      final idPaket = isOfferPaket ? tawaranPaket!.no_id : null;

      debugPrint("➡️ Sending to ChatProvider.sendMessage");
      debugPrint("   - roomId: ${activeRoomId ?? 'null (will create)'}");
      debugPrint("   - userIds: $userIds");
      debugPrint("   - idPaket: $idPaket");

      // =============================================
      // STEP 5: Kirim message via ChatProvider
      // =============================================
      await chatProv.sendMessage(
        activeRoomId ?? "", // Jika null, backend akan create room
        text,
        idPaket,
        null, // noInvoice
        userIds,
      );

      debugPrint("✅ Message sent successfully");

      // =============================================
      // STEP 6: Update local state setelah kirim
      // =============================================

      // Jika sebelumnya room belum ada, fetch ulang untuk dapat roomId
      if (activeRoomId == null) {
        debugPrint("➡️ Fetching new room info after send...");

        // Tunggu sebentar untuk backend create room
        await Future.delayed(Duration(milliseconds: 500));

        final rooms = await chatProv.fetchRooms(idLawan: vendorId);

        if (rooms.isNotEmpty) {
          activeRoomId = rooms.first.roomId;
          roomInfo = rooms.first;

          debugPrint("✅ Room created with ID: $activeRoomId");

          // Load messages untuk room baru
          await chatProv.fetchMessages(activeRoomId!);
        } else {
          debugPrint("⚠️ Room tidak ditemukan setelah send");
        }
      }

      // =============================================
      // STEP 7: Cleanup UI
      // =============================================
      messageController.clear();
      tawaranPaket = null;

      // Reload offer data jika ada perubahan
      if (isOfferPaket) {
        await loadOfferData();
      }

      notifyListeners();

      debugPrint("=== SEND MESSAGE END ===");
    } catch (e, st) {
      debugPrint("❌ sendMessage error: $e\n$st");

      // Show error to user
      // Bisa gunakan SnackBar atau Dialog
      rethrow;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  //=============================
  // ✅ REFRESH ROOM DATA
  //=============================
  Future<void> refreshRoom() async {
    if (activeRoomId == null) {
      debugPrint("⚠️ Cannot refresh: no activeRoomId");
      return;
    }

    debugPrint("🔄 Refreshing room: $activeRoomId");

    try {
      // Refresh messages
      await chatProv.fetchMessages(activeRoomId!);

      // Refresh offer data
      await loadOfferData();

      debugPrint("✅ Room refreshed successfully");
    } catch (e) {
      debugPrint("❌ Refresh room error: $e");
    }
  }

  //=============================
  // ✅ MARK AS READ (opsional)
  //=============================
  // Future<void> markAsRead() async {
  //   if (activeRoomId == null) return;

  //   await chatProv.markRoomAsRead(activeRoomId!);
  // }

  //=============================
  // ✅ CLEANUP
  //=============================
  void reset() {
    debugPrint("🧹 Resetting RoomChatProvider");

    messageController.clear();
    vendorId = null;
    activeRoomId = null;
    roomInfo = null;
    paketList = [];
    penawaranList = [];
    tawaranPaket = null;
    isLoading = false;
    isSending = false;

    notifyListeners();
  }

  void setTawaranPaket(PaketModel? value) {
    tawaranPaket = value;
    notifyListeners();
  }

  void updateDependencies({
    required PaketProvider paketProv,
    required PenawaranProvider penawaranProv,
    required ChatProvider chatProv,
  }) {
    this.paketProv = paketProv;
    this.penawaranProv = penawaranProv;
    this.chatProv = chatProv;
  }
}
