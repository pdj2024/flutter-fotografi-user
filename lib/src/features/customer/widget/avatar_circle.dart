import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AvatarCircle extends StatelessWidget {
  final String? imgUrl;
  final double size;
  const AvatarCircle({super.key, this.imgUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey.shade300,
        child: ClipOval(
          child: (imgUrl == null || imgUrl!.trim().isEmpty)
              ? Container(
                  width: size,
                  height: size,
                  color: Colors.grey,
                  child:
                      const Icon(Icons.person, color: Colors.white, size: 40),
                )
              : CachedNetworkImage(
                  imageUrl: imgUrl!, // dijamin non-null
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.white,
                    child: Container(
                      width: size,
                      height: size,
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: size,
                    height: size,
                    color: Colors.grey,
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                ),
        ),
      ),
    );
  }
}
