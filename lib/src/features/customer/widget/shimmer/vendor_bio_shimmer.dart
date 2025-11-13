import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';

class VendorBioShimmer extends StatelessWidget {
  const VendorBioShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Shimmer Avatar
            ShimmerPlaceholder(width: 60, height: 60, radius: 30),
            const SizedBox(width: 12),

            // Shimmer Data Vendor
            Expanded(
              child:
                  Container(height: 60, child: ShimmerPlaceholder(radius: 5)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Shimmer Pilih Paket dan Pesan
        Row(
          children: [
            Expanded(
              child:
                  Container(height: 45, child: ShimmerPlaceholder(radius: 30)),
            ),
            const SizedBox(width: 12),
            ShimmerPlaceholder(
              width: 45,
              height: 45,
              radius: 30,
            )
          ],
        ),
        const SizedBox(height: 20),

        // Shimmer Text Portofolio
        ShimmerPlaceholder(
          width: 80,
          height: 15,
          radius: 3,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
