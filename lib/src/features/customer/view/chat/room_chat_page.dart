import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/services/fcm/fcm_service.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
// ✅ Isar entity — bukan lagi hive_entity
import 'package:mpjnew/src/data/isar/data/chat_message_entity.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_page_V2.dart';
import 'package:mpjnew/src/features/customer/view/payment/detail_pembayaran_page.dart';
import 'package:mpjnew/src/features/customer/view/payment/waiting_payment_page.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/room_chat_provider.dart';
import 'package:mpjnew/src/features/customer/widget/chat_bubble.dart';
import 'package:mpjnew/src/features/customer/widget/chat_package_card.dart';
import 'package:mpjnew/src/features/customer/widget/chat_penawaran_card.dart';
import 'package:mpjnew/src/features/customer/widget/chat_pesanan_card.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:mpjnew/src/features/customer/widget/refresh_header.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ROOM CHAT PAGE — Customer Edition (Isar)
//
// Perubahan dari versi lama:
//   - Import: isar/data/chat_message_entity (bukan hive_entity)
//   - _messagesStream: dari roomChatProv.messagesStream (Isar broadcast)
//     di-assign SEKALI di _initializeChat, tidak dibuat ulang
//   - Embedded data: entity.paket?.toModel() (bukan entity.paket langsung)
//     karena widget card masih expect PaketModel/PenawaranModel/PesananModel
//   - dispose: panggil roomChatProv.disposeRoom() (handle activeRoomPref)
//   - didChangeAppLifecycleState: roomChatProv.onAppResumed()
//   - _initializeChat: lebih ringkas (tidak ada retry loop manual)
// ═══════════════════════════════════════════════════════════════════════════

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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final PesananService pesananService = PesananService();
  final ScrollController _scrollController = ScrollController();
  late final RefreshController _refreshController;

  // ✅ Providers di-cache di didChangeDependencies — tidak di-read ulang di build()
  late ChatProvider _chatProvider;
  late RoomChatProvider _roomChatProvider;
  bool _providersInitialized = false;

  // ✅ Stream di-assign SEKALI dari roomChatProv.messagesStream setelah initChat
  // Isar broadcast stream sudah stabil — tidak perlu dibuat ulang
  Stream<List<ChatMessageEntity>>? _messagesStream;

  bool _isInitializing = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController(initialRefresh: false);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);

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

  // ── App lifecycle ────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      debugPrint('[RoomChat] 🔄 App resumed');
      // ✅ Drain background queue + markRoomAsRead + API sync
      // Logic read/received ada di RoomChatProvider.onAppResumed
      _roomChatProvider.onAppResumed();
    }
  }

  // ── Scroll ───────────────────────────────────────────────────────────────

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _roomChatProvider.loadMoreMessages();
    }
  }

  // ── Dispose ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _refreshController.dispose();

    // ✅ disposeRoom: cancel stream sub + setActiveRoomPref(null) + clear state
    if (_providersInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _roomChatProvider.disposeRoom();
          _chatProvider.setActiveRoom(null);
          FCMService.instance.setActiveRoom(null);
        } catch (e) {
          debugPrint('[RoomChat] ⚠️ Cleanup error: $e');
        }
      });
    }

    _messagesStream = null;
    super.dispose();
  }

  // =========================================
  // INITIALIZATION
  // =========================================

  Future<void> _initializeChat() async {
    if (_hasInitialized || _isInitializing) return;
    if (!mounted) return;

    if (widget.roomId == null && widget.partnerId == null) {
      debugPrint('[RoomChat] ❌ roomId dan partnerId keduanya null');
      return;
    }

    setState(() => _isInitializing = true);

    try {
      debugPrint(
          '[RoomChat] 🚀 initChat — room: ${widget.roomId}, partner: ${widget.partnerId}');

      // ✅ initChat: set activeRoomPref + trackRoom + markRoomAsRead + loadMessages
      await _roomChatProvider.initChat(
        roomId: widget.roomId,
        partnerId: widget.partnerId,
      );

      if (!mounted) return;

      if (_roomChatProvider.activeRoomId == null) {
        debugPrint('[RoomChat] ⚠️ activeRoomId null setelah initChat');
        // Tidak throw — mungkin room baru (belum punya roomId)
      }

      // ✅ Set active room di ChatProvider + FCMService
      if (_roomChatProvider.activeRoomId != null) {
        _chatProvider.setActiveRoom(_roomChatProvider.activeRoomId);
        FCMService.instance.setActiveRoom(_roomChatProvider.activeRoomId);
      }

      // ✅ Ambil stream SEKALI dari RoomChatProvider
      // roomChatProv.messagesStream sudah di-cache di dalam provider
      _messagesStream = _roomChatProvider.messagesStream;

      if (mounted) {
        setState(() {
          _hasInitialized = true;
          _isInitializing = false;
        });
      }

      debugPrint(
          '[RoomChat] ✅ Initialized — activeRoom: ${_roomChatProvider.activeRoomId}');
    } catch (e, st) {
      debugPrint('[RoomChat] ❌ initChat error: $e\n$st');
      if (mounted) {
        setState(() => _isInitializing = false);
        CustomSnackbar.showErrorSnackbar(context, 'Gagal memuat chat');
      }
    }
  }

  Future<void> _refreshChat() async {
    if (_roomChatProvider.activeRoomId == null) {
      _refreshController.refreshFailed();
      return;
    }
    try {
      // ✅ forceRefresh: true — skip cache, fetch fresh dari API
      await _chatProvider.loadMessages(
        _roomChatProvider.activeRoomId!,
        forceRefresh: true,
        silent: false, // ✅ tampilkan loading indicator saat refresh
      );
      if (mounted) _refreshController.refreshCompleted();
    } catch (e) {
      debugPrint('[RoomChat] ❌ Refresh error: $e');
      if (mounted) _refreshController.refreshFailed();
    }
  }

  Future<void> _retryMessage(
    ChatModel message,
    RoomChatProvider roomChatProv,
    UserProvider userProv,
  ) async {
    if (message.localId == null) return;
    final roomId = roomChatProv.activeRoomId;
    if (roomId == null) return;

    // Hapus pesan failed dari Isar
    await _chatProvider.removeFailedMessage(roomId, message.messageId);

    // Kirim ulang dengan konten yang sama
    final userId = userProv.userId ?? '';
    await _chatProvider.sendMessage(
      roomId: roomId,
      message: message.message,
      idPaket: message.idPaket,
      noPenawaran: message.noPenawaran,
      userIds: roomChatProv.roomInfo?.userIds ?? [],
    );
  }

  // =========================================
  // BUILD
  // =========================================

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();
    final chatProv = context.watch<ChatProvider>();
    final roomChatProv = context.watch<RoomChatProvider>();

    // Loading scaffold — hanya untuk case cari/buat room baru
    if (_isInitializing && widget.roomId == null) {
      return _buildLoadingScaffold();
    }

    // No room
    if (roomChatProv.activeRoomId == null &&
        widget.partnerId == null &&
        widget.roomId == null) {
      return _buildNoRoomScaffold();
    }

    final imgUrl =
        roomChatProv.roomInfo?.idMediaLawan ?? widget.partnerAvatarUrl ?? '';

    return Scaffold(
      appBar: _buildAppBar(roomChatProv, imgUrl),
      backgroundColor: const Color(0xFFF9F9F9),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/chat_background.png'),
            fit: BoxFit.cover,
            opacity: 0.2,
            colorFilter: ColorFilter.mode(
              Constants.primaryColor.withOpacity(0.05),
              BlendMode.lighten,
            ),
          ),
        ),
        child: Column(
          children: [
            // Load more indicator
            if (roomChatProv.isLoadingMoreDisplay)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                            Constants.primaryColorVendor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Memuat pesan lama...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // API sync indicator
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
                        valueColor:
                            AlwaysStoppedAnimation(Colors.blue.shade600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Memuat pesan terbaru...',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ✅ StreamBuilder dengan _messagesStream yang di-cache
            Expanded(
              child: StreamBuilder<List<ChatMessageEntity>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}',
                              style: TextStyle(color: Colors.red.shade600)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _refreshChat,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildMessagesList(
                    context,
                    snapshot.data!,
                    chatProv,
                    roomChatProv,
                    userProv,
                  );
                },
              ),
            ),

            _buildInputArea(roomChatProv, userProv),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // =========================================
  // MESSAGE LIST
  // =========================================

  Widget _buildMessagesList(
    BuildContext context,
    List<ChatMessageEntity> entities,
    ChatProvider chatProv,
    RoomChatProvider roomChatProv,
    UserProvider userProv,
  ) {
    final roomInfo = roomChatProv.roomInfo;

    // ✅ Build index entity by messageId untuk O(1) lookup
    // Hindari orElse: () => entities.first yang bisa return entity yang salah
    final entityIndex = {
      for (final e in entities) e.messageId: e,
    };

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
      header: buildRefreshHeader(reverse: true),
      onRefresh: _refreshChat,
      child: ListView(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        children: grouped.entries.expand((entry) {
          final dateLabel = entry.key;
          final groupMsgs = entry.value;

          return [
            ...groupMsgs.map((message) {
              final isMe = message.senderId == (chatProv.currentUserId ?? '');

              // ✅ FIX: Lookup entity by messageId — null-safe, tidak ada wrong data
              final entity = entityIndex[message.messageId];

              // Reconstruct model dari embedded (null jika belum ter-enrich)
              final paket = entity?.paketModel;
              final penawaran = entity?.penawaranModel;
              final pesanan = entity?.pesananModel;

              final onRetry = (isMe && message.sendStatusEnum.isFailed)
                  ? () => _retryMessage(message, roomChatProv, userProv)
                  : null;

              // ── PESANAN CARD ─────────────────────────────────────────
              // ✅ FIX: Cek dari entity.hasPesanan (bukan message.noInvoice)
              // karena data ada di embedded Isar, bukan di ChatModel flat field
              //
              // Dua kasus pesanan tampil:
              //   1. entity.hasPesanan → ada embedded pesanan langsung
              //   2. entity.hasPenawaran && penawaran.noPesanan tidak kosong
              //      → penawaran sudah konversi ke pesanan, fetch pesanan dari entity
              if (entity?.hasPesanan == true && pesanan != null) {
                return ChatPesananCard(
                  pesanan: pesanan,
                  roomId: widget.roomId ?? '',
                  customerId: userProv.customer?.noId ?? '',
                  onTap: () => _handlePesananTap(context, pesanan),
                );
              }

              // ── PENAWARAN → PESANAN (konversi) ───────────────────────
              // ✅ FIX: Penawaran yang sudah jadi pesanan render sebagai pesanan
              // Identifikasi: entity.hasPenawaran && penawaran.noPesanan tidak kosong
              // Dalam kasus ini embedded pesanan mungkin belum ada (background sync)
              // → tampilkan loading card sementara
              if (entity?.hasPenawaran == true &&
                  penawaran != null &&
                  penawaran.noPesanan.isNotEmpty) {
                // Pesanan embedded sudah ada → render langsung
                if (pesanan != null) {
                  return ChatPesananCard(
                    pesanan: pesanan,
                    roomId: widget.roomId ?? '',
                    customerId: userProv.customer?.noId ?? '',
                    onTap: () => _handlePesananTap(context, pesanan),
                  );
                }
                // Pesanan embedded belum ada (masih sync) → shimmer
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child:
                      ShimmerPlaceholder(width: 300, height: 120, radius: 12),
                );
              }

              // ── PENAWARAN CARD ───────────────────────────────────────
              // ✅ FIX: Cek entity.hasPenawaran, bukan message.noPenawaran
              if (entity?.hasPenawaran == true && penawaran != null) {
                return ChatPenawaranCard(
                  penawaran: penawaran,
                  roomId: widget.roomId ?? '',
                  customerId: userProv.customer?.noId ?? '',
                  onTap: () => _handleOfferTap(context, penawaran, message),
                );
              }

              // ── PENAWARAN / PESANAN BELUM TER-ENRICH ────────────────
              // ID ada di message tapi embedded belum ter-fetch (loading)
              if ((message.noPenawaran?.isNotEmpty == true ||
                      message.noInvoice?.isNotEmpty == true) &&
                  penawaran == null &&
                  pesanan == null) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child:
                      ShimmerPlaceholder(width: 300, height: 120, radius: 12),
                );
              }

              // ── PAKET CARD + BUBBLE ──────────────────────────────────
              // ✅ FIX: Cek entity.hasPaket, bukan message.idPaket
              if (entity?.hasPaket == true ||
                  message.idPaket?.isNotEmpty == true) {
                return Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Shimmer jika paket belum ter-enrich
                    if (paket == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: ShimmerPlaceholder(
                            width: 300, height: 100, radius: 10),
                      )
                    else
                      ChatPackageCard(paket: paket, isMe: isMe, onTap: () {}),

                    // Bubble selalu tampil — untuk timestamp + status icon
                    ChatBubble(
                      message: message,
                      isMe: isMe,
                      onRetry: onRetry,
                    ),
                  ],
                );
              }

              // ── REGULAR TEXT ─────────────────────────────────────────
              return ChatBubble(
                message: message,
                isMe: isMe,
                onRetry: onRetry,
              );
            }),

            // ── Date label ───────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ];
        }).toList(),
      ),
    );
  }

  // ── Pesanan tap handler ──────────────────────────────────────────────────

  void _handlePesananTap(BuildContext context, dynamic pesanan) {
    if (!mounted) return;
    if (pesanan.statusProgresPesanan == 'menunggu bayar') {
      context.read<NavigationProvider>().navigateToPage(
            context,
            targetTabIndex: 2,
            WaitingPaymentPage(paymentData: pesanan),
          );
    } else {
      context.read<NavigationProvider>().navigateToPage(
            context,
            targetTabIndex: 2,
            DetailOrderPageV2(pesananModel: pesanan),
          );
    }
  }

  // =========================================
  // INPUT AREA
  // =========================================

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
                  hintText: 'Ketik pesan...',
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
                ? const SizedBox.shrink()
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
                                  currentUserId: userId);
                            },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // APP BAR
  // =========================================

  AppBar _buildAppBar(RoomChatProvider roomChatProv, String imgUrl) {
    return AppBar(
      backgroundColor: const Color(0xFFF9F9F9),
      elevation: 2,
      shadowColor: Colors.black12,
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
                imageBuilder: (_, imageProvider) => CircleAvatar(
                  radius: 18,
                  backgroundImage: imageProvider,
                ),
                placeholder: (_, __) =>
                    const ShimmerPlaceholder(width: 36, height: 36, radius: 18),
                errorWidget: (_, __, ___) => const CircleAvatar(
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
    );
  }

  // =========================================
  // HELPERS
  // =========================================

  Future<void> _handleOfferTap(
    BuildContext context,
    dynamic penawaran,
    ChatModel message,
  ) async {
    if (penawaran.noPesanan != null && penawaran.noPesanan!.isNotEmpty) {
      final pesananList = await pesananService.getAll(
        noBukti: penawaran.noPesanan,
        status: 'aktif',
      );
      if (pesananList.isEmpty) return;

      final pesanan = pesananList.first;
      if (!mounted) return;

      if (pesanan.statusProgresPesanan == 'menunggu bayar') {
        context.read<NavigationProvider>().navigateToPage(
              context,
              targetTabIndex: 2,
              WaitingPaymentPage(paymentData: pesanan),
            );
      } else {
        context.read<NavigationProvider>().navigateToPage(
              context,
              targetTabIndex: 2,
              DetailOrderPageV2(pesananModel: pesanan),
            );
      }
    } else {
      if (!mounted) return;
      context.read<NavigationProvider>().navigateToPage(
            context,
            targetTabIndex: 1,
            DetailPembayaranPage(
              penawaranId: penawaran.noId,
              message: message,
            ),
          );
    }
  }

  // =========================================
  // STATE WIDGETS
  // =========================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.7),
            Colors.white.withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 32),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text('Hari ini',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    )),
              ],
            ),
          ),
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, double value, _) => Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Constants.primaryColorVendor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Constants.primaryColorVendor.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 56,
                  color: Constants.primaryColorVendor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada pesan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Mulai percakapan dengan\nmengirim pesan pertama',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Constants.primaryColorVendor.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 18, color: Constants.primaryColorVendor),
                const SizedBox(width: 8),
                Text(
                  'Ketik pesan di bawah untuk mulai',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRoomScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: const Color(0xFFF9F9F9),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Tidak ada chat',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 2,
        title: const Row(
          children: [
            ShimmerPlaceholder(width: 36, height: 36, radius: 18),
            SizedBox(width: 12),
            ShimmerPlaceholder(width: 120, height: 20, radius: 4),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF2F2F2),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (_, index) => Align(
          alignment:
              index % 2 == 0 ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: const ShimmerPlaceholder(width: 250, height: 60, radius: 12),
          ),
        ),
      ),
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
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: const Center(
        child: Text(
          'Penawaran ini sudah ditutup',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
