import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/pages/fotografi_user/detil_bayar.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/chat_provider.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/pages/fotografi_user/services/chat_service.dart';

import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/custom_back_button.dart';
import '../../core/routing/navigation_provider.dart';


class VendorSingleChat extends StatefulWidget {
  final String? roomId;

  
  final String? id_lawan;
  final String? username_lawan;

  final String? avatar_lawan;

  const VendorSingleChat({
    super.key,
    this.roomId,
   
  
    this.id_lawan,
    this.username_lawan,
    this.avatar_lawan
  });

  @override
  State<VendorSingleChat> createState() => _SingleChatState();
}

class _SingleChatState extends State<VendorSingleChat> {

    final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();


   bool showOverlay = false;
  void toggleOverlay() => setState(() => showOverlay = !showOverlay);




  String? _activeRoomId;
  Map<String, dynamic>? _roomInfo;
  bool _isLoading = true;

  @override
  void initState() {
     super.initState();

     
      print("===== VENDOR SINGLE CHAT (room id): " + widget.roomId.toString());
       print("===== VENDOR SINGLE CHAT (user ids): " + widget.id_lawan.toString());
      final userId = context.read<UserProvider>().userId ?? '';
    Future.microtask(() {
      context.read<ChatProvider>().init(userId);
    });
     
    _initChat();
  }

  Future<void> _initChat() async {
    final userId = context.read<UserProvider>().userId ?? '';
    final chatProv = context.read<ChatProvider>();

    if (widget.roomId != null) {
      // ✅ langsung pakai roomId yang ada
      _activeRoomId = widget.roomId;
      await chatProv.fetchMessages(_activeRoomId!);

      final rooms = await chatProv.fetchRooms(
        
        room_id: _activeRoomId,
      );
      if (rooms.isNotEmpty) {
        setState(() => _roomInfo = rooms.first);
      }
    } else if (widget.id_lawan != null) {
      // ✅ coba cari room existing dengan lawan
    
      final rooms = await chatProv.fetchRooms(
        
        id_lawan: widget.id_lawan,
      );

      if (rooms.isNotEmpty) {
        // ✅ ketemu existing room
        setState(() {
          _activeRoomId = rooms.first['Room_Id'];
          _roomInfo = rooms.first;
        });
        await chatProv.fetchMessages(_activeRoomId!);
      } else {
        // ✅ belum ada room, tunggu sampai kirim pesan pertama
        setState(() {
          _activeRoomId = null;
          _roomInfo = null;
        });
      }
    } else {
      // ❌ tidak ada roomId & userIds
      setState(() {
        _activeRoomId = null;
        _roomInfo = null;
      });
    }

    setState(() => _isLoading = false);
  }

 void _sendMessage(BuildContext context) async {

  print("==== VENDOR SINGLE CHAT: INI SATU");
    if (_messageController.text.isEmpty) return;
      print("==== VENDOR SINGLE CHAT: INI DUA");

    final chatProv = context.read<ChatProvider>();
    final currentUserId = context.read<UserProvider>().userId ?? '';

   List<String> userIds = [];

  if (_roomInfo == null) {
    // ✅ new chat harus ada id lawan
    if (widget.id_lawan == null) {
      print('============= VENDOR Single Chat: id_lawan kosong, tidak bisa kirim pesan');
      return;
    }

    userIds = [
      currentUserId,
      widget.id_lawan!, // ambil lawan dari widget
    ];
  } else {
    // ✅ kalau roomInfo ada, ambil dari room
    final ids = _roomInfo!['User_Ids'];
    if (ids is List) {
      userIds = ids.map((e) => e.toString()).toList();
    }
  }



    await chatProv.sendMessage(
      _activeRoomId ?? "", // kosong kalau new chat
      _messageController.text,
      null, // idPaket
      null, // noInvoice
      userIds,
    );

    _messageController.clear();

    // setelah kirim pesan pertama, ambil room baru
    if (_activeRoomId == null) {
      final rooms = await chatProv.fetchRooms(
       
        id_lawan: userIds.firstWhere((id) => id != currentUserId, orElse: () => ""),
      );
      if (rooms.isNotEmpty) {
        setState(() {
          _activeRoomId = rooms.first['Room_Id'];
          _roomInfo = rooms.first;
        });
        await chatProv.fetchMessages(_activeRoomId!);
      }
    }
  }







@override
  Widget build(BuildContext context) {
    final chatProv = context.watch<ChatProvider>();
    final messages = _activeRoomId != null
        ? chatProv.getMessages(_activeRoomId!)
        : [];

    // auto-scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && messages.isNotEmpty) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeRoomId == null && (widget.id_lawan == null)) {
      return const Center(child: Text("Tidak ada chat"));
    }

