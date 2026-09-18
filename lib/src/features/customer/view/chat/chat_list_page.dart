import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
// ✅ Isar entity — bukan lagi hive_entity
import 'package:mpjnew/src/data/isar/data/room_chat_entity.dart';
import 'package:mpjnew/src/data/isar/service/chat_isar_service.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/room_chat_provider.dart';
import 'package:mpjnew/src/features/customer/widget/refresh_header.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// ✅ ChatListPage — Isar Edition
///
/// Perubahan dari versi Hive:
///   - Stream rooms: ChatIsarService.instance.watchAllRooms() (Isar native)
///   - Stream di-cache di _roomsStream (SEKALI, tidak dibuat ulang saat setState)
///   - didChangeAppLifecycleState: sync API saat resume
///   - roomChatProv.reset() → roomChatProv.disposeRoom() (Isar edition)
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with WidgetsBindingObserver {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ✅ Stream di-cache SEKALI — tidak dibuat ulang saat setState (misal ketik search).
  // Kalau watchAllRooms() dipanggil langsung di StreamBuilder.stream,
  // setiap rebuild membuat subscription baru → list flash kosong sebentar.
  late final Stream<List<RoomChatEntity>> _roomsStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ✅ Cache stream SEKALI seumur hidup widget
    _roomsStream = ChatIsarService.instance.watchAllRooms();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NavigationProvider>().showBottomNav();

      // ✅ Reset state room sebelumnya (pakai disposeRoom, bukan reset)
      context.read<RoomChatProvider>().disposeRoom();

      // ✅ Background sync dari API — stream Isar otomatis update UI
      _syncRoomsFromApi();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      debugPrint('[ChatList] 🔄 App resumed — syncing rooms...');
      // ✅ Saat resume: RoomChatProvider (di bottom nav) sudah drain queue.
      // Isar _roomsStream (broadcast) otomatis emit data terbaru → rebuild.
      // Kita hanya perlu sync dari API untuk yang mungkin terlewat.
      _syncRoomsFromApi();
    }
  }

  /// Sync ringan saat halaman dibuka / app resume.
  /// Sengaja TIDAK forceRefresh: itu memicu replaceAllRooms yang menimpa
  /// preview lokal dengan Last_Message kosong dari server. Replace penuh
  /// hanya untuk pull-to-refresh eksplisit (_onRefresh).
  Future<void> _syncRoomsFromApi() async {
    if (!mounted) return;
    try {
      await context
          .read<ChatProvider>()
          .loadRooms(forceRefresh: false, silent: true);
    } catch (e) {
      debugPrint('[ChatList] ⚠️ Sync error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (!mounted) {
      _refreshController.refreshCompleted();
      return;
    }
    try {
      unawaited(context.read<ChatProvider>().markAllSentAsReceived());
      await context.read<ChatProvider>().loadRooms(
            forceRefresh: true,
            silent: false,
          );
      _refreshController.refreshCompleted();
    } catch (e) {
      debugPrint('[ChatList] ❌ Refresh error: $e');
      _refreshController.refreshFailed();
    }
  }

  List<RoomChatEntity> _filterAndSortRooms(List<RoomChatEntity> rooms) {
    final filtered = rooms.where((room) {
      if (_searchQuery.isEmpty) return true;
      final name = room.displayName.toLowerCase();
      final preview = room.previewMessage.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || preview.contains(query);
    }).toList();

    filtered.sort((a, b) {
      if (a.hasUnread && !b.hasUnread) return -1;
      if (!a.hasUnread && b.hasUnread) return 1;
      return b.lastMessageAt.compareTo(a.lastMessageAt);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 1,
          title: const Text(
            'Semua Pesan',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: StreamBuilder<List<RoomChatEntity>>(
          // ✅ _roomsStream di-cache — tidak dibuat ulang saat setState
          stream: _roomsStream,
          builder: (context, snapshot) {
            // Loading pertama (stream belum pernah emit)
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return _buildLoadingShimmer();
            }
      
            final allRooms = snapshot.data ?? [];
            final filtered = _filterAndSortRooms(allRooms);
      
            return SmartRefresher(
              controller: _refreshController,
              onRefresh: _onRefresh,
              physics: const AlwaysScrollableScrollPhysics(),
              header: buildRefreshHeader(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(
                        isSearchResult: _searchQuery.isNotEmpty,
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, index) => _buildRoomItem(filtered[index]),
                        childCount: filtered.length,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // =========================================
  // UI BUILDERS
  // =========================================

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari percakapan...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade600),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: Constants.primaryColorVendor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildRoomItem(RoomChatEntity room) {
    return InkWell(
      onTap: () {
        context.read<NavigationProvider>().navigateToPage(
              context,
              RoomChatPage(
                roomId: room.roomId,
                partnerId: room.idLawan,
                partnerUsername: room.usernameLawan,
                partnerAvatarUrl: room.idMediaLawan,
              ),
              targetTabIndex: 1,
            );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: room.hasUnread
              ? Constants.primaryColor.withOpacity(0.05)
              : Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            _buildAvatar(room),
            const SizedBox(width: 14),
            Expanded(child: _buildRoomInfo(room)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(RoomChatEntity room) {
    final hasMedia = room.idMediaLawan != null && room.idMediaLawan!.isNotEmpty;

    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.grey.shade300,
      child: hasMedia
          ? CachedNetworkImage(
              imageUrl: room.idMediaLawan!,
              imageBuilder: (_, img) =>
                  CircleAvatar(radius: 28, backgroundImage: img),
              placeholder: (_, __) => CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade300,
                child:
                    Icon(Icons.person, color: Colors.grey.shade500, size: 28),
              ),
              errorWidget: (_, __, ___) => _buildInitialAvatar(room),
            )
          : _buildInitialAvatar(room),
    );
  }

  Widget _buildInitialAvatar(RoomChatEntity room) {
    final initial =
        room.displayName.isNotEmpty ? room.displayName[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 28,
      backgroundColor: Constants.primaryColorVendor.withOpacity(0.2),
      child: Text(
        initial,
        style: TextStyle(
          color: Constants.primaryColorVendor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRoomInfo(RoomChatEntity room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                room.displayName,
                style: TextStyle(
                  fontWeight:
                      room.hasUnread ? FontWeight.bold : FontWeight.w600,
                  fontSize: 15,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(room.lastMessageAt),
              style: TextStyle(
                color: room.hasUnread
                    ? Constants.primaryColorVendor
                    : Colors.grey.shade500,
                fontSize: 11,
                fontWeight:
                    room.hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                room.previewMessage,
                style: TextStyle(
                  color: room.hasUnread
                      ? Colors.grey.shade700
                      : Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight:
                      room.hasUnread ? FontWeight.w500 : FontWeight.normal,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (room.hasUnread)
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Constants.primaryColorVendor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Constants.primaryColorVendor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  room.actualUnreadCount > 99
                      ? '99+'
                      : '${room.actualUnreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // =========================================
  // STATES
  // =========================================

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 200,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({bool isSearchResult = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, double value, _) => Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Constants.primaryColorVendor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSearchResult ? Icons.search_off : Icons.chat_bubble_outline,
                  size: 56,
                  color: Constants.primaryColorVendor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSearchResult ? 'Tidak ditemukan' : 'Belum ada pesan',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              isSearchResult
                  ? 'Coba gunakan kata kunci lain'
                  : 'Pesan dari anda akan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          if (!isSearchResult) ...[
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 48),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                  Icon(Icons.info_outline,
                      size: 18, color: Constants.primaryColorVendor),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Silahkan hubungi vendor dari halaman Jelajah',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================
  // UTILITIES
  // =========================================

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Kemarin';
    } else if (now.difference(time).inDays < 7) {
      const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
      return days[time.weekday % 7];
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
