import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';

/// Message status indicator.
///
/// Status flow:
/// 1. messageId.startsWith('local-') → Clock icon (pending) — belum confirmed server
/// 2. sent    → Single check (gray)  — sudah di server
/// 3. received → Double check (gray) — sudah diterima recipient
/// 4. read    → Double check (blue)  — sudah dibaca recipient
/// 5. failed  → Error icon (red)     — gagal kirim
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
  Widget build(BuildContext context) => _buildStatusIcon();

  Widget _buildStatusIcon() {
    final status = message.sendStatusEnum;

    // ✅ FIX: Cek local ID — jika messageId masih 'local-xxx' berarti
    // pesan belum di-confirm server, tampilkan pending regardless of sendStatus.
    // Ini menangani kasus di mana local echo belum di-replace oleh FCM echo #1.
    final isLocalEcho = message.messageId.startsWith('local-');

    if (isLocalEcho || status.isPending) {
      return Icon(
        Icons.access_time_rounded,
        size: size,
        color: pendingColor ?? Colors.grey.shade300,
      );
    }

    if (status.isFailed) {
      return Icon(
        Icons.error_outline_rounded,
        size: size,
        color: failedColor ?? Colors.red.shade600,
      );
    }

    if (status.isSent) {
      return Icon(
        Icons.check_rounded,
        size: size,
        color: sentColor ?? Colors.grey.shade200,
      );
    }

    if (status.isReceived) {
      return Icon(
        Icons.done_all_rounded,
        size: size,
        color: receivedColor ?? Colors.grey.shade200,
      );
    }

    if (status.isRead) {
      return Icon(
        Icons.done_all_rounded,
        size: size,
        color: readColor ?? Colors.blue.shade300,
      );
    }

    return const SizedBox.shrink();
  }
}

/// Extension for SendStatus enum
extension SendStatusExtension on SendStatus {
  IconData get icon {
    switch (this) {
      case SendStatus.pending:
        return Icons.access_time_rounded;
      case SendStatus.sent:
        return Icons.check_rounded;
      case SendStatus.received:
        return Icons.done_all_rounded;
      case SendStatus.read:
        return Icons.done_all_rounded;
      case SendStatus.failed:
        return Icons.error_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color getColor(BuildContext context) {
    switch (this) {
      case SendStatus.pending:
        return Colors.grey.shade500;
      case SendStatus.sent:
        return Colors.grey.shade500;
      case SendStatus.received:
        return Colors.grey.shade500;
      case SendStatus.read:
        return Colors.blue.shade600;
      case SendStatus.failed:
        return Colors.red.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  String get label {
    switch (this) {
      case SendStatus.pending:
        return 'Mengirim...';
      case SendStatus.sent:
        return 'Terkirim';
      case SendStatus.received:
        return 'Diterima';
      case SendStatus.read:
        return 'Dibaca';
      case SendStatus.failed:
        return 'Gagal';
      default:
        return 'Unknown';
    }
  }

  bool get isPending => this == SendStatus.pending;
  bool get isSent => this == SendStatus.sent;
  bool get isReceived => this == SendStatus.received;
  bool get isRead => this == SendStatus.read;
  bool get isFailed => this == SendStatus.failed;
}