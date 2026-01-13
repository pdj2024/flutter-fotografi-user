import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/models/paket_model.dart';
import 'package:mpjnew/src/data/models/penawaran_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_page.dart';
import 'package:mpjnew/src/features/customer/view/payment/detail_pembayaran_page.dart';
import 'package:mpjnew/src/features/customer/view/payment/waiting_payment_page.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/room_chat_provider.dart';
import 'package:mpjnew/src/features/customer/widget/chat_bubble.dart';
import 'package:mpjnew/src/features/customer/widget/chat_package_card.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/widget/chat_payment_card.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';
import 'package:mpjnew/src/features/customer/widget/shimmer/room_chat_shimmer.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class RoomChatPage extends StatefulWidget {
  final String? roomId;
  final String? partnerId;
  final String? partnerUsername;
  final String? partnerAvatarUrl;

  const RoomChatPage({
    super.key,
    this.roomId,
    this.partnerId,
    this.partnerUsername,
    this.partnerAvatarUrl,
  });

  @override
  State<RoomChatPage> createState() => _RoomChatPageState();
}

class _RoomChatPageState extends State<RoomChatPage>
    with TickerProviderStateMixin {
  PesananService pesananService = PesananService();
  final ScrollController _scrollController = ScrollController();
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  // ✅ Simpan reference ke providers
  late ChatProvider _chatProvider;
  late RoomChatProvider _roomChatProvider;
  bool _providersInitialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      print("===== INIT SINGLE CHAT (room id): ${widget.roomId}");
      _initializeChat(_roomChatProvider, _chatProvider);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ Simpan reference di sini, bukan di dispose
    if (!_providersInitialized) {
      _chatProvider = context.read<ChatProvider>();
      _roomChatProvider = context.read<RoomChatProvider>();
      _providersInitialized = true;
    }
  }

  @override
  void dispose() {
    // ✅ Gunakan reference yang sudah disimpan
    _chatProvider.clearActiveRoomSilently();
    _roomChatProvider.resetSilently();

    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat(
      RoomChatProvider roomProv, ChatProvider chatProv) async {
    try {
      // 1️⃣ Initialize room
      await roomProv.initChat(
        roomId: widget.roomId,
        partnerId: widget.partnerId,
      );

      // 2️⃣ Load offer data
      await roomProv.loadOfferData();

      // 3️⃣ Set active room di ChatProvider jika berhasil init
      if (roomProv.activeRoomId != null) {
        chatProv.setActiveRoom(roomProv.activeRoomId);
        debugPrint('✅ Active room set: ${roomProv.activeRoomId}');
      }
    } catch (e) {
      print("❌ Error init chat: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();
    final chatProv = context.watch<ChatProvider>();
    final roomChatProvider = context.watch<RoomChatProvider>();

    print("==== SINGLE CHAT: paketList: ${roomChatProvider.paketList}");

    // auto-scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          roomChatProvider.messages.isNotEmpty) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    if (roomChatProvider.isLoading) {
      return RoomChatShimmer();
    }

    if (roomChatProvider.activeRoomId == null && (widget.partnerId == null)) {
      return const Center(child: Text("Tidak ada chat"));
    }

    final String imgUrl = roomChatProvider.roomInfo?.idMediaLawan ??
        widget.partnerAvatarUrl ??
        '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 2,
        shadowColor: Colors.black12,
        leading: CustomBackButton(),
        title: GestureDetector(
          onTap: () {
            context.read<NavigationProvider>().navigateToPage(
                  context,
                  VendorBioPage(
                    idVendor: roomChatProvider.roomInfo?.idLawan ??
                        widget.partnerId ??
                        'unknown',
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
                  roomChatProvider.roomInfo?.usernameLawan ??
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
      backgroundColor: const Color.fromARGB(255, 242, 242, 242),
      body: Column(
        children: [
          // Daftar pesan
          if (roomChatProvider.messages.isEmpty)
            Expanded(
              child: Column(
                children: [
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
                        "Hari ini",
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: Builder(
              builder: (context) {
                // urutkan pesan descending
                final sorted = [...roomChatProvider.messages]
                  ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

                // group per tanggal
                final grouped = Helper.groupMessagesByDate(sorted);
                // print("Hasil grouped: $grouped");

                return SmartRefresher(
                  enablePullUp: true,
                  controller: _refreshController,
                  onRefresh: () {
                    _initializeChat(roomChatProvider, chatProv);
                  },
                  child: ListView(
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
                            PenawaranModel? offer;

                            if (roomChatProvider.isLoadingOfferData) {
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 40),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: ShimmerPlaceholder(),
                              );
                            }

                            if (message.idPaket != null) {
                              final index = roomChatProvider.paketList
                                  .indexWhere((p) =>
                                      p.no_id == message.idPaket &&
                                      p.status == 'aktif');
                              if (index != -1) {
                                paket = roomChatProvider.paketList[index];
                              } else {
                                paket = null;
                              }
                            }

                            if (message.noPenawaran != null &&
                                roomChatProvider.penawaranList.isNotEmpty) {
                              final index = roomChatProvider.penawaranList
                                  .indexWhere((p) =>
                                      p.noId == message.noPenawaran &&
                                      p.status == 'aktif');
                              if (index != -1) {
                                offer = roomChatProvider.penawaranList[index];
                              } else {
                                offer = null;
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
                                      paket: paket,
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

                            if (message.noPenawaran != null &&
                                message.noPenawaran!.isNotEmpty) {
                              if (offer == null) {
                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 40),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Penawaran ini sudah ditutup",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }

                              return ChatPaymentCard(
                                penawaran: offer,
                                roomId: widget.roomId ?? "",
                                customerId: userProv.customer?.noId ?? "",
                                onTap: () async {
                                  print(offer!.noPesanan);
                                  if (offer.noPesanan != "") {
                                    final pesanan = await pesananService.getAll(
                                        noBukti: offer.noPesanan,
                                        status: "aktif");
                                    if (pesanan.first.statusProgresPesanan ==
                                        "menunggu bayar") {
                                      context
                                          .read<NavigationProvider>()
                                          .navigateToPage(
                                            context,
                                            targetTabIndex: 2,
                                            WaitingPaymentPage(
                                              paymentData: pesanan.first,
                                            ),
                                          );
                                    } else {
                                      context
                                          .read<NavigationProvider>()
                                          .navigateToPage(
                                            context,
                                            targetTabIndex: 2,
                                            DetailOrderPage(
                                              pesananModel: pesanan.first,
                                            ),
                                          );
                                    }
                                  } else {
                                    context
                                        .read<NavigationProvider>()
                                        .navigateToPage(
                                          context,
                                          targetTabIndex: 2,
                                          DetailPembayaranPage(
                                            penawaranId: message.noPenawaran!,
                                          ),
                                        );
                                  }
                                },
                              );
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
                  ),
                );
              },
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
                    controller: roomChatProvider.messageController,
                    cursorColor: Constants.primaryColor,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      hintText: "Ketik pesan...",
                      filled: true,
                      fillColor: Colors.white,
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
                  child: roomChatProvider.messageController.text.trim().isEmpty
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
                            onPressed: () async {
                              final userId =
                                  context.read<UserProvider>().userId!;
                              roomChatProvider.sendMessage(
                                currentUserId: userId,
                              );
                            },
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
