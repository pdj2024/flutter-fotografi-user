import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/utils/attachment_compressor.dart';

/// Strip pratinjau lampiran yang belum terkirim.
class AttachmentPreviewStrip extends StatelessWidget {
  final List<PreparedAttachment> items;
  final ValueChanged<int> onRemove;
  final EdgeInsetsGeometry padding;

  const AttachmentPreviewStrip({
    super.key,
    required this.items,
    required this.onRemove,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  items[i].bytes,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  // Tanpa cacheWidth tiap gambar didekode resolusi penuh ke
                  // raster cache hanya untuk thumbnail 64px.
                  cacheWidth: 128,
                  gaplessPlayback: true,
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: () => onRemove(i),
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Colors.black54, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(3),
                    child:
                        const Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
