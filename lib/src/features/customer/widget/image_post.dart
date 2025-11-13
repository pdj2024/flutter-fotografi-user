import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/models/portofolio_model.dart';
import 'package:shimmer/shimmer.dart';

class ImagePost extends StatelessWidget {
  final List<MediaItem> mediaUrl;
  const ImagePost({super.key, required this.mediaUrl});

  @override
  Widget build(BuildContext context) {
    
    return AspectRatio(
      aspectRatio: 5 / 4,
      child: mediaUrl != null
          ? Image.network(
              mediaUrl.first.url!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.grey[300]),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined, size: 40),
              ),
            )
          : Container(
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(Icons.image, size: 40),
            ),
    );
    ;
  }
}