    final String imgUrl = _roomInfo?['Id_Media_Lawan'] ?? widget.avatar_lawan ?? '';

    return WillPopScope(
       onWillPop: () async {
      if (showOverlay) {
        toggleOverlay();
        return false;
      }
      return true;
    },

      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 1,
          leading: CustomBackButton(),
          title: GestureDetector(
            onTap: () {
              // context.read<NavigationProvider>().navigateToPage(
              //       context,
              //       PhotographerBio(idVendor: _roomInfo?['Id_Lawan'] ?? widget.id_lawan),
              //       targetTabIndex: 0,
              //     );
            },
            child: Row(
              children: [
          CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              child: CachedNetworkImage(
                imageUrl: imgUrl ?? '',
                imageBuilder: (context, imageProvider) =>
                    CircleAvatar(radius: 18, backgroundImage: imageProvider),
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: const CircleAvatar(radius: 18, backgroundColor: Colors.white),
                ),
                errorWidget: (context, url, error) =>
                    const CircleAvatar(radius: 18, child: Icon(Icons.person)),
              ),
            ),

      
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _roomInfo?['Username_Lawan'] ?? widget.username_lawan,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          toolbarHeight: 72,
        ),
        backgroundColor: const Color(0xFFF9F9F9),
        body: Column(
          children: [
            // Daftar pesan
           Expanded(
        child: Builder(
      builder: (context) {
        // urutkan pesan descending
        final sorted = [...messages]..sort((a, b) => b['SentAt'].compareTo(a['SentAt']));
      
        // mapping ke ChatMessage
        final chatMessages = sorted.map((msg) => ChatMessage(
          text: msg['Text'] ?? '',
          time: msg['SentAt'] ?? DateTime.now(),
         isMe: (msg['Sender']?.toString() ?? '') == (chatProv.currentUserId ?? ''),
      
          category: msg['Category'] ?? 'chat',
          hargaPaket: msg['Harga_Paket'],
          tglRealisasi: msg['Tgl_Realisasi'],
          lokasiPaket: msg['Lokasi'],
          namaPaket: msg['Nama_Paket'],
        )).toList();
      
        // group per tanggal
        final grouped = groupMessagesByDate(chatMessages);
      
        return ListView(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          children: grouped.entries.expand((entry) {
            final dateLabel = entry.key;
            final groupMsgs = entry.value;
      
            return [
              ...groupMsgs.map((message) {
                if (message.category == "package") {
                  return Column(
                    crossAxisAlignment: message.isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      _buildPackageCard(
                        namaPaket: message.namaPaket ?? '',
                        hargaPaket: message.hargaPaket ?? 0,
                        isMe: message.isMe,
                      ),
                      if (message.text.isNotEmpty) _buildChatBubble(message),
                    ],
                  );
                } else if (message.category == "payment") {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: _buildPaymentCard(
                      context,
                      harga: message.hargaPaket ?? 0,
                      tglRealisasi: message.tglRealisasi,
                      lokasi: message.lokasiPaket ?? "-",
                    ),
                  );
                } else {
                  return _buildChatBubble(message);
                }
              }),
              // label tanggal
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dateLabel,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ];
          }).toList(),
        );
      },
        ),
      ),
      // 🔹 Overlay background
          if (showOverlay)
            Positioned.fill(
              child: GestureDetector(
                onTap: toggleOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),


          // 🔹 Overlay menu
          if (showOverlay)
            Positioned(
              bottom: 72,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: const Color(0xFFFAFAFA),
                  elevation: 8,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildOverlayItem(Icons.receipt_long, "Paket", () {}),
                        _buildOverlayItem(Icons.edit_note, "Penawaran", () {}),
                        _buildOverlayItem(Icons.image, "Gambar", () {}),
                        _buildOverlayItem(Icons.insert_drive_file, "File", () {}),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Input box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white.withOpacity(0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      cursorColor: Constants.primaryColor,
                      controller: _messageController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        hintText: "Ketik pesan...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFE8E8E8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                   
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.add, color: Constants.primaryColor),
                      onPressed: toggleOverlay,
                    ),

                  IconButton(
                    icon: const Icon(Icons.send, color: Constants.primaryColor),
                    onPressed: () => _sendMessage(context),
                  ),
                ],
              ),
            ),
           

          ],
        ),
      ),
    );
  }

