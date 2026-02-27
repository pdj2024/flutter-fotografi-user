import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/hive_entity/media_url_model.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';
import 'package:mpjnew/src/features/customer/view/single_post_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:provider/provider.dart';

class PortofolioAccountSection extends StatefulWidget {
  /// 'like' atau 'save'
  final String data;

  const PortofolioAccountSection({super.key, required this.data});

  @override
  State<PortofolioAccountSection> createState() =>
      _PortofolioAccountSectionState();
}

class _PortofolioAccountSectionState extends State<PortofolioAccountSection>
    with AutomaticKeepAliveClientMixin {
  bool get _isLike => widget.data == 'like';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final provider = context.read<PortofolioProvider>();
    if (_isLike) {
      // loadLikedPortofolio: load dari Hive dulu, lalu sync API background
      await provider.loadLikedPortofolio(
        context: context,
        syncFromApi: true,
      );
    } else {
      await provider.loadSavedPortofolio(
        context: context,
        syncFromApi: true,
      );
    }
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    final provider = context.read<PortofolioProvider>();
    if (_isLike) {
      // Refresh = paksa sync dari API lagi
      await provider.loadLikedPortofolio(
        context: context,
        syncFromApi: true,
      );
    } else {
      await provider.loadSavedPortofolio(
        context: context,
        syncFromApi: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Consumer<PortofolioProvider>(
        builder: (context, provider, _) {
          final isLoading =
              _isLike ? provider.isLoadingLike : provider.isLoadingSave;
          final dataList = _isLike
              ? provider.portofolioLikelist
              : provider.portofolioSaveList;

          // ── Loading skeleton ──────────────────────────────
          if (isLoading && dataList.isEmpty) {
            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8),
              itemCount: 6,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (_, __) => const ShimmerPlaceholder(radius: 10),
            );
          }

          // ── Kosong ────────────────────────────────────────
          if (dataList.isEmpty) {
            return ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Icon(
                    _isLike
                        ? Icons.favorite_border_rounded
                        : Icons.bookmark_border_rounded,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _isLike
                        ? 'Belum ada portofolio yang disukai'
                        : 'Belum ada portofolio yang disimpan',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Tarik ke bawah untuk memperbarui',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ),
              ],
            );
          }

          // ── Grid ─────────────────────────────────────────
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8),
            itemCount: dataList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final porto = dataList[index];
              return _PortoGridItem(porto: porto, isLikeSection: _isLike);
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// GRID ITEM
// ═══════════════════════════════════════════════════════════

class _PortoGridItem extends StatelessWidget {
  final PortofolioModel porto;
  final bool isLikeSection;

  const _PortoGridItem({
    required this.porto,
    required this.isLikeSection,
  });

  @override
  Widget build(BuildContext context) {
    final firstMedia =
        porto.mediaUrls.isNotEmpty ? porto.mediaUrls.first : null;
    final isVideo = (firstMedia?.contentType ?? '').startsWith('video');
    final hasMultiple = porto.mediaUrls.length > 1;

    return GestureDetector(
      onTap: () {
        context.read<PortofolioProvider>().setSelectedPortofolio(porto);
        context.read<NavigationProvider>().navigateToPage(
              context,
              const SinglePostPage(),
              hrsLogin: true,
              targetTabIndex: 3,
            );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Gambar utama ────────────────────────────
            firstMedia != null
                ? _MediaImage(media: firstMedia)
                : _placeholder(),

            // ── Gradient bawah untuk readability ────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.35),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),

            // ── Badge video ─────────────────────────────
            if (isVideo)
              const Positioned(
                bottom: 6,
                left: 6,
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),

            // ── Badge jumlah media ───────────────────────
            if (hasMultiple)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.collections_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${porto.mediaUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Tombol unlike / unsave di pojok bawah kanan ──
            Positioned(
              bottom: 6,
              right: 6,
              child: _QuickActionButton(
                porto: porto,
                isLikeSection: isLikeSection,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade200,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey.shade400,
        ),
      );
}

// ═══════════════════════════════════════════════════════════
// QUICK ACTION BUTTON (unlike / unsave langsung dari grid)
// ═══════════════════════════════════════════════════════════

class _QuickActionButton extends StatelessWidget {
  final PortofolioModel porto;
  final bool isLikeSection;

  const _QuickActionButton({
    required this.porto,
    required this.isLikeSection,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<PortofolioProvider, _ActionState>(
      selector: (_, provider) => _ActionState(
        isActive: isLikeSection
            ? provider.isLiked(porto.noId)
            : provider.isSaved(porto.noId),
        isInProgress: isLikeSection
            ? provider.isLikeInProgress(porto.noId)
            : provider.isSaveInProgress(porto.noId),
      ),
      builder: (context, state, _) {
        final provider = context.read<PortofolioProvider>();

        return GestureDetector(
          onTap: state.isInProgress
              ? null
              : () {
                  if (isLikeSection) {
                    provider.toggleLike(context: context, porto: porto);
                  } else {
                    provider.toggleSave(context: context, porto: porto);
                  }
                },
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              shape: BoxShape.circle,
            ),
            child: state.isInProgress
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isLikeSection
                        ? (state.isActive
                            ? Icons.favorite
                            : Icons.favorite_border)
                        : (state.isActive
                            ? Icons.bookmark
                            : Icons.bookmark_border),
                    color: state.isActive
                        ? (isLikeSection
                            ? Colors.red.shade300
                            : Colors.amber.shade300)
                        : Colors.white,
                    size: 16,
                  ),
          ),
        );
      },
    );
  }
}

class _ActionState {
  final bool isActive;
  final bool isInProgress;

  const _ActionState({required this.isActive, required this.isInProgress});

  @override
  bool operator ==(Object other) =>
      other is _ActionState &&
      other.isActive == isActive &&
      other.isInProgress == isInProgress;

  @override
  int get hashCode => Object.hash(isActive, isInProgress);
}

// ═══════════════════════════════════════════════════════════
// _MediaImage — local-first image loader
// ═══════════════════════════════════════════════════════════

class _MediaImage extends StatelessWidget {
  final MediaUrlModel media;

  const _MediaImage({required this.media});

  @override
  Widget build(BuildContext context) {
    // ── Prioritas 1: file lokal (sudah di-cache ke disk) ──────
    if (media.isCached && media.localPath != null) {
      final file = File(media.localPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          // Jika file korup / tidak terbaca, fallback ke network
          errorBuilder: (_, __, ___) => _networkImage(),
        );
      }
      // File sudah hilang dari disk → fallback ke network
      debugPrint('[PortoSection] ⚠️ Local file missing: \${media.localPath}');
    }

    // ── Prioritas 2: network URL ──────────────────────────────
    // Menangani kasus baru like/save di mana media belum sempat
    // di-download ke lokal (isCached = false) tapi URL tersedia.
    return _networkImage();
  }

  Widget _networkImage() {
    final isVideo = media.contentType?.startsWith('video') ?? false;

    // Untuk video: pakai thumbnail dulu, fallback ke url utama
    // Untuk gambar: langsung url
    final url = isVideo ? (media.thumbUrl ?? media.url) : media.url;

    // Jika url kosong, coba ambil dari field lain sebagai last resort
    final effectiveUrl = (url != null && url.trim().isNotEmpty)
        ? url
        : media.thumbUrl ?? media.idMedia;

    if (effectiveUrl == null || effectiveUrl.trim().isEmpty) {
      return _errorWidget();
    }

    return CachedNetworkImage(
      imageUrl: effectiveUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => const ShimmerPlaceholder(radius: 10),
      errorWidget: (_, __, ___) => _errorWidget(),
      fadeInDuration: const Duration(milliseconds: 250),
    );
  }

  Widget _errorWidget() => Container(
        color: Colors.grey.shade200,
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.grey.shade400,
        ),
      );
}
