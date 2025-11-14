import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatModel message;
  final bool isMe;
  const ChatBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? Constants.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.message,
                style: const TextStyle(fontSize: 14, color: Colors.black)),
            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(message.sentAt.toLocal()),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
