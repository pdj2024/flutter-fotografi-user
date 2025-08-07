import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mpjnew/src/pages/fotografi_user/single_chat.dart';
import 'package:provider/provider.dart';

import '../providers/constants.dart';
import '../providers/custom_back_button.dart';
import '../providers/navigation_provider.dart';

class AllChat extends StatefulWidget {
  const AllChat({super.key});

  @override
  State<AllChat> createState() => _AllChatState();
}

class _AllChatState extends State<AllChat> {
  final List<Map<String, dynamic>> _chats = [
    {
      'name': 'Michael Williams',
      'username': 'michaelwilliams',
      'avatar': '14eac222-0e59-446b-be37-60b222800f5d-image_cropper_1748677848826.jpg',
      'receiverEmail': 'michaelwilliams@gmail.com',
      'receiverId': 'michael-williams',
      'message': 'Apakah kamu tersedia untuk sesi prewedding?',
      'time': DateTime.now().subtract(const Duration(minutes: 5)),
      'unread': 2
    },
    {
      'name': 'Emily Photos',
       'username': 'emilyphotos',
      'avatar': '1d98c486-b810-42d8-8779-3b0ca34154ef-image_cropper_1748677884447.jpg',
      'receiverEmail': 'emilyphotos@gmail.com',
      'receiverId': 'emily-photos',
      'message': 'File hasil foto sudah dikirim via email ya!',
      'time': DateTime.now().subtract(const Duration(minutes: 30)),
      'unread': 0
    },
    {
      'name': 'Davis Miller',
       'username': 'davismiller',
      'avatar': '65868b74-ef32-4388-a6e9-c87b86f6541f-image_cropper_1748677941144.jpg',
      'receiverEmail': 'davismiller@gmail.com',
      'receiverId': 'davis-miller',
      'message': 'Kapan jadwal sesi foto berikutnya?',
      'time': DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
      'unread': 1
    },
    {
      'name': 'Amanda Reed Photo',
       'username': 'amandareed',
      'avatar': '355c5d9f-0e1b-4c8f-a715-c388b9d2e21d-image_cropper_1748677911014.jpg',
       'receiverEmail': 'amandareed@gmail.com',
      'receiverId': 'amanda-reed',
      'message': 'Terima kasih untuk sesi kemarin!',
      'time': DateTime.now().subtract(const Duration(hours: 3)),
      'unread': 3
    },
    {
      'name': 'Sarah Lee',
       'username': 'sarahlee',
      'avatar': '175a09b7-bd6e-4b0b-b74c-d06d94d8683e-image_cropper_1748677929955.jpg',
       'receiverEmail': 'sarahlee@gmail.com',
      'receiverId': 'sarah-lee',
      'message': 'Besok kita ketemu jam 10 ya',
      'time': DateTime.now().subtract(const Duration(days: 1)),
      'unread': 0
    },
    {
      'name': 'Runita Diah',
       'username': 'runitadiah',
      'avatar': 'db66c60d-57d6-4eec-ac0a-2a325a088825-image_cropper_1748677859114.jpg',
       'receiverEmail': 'runitadiah@gmail.com',
      'receiverId': 'runita-diah',
      'message': 'Ada slot untuk bulan depan?',
      'time': DateTime.now().subtract(const Duration(days: 2)),
      'unread': 4
    },
    {
      'name': 'Bridals Photos',
       'username': 'bridalsphotos',
      'avatar': '7aa46c78-118e-41c6-9e21-e8ac39ccfe93-image_cropper_1748677935167.jpg',
       'receiverEmail': 'bridalsphoto@gmail.com',
      'receiverId': 'bridals-photo',
      'message': 'Saya butuh file high-res ya',
      'time': DateTime.now().subtract(const Duration(days: 3, hours: 2)),
      'unread': 0
    },
    {
      'name': 'Nikita Lusi',
       'username': 'nikitalusi',
      'avatar': '34442862-aa5d-4e74-8129-43104eb79aa7-image_cropper_1748677842439.jpg',
       'receiverEmail': 'nikitalusi@gmail.com',
      'receiverId': 'nikita-lusi',
      'message': 'Mantap hasil fotonya!',
      'time': DateTime.now().subtract(const Duration(days: 5)),
      'unread': 1
    },
    {
      'name': 'Andi Utami',
       'username': 'andiutami',
      'avatar': '16a113e9-a9b3-4590-92a0-979ec358f4a1-image_cropper_1748677918469.jpg',
       'receiverEmail': 'andiutami@gmail.com',
      'receiverId': 'andi-utami',
      'message': 'Foto wisuda saya bagus banget',
      'time': DateTime.now().subtract(const Duration(days: 6)),
      'unread': 0
    },
    {
      'name': 'Budi Bali',
       'username': 'budibali',
      'avatar': 'd00c8632-393e-49e8-847f-3c01a4dbf701-image_cropper_1748677823909.jpg',
       'receiverEmail': 'budibali@gmail.com',
      'receiverId': 'budi-bali',
      'message': 'Nanti ada diskon untuk repeat client?',
      'time': DateTime.now().subtract(const Duration(days: 8)),
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
                  receiverUserName: chat['username'],
                  avatar: chat['avatar'],
                  receiverEmail: chat['receiverEmail'],
                  receiverId: chat['receiverId'],
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
  final String name;
  final String receiverUserName;
  final String receiverEmail;
  final String receiverId;
  final String avatar;
  final String message;
  final DateTime time;
  final int unreadCount;

  const ChatItem({
    super.key,
    required this.name,
    required this.receiverUserName,
    required this.receiverEmail,
    required this.receiverId,
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
        context.read<NavigationProvider>().ambilGambar(avatar);

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[200],
        child: ClipOval(
          // child: CachedNetworkImage(
          //   imageUrl: imgUrl,
          //   width: 48,
          //   height: 48,
          //   fit: BoxFit.cover,
          //   placeholder: (context, url) => _shimmerAvatar(48),
          //   errorWidget: (context, url, error) =>
          //       const Icon(Icons.person, size: 24),
          // ),
          child: SizedBox(
  width: 48,
  height: 48,
  child: ClipOval(
    child: Image.network(
      imgUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _shimmerAvatar(48);  // panggil fungsi shimmer placeholder kamu
      },
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.person, size: 24);
      },
    ),
  ),
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
        context
            .read<NavigationProvider>()
            .navigateToPage(context, SingleChat(receiverUserName: receiverUserName, receiverEmail: receiverEmail, receiverID: receiverId), targetTabIndex: 1);
      },
    );
  }
}
