import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/text_style.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/widget/portofolio_card.dart';
import 'package:provider/provider.dart';

class PortofolioSection extends StatelessWidget {
  const PortofolioSection({super.key});

  String? _getMediaUrl(dynamic portofolio) {
    try {
      if (portofolio.mediaUrls != null &&
          portofolio.mediaUrls is List &&
          portofolio.mediaUrls.isNotEmpty) {
        final firstMedia = portofolio.mediaUrls[0];
        if (firstMedia != null && firstMedia.url != null) {
          return firstMedia.url;
        }
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
    final provider = context.watch<PortofolioProvider>();
    final list = provider.portofolioList;
    final isLoading = provider.isLoadingPorto;
    final error = provider.errorPorto;

    // ── Loading ──────────────────────────────────────────────────────
    if (isLoading) {
      return Column(
        children: List.generate(5, (_) => _ShimmerCard()),
      );
    }

    // ── Error ────────────────────────────────────────────────────────
    if (error != null) {
      return Padding(
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
      );
    }

    // ── Empty ────────────────────────────────────────────────────────
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(10),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('Belum ada portofolio', style: AppTextStyle.body1),
            ],
          ),
        ),
      );
    }

    // ── Data ─────────────────────────────────────────────────────────
    return Column(
      children: List.generate(list.length, (index) {
        try {
          final p = list[index];
          return RepaintBoundary(
            child: PortofolioCard(
              portofolio: p,
              photographerIcon: p.idMediaVendor ?? '',
              imageUrl: _getMediaUrl(p),
              name: p.usernameVendor ?? '',
              rating: p.ratingVendor,
              noId: p.noId,
              idVendor: p.idVendor,
            ),
          );
        } catch (e, st) {
          debugPrint('[PortofolioSection] ❌ Error item $index: $e');
          debugPrint('[PortofolioSection] Stack: $st');
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
      }),
    );
  }
}

// ── Shimmer card ──────────────────────────────────────────────────────

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: const ShimmerPlaceholder(height: 160, radius: 15),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: const [
                ClipOval(
                  child: ShimmerPlaceholder(width: 32, height: 32, radius: 16),
                ),
                SizedBox(width: 10),
                Expanded(child: ShimmerPlaceholder(height: 14, radius: 4)),
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
