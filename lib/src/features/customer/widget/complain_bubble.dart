import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/models/complain_model.dart';
import 'package:mpjnew/src/features/customer/widget/complain_avatar.dart';
import 'package:mpjnew/src/features/customer/widget/linkified_text.dart';

/// Kartu pesan untuk fitur Complain — gaya "post" full-width (bukan chat
/// bubble kiri/kanan), karena Complain punya 3 kemungkinan pengirim
/// (customer/vendor/admin) dan bukan percakapan 2-pihak. Semua kartu
/// selebar parent, tidak ada perbedaan alignment berdasarkan pengirim.
class ComplainBubble extends StatelessWidget {
  final ComplainMessageModel message;

  /// Foto vendor pada order terkait — di-resolve halaman thread, karena
  /// payload complain tidak membawa foto profil.
  final String? vendorPhotoUrl;

  /// No_Id user yang sedang login — dipakai untuk menandai pesan sendiri.
  final String? currentUserId;

  const ComplainBubble({
    super.key,
    required this.message,
    this.vendorPhotoUrl,
    this.currentUserId,
  });

  bool get isMine =>
      currentUserId != null &&
      currentUserId!.isNotEmpty &&
      message.senderId == currentUserId;

  Widget _roleChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: (label == 'Admin')
              ? Colors.blue.shade50
              : Constants.primaryColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: (label == 'Admin')
                ? Colors.blue.shade700
                : Constants.primaryColor,
          ),
        ),
      ),
    );
  }

  void _copyMessage(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Pesan disalin',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
    HapticFeedback.mediumImpact();
  }

  void _openImage(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FullscreenImageViewer(url: url),
    ));
  }

  Widget _buildMediaRow(BuildContext context) {
    if (message.attachments.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: message.attachments.map((attachment) {
          return GestureDetector(
            onTap: () => _openImage(context, attachment.url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: attachment.url,
                width: 84,
                height: 84,
                fit: BoxFit.cover,
                placeholder: (_, __) => _mediaBox(loading: true),
                errorWidget: (_, __, ___) => _mediaBox(broken: true),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _mediaBox({bool loading = false, bool broken = false}) {
    return Container(
      width: 84,
      height: 84,
      color: Colors.grey.shade200,
      child: Center(
        child: broken
            ? Icon(Icons.broken_image_outlined, color: Colors.grey.shade400)
            : const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = message.isAdmin;

    return GestureDetector(
      onLongPress:
          message.message.isNotEmpty ? () => _copyMessage(context) : null,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isAdmin
                ? Constants.primaryColor.withOpacity(0.5)
                : Colors.grey.shade200,
            width: isAdmin ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMediaRow(context),
            if (message.message.isNotEmpty)
              LinkifiedText(
                text: message.message,
                style: const TextStyle(
                    fontSize: 14.5, color: Colors.black87, height: 1.4),
              ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFEFEFEF)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ComplainAvatar(
                        message: message,
                        vendorPhotoUrl: vendorPhotoUrl,
                        radius: 11,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          message.senderNama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isAdmin)
                        _roleChip('Admin')
                      else if (isMine)
                        _roleChip('Anda'),
                    ],
                  ),
                ),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    Helper.formatTanggal(message.tglCreated),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  if (message.isPending) ...[
                    const SizedBox(width: 4),
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: Colors.grey),
                    ),
                  ] else if (message.isFailed) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.error_outline_rounded,
                        size: 12, color: Colors.red.shade400),
                  ],
                ])
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenImageViewer extends StatelessWidget {
  final String url;
  const _FullscreenImageViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: InteractiveViewer(
            child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
