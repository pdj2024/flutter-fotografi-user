import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:mpjnew/src/features/customer/widget/chat_bubble.dart';
import 'package:mpjnew/src/features/customer/widget/chat_package_card.dart';
import 'package:mpjnew/src/features/customer/widget/chat_payment_card.dart';
import 'package:mpjnew/src/pages/fotografi_user/detil_bayar.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/chat_provider.dart';
import 'package:mpjnew/src/pages/fotografi_user/single_chat.dart';
import 'package:mpjnew/src/pages/providers/custom_back_button.dart';
import 'package:provider/provider.dart';

class RoomChatPage extends StatefulWidget {
  final String? roomId;
  final String? partnerId;
  final String? partnerUsername;
  final String? partnerAvatarUrl;

  const RoomChatPage(
      {super.key,
      this.roomId,
      this.partnerId,
      this.partnerUsername,
      this.partnerAvatarUrl});

  @override
  State<RoomChatPage> createState() => _RoomChatPageState();
}

class _RoomChatPageState extends State<RoomChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _activeRoomId;
  Map<String, dynamic>? _roomInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print("===== SINGLE CHAT (room id): " + widget.roomId.toString());
    print("===== SINGLE CHAT (user ids): " + widget.partnerId.toString());

    _initChat();
  }

  Future<void> _initChat() async {
    // final userId = context.read<UserProvider>().userId ?? '';
    _isLoading = true;
    final chatProv = context.read<ChatProvider>();

    try {
      /**
       * Jadi ada 2 kemungkinan, masuk ke halaman ini
       * 1. room id ada, langsung pakai room id tersebut
       * 2. room id tidak ada, coba cari room existing dengan lawan menggunakan partnerId
       * 
       */

      // jika room id dan partner id kosong, kembali ke halaman sebelumnya
      if (widget.roomId == null && widget.partnerId == null) {
        return Navigator.of(context).pop();
      }

      // Jika room id kosong, maka cari room dari Parnert ID
      if (widget.roomId == null) {
        final rooms = await chatProv.fetchRooms(
          id_lawan: widget.partnerId,
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
      }

      // Jika partner id kosong, maka cari room lewat roomId
      if (widget.partnerId == null) {
        final rooms = await chatProv.fetchRooms(
          room_id: widget.roomId,
        );

        if (rooms.isNotEmpty) {
          setState(() => _roomInfo = rooms.first);
        }
      }
    } catch (e) {
      print("❌ Error saat init chat: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _sendMessage(BuildContext context) async {
    print("==== SINGLE CHAT: INI SATU");
    if (_messageController.text.isEmpty) return;
    print("==== SINGLE CHAT: INI DUA");

    final chatProv = context.read<ChatProvider>();
    final currentUserId = context.read<UserProvider>().userId ?? '';

    List<String> userIds = [];

    if (_roomInfo == null) {
      // ✅ new chat harus ada id lawan
      if (widget.partnerId == null) {
        print(
            '============= Single Chat: id_lawan kosong, tidak bisa kirim pesan');
        return;
      }

      userIds = [
        currentUserId,
        widget.partnerId!, // ambil lawan dari widget
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
        id_lawan:
            userIds.firstWhere((id) => id != currentUserId, orElse: () => ""),
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
    final messages =
        _activeRoomId != null ? chatProv.getMessages(_activeRoomId!) : [];

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

    if (_activeRoomId == null && (widget.partnerId == null)) {
      return const Center(child: Text("Tidak ada chat"));
    }

    final String imgUrl =
        _roomInfo?['Id_Media_Lawan'] ?? widget.partnerAvatarUrl ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
        leading: CustomBackButton(),
        title: GestureDetector(
          onTap: () {
            context.read<NavigationProvider>().navigateToPage(
                  context,
                  VendorBioPage(
                      idVendor: _roomInfo?['Id_Lawan'] ?? widget.partnerId),
                  targetTabIndex: 0,
                );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade300,
                child: CachedNetworkImage(
                  imageUrl: imgUrl,
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: 18,
                    backgroundImage: imageProvider,
                  ),
                  placeholder: (context, url) => ShimmerPlaceholder(
                    radius: 18,
                  ),
                  errorWidget: (context, url, error) => const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _roomInfo?['Username_Lawan'] ?? widget.partnerUsername,
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
                final sorted = [...messages]
                  ..sort((a, b) => b['SentAt'].compareTo(a['SentAt']));

                // mapping ke ChatMessage
                final chatMessages = sorted
                    .map((msg) => ChatMessage(
                          text: msg['Text'] ?? '',
                          time: msg['SentAt'] ?? DateTime.now(),
                          isMe: (msg['Sender']?.toString() ?? '') ==
                              (chatProv.currentUserId ?? ''),
                          category: msg['Category'] ?? 'chat',
                          hargaPaket: msg['Harga_Paket'],
                          tglRealisasi: msg['Tgl_Realisasi'],
                          lokasiPaket: msg['Lokasi'],
                          namaPaket: msg['Nama_Paket'],
                        ))
                    .toList();

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
                      ...groupMsgs.map(
                        (message) {
                          if (message.category == "package") {
                            return Column(
                              crossAxisAlignment: message.isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                ChatPackageCard(
                                  namaPaket: message.namaPaket ?? '',
                                  hargaPaket: message.hargaPaket ?? 0,
                                  isMe: message.isMe,
                                ),
                                if (message.text.isNotEmpty)
                                  ChatBubble(message: message)
                              ],
                            );
                          } else if (message.category == "payment") {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: ChatPaymentCard(
                                harga: message.hargaPaket ?? 0,
                                lokasi: message.lokasiPaket ?? '',
                                tglRealisasi: message.tglRealisasi,
                              ),
                            );
                          } else {
                            return ChatBubble(message: message);
                          }
                        },
                      ),
                      // label tanggal
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDEDED),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            dateLabel,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ];
                  }).toList(),
                );
              },
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
                  icon: const Icon(Icons.send, color: Constants.primaryColor),
                  onPressed: () => _sendMessage(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
