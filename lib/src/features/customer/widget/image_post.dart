import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/media_preload_service.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/hive_entity/media_url_model.dart';

/// Widget untuk menampilkan gambar post dengan swipe horizontal.
///
/// State like/save TIDAK disimpan di sini.
/// Semua logic ada di PortofolioProvider — widget ini hanya menerima
/// nilai dan callback dari luar (stateless dari sisi business logic).
class ImagePost extends StatefulWidget {
  final List<MediaUrlModel> mediaUrl;
  final bool isLiked;
  final bool isSaved;
  final int likeCount;
  final BoxFit fit;
  final bool enablePreload;

  // Callback — null = disable tap (saat API sedang berjalan)
  final VoidCallback? onLike;
  final VoidCallback? onSave;

  // Tampilkan spinner kecil saat API sedang berjalan
  final bool isLikeInProgress;
  final bool isSaveInProgress;

  const ImagePost({
    super.key,
    required this.mediaUrl,
    this.fit = BoxFit.cover,
    this.enablePreload = true,
    this.isLiked = false,
    this.isSaved = false,
    this.likeCount = 0,
    this.onLike,
    this.onSave,
    this.isLikeInProgress = false,
    this.isSaveInProgress = false,
  });

  @override
  State<ImagePost> createState() => _ImagePostState();
}

class _ImagePostState extends State<ImagePost> {
  int _currentIndex = 0;
  bool _isImageLoaded = false;
  double? _imageHeight;

  final MediaPreloadService _preloadService = MediaPreloadService();
  bool _isPreloading = false;
  final Set<int> _preloadedIndices = {};

  @override
  void initState() {
    super.initState();
    if (widget.enablePreload) {
      _preloadAllImages();
    }
  }

