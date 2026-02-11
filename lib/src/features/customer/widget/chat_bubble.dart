import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'message_status_indicator.dart';

/// ✅ IMPROVED: Chat bubble with better visual design
class ChatBubble extends StatefulWidget {
  final ChatModel message;
  final bool isMe;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onRetry,
    this.onDelete,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _isPressed = false;

  void _showContextMenu(BuildContext context) {
    final RenderBox? bubbleBox = context.findRenderObject() as RenderBox?;
    if (bubbleBox == null) return;

    final Offset bubblePosition = bubbleBox.localToGlobal(Offset.zero);
    final Size bubbleSize = bubbleBox.size;
    final Size screenSize = MediaQuery.of(context).size;

    final double spaceBelow =
        screenSize.height - (bubblePosition.dy + bubbleSize.height);
    final double spaceAbove = bubblePosition.dy;
    final bool showBelow = spaceBelow > 100 || spaceBelow > spaceAbove;

    final double leftPosition = widget.isMe
        ? bubblePosition.dx + bubbleSize.width - 160
        : bubblePosition.dx;

    final double topPosition = showBelow
        ? bubblePosition.dy + bubbleSize.height + 8
        : bubblePosition.dy - 8;

    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => overlayEntry?.remove(),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: leftPosition.clamp(16.0, screenSize.width - 176),
            top: showBelow ? topPosition : null,
            bottom: showBelow ? null : screenSize.height - topPosition,
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 200),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  final clampedValue = value.clamp(0.0, 1.0);

                  return Transform.scale(
                    scale: clampedValue,
                    alignment: showBelow
                        ? Alignment.topCenter
                        : Alignment.bottomCenter,
                    child: Opacity(
                      opacity: clampedValue,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuItem(
                        icon: Icons.copy_rounded,
                        iconColor: Constants.primaryColor,
                        label: 'Salin Pesan',
                        onTap: () {
                          overlayEntry?.remove();
                          _copyMessage();
                        },
                      ),
                      if (widget.isMe && widget.onDelete != null) ...[
                        Divider(height: 1, color: Colors.grey.shade200),
                        _buildMenuItem(
                          icon: Icons.delete_outline_rounded,
                          iconColor: Colors.red.shade400,
                          label: 'Hapus Pesan',
                          labelColor: Colors.red.shade700,
                          onTap: () {
                            overlayEntry?.remove();
                            widget.onDelete?.call();
                          },
                        ),
                      ],
                      if (widget.message.sendStatusEnum.isFailed &&
                          widget.isMe &&
                          widget.onRetry != null) ...[
                        Divider(height: 1, color: Colors.grey.shade200),
                        _buildMenuItem(
                          icon: Icons.refresh_rounded,
                          iconColor: Colors.orange.shade600,
                          label: 'Kirim Ulang',
                          labelColor: Colors.orange.shade700,
                          onTap: () {
                            overlayEntry?.remove();
                            widget.onRetry?.call();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(overlayEntry);
    HapticFeedback.mediumImpact();
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    Color? labelColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: labelColor ?? Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyMessage() {
    Clipboard.setData(ClipboardData(text: widget.message.message));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Text(
              'Pesan disalin',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isFailed = widget.message.sendStatusEnum.isFailed;

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showContextMenu(context),
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            margin: EdgeInsets.only(
              left: widget.isMe ? 60 : 0,
              right: widget.isMe ? 0 : 60,
              top: 4,
              bottom: 4,
            ),
            child: Column(
              crossAxisAlignment: widget.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // ✅ IMPROVED: Better bubble design
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    // ✅ Better colors
                    color: widget.isMe
                        ? (isFailed
                            ? Colors.red.shade50
                            : Constants.primaryColor) // Messenger blue
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18), // ✅ Rounder
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
                      bottomRight: Radius.circular(widget.isMe ? 4 : 18),
                    ),
                    // ✅ Softer shadow
                    boxShadow: [
                      BoxShadow(
                        color: widget.isMe
                            ? Constants.primaryColor.withOpacity(0.2)
                            : Colors.black.withOpacity(0.08),
                        blurRadius: _isPressed ? 4 : 8,
                        offset: Offset(0, _isPressed ? 2 : 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.message.message,
                        style: TextStyle(
                          fontSize: 15,
                          // ✅ White text for sent, black for received
                          color: widget.isMe
                              ? (isFailed ? Colors.red.shade900 : Colors.white)
                              : Colors.black87,
                          height: 1.4, // ✅ Better line spacing
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(widget.message.sentAt),
                            style: TextStyle(
                              fontSize: 11,
                              // ✅ Appropriate text color
                              color: widget.isMe
                                  ? (isFailed
                                      ? Colors.red.shade700
                                      : Colors.grey.shade200)
                                  : Colors.grey.shade600,
                            ),
                          ),
                          if (widget.isMe) ...[
                            const SizedBox(width: 4),
                            MessageStatusIndicator(
                              message: widget.message,
                              size: 14,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Failed message indicator
                if (isFailed && widget.isMe)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Gagal terkirim',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '• Tahan untuk opsi',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
