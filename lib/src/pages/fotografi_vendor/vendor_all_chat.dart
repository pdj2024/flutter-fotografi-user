import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/pages/fotografi_user/single_chat.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/constants.dart';
import '../providers/custom_back_button.dart';
import '../providers/navigation_provider.dart';
import 'vendor_single_chat.dart';

class VendorAllChat extends StatefulWidget {
  

  const VendorAllChat({super.key});

  @override
  State<VendorAllChat> createState() => _VendorAllChatState();
}

class _VendorAllChatState extends State<VendorAllChat> {
  final List<Map<String, dynamic>> _chats = [
    {
      'name': 'Michael Williams',
      'avatar': 'default_user.jpg',
      'message': 'Apakah kamu tersedia untuk sesi prewedding?',
      'time': DateTime.now().subtract(Duration(minutes: 5)),
      'unread': 2
    },
    {
      'name': 'Emily Photos',
       'avatar': 'default_user.jpg',
      'message': 'File hasil foto sudah dikirim via email ya!',
      'time': DateTime.now().subtract(Duration(minutes: 30)),
      'unread': 0
    },
    {
      'name': 'Davis Miller',
       'avatar': 'default_user.jpg',
      'message': 'Kapan jadwal sesi foto berikutnya?',
      'time': DateTime.now().subtract(Duration(hours: 1, minutes: 20)),
      'unread': 1
    },
    {
      'name': 'Amanda Reed Photo',
     'avatar': 'default_user.jpg',
      'message': 'Terima kasih untuk sesi kemarin!',
      'time': DateTime.now().subtract(Duration(hours: 3)),
      'unread': 3
    },
    {
      'name': 'Sarah Lee',
      'avatar': 'default_user.jpg',
      'message': 'Besok kita ketemu jam 10 ya',
      'time': DateTime.now().subtract(Duration(days: 1)),
      'unread': 0
    },
    {
      'name': 'Runita Diah',
      'avatar': 'default_user.jpg',
      'message': 'Ada slot untuk bulan depan?',
      'time': DateTime.now().subtract(Duration(days: 2)),
      'unread': 4
    },
    {
      'name': 'Bridals Photos',
       'avatar': 'default_user.jpg',
      'message': 'Saya butuh file high-res ya',
      'time': DateTime.now().subtract(Duration(days: 3, hours: 2)),
      'unread': 0
    },
    {
      'name': 'Nikita Lusi',
       'avatar': 'default_user.jpg',
      'message': 'Mantap hasil fotonya!',
      'time': DateTime.now().subtract(Duration(days: 5)),
      'unread': 1
    },
    {
      'name': 'Andi Utami',
      'avatar': 'default_user.jpg',
      'message': 'Foto wisuda saya bagus banget',
      'time': DateTime.now().subtract(Duration(days: 6)),
      'unread': 0
    },
    {
      'name': 'Budi Bali',
      'avatar': 'default_user.jpg',
      'message': 'Nanti ada diskon untuk repeat client?',
      'time': DateTime.now().subtract(Duration(days: 8)),
      'unread': 0
    },
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> sortedChats = [..._chats];
    sortedChats.sort((a, b) => b['time'].compareTo(a['time']));

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
                  name: chat['name'],
                  avatar: chat['avatar'],
                  message: chat['message'],
                  time: chat['time'],
                  unreadCount: chat['unread'],
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
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
  final String name;
  final String avatar;
  final String message;
  final DateTime time;
  final int unreadCount;

  const ChatItem({
    super.key,
    required this.name,
    required this.avatar,
    required this.message,
    required this.time,
    required this.unreadCount,
  });

  String formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
      final String imgUrl = context.read<NavigationProvider>().ambilGambar(avatar);
    return ListTile(
      leading: ClipOval(
  child: CachedNetworkImage(
    imageUrl: imgUrl,
    width: 48, // 2 * radius (24)
    height: 48,
    fit: BoxFit.cover,
    placeholder: (context, url) => Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 48,
        height: 48,
        color: Colors.white,
      ),
    ),
    errorWidget: (context, url, error) => Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.error, color: Colors.red),
    ),
  ),
),

      title: Text(name),
      subtitle: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatTime(time),
            style: const TextStyle(
              color: Constants.primaryColorVendor,
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
                color: Constants.primaryColorVendor,
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
        context.read<NavigationProvider>().vendorNavigateToPage(
                          context, VendorSingleChat(), targetTabIndex:1, );
      },
    );
  }
}