Widget _buildOverlayItem(IconData icon, String label, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white,
          child: Icon(icon, color: Constants.primaryColor, size: 24),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
      ],
    ),
  );
}


  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: message.isMe
              ? Constants.primaryColor.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.text,
                style: const TextStyle(fontSize: 14, color: Colors.black)),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.time),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard({
    required String namaPaket,
    required int hargaPaket,
    required bool isMe,
  }) {
    final formattedHarga = NumberFormat("#,###", "id_ID").format(hargaPaket);
    final backgroundColor =
        isMe ? Constants.primaryColor.withOpacity(0.1) : Colors.white;
    final innerContainerColor =
        isMe ? Colors.white : const Color(0xFFF5F5F5);
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final titleText =
        isMe ? "Kamu bertanya tentang paket ini" : "Vendor mengajukan paket ini";

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isMe
              ? null
              : [
                  const BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titleText,
                style:
                    const TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: innerContainerColor,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard,
                      color: Constants.primaryColor, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(namaPaket,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text("IDR $formattedHarga",
                            style: const TextStyle(
                                fontSize: 14,
                                color: Constants.primaryColor,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(
    BuildContext context, {
    required int harga,
    required DateTime? tglRealisasi,
    required String lokasi,
  }) {
    final formattedHarga = NumberFormat("#,###", "id_ID").format(harga);
    String jam = "-";
    String tanggal = "-";
    if (tglRealisasi != null) {
      jam = DateFormat("HH:mm").format(tglRealisasi) + " WIB";
      tanggal = DateFormat("dd MMM yyyy", "id_ID").format(tglRealisasi);
    }

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("IDR $formattedHarga",
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text("$jam, $tanggal",
              style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 2),
          Text(lokasi, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                context
                    .read<NavigationProvider>()
                    .pushFullPage(context, DetilBayar());
              },
              child: const Text("BAYAR",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final DateTime time;
  final bool isMe;
  final String category;
  final int? hargaPaket;
  final DateTime? tglRealisasi;
  final String? lokasiPaket;
  final String? namaPaket;

  ChatMessage({
    required this.text,
    required this.time,
    required this.isMe,
    required this.category,
    this.hargaPaket,
    this.tglRealisasi,
    this.lokasiPaket,
    this.namaPaket,
  });
}


Map<String, List<ChatMessage>> groupMessagesByDate(List<ChatMessage> messages) {
  final Map<String, List<ChatMessage>> grouped = {};
  for (var message in messages) {
    final key = _formatDateLabel(message.time);
    grouped.putIfAbsent(key, () => []).add(message);
  }
  return grouped;
}

String _formatDateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDate = DateTime(date.year, date.month, date.day);

  if (messageDate == today) return "Hari ini";
  if (messageDate == today.subtract(const Duration(days: 1))) return "Kemarin";

  return DateFormat("d MMM yyyy", "id_ID").format(date);
}
