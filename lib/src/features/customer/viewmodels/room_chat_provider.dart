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
  bool isLoading = false;

  /// Getter messages mengambil langsung dari ChatProvider
  List<ChatModel> get messages {
    if (activeRoomId == null) return [];
    return chatProv.getMessages(activeRoomId!);
  }

  void setTawaranPaket(PaketModel? paket) {
    tawaranPaket = paket;
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

  /// --------------------------------------------------------------
  ///  INIT CHAT
  /// --------------------------------------------------------------
  Future<void> initChat({
    required String? roomId,
    required String? partnerId,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      print("=== INIT CHAT ===");
      print("roomId: $roomId");
      print("partnerId: $partnerId");

      vendorId = partnerId;

      if (roomId == null) {
        print("➡ Mencari room berdasarkan partnerId...");
        final rooms = await chatProv.fetchRooms(idLawan: vendorId);

        if (rooms.isNotEmpty) {
          activeRoomId = rooms.first.roomId;
          roomInfo = rooms.first;
        }
      } else {
        print("➡ Mengambil detail roomId...");
        activeRoomId = roomId;
        final rooms = await chatProv.fetchRooms(roomId: roomId);
        if (rooms.isNotEmpty) roomInfo = rooms.first;
      }

      if (activeRoomId != null) {
        print("➡ Mengambil pesan untuk room: $activeRoomId");
        await chatProv.fetchMessages(activeRoomId!);
      }

      await loadOfferData();

      print("=== INIT CHAT SELESAI ===");
    } catch (e) {
      print("❌ Init chat error: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  /// --------------------------------------------------------------
  ///  LOAD PACKAGE & OFFER
  /// --------------------------------------------------------------
  Future<void> loadOfferData() async {
    if (activeRoomId == null) return;

    print("=== LOAD OFFER/PACKAGE DATA ===");

    final msgs = chatProv.getMessages(activeRoomId!);

    paketList = await paketProv.fetchPaketFromRoom(msgs);
    penawaranList = await penawaranProv.fetchPenawaranFromRoom(msgs);

    print("paketList length: ${paketList.length}");
    print("penawaranList length: ${penawaranList.length}");

    notifyListeners();
  }

  /// --------------------------------------------------------------
  ///    SEND MESSAGE
  /// --------------------------------------------------------------
  Future<void> sendMessage({
    required String currentUserId,
  }) async {
    if (messageController.text.trim().isEmpty) return;

    print("=== SEND MESSAGE START ===");

    final text = messageController.text.trim();
    final isOfferPaket = tawaranPaket != null;

    List<String> userIds = [];

    if (roomInfo == null) {
      if (vendorId == null) return;
      print("Room baru → set userIds manual");
      userIds = [currentUserId, vendorId!];
    } else {
      userIds = roomInfo!.userIds.map((e) => e.toString()).toList();
    }

    print("send message: $text");
    print("roomId: $activeRoomId");
    print("userIds: $userIds");
    print("idPaket: ${tawaranPaket?.no_id}");

    print("➡ Mencari room berdasarkan partnerId...");
    final rooms = await chatProv.fetchRooms(idLawan: vendorId);

    if (rooms.isNotEmpty) {
      activeRoomId = rooms.first.roomId;
      roomInfo = rooms.first;
    }

    await chatProv.sendMessage(
      activeRoomId ?? "",
      text,
      isOfferPaket ? tawaranPaket!.no_id : null,
      null,
      userIds,
    );

    messageController.clear();
    tawaranPaket = null;

    /// Jika room baru → ambil lagi roomId
    if (activeRoomId == null) {
      final rooms = await chatProv.fetchRooms(idLawan: vendorId);
      if (rooms.isNotEmpty) {
        activeRoomId = rooms.first.roomId;
        roomInfo = rooms.first;
      }
    }

    // print("➡ Fetch ulang pesan setelah kirim");
    // await chatProv.fetchMessages(activeRoomId!);
    // await chatProv.refreshRooms(vendorId!, activeRoomId!, currentUserId);

    notifyListeners();

    print("=== SEND MESSAGE END ===");
  }
}
