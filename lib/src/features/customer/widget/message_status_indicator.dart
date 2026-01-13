import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';

/// Widget untuk menampilkan status pengiriman pesan
class MessageStatusIndicator extends StatelessWidget {
  final ChatModel message;
  final double size;
  final Color? readColor;

  const MessageStatusIndicator({
    super.key,
    required this.message,
    this.size = 16,
    this.readColor,
  });

  @override
  Widget build(BuildContext context) {
    final status = message.sendStatusEnum;
    final grey = Colors.grey.shade500;
    final blue = readColor ?? Colors.blue;

    if (status.isPending || status.isSending) {
      return Icon(Icons.access_time, size: size, color: grey);
    }

    if (status.isFailed) {
      return Icon(Icons.error_outline, size: size, color: Colors.red);
    }

    if (status.isRead) {
      return Icon(Icons.done_all, size: size, color: blue);
    }

    if (status.isDelivered) {
      return Icon(Icons.done_all, size: size, color: grey);
    }

    if (status.isSent) {
      return Icon(Icons.done, size: size, color: grey);
    }

    return Icon(Icons.access_time, size: size, color: grey);
  }
}

/// Compact version dengan string status
class CompactStatusIcon extends StatelessWidget {
  final String sendStatus;
  final double size;

  const CompactStatusIcon({
    super.key,
    required this.sendStatus,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    final status = SendStatus.fromString(sendStatus);
    final grey = Colors.grey.shade500;

    IconData icon;
    Color color;

    switch (status) {
      case SendStatus.pending:
      case SendStatus.sending:
        icon = Icons.access_time;
        color = grey;
        break;
      case SendStatus.sent:
        icon = Icons.done;
        color = grey;
        break;
      case SendStatus.delivered:
        icon = Icons.done_all;
        color = grey;
        break;
      case SendStatus.read:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      case SendStatus.failed:
        icon = Icons.error_outline;
        color = Colors.red;
        break;
    }

    return Icon(icon, size: size, color: color);
  }
}
