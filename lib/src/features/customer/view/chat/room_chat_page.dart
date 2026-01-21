import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/hive_entity/chat_message_entity.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
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
import 'package:mpjnew/src/features/customer/widget/chat_penawaran_card.dart';
import 'package:mpjnew/src/features/customer/widget/chat_pesanan_card.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// ✅ FIXED: Room Chat Page with proper notification support
///
/// Key fixes:
/// - ✅ Properly reference chatService through ChatProvider
/// - ✅ Set active room to suppress notifications when viewing
/// - ✅ Clear active room when leaving to enable notifications
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
  late RefreshController _refreshController;

  // Provider references
  late ChatProvider _chatProvider;
  late RoomChatProvider _roomChatProvider;
  bool _providersInitialized = false;

  // State tracking
  bool _isInitializing = true;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController(initialRefresh: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeChat();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_providersInitialized) {
      _chatProvider = context.read<ChatProvider>();
      _roomChatProvider = context.read<RoomChatProvider>();
      _providersInitialized = true;
    }
  }

  @override
  void dispose() {
    // ✅ FIXED: Access chatService through ChatProvider
    _chatProvider.chatService.setActiveRoom(null); // ✅ Allow notifications
    _chatProvider.clearActiveRoomSilently();
    _roomChatProvider.resetSilently();
    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  // =========================================
  // INITIALIZATION
  // =========================================

  Future<void> _initializeChat() async {
    if (_hasInitialized) return;

    setState(() {
      _isInitializing = true;
    });

    try {
      debugPrint('═══════════════════════════════════════');
      debugPrint('🚀 INIT ROOM CHAT');
      debugPrint('RoomId: ${widget.roomId}');
      debugPrint('PartnerId: ${widget.partnerId}');
      debugPrint('═══════════════════════════════════════');

      // Initialize RoomChatProvider
      await _roomChatProvider.initChat(
        roomId: widget.roomId,
        partnerId: widget.partnerId,
      );

      // ✅ FIXED: Set active room in both ChatProvider and ChatService
      if (_roomChatProvider.activeRoomId != null) {
        _chatProvider.setActiveRoom(_roomChatProvider.activeRoomId);
        // ✅ Also set in ChatService to suppress notifications
        _chatProvider.chatService.setActiveRoom(_roomChatProvider.activeRoomId);
        debugPrint('✅ Active room set: ${_roomChatProvider.activeRoomId}');
        debugPrint('✅ Notifications suppressed for this room');
      }

      setState(() {
        _hasInitialized = true;
      });

      debugPrint('✅ Chat initialized successfully');
    } catch (e, st) {
      debugPrint('❌ Error initializing chat: $e\n$st');
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _refreshChat() async {
    try {
      await _chatProvider.loadMessages(_roomChatProvider.activeRoomId!);
      _refreshController.refreshCompleted();
    } catch (e) {
      debugPrint('❌ Error refreshing chat: $e');
      _refreshController.refreshFailed();
    }
  }

  // =========================================
  // BUILD
  // =========================================

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();
    final chatProv = context.watch<ChatProvider>();
    final roomChatProv = context.watch<RoomChatProvider>();

    // Loading state
    if (_isInitializing && roomChatProv.activeRoomId == null) {
      return _buildLoadingScaffold();
    }

    // Empty state
    if (roomChatProv.activeRoomId == null && widget.partnerId == null) {
      return const Scaffold(
        body: Center(child: Text("Tidak ada chat")),
      );
    }

    // Main UI
    final String imgUrl =
        roomChatProv.roomInfo?.idMediaLawan ?? widget.partnerAvatarUrl ?? '';

    return Scaffold(
      appBar: _buildAppBar(roomChatProv, imgUrl),
      backgroundColor: const Color.fromARGB(255, 242, 242, 242),
      body: Column(
        children: [
          // Background sync indicator
          if (chatProv.isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.blue.shade600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Memuat pesan terbaru...',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),

          // Messages stream
          Expanded(
            child: roomChatProv.activeRoomId == null
                ? const Center(child: Text('Memuat pesan...'))
                : StreamBuilder<List<ChatMessageEntity>>(
                    stream: chatProv.repository
                        .getMessagesStream(roomChatProv.activeRoomId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData && chatProv.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState();
                      }

                      final entities = snapshot.data!;
                      return _buildMessagesList(
                        context,
                        entities,
                        chatProv,
                        roomChatProv,
                        userProv,
                      );
                    },
                  ),
          ),

          // Input area
          _buildInputArea(roomChatProv, userProv),
        ],
      ),
    );
  }

  // =========================================
  // UI BUILDERS
  // =========================================

  AppBar _buildAppBar(RoomChatProvider roomChatProv, String imgUrl) {
    return AppBar(
      backgroundColor: const Color(0xFFF9F9F9),
      elevation: 2,
      shadowColor: Colors.black12,
      leading: CustomBackButton(),
      title: GestureDetector(
        onTap: () {
          context.read<NavigationProvider>().navigateToPage(
                context,
                VendorBioPage(
                  idVendor: roomChatProv.roomInfo?.idLawan ??
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
                placeholder: (context, url) => ShimmerPlaceholder(radius: 18),
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
                roomChatProv.roomInfo?.usernameLawan ??
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
    );
  }

  Widget _buildMessagesList(
    BuildContext context,
    List<ChatMessageEntity> entities,
    ChatProvider chatProv,
    RoomChatProvider roomChatProv,
    UserProvider userProv,
  ) {
    final roomInfo = roomChatProv.roomInfo;
    final messages = entities
        .map((entity) => entity.toChatModel(
              tipeUser: 'customer',
              roomType: roomInfo?.roomType ?? 'direct',
              userIds: roomInfo?.userIds ?? [],
            ))
        .toList();

    final sorted = [...messages]..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    final grouped = Helper.groupMessagesByDate(sorted);

    return SmartRefresher(
      enablePullUp: true,
      controller: _refreshController,
      onRefresh: _refreshChat,
      child: ListView(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        children: grouped.entries.expand((entry) {
          final dateLabel = entry.key;
          final groupMsgs = entry.value;

          return [
            ...groupMsgs.map((message) {
              final isMe = message.senderId == (chatProv.currentUserId ?? '');

              final entity = entities.firstWhere(
                (e) => e.messageId == message.messageId,
                orElse: () => entities.first,
              );

              final paket = entity.paket;
              final penawaran = entity.penawaran;
              final pesanan = entity.pesanan;

              // PESANAN CARD
              if (message.noInvoice != null && message.noInvoice!.isNotEmpty) {
                if (pesanan == null) {
                  return _buildOfferClosedCard();
                }

                return Column(
                  children: [
                    Text(
                        "Jenis Pesan: ${message.jenisPesan} ${message.noInvoice}"),
                    ChatPesananCard(
                      pesanan: pesanan,
                      roomId: widget.roomId ?? "",
                      customerId: userProv.customer?.noId ?? "",
                      onTap: () {
                        if (pesanan.statusProgresPesanan == "menunggu bayar") {
                          if (!mounted) return;
                          context.read<NavigationProvider>().navigateToPage(
                                context,
                                targetTabIndex: 2,
                                WaitingPaymentPage(paymentData: pesanan),
                              );
                        } else {
                          if (!mounted) return;
                          context.read<NavigationProvider>().navigateToPage(
                                context,
                                targetTabIndex: 2,
                                DetailOrderPage(pesananModel: pesanan),
                              );
                        }
                      },
                    ),
                  ],
                );
              }

              // PENAWARAN CARD
              if (message.noPenawaran != null &&
                  message.noPenawaran!.isNotEmpty) {
                if (penawaran == null) {
                  return _buildOfferClosedCard();
                }

                return Column(
                  children: [
                    Text(
                        "Jenis Pesan: ${message.jenisPesan} ${message.noInvoice}"),
                    SizedBox(
                      height: 5,
                    ),
                    ChatPenawaranCard(
                      penawaran: penawaran,
                      isPesanan: penawaran.noPesanan != null &&
                          penawaran.noPesanan!.isNotEmpty,
                      roomId: widget.roomId ?? "",
                      customerId: userProv.customer?.noId ?? "",
                      onTap: () => _handleOfferTap(context, penawaran),
                    ),
                  ],
                );
              }

              // PAKET CARD + OPTIONAL TEXT
              if (message.idPaket != null && message.idPaket!.isNotEmpty) {
                return Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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

              // REGULAR TEXT MESSAGE
              return ChatBubble(
                message: message,
                isMe: isMe,
              );
            }),

            // Date label
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
  }

  Widget _buildInputArea(RoomChatProvider roomChatProv, UserProvider userProv) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white.withOpacity(0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: roomChatProv.messageController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                cursorColor: Constants.primaryColor,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
          ),

          const SizedBox(width: 8),

          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: roomChatProv.messageController.text.trim().isEmpty
                ? const SizedBox(width: 0, height: 0)
                : AnimatedOpacity(
                    opacity: 1,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      icon: roomChatProv.isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                    Constants.primaryColor),
                              ),
                            )
                          : const Icon(Icons.send,
                              color: Constants.primaryColor),
                      onPressed: roomChatProv.isSending
                          ? null
                          : () async {
                              final userId = userProv.userId!;
                              await roomChatProv.sendMessage(
                                currentUserId: userId,
                              );
                            },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // HELPERS
  // =========================================

  Future<void> _handleOfferTap(
      BuildContext context, PenawaranModel offer) async {
    if (offer.noPesanan != null && offer.noPesanan!.isNotEmpty) {
      final pesanan = await pesananService.getAll(
        noBukti: offer.noPesanan,
        status: "aktif",
      );

      if (pesanan.isEmpty) return;

      if (pesanan.first.statusProgresPesanan == "menunggu bayar") {
        if (!mounted) return;
        context.read<NavigationProvider>().navigateToPage(
              context,
              targetTabIndex: 2,
              WaitingPaymentPage(paymentData: pesanan.first),
            );
      } else {
        if (!mounted) return;
        context.read<NavigationProvider>().navigateToPage(
              context,
              targetTabIndex: 2,
              DetailOrderPage(pesananModel: pesanan.first),
            );
      }
    } else {
      if (!mounted) return;
      context.read<NavigationProvider>().navigateToPage(
            context,
            targetTabIndex: 2,
            DetailPembayaranPage(penawaranId: offer.noId),
          );
    }
  }

  // =========================================
  // STATE WIDGETS
  // =========================================

  Widget _buildEmptyState() {
    return Column(
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEDED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Hari ini",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferClosedCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 40),
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
      child: const Center(
        child: Text(
          "Penawaran ini sudah ditutup",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 2,
        shadowColor: Colors.black12,
        leading: CustomBackButton(),
        title: Row(
          children: [
            ShimmerPlaceholder(width: 36, height: 36, radius: 18),
            const SizedBox(width: 12),
            ShimmerPlaceholder(width: 120, height: 20, radius: 4),
          ],
        ),
        toolbarHeight: 72,
      ),
      backgroundColor: const Color.fromARGB(255, 242, 242, 242),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) {
          final isMe = index % 2 == 0;
          return Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: ShimmerPlaceholder(width: 250, height: 60, radius: 12),
            ),
          );
        },
      ),
    );
  }
}