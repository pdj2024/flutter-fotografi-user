import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';

/// Shimmer loading state untuk VendorBioPage
/// Menampilkan skeleton loading untuk vendor info + portfolio grid
class VendorBioShimmer extends StatelessWidget {
  const VendorBioShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 1,
          // ✅ Use standard back button instead of shimmer
          leading: const BackButton(color: Colors.grey),
          // ✅ Use Container with fixed constraints for title shimmer
          title: Container(
            height: 20,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        backgroundColor: const Color(0xFFF9F9F9),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vendor Bio Shimmer
                _buildVendorBioShimmer(),

                const SizedBox(height: 24),

                // Portfolio Title Shimmer
                const ShimmerPlaceholder(
                  width: 100,
                  height: 18,
                  radius: 4,
                ),

                const SizedBox(height: 16),

                // Portfolio Grid Shimmer
                _buildPortfolioGridShimmer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shimmer untuk vendor bio section
  Widget _buildVendorBioShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Avatar shimmer
            const ShimmerPlaceholder(
              width: 60,
              height: 60,
              radius: 30,
            ),

            const SizedBox(width: 12),

            // Vendor info shimmer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama vendor
                  const ShimmerPlaceholder(
                    width: double.infinity,
                    height: 20,
                    radius: 4,
                  ),

                  const SizedBox(height: 8),

                  // Rating & kota
                  const ShimmerPlaceholder(
                    width: 150,
                    height: 16,
                    radius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Deskripsi shimmer
        const ShimmerPlaceholder(
          width: double.infinity,
          height: 60,
          radius: 8,
        ),

        const SizedBox(height: 16),

        // Buttons shimmer
        Row(
          children: [
            // Pilih Paket button
            Expanded(
              child: const ShimmerPlaceholder(
                height: 45,
                radius: 22.5,
              ),
            ),

            const SizedBox(width: 12),

            // Chat button
            const ShimmerPlaceholder(
              width: 45,
              height: 45,
              radius: 22.5,
            ),
          ],
        ),
      ],
    );
  }

  /// Shimmer untuk portfolio grid (2 columns)
  Widget _buildPortfolioGridShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6, // Show 6 placeholder items
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: 1, // Square items
      ),
      itemBuilder: (context, index) {
        return const ShimmerPlaceholder(
          radius: 5,
        );
      },
    );
  }
}
