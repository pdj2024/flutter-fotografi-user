import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/hive_entity/room_chat_entity.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/room_chat_provider.dart';
import 'package:mpjnew/src/features/customer/widget/refresh_header.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final roomChatProv = context.read<RoomChatProvider>();
      final chatProv = context.read<ChatProvider>();

      context.read<NavigationProvider>().showBottomNav();
      roomChatProv.reset();

      if (chatProv.isInitialized) {
        debugPrint('[RoomList] 🔄 Starting background sync...');
        chatProv.loadRooms(forceRefresh: true, silent: true).then((_) {
          debugPrint('[RoomList] ✅ Background sync complete');
        }).catchError((e) {
          debugPrint('[RoomList] ⚠️ Background sync error: $e');
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (!mounted) {
      _refreshController.refreshCompleted();
      return;
    }
    try {
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
    final chatProv = context.watch<ChatProvider>();

    return Scaffold(
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

      // ✅ Struktur: SmartRefresher di luar segalanya
      //    SmartRefresher
      //      └── StreamBuilder
      //            └── CustomScrollView
      //                  ├── SliverToBoxAdapter (search bar) ← ikut scroll
      //                  └── SliverList / SliverFillRemaining (content)
      body: StreamBuilder<List<RoomChatEntity>>(
        stream: chatProv.repository.getRoomsStream(),
        builder: (context, snapshot) {
          final allRooms = snapshot.data ?? [];
          final filtered = _filterAndSortRooms(allRooms);

          return SmartRefresher(
            controller: _refreshController,
            onRefresh: _onRefresh,
            physics: const AlwaysScrollableScrollPhysics(),
            header: buildRefreshHeader(),
            child: CustomScrollView(
              slivers: [
                // Search bar — ikut scroll ke atas saat pull-to-refresh
                SliverToBoxAdapter(child: _buildSearchBar()),

                // Content
                if (!snapshot.hasData && chatProv.isLoading)
                  // Loading shimmer
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => _buildShimmerItem(),
                      childCount: 6,
                    ),
                  )
                else if (filtered.isEmpty)
                  // Empty state — SliverFillRemaining agar mengisi sisa layar
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(
                      isSearchResult: _searchQuery.isNotEmpty,
                    ),
                  )
                else
                  // Room list
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
        debugPrint('[RoomList] 🚀 Opening room: ${room.roomId}');
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
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade300,
              child: room.idMediaLawan != null && room.idMediaLawan!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: room.idMediaLawan!,
                      imageBuilder: (_, img) => CircleAvatar(
                        radius: 28,
                        backgroundImage: img,
                      ),
                      placeholder: (_, __) => CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey.shade300,
                        child: Icon(Icons.person,
                            color: Colors.grey.shade500, size: 28),
                      ),
                      errorWidget: (_, __, ___) => _buildInitialAvatar(room),
                    )
                  : _buildInitialAvatar(room),
            ),

            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.displayName,
                          style: TextStyle(
                            fontWeight: room.hasUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
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
                          fontWeight: room.hasUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Preview & badge
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
                            fontWeight: room.hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Constants.primaryColorVendor,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Constants.primaryColorVendor
                                    .withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${room.actualUnreadCount > 99 ? '99+' : room.actualUnreadCount}',
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(RoomChatEntity room) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Constants.primaryColorVendor.withOpacity(0.2),
      child: Text(
        room.displayName[0].toUpperCase(),
        style: TextStyle(
          color: Constants.primaryColorVendor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =========================================
  // STATES
  // =========================================

  Widget _buildEmptyState({bool isSearchResult = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Constants.primaryColorVendor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSearchResult
                        ? Icons.search_off
                        : Icons.chat_bubble_outline,
                    size: 56,
                    color: Constants.primaryColorVendor,
                  ),
                ),
              );
            },
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
                  : 'Pesan dari customer akan muncul di sini',
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
                      'Chat otomatis muncul saat customer menghubungi',
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

  Widget _buildShimmerItem() {
    return Container(
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
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
