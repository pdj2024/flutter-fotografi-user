import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/pages/fotografi_user/detil_bayar.dart';
import 'package:mpjnew/src/pages/providers/chat_service.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/constants.dart';
import 'fotographerbio.dart';
import '../providers/custom_back_button.dart';
import '../providers/navigation_provider.dart';

class SingleChat extends StatefulWidget {

  final String receiverUserName;
  final String receiverEmail;
  final String receiverID;

  SingleChat({super.key, required this.receiverUserName, required this.receiverEmail, required this.receiverID});

  @override
  State<SingleChat> createState() => _SingleChatState();
}

class _SingleChatState extends State<SingleChat> {
  final ChatService _chatService = ChatService();

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();







  // Widget _buildUserList() {
  void sendMessage(BuildContext context) async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(context.read<NavigationProvider>(), widget.receiverID, widget.receiverEmail, _messageController.text);

      _messageController.clear();
    }
  }

//  final List<ChatMessage> messages = [
 // Fungsi grouping pesan per tanggal, pesan dalam grup diurut ascending (lama ke baru)
  

  Widget _buildMessageList(BuildContext context) {
    String senderID = 'cus_2'; //context.read<NavigationProvider>().getCurrentUserID();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _chatService.getMessages(userID: widget.receiverID, otherUserID: senderID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs.map((doc) {
          final data = doc.data();
          return ChatMessage(
            text: data['message'] ?? '',
            time: (data['timestamp'] as Timestamp).toDate(),
            isMe: data['senderID'] == senderID,
            category: data['category'] ?? 'chat',

             // Tambahan untuk category: 'payment' (bisa null dan aman)
    hargaPaket: data['harga_paket'],
   tglRealisasi: data['tgl_realisasi'] != null
    ? (data['tgl_realisasi'] as Timestamp).toDate()
    : null,
    lokasiPaket: data['lokasi']  ?? '',

            // Tambahan untuk category: 'package' (bisa null dan aman)
            namaPaket: data['nama_paket']  ?? ''
          );
        }).toList();

        // Urutkan tanggal dari terbaru ke terlama (descending)
        messages.sort((a, b) => b.time.compareTo(a.time));

        // Group pesan per tanggal
        final grouped = groupMessagesByDate(messages);

        // auto-scroll ke bawah setiap kali rebuild
WidgetsBinding.instance.addPostFrameCallback((_) {
  _scrollController.animateTo(
    0.0,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );
});

        return ListView(
          controller: _scrollController,
          reverse: true, // supaya scroll mulai dari bawah (terbaru)
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          children: grouped.entries.expand((entry) {
            final dateLabel = entry.key;
            final messages = entry.value;

            // Pesan di tiap grup sudah ascending, tinggal render

            return [
              // Karena reverse: true, tanggal diletakkan setelah pesan
              ...messages.map((message) {
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
        // const SizedBox(height: 8),
        if (message.text.isNotEmpty) _buildChatBubble(message),
      
            
        
      
        // const SizedBox(height: 12),
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
    );
  }



  Widget _buildMessageItem(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data();
  return Text(data["message"] ?? '', style: const TextStyle(color: Colors.black));
}


  Map<String, List<ChatMessage>> groupMessagesByDate(List<ChatMessage> messages) {
    final Map<String, List<ChatMessage>> grouped = {};
    for (var message in messages) {
      final key = context.read<NavigationProvider>().formatDateLabel(message.time);
      grouped.putIfAbsent(key, () => []).add(message);
    }
    return grouped;
  }

// String _formatDateLabel(DateTime date) {
//   final now = DateTime.now();
//   final today = DateTime(now.year, now.month, now.day);
//   final messageDate = DateTime(date.year, date.month, date.day);

//   if (messageDate == today) return "Hari ini";
//   if (messageDate == today.subtract(const Duration(days: 1))) return "Kemarin";
  
//   // Format dengan singkatan bulan dan locale Indonesia
//   return DateFormat("d MMM yyyy", "id_ID").format(date); // Contoh: 6 Mei 2025
// }

  @override
  Widget build(BuildContext context) {
    // final groupedMessages = groupMessagesByDate(sortedMessages);
      final String imgUrl = context.read<NavigationProvider>().ambilGambar('d00c8632-393e-49e8-847f-3c01a4dbf701-image_cropper_1748677823909.jpg');

    return Scaffold(
      appBar: AppBar(
  backgroundColor: const Color(0xFFF9F9F9),
  elevation: 1,
   leading: CustomBackButton(),
  title: GestureDetector(
    onTap: () {
    context.read<NavigationProvider>().navigateToPage(
                          context, PhotographerBio(idVendor: 'ven_100',), targetTabIndex:0, );  // Ubah idVendor sesuai kebutuhan
    },
    child: Row(
      children: [
       CircleAvatar(
  radius: 18,
  backgroundColor: Colors.grey.shade300,
  child: ClipOval(
    child: CachedNetworkImage(
      imageUrl: imgUrl,
      width: 36,  // radius * 2
      height: 36,
      fit: BoxFit.cover,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          width: 36,
          height: 36,
          color: Colors.white,
        ),
      ),
      errorWidget: (context, url, error) => Icon(
        Icons.error,
        size: 18,
        color: Colors.red,
      ),
    ),
  ),
),

        const SizedBox(width: 12),
        Expanded(
          child: Text(
          widget.receiverUserName,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20, // lebih besar
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    ),
  ),
  toolbarHeight: 72, // menaikkan tinggi AppBar
),

      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [

          Expanded(
  child: _buildMessageList(context),
),

        
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white.withOpacity(0),
            child: Row(
              children: [
                Expanded(
  child: TextField(
    cursorColor: Constants.primaryColor, // warna kursor diubah di sini
     controller: _messageController,
    decoration: InputDecoration(
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                  icon: const Icon(Icons.send, color: Constants.primaryColor),
                  onPressed: () {
                    // Kirim pesan
                    sendMessage(context);
                  },
                ),
              ],
            ),
          ),
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
          color: message.isMe ? Constants.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
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

  final backgroundColor = isMe
      ? Constants.primaryColor.withOpacity(0.1)
      : Colors.white;

  final innerContainerColor = isMe ? Colors.white : const Color(0xFFF5F5F5);

  final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;

  final titleText = isMe
      ? "Kamu bertanya tentang paket ini"
      : "Vendor mengajukan paket ini";

  return Align(
    alignment: alignment,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 300),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isMe ? null : [
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
          Text(
            titleText,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: innerContainerColor,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                const Icon(
                  Icons.card_giftcard,
                  color: Constants.primaryColor,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaPaket,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "IDR $formattedHarga",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Constants.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  // Format tanggal dan jam dari tglRealisasi
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text("$jam, $tanggal", style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(height: 2),
        Text(lokasi, style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              context.read<NavigationProvider>().pushFullPage(
                  context, DetilBayar());
            },
            child: const Text("BAYAR",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

   // Tambahan (nullable, karena hanya ada di message payment)
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
    this.namaPaket
  });
}