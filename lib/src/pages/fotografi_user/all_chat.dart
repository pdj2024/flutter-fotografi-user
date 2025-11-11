import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/chat_provider.dart';
// import 'package:mpjnew/src/pages/fotografi_user/services/chat_service.dart' show ChatService;

import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/custom_back_button.dart';
import '../../core/routing/navigation_provider.dart';

import '../../features/auth/services/user_provider.dart';

import 'single_chat.dart';

class AllChat extends StatefulWidget {
  const AllChat({super.key});

  @override
  State<AllChat> createState() => _AllChatState();
}

class _AllChatState extends State<AllChat> {
  // final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // List<Map<String, dynamic>> _chats = [];
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    final userId = context.read<UserProvider>().userId ?? '';
    Future.microtask(() {
      context.read<ChatProvider>().init(userId);
    });
  }

DateTime? parseIsoDate(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  try {
    return DateTime.parse(iso).toLocal(); // konversi ke local timezone
  } catch (_) {
    return null;
  }
}

  @override
  Widget build(BuildContext context) {
      final _chats = context.watch<ChatProvider>().rooms;

    final List<Map<String, dynamic>> sortedChats = [..._chats];
    // sortedChats.sort((a, b) => b['time'].compareTo(a['time']));
    sortedChats.sort((a, b) {
  final timeA = a['Last_Message_At'] is DateTime
      ? a['Last_Message_At'] as DateTime
      : parseIsoDate(a['Last_Message_At'] as String?) ?? DateTime.fromMillisecondsSinceEpoch(0);

  final timeB = b['Last_Message_At'] is DateTime
      ? b['Last_Message_At'] as DateTime
      : parseIsoDate(b['Last_Message_At'] as String?) ?? DateTime.fromMillisecondsSinceEpoch(0);

  return timeB.compareTo(timeA);
});


    final List<Map<String, dynamic>> filteredChats = sortedChats.where((chat) {
      final name = chat['Username_Lawan'].toString().toLowerCase();
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
            // unreadCount: sortedChats.where((c) => c['unread'] > 0).length,
             unreadCount: sortedChats.where((c) => (c['unread'] ?? 0) > 0).length,
            searchController: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          Expanded(
  child: context.watch<ChatProvider>().isLoading
      ? ListView.builder(
          itemCount: 6, // jumlah skeleton dummy
          itemBuilder: (context, index) {
            return const ChatItemShimmer();
          },
        )
      : ListView.builder(
          itemCount: filteredChats.length,
          itemBuilder: (context, index) {
            final chat = filteredChats[index];
            return ChatItem(
              username: chat['Username_Lawan'] ?? '',
              avatar: chat['Id_Media_Lawan'] as String?,
              message: chat['Last_Message'] as String?,
              time: chat['Last_Message_At'] is DateTime
                  ? chat['Last_Message_At'] as DateTime
                  : parseIsoDate(chat['Last_Message_At'] as String?),
              unreadCount: chat['unread'] ?? 0,
              roomId: chat['Room_Id'] ?? '',
            );
          },
        ),
),

        ],
      ),
    );
  }
}

class ChatItemShimmer extends StatelessWidget {
  const ChatItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: const CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white,
        ),
      ),
      title: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: double.infinity,
          height: 14,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 6),
        ),
      ),
      subtitle: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.4,
          height: 12,
          color: Colors.white,
        ),
      ),
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
  final String username;


  final String? avatar;
 final String? message;
  final DateTime? time;
  final int unreadCount; 
  final String roomId;

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
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String imgUrl =
       avatar ?? '';

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
      title: Text(username),
      subtitle: Text(
        message ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
        Text(
  time != null
      ? context.read<NavigationProvider>().formatDateLabel(
            time!,
            showTodaysJam: true,
          )
      : '', // kalau null tampilkan string kosong
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
           
            roomId: roomId,
          ),
          targetTabIndex: 1,
        );
      },
    );
  }
}