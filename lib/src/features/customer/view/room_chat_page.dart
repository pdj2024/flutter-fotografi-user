import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/paket_model.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:mpjnew/src/features/customer/widget/chat_bubble.dart';
import 'package:mpjnew/src/features/customer/widget/chat_package_card.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/chat_provider.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/paket_provider.dart';
import 'package:mpjnew/src/pages/providers/custom_back_button.dart';
import 'package:provider/provider.dart';

class RoomChatPage extends StatefulWidget {
  final String? roomId;
  final String? partnerId;
  final String? partnerUsername;
  final String? partnerAvatarUrl;
  final PaketModel? paket;

  const RoomChatPage(
      {super.key,
      this.roomId,
      this.partnerId,
      this.partnerUsername,
      this.partnerAvatarUrl,
      this.paket});

  @override
  State<RoomChatPage> createState() => _RoomChatPageState();
}

class _RoomChatPageState extends State<RoomChatPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _activeRoomId;
  RoomChatModel? _roomInfo;
  bool _isLoading = true;
  List<PaketModel?> _paketList = [];

  PaketModel? _paket;

  @override
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print("===== SINGLE CHAT (room id): ${widget.roomId}");
      print("===== SINGLE CHAT (user ids): ${widget.partnerId}");

      _startInit();

      setState(() {
        _paket = widget.paket;
      });

      _messageController.addListener(() {
        setState(() {});
      });
    });
  }

  Future<void> _startInit() async {
    await _initChat(); // proses dapat room + messages

    final chatProv = context.read<ChatProvider>();
    final paketProv = context.read<PaketProvider>();

    final list = await paketProv
        .fetchPaketFromRoom(chatProv.getMessages(_activeRoomId ?? ''));

    setState(() {
      _paketList = list; // simpan
    });
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
        print(
            "==== ROOM ID (null) -> Mencoba get room lewat partner id : ${widget.partnerId}");
        final rooms = await chatProv.fetchRooms(
          idLawan: widget.partnerId,
        );

        if (rooms.isNotEmpty) {
          print(
              "==== ROOM ID ditemukan (${rooms.first.roomId}) -> Mengambil data chat");

          // ✅ ketemu existing room
          setState(() {
            _activeRoomId = rooms.first.roomId;
            _roomInfo = rooms.first;
          });
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
        _activeRoomId = widget.roomId;

        print(
            "==== PARTNER ID (null) -> Mencoba get room lewat room id : ${widget.roomId}");
        final rooms = await chatProv.fetchRooms(
          roomId: _activeRoomId,
        );

        if (rooms.isNotEmpty) {
          print(
              "==== MENGAMBIL DATA CHAT DARI ROOM ID (${rooms.first.roomId})");

          setState(() => _roomInfo = rooms.first);
        }
      }
    } catch (e) {
      print("❌ Error saat init chat: $e");
    } finally {
      await chatProv.fetchMessages(_activeRoomId!);
      setState(() => _isLoading = false);
    }
  }

  void _sendMessage(BuildContext context) async {
    print("==== SINGLE CHAT: INI SATU");
    if (_messageController.text.isEmpty) return;
    print("==== SINGLE CHAT: INI DUA");

    final chatProv = context.read<ChatProvider>();
    final currentUserId = context.read<UserProvider>().userId ?? '';
    bool isAskPaket = _paket != null;

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
        widget.partnerId!,
      ];
    } else {
      // ✅ kalau roomInfo ada, ambil dari room
      final ids = _roomInfo!.userIds;
      userIds = ids.map((e) => e.toString()).toList();
    }

    await chatProv.sendMessage(
      _activeRoomId ?? "", // kosong kalau new chat
      _messageController.text,
      isAskPaket ? widget.paket!.no_id : null,
      null, // noInvoice
      userIds,
    );

    setState(() {
      _paket = null;
    });

    _messageController.clear();

    // setelah kirim pesan pertama, ambil room baru
    if (_activeRoomId == null) {
      final rooms = await chatProv.fetchRooms(
        idLawan:
            userIds.firstWhere((id) => id != currentUserId, orElse: () => ""),
      );
      if (rooms.isNotEmpty) {
        setState(() {
          _activeRoomId = rooms.first.roomId;
          _roomInfo = rooms.first;
        });
        await chatProv.fetchMessages(_activeRoomId!);
      }
    }

    // setelah mengirim pesan get data lagi
    print("===== fetch data message lagi setelah mengirim pesan");
    await chatProv.fetchMessages(_activeRoomId!);
  }

  @override
  Widget build(BuildContext context) {
    final chatProv = context.watch<ChatProvider>();
    final messages = chatProv.getMessages(_activeRoomId ?? '');
    final paketList = _paketList;

    print("==== SINGLE CHAT: paketList: $paketList");

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
        _roomInfo?.idMediaLawan ?? widget.partnerAvatarUrl ?? '';

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
                    idVendor:
                        _roomInfo?.idLawan ?? widget.partnerId ?? 'unknown',
                  ),
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
                  _roomInfo?.usernameLawan ??
                      widget.partnerUsername ??
                      'unknown',
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
          if (messages.isEmpty)
            const Expanded(child: Center(child: Text('Belum ada pesan'))),

          Expanded(
            child: Builder(
              builder: (context) {
                // urutkan pesan descending
                final sorted = [...messages]
                  ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

                // group per tanggal
                final grouped = Helper.groupMessagesByDate(sorted);
                // print("Hasil grouped: $grouped");

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
                          bool isMe = (message.senderId) ==
                              (chatProv.currentUserId ?? '');

                          PaketModel? paket;

                          if (message.idPaket != null) {
                            final index = paketList
                                .indexWhere((p) => p!.no_id == message.idPaket);
                            if (index != -1) {
                              paket = paketList[index];
                            } else {
                              paket = null;
                            }
                          }
                          if (message.idPaket != null) {
                            return Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (paket == null)
                                  ShimmerPlaceholder(
                                    width: 300,
                                    height: 100,
                                    radius: 10,
                                  ),
                                if (paket != null)
                                  ChatPackageCard(
                                    namaPaket: paket.nama_paket,
                                    hargaPaket: paket.harga,
                                    isMe: isMe,
                                  ),
                                if (message.message.isNotEmpty)
                                  ChatBubble(
                                    message: message,
                                    isMe: isMe,
                                  ),
                              ],
                            );
                          }

                          if (message.jenisPesan == "payment" ||
                              message.noInvoice != null) {
                            // return ChatPaymentCard(
                            //   harga: message.hargaPaket ?? 0,
                            //   lokasi: message.lokasiPaket ?? '',
                            //   tglRealisasi: message.tglRealisasi,
                            // );
                          }

                          return ChatBubble(
                            message: message,
                            isMe: isMe,
                          );
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

          if (widget.paket != null)
            Padding(
              padding: const EdgeInsets.only(right: 15, top: 10),
              child: ChatPackageCard(
                namaPaket: widget.paket!.nama_paket,
                hargaPaket: widget.paket!.harga,
                isMe: true,
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white.withOpacity(0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                /// TEXTFIELD YANG BISA MELEBAR SAAT SEND BUTTON HILANG
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    cursorColor: Constants.primaryColor,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      hintText: "Ketik pesan...",
                      filled: true,
                      fillColor: const Color(0xFFE8E8E8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),

                const SizedBox(width: 8),

                /// ANIMASI 100% BERHASIL
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _messageController.text.trim().isEmpty
                      ? const SizedBox(
                          width: 0,
                          height: 0,
                        )
                      : AnimatedOpacity(
                          opacity: 1,
                          duration: const Duration(milliseconds: 200),
                          child: IconButton(
                            icon: const Icon(Icons.send,
                                color: Constants.primaryColor),
                            onPressed: () => _sendMessage(context),
                          ),
                        ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
