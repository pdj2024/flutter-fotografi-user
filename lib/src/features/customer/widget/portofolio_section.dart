import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/widget/portofolio_card.dart';
import 'package:provider/provider.dart';

/// Widget ini mengembalikan Sliver — harus digunakan di dalam CustomScrollView.
class PortofolioSection extends StatelessWidget {
  const PortofolioSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortofolioProvider>();
    final list = provider.portofolioList;
    final isLoading = provider.isLoadingPorto;
    final error = provider.errorPorto;

    // ── Loading ──────────────────────────────────────────────────────
    // Shimmer HANYA saat benar-benar belum ada data. Kalau list sudah terisi
    // (dari cache atau prefetch splash), refresh berjalan diam-diam di
    // belakang — jangan tarik balik UI ke skeleton.
    if (isLoading && list.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate(
          List.generate(5, (_) => _ShimmerCard()),
        ),
      );
    }

    // ── Error ────────────────────────────────────────────────────────
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

    // ── Empty ────────────────────────────────────────────────────────
    if (list.isEmpty) {
      return const SliverToBoxAdapter(child: _EmptyPortofolio());
    }

    // ── Data — lazy build via SliverList.builder ─────────────────────
    // Hanya card yang visible di viewport yang dibangun, bukan semua sekaligus.
    return SliverList.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        try {
          final p = list[index];
          return RepaintBoundary(
            child: PortofolioCard(
              portofolio: p,
              photographerIcon: p.idMediaVendor ?? '',
              imageUrl: null,
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
      },
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────

class _EmptyPortofolio extends StatelessWidget {
  const _EmptyPortofolio();

  @override
  Widget build(BuildContext context) {
    const primary = Constants.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          SizedBox(height: 50),
          // ── Ilustrasi ─────────────────────────────────────────────
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Lingkaran latar belakang
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withOpacity(0.06),
                  ),
                ),
                // Frame kiri belakang
                Positioned(
                  left: 8,
                  bottom: 20,
                  child: Transform.rotate(
                    angle: -0.22,
                    child: _PhotoFrame(
                      icon: Icons.landscape_outlined,
                      bgColor: primary.withOpacity(0.12),
                      iconColor: primary.withOpacity(0.5),
                      size: 84,
                    ),
                  ),
                ),
                // Frame kanan belakang
                Positioned(
                  right: 8,
                  bottom: 20,
                  child: Transform.rotate(
                    angle: 0.22,
                    child: _PhotoFrame(
                      icon: Icons.portrait_outlined,
                      bgColor: primary.withOpacity(0.08),
                      iconColor: primary.withOpacity(0.4),
                      size: 84,
                    ),
                  ),
                ),
                // Frame utama tengah
                _PhotoFrame(
                  icon: Icons.camera_alt_outlined,
                  bgColor: Colors.white,
                  iconColor: primary,
                  size: 110,
                  elevated: true,
                ),
                // Bintang / sparkle kiri atas
                Positioned(
                  top: 20,
                  left: 30,
                  child: Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: primary.withOpacity(0.35),
                  ),
                ),
                // Bintang / sparkle kanan atas
                Positioned(
                  top: 30,
                  right: 28,
                  child: Icon(
                    Icons.star_rounded,
                    size: 10,
                    color: primary.withOpacity(0.25),
                  ),
                ),
                // Titik dekorasi kiri bawah
                Positioned(
                  bottom: 30,
                  left: 18,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withOpacity(0.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Teks ──────────────────────────────────────────────────
          const Text(
            'Belum ada portofolio',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Karya fotografer terbaik\nakan segera hadir di sini',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _PhotoFrame extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final double size;
  final bool elevated;

  const _PhotoFrame({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.size,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Constants.primaryColor.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(icon, size: size * 0.42, color: iconColor),
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
