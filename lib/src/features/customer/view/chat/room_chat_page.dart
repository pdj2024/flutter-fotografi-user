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
import 'package:mpjnew/src/data/models/history_order_model.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_page_V2.dart';
import 'package:mpjnew/src/features/customer/view/payment/detail_pembayaran_page.dart';
import 'package:mpjnew/src/features/customer/view/payment/waiting_payment_page.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
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

  // Keys untuk scroll ke bubble per item aktif (penawaran/pesanan)
  // Key: 'pen_<noPenawaran>' atau 'psn_<noBukti>'
  final Map<String, GlobalKey> _itemBubbleKeys = {};

  bool _isInitializing = false;
  bool _hasInitialized = false;

  Function(HistoryOrderModel)? _prevProgressCallback;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController(initialRefresh: false);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeChat();
      _registerProgressListener();
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

    // Restore progress callback ke sebelum masuk room
    FCMService.instance.onProgressReceived = _prevProgressCallback;

    _messagesStream = null;
    super.dispose();
  }

  // ── Progress FCM listener ────────────────────────────────────────────────

  void _registerProgressListener() {
    _prevProgressCallback = FCMService.instance.onProgressReceived;
    FCMService.instance.onProgressReceived = (progress) {
      _prevProgressCallback?.call(progress);
      _onProgressFCM(progress);
    };
  }

  void _onProgressFCM(HistoryOrderModel progress) {
    if (!mounted) return;
    final roomId = _roomChatProvider.activeRoomId;
    if (roomId == null) return;
    // Refresh pesan agar embedded pesanan di Isar terupdate → card rebuild
    _chatProvider.loadMessages(roomId, forceRefresh: true);
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
      await _roomChatProvider.initChat(
        roomId: widget.roomId,
        partnerId: widget.partnerId,
      );

      if (!mounted) return;

      if (_roomChatProvider.activeRoomId != null) {
        _chatProvider.setActiveRoom(_roomChatProvider.activeRoomId);
        FCMService.instance.setActiveRoom(_roomChatProvider.activeRoomId);
      }

      // ✅ FIX: Selalu ambil stream dari provider — termasuk kasus room baru
      // dengan partnerId. Provider sudah return merged stream (room + pending)
      // sehingga local echo langsung tampil walau roomId masih kosong.
      //
      // SEBELUMNYA: _messagesStream = _roomChatProvider.messagesStream
      //   → jika activeRoomId null, messagesStream return Stream.empty()
      //   → UI stuck di empty state sampai FCM datang
      //
      // SEKARANG: getter messagesStream sudah handle kasus roomId null/kosong
      //   dengan mengembalikan pendingStream (watch roomId='')
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

    if (_hasInitialized && roomChatProv.activeRoomId != null) {
      // Cek apakah stream perlu di-refresh karena room baru resolved
      // (dari pending-only stream ke merged stream dengan roomId asli)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Selalu sync stream dari provider — provider sudah handle merge
        final latestStream = roomChatProv.messagesStream;
        if (latestStream != _messagesStream) {
          setState(() {
            _messagesStream = latestStream;
          });
          _chatProvider.setActiveRoom(roomChatProv.activeRoomId);
          FCMService.instance.setActiveRoom(roomChatProv.activeRoomId);
          debugPrint('[RoomChat] 🔄 Stream refreshed after room resolved: '
              '${roomChatProv.activeRoomId}');
        }
      });
    }

    // Loading scaffold — hanya untuk case cari/buat room baru
    if (_isInitializing && widget.roomId == null) {
      return _buildLoadingScaffold();
    }

    // No room — keduanya null (bukan case pesan pertama dengan partnerId)
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

            // Banner penawaran/pesanan aktif
            if (_hasInitialized && _messagesStream != null)
              StreamBuilder<List<ChatMessageEntity>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final pens = _findActivePenawarans(snapshot.data!);
                  final psns = _findActivePesanans(snapshot.data!);
                  if (pens.isEmpty && psns.isEmpty) return const SizedBox.shrink();
                  return _buildActiveItemsBanner(pens, psns);
                },
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

                  // ✅ FIX: _messagesStream null = belum ada room (pesan pertama)
                  // Terjadi saat: buka dengan partnerId, belum pernah chat,
                  // stream belum di-assign karena FCM echo belum datang.
                  // Tampilkan empty state agar user tahu bisa ketik pesan.
                  if (_messagesStream == null) {
                    return _buildEmptyState();
                  }

                  // Stream belum emit (initial state) → skeleton
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return _buildLoadingMessages();
                  }

                  // Stream emit tapi kosong → empty state (room ada tapi belum ada pesan)
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

  Widget _buildLoadingMessages() {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, index) {
        // Alternating kiri-kanan seperti chat sungguhan
        final isMe = index % 2 == 0;
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ShimmerPlaceholder(
              width: isMe ? 200 : 250,
              height: 48,
              radius: 12,
            ),
          ),
        );
      },
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

    // Hitung active message IDs untuk assign GlobalKey (banner scroll-to)
    final activeMessageIds = {
      for (final e in [
        ..._findActivePenawarans(entities),
        ..._findActivePesanans(entities),
      ])
        e.messageId,
    };

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
                final card = ChatPesananCard(
                  pesanan: pesanan,
                  roomId: widget.roomId ?? '',
                  customerId: userProv.customer?.noId ?? '',
                  onTap: () => _handlePesananTap(context, pesanan),
                  onBatal: () => _batalkanPesanan(pesanan),
                  onGantiMetode: () => _gantiMetodePembayaran(pesanan),
                );
                if (activeMessageIds.contains(entity!.messageId)) {
                  final key = _itemBubbleKeys.putIfAbsent(
                      'psn_${entity.pesanan!.noBukti}', () => GlobalKey());
                  return KeyedSubtree(key: key, child: card);
                }
                return card;
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
                    onBatal: () => _batalkanPesanan(pesanan),
                    onGantiMetode: () => _gantiMetodePembayaran(pesanan),
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
                final card = ChatPenawaranCard(
                  penawaran: penawaran,
                  roomId: widget.roomId ?? '',
                  customerId: userProv.customer?.noId ?? '',
                  onTap: () => _handleOfferTap(context, penawaran, message),
                );
                if (activeMessageIds.contains(entity!.messageId)) {
                  final key = _itemBubbleKeys.putIfAbsent(
                      'pen_${entity.penawaran!.noId}', () => GlobalKey());
                  return KeyedSubtree(key: key, child: card);
                }
                return card;
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

  Future<void> _batalkanPesanan(dynamic pesanan) async {
    try {
      await PesananService().batal(pesanan.noBukti);
      final history = HistoryOrderService.createDibatalkan(
        noOrder: pesanan.noBukti,
        senderId: pesanan.idCustomer ?? '',
        customDeskripsi: 'Pesanan ini dibatalkan oleh customer.',
      );
      await HistoryOrderService().create(history);
      if (!mounted) return;
      context.read<PesananProvider>().refreshOrder(pesanan.noBukti);
      // Re-fetch pesan agar embedded pesanan di Isar terupdate → card rebuild
      final roomId = _roomChatProvider.activeRoomId;
      if (roomId != null) {
        await _chatProvider.loadMessages(roomId, forceRefresh: true);
      }
      if (!mounted) return;
      CustomSnackbar.showSuccessSnackbar(context, 'Pesanan berhasil dibatalkan.');
    } catch (e) {
      if (mounted) CustomSnackbar.showErrorSnackbar(context, e.toString());
    }
  }

  void _gantiMetodePembayaran(dynamic pesanan) {
    if (!mounted) return;
    context.read<NavigationProvider>().navigateToPage(
      context,
      targetTabIndex: 2,
      WaitingPaymentPage(paymentData: pesanan),
    );
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
  // ACTIVE ITEMS BANNER (penawaran + pesanan)
  // =========================================

  List<ChatMessageEntity> _findActivePenawarans(
      List<ChatMessageEntity> entities) {
    final sorted = [...entities]..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    final result = <ChatMessageEntity>[];
    final seen = <String>{};
    for (final e in sorted) {
      if (result.length >= 3) break;
      if (e.hasPenawaran &&
          !e.penawaran!.sudahJadiPesanan &&
          e.penawaran!.status != 'nonaktif') {
        final id = e.penawaran!.noId;
        if (id.isNotEmpty && seen.add(id)) result.add(e);
      }
    }
    return result;
  }

  List<ChatMessageEntity> _findActivePesanans(
      List<ChatMessageEntity> entities) {
    final sorted = [...entities]..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    final result = <ChatMessageEntity>[];
    final seen = <String>{};
    for (final e in sorted) {
      if (e.hasPesanan) {
        final status = e.pesanan!.status?.toLowerCase() ?? '';
        final progress = e.pesanan!.statusProgresPesanan?.toLowerCase() ?? '';
        if (status != 'selesai' &&
            progress != 'selesai' &&
            progress != 'dibatalkan') {
          final id = e.pesanan!.noBukti;
          if (id.isNotEmpty && seen.add(id)) result.add(e);
        }
      }
    }
    return result;
  }

  void _scrollToItem(String keyId) {
    final ctx = _itemBubbleKeys[keyId]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.3,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildActiveItemsBanner(
    List<ChatMessageEntity> penawarans,
    List<ChatMessageEntity> pesanans,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        children: [
          if (penawarans.isNotEmpty) ...[
            _buildBannerChip(
              icon: Icons.description_outlined,
              label: 'Penawaran',
              count: penawarans.length,
              color: Constants.primaryColor,
              onTap: () => _showActiveItemsSheet('penawaran', penawarans),
            ),
          ],
          if (penawarans.isNotEmpty && pesanans.isNotEmpty)
            const SizedBox(width: 8),
          if (pesanans.isNotEmpty) ...[
            _buildBannerChip(
              icon: Icons.receipt_long_outlined,
              label: 'Pesanan',
              count: pesanans.length,
              color: const Color(0xFF2563EB),
              onTap: () => _showActiveItemsSheet('pesanan', pesanans),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBannerChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 14, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  void _showActiveItemsSheet(String type, List<ChatMessageEntity> items) {
    final isPenawaran = type == 'penawaran';
    final title = isPenawaran ? 'Penawaran Aktif' : 'Pesanan Aktif';
    final color =
        isPenawaran ? Constants.primaryColor : const Color(0xFF2563EB);
    final sheetIcon = isPenawaran
        ? Icons.description_outlined
        : Icons.receipt_long_outlined;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Icon(sheetIcon, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text(
                    '$title (${items.length})',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, thickness: 1),
                itemBuilder: (ctx, i) {
                  final e = items[i];
                  final keyId = e.hasPesanan
                      ? 'psn_${e.pesanan!.noBukti}'
                      : 'pen_${e.penawaran!.noId}';
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _scrollToItem(keyId);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: e.hasPesanan
                          ? _buildPesananSheetRow(e, color)
                          : _buildPenawaranSheetRow(e, color),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPenawaranSheetRow(ChatMessageEntity e, Color color) {
    final p = e.penawaran!;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.description_outlined, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${p.noTrackingPenawaran}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '${p.namaPaket} • ${p.lokasi}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Helper.formatCurrency(p.harga),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ],
    );
  }

  Widget _buildPesananSheetRow(ChatMessageEntity e, Color color) {
    final p = e.pesanan!;
    final statusLabel = p.statusProgresPesanan?.isNotEmpty == true
        ? p.statusProgresPesanan!
        : (p.status ?? 'Proses');
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.receipt_long_outlined, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${p.noTrackingPesanan ?? p.noBukti}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                statusLabel,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Helper.formatCurrency(p.grandTotal),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ],
    );
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
