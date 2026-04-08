import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/text_style.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/widget/portofolio_card.dart';
import 'package:provider/provider.dart';

class PortofolioSection extends StatefulWidget {
  const PortofolioSection({super.key});

  @override
  State<PortofolioSection> createState() => _PortofolioSectionState();
}

class _PortofolioSectionState extends State<PortofolioSection> {
  @override
  void initState() {
    super.initState();
    // ambil data kategori dari provider saat pertama kali build
    Future.microtask(
        () => context.read<PortofolioProvider>().loadPortofolio(context));
  }

  /// ✅ Helper method untuk safely get media URL
  String? _getMediaUrl(dynamic portofolio) {
    try {
      // Check if mediaUrls exists and is not empty
      if (portofolio.mediaUrls != null &&
          portofolio.mediaUrls is List &&
          portofolio.mediaUrls.isNotEmpty) {
        final firstMedia = portofolio.mediaUrls[0];

        // Check if firstMedia has url property
        if (firstMedia != null && firstMedia.url != null) {
          return firstMedia.url;
        }
      }

      // Fallback: Try to get from idMedia if available
      if (portofolio.mediaUrls != null &&
          portofolio.mediaUrls is List &&
          portofolio.mediaUrls.isNotEmpty) {
        final firstMedia = portofolio.mediaUrls[0];
        if (firstMedia?.idMedia != null) {
          return firstMedia.idMedia;
        }
      }

      return null;
    } catch (e) {
      debugPrint('[PortofolioSection] ❌ Error getting media URL: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final portofolioProvider = context.watch<PortofolioProvider>();
    final portofolioList = portofolioProvider.portofolioList;
    final isLoadingPorto = portofolioProvider.isLoadingPorto;
    final error = portofolioProvider.errorPorto;

    debugPrint("═══════════════════════════════════════════════════");
    debugPrint(
        "[PortofolioSection] 📊 Total portofolio: ${portofolioList.length}");
    if (error != null) {
      debugPrint("[PortofolioSection] ❌ Error: $error");
    }
    debugPrint("═══════════════════════════════════════════════════");

    // ===== Kondisi Loading =====
    if (isLoadingPorto) {
      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            ...List.generate(5, (index) => _buildShimmerCard()),
          ],
        ),
      );
    }

    // ===== Kondisi Error =====
    if (error != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                const Text(
                  'Gagal memuat portofolio',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      context.read<PortofolioProvider>().loadPortofolio(context),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ===== Kondisi Kosong =====
    if (portofolioList.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.photo_library_outlined,
                    size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('Belum ada portofolio', style: AppTextStyle.body1),
              ],
            ),
          ),
        ),
      );
    }

    // ===== Daftar Portofolio — SliverList proper, tanpa shrinkWrap =====
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          try {
            final p = portofolioList[index];
            final String? mediaUrl = _getMediaUrl(p);
            return PortofolioCard(
              portofolio: p,
              photographerIcon: p.idMediaVendor ?? '',
              imageUrl: mediaUrl,
              name: p.usernameVendor ?? "",
              rating: p.ratingVendor,
              noId: p.noId,
              idVendor: p.idVendor,
            );
          } catch (e, stackTrace) {
            debugPrint(
                "[PortofolioSection] ❌ Error rendering item $index: $e");
            debugPrint("[PortofolioSection] Stack: $stackTrace");
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error memuat item portofolio',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            );
          }
        },
        childCount: portofolioList.length,
      ),
    );
  }

  // =============== Widget Helper ===============
  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.grey.withOpacity(0.1),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer untuk gambar utama
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: const ShimmerPlaceholder(
              height: 160,
              radius: 15,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: const [
                ClipOval(
                  child: ShimmerPlaceholder(width: 32, height: 32, radius: 16),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ShimmerPlaceholder(height: 14, radius: 4),
                ),
                SizedBox(width: 10),
                ShimmerPlaceholder(width: 40, height: 14, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
