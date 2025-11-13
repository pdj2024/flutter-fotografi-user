import 'package:flutter/material.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/widget/chat_list_tile.dart';
import 'package:mpjnew/src/features/customer/widget/search_chat_field.dart';
import 'package:mpjnew/src/features/customer/widget/shimmer/vendor_bio_shimmer.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/chat_provider.dart';
import 'package:mpjnew/src/pages/providers/custom_back_button.dart';
import 'package:provider/provider.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  // final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // List<Map<String, dynamic>> _chats = [];
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    // final userId = context.read<UserProvider>().userId ?? '';
    // Future.microtask(() {
    //   context.read<ChatProvider>().init(userId);
    // });
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
    print("=== CHATS: " + _chats.length.toString());

    final List<Map<String, dynamic>> sortedChats = [..._chats];
    // sortedChats.sort((a, b) => b['time'].compareTo(a['time']));
    sortedChats.sort((a, b) {
      final timeA = a['Last_Message_At'] is DateTime
          ? a['Last_Message_At'] as DateTime
          : parseIsoDate(a['Last_Message_At'] as String?) ??
              DateTime.fromMillisecondsSinceEpoch(0);

      final timeB = b['Last_Message_At'] is DateTime
          ? b['Last_Message_At'] as DateTime
          : parseIsoDate(b['Last_Message_At'] as String?) ??
              DateTime.fromMillisecondsSinceEpoch(0);

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
          SearchChatField(
            // unreadCount: sortedChats.where((c) => c['unread'] > 0).length,
            unreadCount:
                sortedChats.where((c) => (c['unread'] ?? 0) > 0).length,
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
                      return const VendorBioShimmer();
                    },
                  )
                : ListView.builder(
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      return ChatListTile(
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
