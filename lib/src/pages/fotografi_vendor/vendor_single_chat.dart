import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/pages/fotografi_user/detil_bayar.dart';
import 'package:provider/provider.dart';

import '../providers/constants.dart';
// import 'fotographerbio.dart';
import '../providers/custom_back_button.dart';
import '../providers/navigation_provider.dart';
import 'chat_offer.dart';

class VendorSingleChat extends StatefulWidget {
  VendorSingleChat({super.key});

  @override
  State<VendorSingleChat> createState() => _VendorSingleChatState();
}

class _VendorSingleChatState extends State<VendorSingleChat> {
  bool showOverlay = false;

  void toggleOverlay() => setState(() => showOverlay = !showOverlay);



  final List<ChatMessage> messages = [
    ChatMessage(
      text: "",
      time: DateTime.now().subtract(const Duration(days: 3, hours: 2, minutes: 25)),
      isMe: false,
      category: "package",
    ),
    ChatMessage(
      text: "Paket pernikahan apa saja yang tersedia?",
      time: DateTime.now().subtract(const Duration(days: 3, hours: 2, minutes: 25)),
      isMe: false,
      category: "chat",
    ),
    ChatMessage(
      text:
          "Paket pernikahan yang kami tawarkan meliputi berbagai layanan lengkap.\n\nHarga paket ini adalah IDR 500.000. Termasuk foto dan video.",
      time: DateTime.now().subtract(const Duration(days: 3, hours: 1, minutes: 12)),
      isMe: true,
      category: "chat",
    ),
    ChatMessage(
      text: "450.000 boleh?",
      time: DateTime.now().subtract(const Duration(days: 2, hours: 10, minutes: 18)),
      isMe: false,
      category: "chat",
    ),
    ChatMessage(
      text: "Baik, harga IDR 450.000 sudah termasuk semua layanan yang disebutkan.",
      time: DateTime.now().subtract(const Duration(days: 2, hours: 4, minutes: 14)),
      isMe: true,
      category: "chat",
    ),
    ChatMessage(
      text: "Bagus, kita lanjutkan dengan harga itu!",
      time: DateTime.now().subtract(const Duration(days: 1, hours: 4, minutes: 14)),
      isMe: false,
      category: "chat",
    ),
    ChatMessage(
      text: "",
      time: DateTime.now().subtract(const Duration(days: 1, hours: 4, minutes: 12)),
      isMe: true,
      category: "payment",
    ),
    ChatMessage(
      text: "Terima kasih ya kak!",
      time: DateTime.now().subtract(const Duration(hours: 4, minutes: 48)),
      isMe: false,
      category: "chat",
    ),
    ChatMessage(
      text: "Sampai jumpa di hari H.",
      time: DateTime.now().subtract(const Duration(hours: 4, minutes: 14)),
      isMe: true,
      category: "chat",
    ),
  ];

  List<ChatMessage> get sortedMessages {
    final sorted = List<ChatMessage>.from(messages);
    sorted.sort((a, b) => a.time.compareTo(b.time));
    return sorted;
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

  @override
  Widget build(BuildContext context) {
    final groupedMessages = groupMessagesByDate(sortedMessages);

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
          elevation: 3,
          leading: CustomBackButton(),
          title: GestureDetector(
            onTap: () {
              // context.read<NavigationProvider>().navigateToPage(context, PhotographerBio(), targetTabIndex: 0);
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "rizkyputra",
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
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    children: groupedMessages.entries.expand((entry) {
                      final dateLabel = entry.key;
                      final messages = entry.value;
                      return [
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
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        ...messages.map((message) {
                          if (message.category == "package") {
                            return _buildPackageCard();
                          } else if (message.category == "payment") {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: _buildPaymentCard(context),
                            );
                          } else {
                            return _buildChatBubble(message);
                          }
                        }),
                      ];
                    }).toList(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white.withOpacity(0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          cursorColor: Constants.primaryColorVendor,
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
                        icon: const Icon(Icons.add, color: Constants.primaryColorVendor),
                        onPressed: toggleOverlay,
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        icon: const Icon(Icons.send, color: Constants.primaryColorVendor),
                        onPressed: () {
                          // Kirim pesan
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (showOverlay)
              Positioned.fill(
                child: GestureDetector(
                  onTap: toggleOverlay,
                  child: Container(color: Colors.transparent),
                ),
              ),

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
                    shadowColor: Colors.black.withOpacity(0.2),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildOverlayItem(Icons.receipt_long, "Paket\nSaya", () {
  toggleOverlay();
  context.read<NavigationProvider>().vendorNavigateToPage(
    context, ChatOffer(), targetTabIndex: 1,
  );}),
  _buildOverlayItem(Icons.edit_note, "Buat\nPenawaran", () {
  toggleOverlay();
  context.read<NavigationProvider>().vendorNavigateToPage(
    context, ChatOffer(), targetTabIndex: 1,
  );}),
                          _buildOverlayItem(Icons.image, "Gambar\n", toggleOverlay),
                          _buildOverlayItem(Icons.insert_drive_file, "File\n", toggleOverlay),
                        ],
                      ),
                    ),
                  ),
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
            child: Icon(icon, color: Constants.primaryColorVendor, size: 24),
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
          color: message.isMe ? Constants.primaryColorVendor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.text, style: const TextStyle(fontSize: 14, color: Colors.black)),
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

  Widget _buildPackageCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
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
          const Text("Customer bertanya tentang paket ini", style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard, color: Constants.primaryColorVendor, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Wedding Package",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      SizedBox(height: 4),
                      Text("Rp500.000",
                          style: TextStyle(
                              fontSize: 14,
                              color: Constants.primaryColorVendor,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context) {
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
          const Text("IDR 450.000",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text("15.00, 22 Apr 2024", style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 2),
          Text("Crowne Plaza Bandung", style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColorVendor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                // context.read<NavigationProvider>().pushFullPage(context, DetilBayar());
              },
              child: const Text("CEK STATUS",
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

  ChatMessage({
    required this.text,
    required this.time,
    required this.isMe,
    required this.category,
  });
}
