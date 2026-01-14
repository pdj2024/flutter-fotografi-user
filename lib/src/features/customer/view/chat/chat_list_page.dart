import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/room_chat_provider.dart';
import 'package:provider/provider.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roomChatProv = context.read<RoomChatProvider>();
      roomChatProv.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProv = context.watch<ChatProvider>();
    final rooms = chatProv.rooms;

    // Filter & sort
    final filtered = rooms.where((room) {
      if (_searchQuery.isEmpty) return true;
      final name = room.displayName.toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    filtered.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

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
          // Connection indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              chatProv.isConnected ? Icons.wifi : Icons.wifi_off,
              color: chatProv.isConnected ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(filtered),

          // Room list
          Expanded(
            child: _buildRoomList(chatProv, filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(List<RoomChatModel> rooms) {
    final unreadCount = rooms.where((r) => r.hasUnread).length;

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
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
                fillColor: Colors.grey.shade100,
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

          // Unread badge
          if (unreadCount > 0) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomList(ChatProvider chatProv, List<RoomChatModel> rooms) {
    // Loading state
    if (chatProv.isLoading && rooms.isEmpty) {
      return ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => _buildShimmerItem(),
      );
    }

    // Empty state
    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'Belum ada pesan' : 'Tidak ditemukan',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Room list
    return RefreshIndicator(
      onRefresh: () => chatProv.refresh(),
      child: ListView.builder(
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          return _buildRoomItem(rooms[index]);
        },
      ),
    );
  }

  Widget _buildRoomItem(RoomChatModel room) {
    return InkWell(
      onTap: () {
        // Navigate ke RoomChatPage
        context.read<NavigationProvider>().navigateToPage(
              context,
              RoomChatPage(
                roomId: room.roomId,
              ),
              targetTabIndex: 1,
            );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: room.hasUnread ? Colors.blue.withOpacity(0.05) : Colors.white,
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
                  child: room.idMediaLawan != null &&
                          room.idMediaLawan!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: room.idMediaLawan!,
                          imageBuilder: (_, img) => CircleAvatar(
                            radius: 26,
                            backgroundImage: img,
                          ),
                          placeholder: (_, __) =>
                              const CircleAvatar(radius: 26),
                          errorWidget: (_, __, ___) => const Icon(Icons.person),
                        )
                      : const Icon(Icons.person, color: Colors.white),
                ),
                // Online indicator (optional)
                // Positioned(
                //   right: 0,
                //   bottom: 0,
                //   child: Container(
                //     width: 12,
                //     height: 12,
                //     decoration: BoxDecoration(
                //       color: Colors.green,
                //       shape: BoxShape.circle,
                //       border: Border.all(color: Colors.white, width: 2),
                //     ),
                //   ),
                // ),
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
                              ? Colors.blue
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
                            color: Colors.blue,
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
