import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/pages/fotografi_user/single_chat.dart';
import 'package:provider/provider.dart';

class ChatListTile extends StatelessWidget {
  final String username;

  final String? avatar;
  final String? message;
  final DateTime? time;
  final int unreadCount;
  final String roomId;

  const ChatListTile(
      {super.key,
      required this.username,
      this.avatar,
      this.message,
      this.time,
      required this.unreadCount,
      required this.roomId});

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
                return ShimmerPlaceholder(height: 48, width: 48, radius: 30,);
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