  @override
  void didUpdateWidget(ImagePost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mediaUrl != oldWidget.mediaUrl && widget.enablePreload) {
      _preloadAllImages();
    }
  }

  Future<void> _preloadAllImages() async {
    if (_isPreloading) return;

    final validMedia = widget.mediaUrl
        .where((m) => m.idMedia != null && m.idMedia!.isNotEmpty)
        .toList();

    if (validMedia.isEmpty) return;

    setState(() => _isPreloading = true);

    try {
      final urls = validMedia
          .map((m) => m.displayUrl)
          .where((url) => url != null && url.isNotEmpty)
          .cast<String>()
          .toList();

      await _preloadService.preloadUrls(urls, priority: 10);

      if (mounted) {
        setState(() {
          for (int i = 0; i < validMedia.length; i++) {
            _preloadedIndices.add(i);
          }
        });
      }
    } catch (e) {
      debugPrint('[ImagePost] ⚠️ Preload error: $e');
    } finally {
      if (mounted) setState(() => _isPreloading = false);
    }
  }

  void _preloadAdjacentImages(int currentIndex) {
    final validMedia = widget.mediaUrl
        .where((m) => m.idMedia != null && m.idMedia!.isNotEmpty)
        .toList();

    for (final offset in [1, -1]) {
      final idx = currentIndex + offset;
      if (idx >= 0 &&
          idx < validMedia.length &&
          !_preloadedIndices.contains(idx)) {
        final url = validMedia[idx].displayUrl;
        if (url != null) {
          _preloadService.preloadUrls([url], priority: 9);
          _preloadedIndices.add(idx);
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final validMedia = widget.mediaUrl
        .where((m) => m.idMedia != null && m.idMedia!.isNotEmpty)
        .toList();

    if (validMedia.isEmpty) return _buildEmptyPlaceholder();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Gambar ────────────────────────────────────────
        GestureDetector(
          onHorizontalDragEnd: (details) {
            if (validMedia.length <= 1) return;

            if (details.primaryVelocity! < -300 &&
                _currentIndex < validMedia.length - 1) {
              setState(() {
                _currentIndex++;
                _isImageLoaded = false;
              });
              _preloadAdjacentImages(_currentIndex);
            } else if (details.primaryVelocity! > 300 && _currentIndex > 0) {
              setState(() {
                _currentIndex--;
                _isImageLoaded = false;
              });
              _preloadAdjacentImages(_currentIndex);
            }
          },
          child: Container(
            width: double.infinity,
            color: Colors.grey.shade50,
            constraints: BoxConstraints(
              minHeight: _imageHeight ?? 200,
              maxHeight: _imageHeight ?? double.infinity,
            ),
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: _buildImageItem(
                    validMedia[_currentIndex],
                    key: ValueKey(_currentIndex),
                    isPreloaded: _preloadedIndices.contains(_currentIndex),
                  ),
                ),
                if (validMedia.length > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildCounter(validMedia.length),
                  ),
                if (widget.enablePreload && _isPreloading)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: _buildPreloadIndicator(),
                  ),
              ],
            ),
          ),
        ),

        // ── Action row (like / dots / save) ───────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Like button ──────────────────────────────
              _LikeButton(
                isLiked: widget.isLiked,
                isInProgress: widget.isLikeInProgress,
                onTap: widget.onLike,
              ),

              // ── Dot indicators ───────────────────────────
              if (validMedia.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _buildIndicator(validMedia.length),
                ),

              // ── Save button ──────────────────────────────
              _SaveButton(
                isSaved: widget.isSaved,
                isInProgress: widget.isSaveInProgress,
                onTap: widget.onSave,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // IMAGE ITEM
  // ═══════════════════════════════════════════════════════════

  Widget _buildImageItem(
    MediaUrlModel media, {
    Key? key,
    bool isPreloaded = false,
  }) {
    return CachedNetworkImage(
      key: key,
      imageUrl: media.idMedia!,
      fit: widget.fit,
      width: double.infinity,
      placeholder: (context, url) {
        if (isPreloaded) return _buildSubtleLoadingPlaceholder();

        if (media.thumbUrl != null && media.thumbUrl!.isNotEmpty) {
          return Stack(
            children: [
              CachedNetworkImage(
                imageUrl: media.thumbUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: _imageHeight,
                placeholder: (_, __) => _buildLoadingPlaceholder(),
                errorWidget: (_, __, ___) => _buildLoadingPlaceholder(),
              ),
              _buildLoadingOverlay(),
            ],
          );
        }
        return _buildLoadingPlaceholder();
      },
      errorWidget: (_, __, ___) => _buildErrorWidget(),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 150),
      memCacheWidth: 1080,
      maxWidthDiskCache: 1080,
      imageBuilder: (context, imageProvider) {
        if (!_isImageLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadImageDimensions(imageProvider);
          });
        }
        return Image(
          image: imageProvider,
          fit: widget.fit,
          width: double.infinity,
          errorBuilder: (_, __, ___) => _buildErrorWidget(),
        );
      },
    );
  }

  Future<void> _loadImageDimensions(ImageProvider imageProvider) async {
    if (!mounted) return;

    final stream = imageProvider.resolve(const ImageConfiguration());
    final completer = Completer<void>();
    late ImageStreamListener listener;

    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!mounted) return;

        final screenWidth = MediaQuery.of(context).size.width;
        final ar = info.image.width / info.image.height;
        setState(() {
          _imageHeight = screenWidth / ar;
          _isImageLoaded = true;
        });

        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
      onError: (_, __) {
        if (!mounted) return;
        setState(() {
          _imageHeight = 300;
          _isImageLoaded = true;
        });
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
    );

    stream.addListener(listener);

    Future.delayed(const Duration(seconds: 5), () {
      if (!completer.isCompleted && mounted) {
        setState(() {
          _imageHeight = 300;
          _isImageLoaded = true;
        });
        stream.removeListener(listener);
        completer.complete();
      }
    });
  }

  // ═══════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════

  Widget _buildLoadingPlaceholder() => Container(
        width: double.infinity,
        height: _imageHeight ?? 300,
        color: Colors.grey.shade50,
        child: Stack(
          children: [
            const ShimmerPlaceholder(
                width: double.infinity, height: double.infinity),
            _buildLoadingOverlay(),
          ],
        ),
      );

  Widget _buildSubtleLoadingPlaceholder() => Container(
        width: double.infinity,
        height: _imageHeight ?? 300,
        color: Colors.grey.shade50,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
            ),
          ),
        ),
      );

  Widget _buildLoadingOverlay() => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Memuat gambar...',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildPreloadIndicator() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Memuat...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _buildIndicator(int count) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final isActive = _currentIndex == index;
          final isPreloaded = _preloadedIndices.contains(index);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 6,
            width: isActive ? 20 : 6,
            decoration: BoxDecoration(
              color: isActive
                  ? Constants.primaryColor
                  : (isPreloaded ? Colors.grey.shade300 : Colors.grey.shade400),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      );

  Widget _buildCounter(int count) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${_currentIndex + 1}/$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      );

  Widget _buildErrorWidget() => Container(
        width: double.infinity,
        height: _imageHeight ?? 300,
        color: Colors.grey.shade100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'Gagal memuat gambar',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _isImageLoaded = false),
                child: Text(
                  'Coba lagi',
                  style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyPlaceholder() => Container(
        width: double.infinity,
        height: 300,
        color: Colors.grey.shade100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported_outlined,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'Tidak ada gambar',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// LIKE BUTTON
// Menampilkan ikon + jumlah like.
// Saat isInProgress: tampilkan spinner, tap dinonaktifkan.
// ═══════════════════════════════════════════════════════════════

class _LikeButton extends StatelessWidget {
  final bool isLiked;
  final bool isInProgress;
  final VoidCallback? onTap;

  const _LikeButton({
    required this.isLiked,
    required this.isInProgress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isInProgress ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: isInProgress
                ? Padding(
                    padding: const EdgeInsets.all(4),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isLiked ? Colors.red : Colors.black54,
                      ),
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      key: ValueKey(isLiked),
                      color: isLiked ? Colors.red : Colors.black,
                      size: 28,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SAVE BUTTON
// Saat isInProgress: tampilkan spinner, tap dinonaktifkan.
// ═══════════════════════════════════════════════════════════════

class _SaveButton extends StatelessWidget {
  final bool isSaved;
  final bool isInProgress;
  final VoidCallback? onTap;

  const _SaveButton({
    required this.isSaved,
    required this.isInProgress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isInProgress ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 29,
        height: 29,
        child: isInProgress
            ? Padding(
                padding: const EdgeInsets.all(4),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isSaved ? Colors.amber.shade700 : Colors.black54,
                  ),
                ),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  key: ValueKey(isSaved),
                  color: isSaved ? Colors.amber : Colors.black,
                  size: 29,
                ),
              ),
      ),
    );
  }
}
