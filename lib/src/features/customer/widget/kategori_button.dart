import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';

class KategoriButton extends StatelessWidget {
  const KategoriButton(
      {super.key,
      required this.imageUrl,
      required this.label,
      required this.bgColor,
      required this.onTap});

  final String imageUrl;
  final String label;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 110,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: bgColor,
              radius: 28,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // border: Border.all(
                  //   color:
                  //       Constants.primaryColor, // Ganti warna sesuai kebutuhan
                  //   width: 1, // Atur ketebalan border
                  // ),
                ),
                child: ClipOval(
                  child: Stack(
                    children: [
                      ShimmerPlaceholder(width: 56, height: 56, radius: 28),
                      Image.network(
                        imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(); // Biarkan shimmer tetap tampil
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image_outlined, size: 28),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
