import 'package:flutter/material.dart';
import 'package:mpjnew/src/pages/core/api_singleton.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/constants.dart';
import '../providers/custom_back_button.dart';
import '../providers/navigation_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'providers/user_provider.dart';
import 'services/chat_service.dart';
import 'single_chat.dart';

class AllChat extends StatefulWidget {
  const AllChat({super.key});

  @override
  State<AllChat> createState() => _AllChatState();
}

class _AllChatState extends State<AllChat> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> _chats = [];
  late String currentUserId; 
    
  @override
  void initState() {
    super.initState();
    currentUserId = context.read<UserProvider>().userId ?? '';
    _initChat();
  }

  Future<void> _initChat() async {
  // Step 1: Connect ke SignalR
  try {
    await _chatService.connect(currentUserId, apiClient);
  } catch (e, s) {
    debugPrint("Error connect SignalR: $e");
    debugPrintStack(stackTrace: s);
  }

  // Step 2: Listener pesan baru
  try {
    _chatService.onRoomMessageReceived = (roomId, sender, message, sentAt) {
      try {
        setState(() {
          final idx = _chats.indexWhere((c) => c['roomId'] == roomId);
          if (idx >= 0) {
            _chats[idx]['message'] = message;
            _chats[idx]['time'] = sentAt;
            if (sender != currentUserId) {
              _chats[idx]['unread'] = (_chats[idx]['unread'] ?? 0) + 1;
            }
          } else {
            // fallback jika room belum ada
            _chats.add({
             
              'username': sender,
              'avatar': '',
             
              'message': message,
              'time': sentAt,
              'unread': 1,
              'roomId': roomId,
            });
          }
        });
      } catch (e, s) {
        debugPrint("Error handle incoming message: $e");
        debugPrintStack(stackTrace: s);
      }
    };
  } catch (e, s) {
    debugPrint("Error set listener: $e");
    debugPrintStack(stackTrace: s);
  }

  List<Map<String, dynamic>> rooms = [];
  // Step 3: Fetch semua room (langsung ambil detailnya)
  try {
    rooms = await _chatService.fetchRoomsForUser(currentUserId); 
    // hasil sudah berupa List<Map> dengan key seperti Room_Id, Username_Lawan, Avatar, dll
  } catch (e, s) {
    debugPrint("Error fetch rooms: $e");
    debugPrintStack(stackTrace: s);
  }

  // Step 4: Join semua room
  try {
    final roomIds = rooms.map((r) => r['Room_Id'] as String).toList();
    if (roomIds.isNotEmpty) {
      await _chatService.joinMultipleRooms(roomIds);
    }
  } catch (e, s) {
    debugPrint("Error join rooms: $e");
    debugPrintStack(stackTrace: s);
  }

  // Step 5: Ambil pesan terakhir + gabungkan dengan data room
  try {
    List<Map<String, dynamic>> tempChats = [];
    for (final room in rooms) {
          try {
            final msgs = await _chatService.fetchMessagesForRoom(room['Room_Id']);

            // Ambil pesan terakhir (kalau ada)
            final last = msgs.isNotEmpty ? msgs.last : null;

            tempChats.add({
            
              'username': room['Username_Lawan'] ?? '',
              'avatar': room['Id_Media_Lawan'] ?? '',
            
              'message': last?['Text'] ?? '', // ✅ sesuai key di fetchMessagesForRoom
              'time': last?['SentAt'] ?? DateTime.tryParse(room['Last_Chat'] ?? ''),
              'unread': 0,
              'roomId': room['Room_Id'] ?? '',
            });
            } catch (e, s) {
              debugPrint("Error fetch messages for room ${room['Room_Id']}: $e");
              debugPrintStack(stackTrace: s);
            }
}

    setState(() {
      _chats = tempChats;
    });
  } catch (e, s) {
    debugPrint("Error proses pesan terakhir: $e");
    debugPrintStack(stackTrace: s);
  }
}

String _findReceiverId(Map<String, dynamic> room) {
  // ambil id lawan bicara
  final ids = List<String>.from(room['User_Ids']);
  return ids.firstWhere((id) => id != currentUserId, orElse: () => '');
}


  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> sortedChats = [..._chats];
    // sortedChats.sort((a, b) => b['time'].compareTo(a['time']));
    sortedChats.sort((a, b) {
  final timeB = b['time'] ?? DateTime.fromMillisecondsSinceEpoch(0);
  final timeA = a['time'] ?? DateTime.fromMillisecondsSinceEpoch(0);
  return timeB.compareTo(timeA);
});

    final List<Map<String, dynamic>> filteredChats = sortedChats.where((chat) {
      final name = chat['name'].toString().toLowerCase();
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
            unreadCount: sortedChats.where((c) => c['unread'] > 0).length,
            searchController: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredChats.length,
              itemBuilder: (context, index) {
                final chat = filteredChats[index];
                return ChatItem(
                  username: chat['username'], // display
                
                  avatar: chat['avatar'], // display
                  
                  message: chat['message'], // display
                  time: chat['time'], // display
                  unreadCount: chat['unread'], // display
                  roomId: chat['roomId'],
                );
              },
            ),
          ),
        ],
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
  final DateTime time;
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

  String formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

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
            formatTime(time),
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
            receiverUserName: username,
            receiverEmail: 'INI RECEIVER EMAIL',
            receiverID: 'INI RECEIVER ID',
            // roomId: roomId,
          ),
          targetTabIndex: 1,
        );
      },
    );
  }
}
