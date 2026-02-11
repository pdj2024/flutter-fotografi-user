import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';

/// ✅ UPDATED: Message status indicator with "received" instead of "delivered"
///
/// Status flow:
/// 1. pending → Clock icon (gray) - Message being sent
/// 2. sent → Single check (gray) - Sent to server
/// 3. received → Double check (gray) - Received by recipient device
/// 4. read → Double check (blue) - Read by recipient
/// 5. failed → Error icon (red) - Failed to send
class MessageStatusIndicator extends StatelessWidget {
  final ChatModel message;
  final double size;
  final Color? sentColor;
  final Color? receivedColor;
  final Color? readColor;
  final Color? pendingColor;
  final Color? failedColor;

  const MessageStatusIndicator({
    super.key,
    required this.message,
    this.size = 16,
    this.sentColor,
    this.receivedColor,
    this.readColor,
    this.pendingColor,
    this.failedColor,
  });

  @override
  Widget build(BuildContext context) {
    return _buildStatusIcon();
  }

  Widget _buildStatusIcon() {
    final status = message.sendStatusEnum;

    // ✅ Pending (Clock)
    if (status.isPending) {
      return Icon(
        Icons.access_time_rounded,
        size: size,
        color: pendingColor ?? Colors.grey.shade200,
      );
    }

    // ✅ Failed (Error)
    if (status.isFailed) {
      return Icon(
        Icons.error_outline_rounded,
        size: size,
        color: failedColor ?? Colors.red.shade600,
      );
    }

    // ✅ Sent (Single check - gray)
    if (status.isSent) {
      return Icon(
        Icons.check_rounded,
        size: size,
        color: sentColor ?? Colors.grey.shade200,
      );
    }

    // ✅ Received (Double check - gray) - Changed from "delivered"
    if (status.isReceived) {
      return Icon(
        Icons.done_all_rounded,
        size: size,
        color: receivedColor ?? Colors.grey.shade200,
      );
    }

    // ✅ Read (Double check - blue)
    if (status.isRead) {
      return Icon(
        Icons.done_all_rounded,
        size: size,
        color: readColor ?? Colors.blue.shade300,
      );
    }

    // ✅ Default (empty)
    return const SizedBox.shrink();
  }
}

/// ✅ Extension for SendStatus enum
extension SendStatusExtension on SendStatus {
  /// Get icon for status
  IconData get icon {
    switch (this) {
      case SendStatus.pending:
        return Icons.access_time_rounded;
      case SendStatus.sent:
        return Icons.check_rounded;
      case SendStatus.received: // ✅ Changed
        return Icons.done_all_rounded;
      case SendStatus.read:
        return Icons.done_all_rounded;
      case SendStatus.failed:
        return Icons.error_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  /// Get color for status
  Color getColor(BuildContext context) {
    switch (this) {
      case SendStatus.pending:
        return Colors.grey.shade500;
      case SendStatus.sent:
        return Colors.grey.shade500;
      case SendStatus.received: // ✅ Changed
        return Colors.grey.shade500;
      case SendStatus.read:
        return Colors.blue.shade600;
      case SendStatus.failed:
        return Colors.red.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  /// Get label for status
  String get label {
    switch (this) {
      case SendStatus.pending:
        return 'Mengirim...';
      case SendStatus.sent:
        return 'Terkirim';
      case SendStatus.received: // ✅ Changed from "Delivered"
        return 'Diterima';
      case SendStatus.read:
        return 'Dibaca';
      case SendStatus.failed:
        return 'Gagal';
      default:
        return 'Unknown';
    }
  }

  /// Check status type
  bool get isPending => this == SendStatus.pending;
  bool get isSent => this == SendStatus.sent;
  bool get isReceived => this == SendStatus.received; // ✅ Changed
  bool get isRead => this == SendStatus.read;
  bool get isFailed => this == SendStatus.failed;
}
