import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/constants.dart';
import '../providers/custom_back_button.dart';
import '../providers/navigation_provider.dart';
import 'providers/user_provider.dart';
import 'providers/chat_provider.dart';
import 'single_chat.dart';

class AllChat extends StatefulWidget {
  const AllChat({super.key});

  @override
  State<AllChat> createState() => _AllChatState();
}

class _AllChatState extends State<AllChat> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final currentUserId = context.read<UserProvider>().userId;
      if (currentUserId != null && currentUserId.isNotEmpty) {
        context.read<ChatProvider>().init(currentUserId);
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final sortedChats = [...chatProvider.rooms];
        sortedChats.sort((a, b) {
          final timeB = b['time'] ?? DateTime.fromMillisecondsSinceEpoch(0);
          final timeA = a['time'] ?? DateTime.fromMillisecondsSinceEpoch(0);
          return timeB.compareTo(timeA);
        });

        final filteredChats = sortedChats.where((chat) {
          final name = chat['username'].toString().toLowerCase();
          return name.contains(_searchQuery.toLowerCase());
        }).toList();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFFF9F9F9),
            elevation: 1,
            leading: CustomBackButton(),
            title: const Text(
              "Semua Pesan",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Column(
            children: [
              ChatHeader(
                unreadCount: sortedChats.where((c) => (c['unread'] ?? 0) > 0).length,
                searchController: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              Expanded(
                child: chatProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = filteredChats[index];
                          return ChatItem(
                            username: chat['username'] ?? 'Unknown',
                            avatar: chat['avatar'],
                            message: chat['message'],
                            time: chat['time'],
                            unreadCount: chat['unread'] ?? 0,
                            roomId: chat['roomId'] ?? '',
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChatHeader extends StatelessWidget {
  final int unreadCount;
  final TextEditingController searchController;
  final Function(String) onChanged;

  const ChatHeader({
    super.key,
    required this.unreadCount,
    required this.searchController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: searchController,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Cari pesan...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
      ],
    );
  }
}

class ChatItem extends StatelessWidget {
  final String? username;
  final String? avatar;
  final String? message;
  final DateTime? time;
  final int unreadCount;
  final String? roomId;

  const ChatItem({
    super.key,
    required this.username,
    required this.avatar,
    required this.message,
    required this.time,
    required this.unreadCount,
    required this.roomId,
  });

  Widget _shimmerAvatar(double size) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String imgUrl = avatar ?? '';

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[200],
        child: ClipOval(
          child: SizedBox(
            width: 48,
            height: 48,
            child: Image.network(
              imgUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _shimmerAvatar(48);
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.person, size: 24);
              },
            ),
          ),
        ),
      ),
      title: Text(username ?? 'Unknown'),
      subtitle: Text(
        message ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            context.read<NavigationProvider>().formatDateLabel(time, showTodaysJam: true),
            style: const TextStyle(
              color: Constants.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Constants.primaryColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
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
      ),
      onTap: () {
        context.read<NavigationProvider>().navigateToPage(
          context,
          SingleChat(
            receiverUserName: username ?? 'Unknown',
            receiverEmail: 'INI RECEIVER EMAIL',
            receiverID: 'INI RECEIVER ID',
          ),
          targetTabIndex: 1,
        );
      },
    );
  }
}
