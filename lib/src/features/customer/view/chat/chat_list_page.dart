import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/hive_entity/room_chat_entity.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/room_chat_provider.dart';
import 'package:provider/provider.dart';

/// ✅ REFACTORED: Chat List Page using Hive Streams
///
/// Changes:
/// - Uses StreamBuilder untuk reactive updates dari Hive
/// - Data loads instantly dari Hive cache
/// - Background sync berjalan otomatis
/// - No manual notifyListeners needed
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // Reset RoomChatProvider saat masuk ke list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roomChatProv = context.read<RoomChatProvider>();
      roomChatProv.reset();

      // ✅ Optional: Trigger background sync
      final chatProv = context.read<ChatProvider>();
      if (chatProv.isInitialized) {
        chatProv.loadRooms(); // Background sync, tidak blocking UI
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        actions: [
          if (chatProv.isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Tooltip(
                message: 'Mengecek koneksi chat...',
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(
                  Icons.circle,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
            )
          else if (chatProv.isConnected)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Tooltip(
                message: 'Chat terhubung',
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(
                  Icons.circle,
                  color: Colors.green,
                  size: 20,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Tooltip(
                message: "Mencoba menghubungkan kembali",
                triggerMode: TooltipTriggerMode.tap,
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Constants.primaryColorVendor,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),

          // ✅ MAIN CHANGE: StreamBuilder untuk rooms
          Expanded(
            child: StreamBuilder<List<RoomChatEntity>>(
              stream: chatProv.repository.getRoomsStream(),
              builder: (context, snapshot) {
                // ════════════════════════════════════════════════════════
                // LOADING STATE (hanya untuk initial load)
                // ════════════════════════════════════════════════════════
                if (!snapshot.hasData) {
                  // Cek apakah sedang loading initial data
                  if (chatProv.isLoading) {
                    return _buildLoadingState();
                  }
                  // Jika tidak loading tapi tidak ada data = empty
                  return _buildEmptyState();
                }

                // ════════════════════════════════════════════════════════
                // DATA STATE
                // ════════════════════════════════════════════════════════
                final allRooms = snapshot.data!;

                // Filter & sort
                final filtered = _filterAndSortRooms(allRooms);

                // Empty state setelah filter
                if (filtered.isEmpty) {
                  return _buildEmptyState(
                    isSearchResult: _searchQuery.isNotEmpty,
                  );
                }

                // ✅ Room list
                return _buildRoomList(chatProv, filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // FILTER & SORT
  // =========================================

  List<RoomChatEntity> _filterAndSortRooms(List<RoomChatEntity> rooms) {
    // Filter berdasarkan search query
    final filtered = rooms.where((room) {
      if (_searchQuery.isEmpty) return true;
      final name = room.displayName.toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort by lastMessageAt descending
    filtered.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

    return filtered;
  }

  // =========================================
  // UI BUILDERS
  // =========================================

  Widget _buildSearchBar() {
    return StreamBuilder<List<RoomChatEntity>>(
      stream: context.read<ChatProvider>().repository.getRoomsStream(),
      builder: (context, snapshot) {
        final rooms = snapshot.data ?? [];
        final unreadCount = rooms.where((r) => r.hasUnread).length;

        return Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFFF9F9F9),
          child: Row(
            children: [
              // Search field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari percakapan...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoomList(ChatProvider chatProv, List<RoomChatEntity> rooms) {
    return RefreshIndicator(
      onRefresh: () => chatProv.loadRooms(forceRefresh: true),
      child: ListView.builder(
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          return _buildRoomItem(rooms[index]);
        },
      ),
    );
  }

  Widget _buildRoomItem(RoomChatEntity room) {
    return InkWell(
      onTap: () {
        // Navigate ke RoomChatPage
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
              : Color(0xFFF9F9F9),
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey.shade300,
                  child:
                      room.idMediaLawan != null && room.idMediaLawan!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: room.idMediaLawan!,
                              imageBuilder: (_, img) => CircleAvatar(
                                radius: 26,
                                backgroundImage: img,
                                backgroundColor: Colors.transparent,
                              ),
                              placeholder: (_, __) =>
                                  const CircleAvatar(radius: 26),
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(width: 12),

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
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(room.lastMessageAt),
                        style: TextStyle(
                          color: room.hasUnread
                              ? Constants.primaryColor
                              : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Preview & unread
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.previewMessage,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: room.hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (room.hasUnread)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Constants.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${room.unread}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
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

  // =========================================
  // STATES
  // =========================================

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (_, __) => _buildShimmerItem(),
    );
  }

  Widget _buildEmptyState({bool isSearchResult = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            isSearchResult ? 'Tidak ditemukan' : 'Belum ada pesan',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerItem() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar shimmer
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
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
