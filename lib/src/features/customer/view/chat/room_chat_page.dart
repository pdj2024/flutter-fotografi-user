import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/services/fcm/fcm_service.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/hive_entity/chat_message_entity.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
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
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// ✅ FIXED: Room Chat Page with proper stream caching and dispose handling
///
/// Key fixes:
/// - ✅ Cache stream reference to prevent recreation on every build
/// - ✅ Setup stream during initialization, not in build()
/// - ✅ Proper dispose with PostFrameCallback to avoid setState() errors
/// - ✅ Debug logging for troubleshooting
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

  // ✅ Simpan reference ke providers
  late ChatProvider _chatProvider;
  late RoomChatProvider _roomChatProvider;
  bool _providersInitialized = false;

  // ✅ CRITICAL: Cache stream reference to prevent rebuilding
  Stream<List<ChatMessageEntity>>? _messagesStream;
  String? _currentStreamRoomId;

  // ✅ State tracking - NO initial loading!
  bool _isInitializing = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController(initialRefresh: false);

    // ✅ Scroll listener for lazy display
    _scrollController.addListener(_onScroll);

    // ✅ Initialize immediately after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeChat();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Check if at top (reverse list - so maxScrollExtent is the top/oldest)
    final position = _scrollController.position;
    final threshold = 200.0; // Trigger 200px before reaching top

    if (position.pixels >= position.maxScrollExtent - threshold) {
      _loadMoreForDisplay();
    }
  }

  /// ✅ Load more messages for display (from memory, not API!)
  Future<void> _loadMoreForDisplay() async {
    if (!mounted) return;

    // This calls RoomChatProvider.loadMoreMessages()
    // which loads from memory (instant!)
    await _roomChatProvider.loadMoreMessages();
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
    debugPrint('═══════════════════════════════════════');
    debugPrint('[RoomChat] 🧹 DISPOSING PAGE');
    debugPrint('═══════════════════════════════════════');

    if (_providersInitialized && _roomChatProvider.activeRoomId != null) {
      final roomId = _roomChatProvider.activeRoomId!;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _chatProvider.untrackRoom(roomId);
          _chatProvider.setActiveRoom(null);
          FCMService.instance.setActiveRoom(null);

          debugPrint('[RoomChat] ✅ Cleaned up room: $roomId');
        } catch (e) {
          debugPrint('[RoomChat] ⚠️ Cleanup error: $e');
        }
      });
    }

    _messagesStream = null;
    _currentStreamRoomId = null;

    // ✅ Remove scroll listener before disposing
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _refreshController.dispose();

    debugPrint('[RoomChat] ✅ Dispose complete');
    debugPrint('═══════════════════════════════════════');

    super.dispose();
  }

  // =========================================
  // INITIALIZATION
  // =========================================
  Future<void> _initializeChat() async {
    if (_hasInitialized) {
      debugPrint('[RoomChat] ⚠️ Already initialized, skipping...');
      return;
    }

    if (!mounted) return;

    // ✅ NO loading state initially - instant display!
    try {
      debugPrint('═══════════════════════════════════════');
      debugPrint('🚀 INIT ROOM CHAT (Instant Display Mode)');
      debugPrint('RoomId: ${widget.roomId}');
      debugPrint('PartnerId: ${widget.partnerId}');
      debugPrint('═══════════════════════════════════════');

      // ✅ CRITICAL: Ensure we have roomId or partnerId
      if (widget.roomId == null && widget.partnerId == null) {
        throw Exception('Both roomId and partnerId are null');
      }

      // ✅ Step 1: Track room in ChatProvider FIRST (if we have roomId)
      if (widget.roomId != null) {
        await _chatProvider.trackRoom(widget.roomId!);
        debugPrint('[RoomChat] ✅ Room tracked in ChatProvider');
      }

      // ✅ Step 2: Initialize RoomChatProvider
      // This will instantly load from Hive + background sync
      await _roomChatProvider.initChat(
        roomId: widget.roomId,
        partnerId: widget.partnerId,
      );

      if (!mounted) return;

      // ✅ Step 3: Wait for activeRoomId to be set
      int retries = 0;
      const maxRetries = 20;
      while (_roomChatProvider.activeRoomId == null && retries < maxRetries) {
        debugPrint('[RoomChat] ⏳ Waiting for activeRoomId... (retry $retries)');
        await Future.delayed(const Duration(milliseconds: 100));
        retries++;

        if (!mounted) return;
      }

      if (_roomChatProvider.activeRoomId == null) {
        throw Exception('Failed to initialize room after $maxRetries retries');
      }

      debugPrint(
          '[RoomChat] ✅ ActiveRoomId set: ${_roomChatProvider.activeRoomId}');

      // ✅ Step 4: Track room if not tracked yet (for partnerId case)
      if (widget.roomId == null && _roomChatProvider.activeRoomId != null) {
        await _chatProvider.trackRoom(_roomChatProvider.activeRoomId!);
        debugPrint('[RoomChat] ✅ Room tracked (from partnerId)');
      }

      // ✅ Step 5: Set active room in ChatProvider & FCM
      _chatProvider.setActiveRoom(_roomChatProvider.activeRoomId);
      FCMService.instance.setActiveRoom(_roomChatProvider.activeRoomId);

      // ✅ Step 6: Setup stream ONCE
      _setupMessagesStream(_roomChatProvider.activeRoomId!);

      debugPrint('═══════════════════════════════════════');
      debugPrint('✅ ROOM CHAT INITIALIZED (Instant Mode)');
      debugPrint('═══════════════════════════════════════');
      debugPrint('Active Room: ${_roomChatProvider.activeRoomId}');
      debugPrint('Stream Setup: ${_messagesStream != null}');
      debugPrint('Display: Instant from Hive');
      debugPrint('Background: Syncing from API...');
      debugPrint('═══════════════════════════════════════');

      if (!mounted) return;

      setState(() {
        _hasInitialized = true;
      });
    } catch (e, st) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('❌ ROOM CHAT INIT ERROR');
      debugPrint('═══════════════════════════════════════');
      debugPrint('Error: $e');
      debugPrint('Stack: $st');
      debugPrint('═══════════════════════════════════════');

      if (mounted) {
        CustomSnackbar.showErrorSnackbar(context, "Gagal memuat");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  /// ✅ CRITICAL: Setup stream ONCE and cache it
  void _setupMessagesStream(String roomId) {
    debugPrint('═══════════════════════════════════════');
    debugPrint('[RoomChat] 🎛️ SETTING UP MESSAGES STREAM');
    debugPrint('[RoomChat] Room ID: $roomId');
    debugPrint('═══════════════════════════════════════');

    // Only setup if not already setup for this room
    if (_currentStreamRoomId == roomId && _messagesStream != null) {
      debugPrint('[RoomChat] ℹ️ Stream already setup for this room');
      return;
    }

    // Get stream from ChatProvider
    _messagesStream = _chatProvider.getMessagesStream(roomId);
    _currentStreamRoomId = roomId;

    debugPrint('[RoomChat] ✅ Messages stream created');
    debugPrint('[RoomChat] 📡 Listening for updates...');
    debugPrint('═══════════════════════════════════════');
  }

  Future<void> _refreshChat() async {
    if (_roomChatProvider.activeRoomId == null) {
      debugPrint('[RoomChat] ⚠️ Cannot refresh: no active room');
      if (mounted) {
        _refreshController.refreshFailed();
      }
      return;
    }

    try {
      debugPrint('[RoomChat] 🔄 Refreshing messages...');

      await _chatProvider.loadMessages(
        _roomChatProvider.activeRoomId!,
        forceRefresh: true,
      );

      debugPrint('[RoomChat] ✅ Messages refreshed');

      if (mounted) {
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      debugPrint('[RoomChat] ❌ Error refreshing chat: $e');

      if (mounted) {
        _refreshController.refreshFailed();
        CustomSnackbar.showErrorSnackbar(context, "Gagal memuat");
      }
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

    // ✅ Only show loading scaffold when creating new room (not for existing room)
    if (_isInitializing && widget.roomId == null && widget.partnerId != null) {
      return _buildLoadingScaffold();
    }

    // Empty state - only if no room can be created
    if (roomChatProv.activeRoomId == null &&
        widget.partnerId == null &&
        widget.roomId == null) {
      return _buildNoRoomScaffold();
    }

    // Main UI
    final String imgUrl =
        roomChatProv.roomInfo?.idMediaLawan ?? widget.partnerAvatarUrl ?? '';

    return Scaffold(
      appBar: _buildAppBar(roomChatProv, imgUrl),
      backgroundColor: const Color(0xFFF9F9F9),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/chat_background.png'),
            fit: BoxFit.cover,
            opacity: 0.2, // ✅ Much lighter (was 0.95)
            colorFilter: ColorFilter.mode(
              Constants.primaryColor.withOpacity(0.05),

              BlendMode.lighten, // ✅ Lighten instead of srcATop
            ),
          ),
        ),
        child: Column(
          children: [
            if (_roomChatProvider.isLoadingMoreDisplay)
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
                          Constants.primaryColorVendor,
                        ),
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
                        valueColor:
                            AlwaysStoppedAnimation(Colors.blue.shade600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
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

            // ✅ CRITICAL: Messages stream with cached reference
            Expanded(
              child: StreamBuilder<List<ChatMessageEntity>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  // ✅ Debug: Log stream state
                  debugPrint('═══════════════════════════════════════');
                  debugPrint('[RoomChat] 📺 STREAMBUILDER REBUILD');
                  debugPrint(
                      '[RoomChat] Connection: ${snapshot.connectionState}');
                  debugPrint('[RoomChat] Has data: ${snapshot.hasData}');
                  debugPrint('[RoomChat] Has error: ${snapshot.hasError}');
                  if (snapshot.hasData) {
                    debugPrint(
                        '[RoomChat] Messages count: ${snapshot.data!.length}');
                  }
                  if (snapshot.hasError) {
                    debugPrint('[RoomChat] Error: ${snapshot.error}');
                  }
                  debugPrint('═══════════════════════════════════════');

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(
                              color: Colors.red.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _refreshChat(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  }

                  // ✅ Show empty state immediately if no data (don't wait for connection)
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
            const SizedBox(height: 10),
          ],
        ),
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
                placeholder: (context, url) => const ShimmerPlaceholder(
                  width: 36,
                  height: 36,
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
              if (pesanan != null &&
                  message.noInvoice != null &&
                  message.noInvoice!.isNotEmpty) {
                return ChatPesananCard(
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
                );
              }

              // PENAWARAN CARD
              if (message.noPenawaran != null &&
                  message.noPenawaran!.isNotEmpty) {
                if (penawaran == null) {
                  return _buildOfferClosedCard();
                }

                return ChatPenawaranCard(
                  penawaran: penawaran,
                  roomId: widget.roomId ?? "",
                  customerId: userProv.customer?.noId ?? "",
                  onTap: () => _handleOfferTap(context, penawaran, message),
                );
              }

              // PAKET CARD + OPTIONAL TEXT
              if (message.idPaket != null && message.idPaket!.isNotEmpty) {
                return Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (paket == null)
                      const ShimmerPlaceholder(
                        width: 300,
                        height: 100,
                        radius: 10,
                      ),
                    if (paket != null)
                      ChatPackageCard(
                        paket: paket,
                        isMe: isMe,
                        onTap: () {},
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
      BuildContext context, PenawaranModel offer, ChatModel message) async {
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
            targetTabIndex: 1,
            DetailPembayaranPage(
              penawaranId: offer.noId,
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
          // Date badge
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
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  "Hari ini",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Animated chat icon
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, double value, child) {
              return Transform.scale(
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
              );
            },
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            'Belum ada pesan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 12),

          // Subtitle with better formatting
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

          // Quick action hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Constants.primaryColorVendor.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: Constants.primaryColorVendor,
                ),
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

  Widget _buildEmptyStateScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: const Color(0xFFF9F9F9),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada chat',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
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

  Widget _buildNoRoomScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: const Color(0xFFF9F9F9),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Constants.primaryColorVendor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Constants.primaryColorVendor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Tidak ada chat',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'Tidak dapat menemukan\nruang percakapan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColorVendor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: Constants.primaryColorVendor.withOpacity(0.4),
                ),
              ),
            ],
          ),
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
        title: const Row(
          children: [
            ShimmerPlaceholder(width: 36, height: 36, radius: 18),
            SizedBox(width: 12),
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
              child: const ShimmerPlaceholder(
                width: 250,
                height: 60,
                radius: 12,
              ),
            ),
          );
        },
      ),
    );
  }
}
