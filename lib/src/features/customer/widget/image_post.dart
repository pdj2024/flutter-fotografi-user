import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/utils/app_image.dart';
import 'package:mpjnew/src/data/hive_entity/media_url_model.dart';

class ImagePost extends StatefulWidget {
  final List<MediaUrlModel> mediaUrl;
  final BoxFit fit;
  final bool enablePreload;

  // Like / Save state (dikelola oleh parent — SinglePostPage)
  final bool isLiked;
  final bool isSaved;
  final bool isLikeInProgress;
  final bool isSaveInProgress;
  final int likeCount;
  final VoidCallback? onLike;
  final VoidCallback? onSave;

  const ImagePost({
    super.key,
    required this.mediaUrl,
    this.fit = BoxFit.cover,
    this.enablePreload = false,
    this.isLiked = false,
    this.isSaved = false,
    this.isLikeInProgress = false,
    this.isSaveInProgress = false,
    this.likeCount = 0,
    this.onLike,
    this.onSave,
  });

  @override
  State<ImagePost> createState() => _ImagePostState();
}

class _ImagePostState extends State<ImagePost> {
  late final PageController _pageController;
  int _currentIndex = 0;

  double? _imageHeight;
  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  // Kunci stabil gambar yang sudah di-precache — supaya tidak precache ulang
  // tiap rebuild, tapi tetap precache kalau daftar media berubah.
  final Set<String> _precached = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheAll();
  }

  @override
  void didUpdateWidget(covariant ImagePost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _precacheAll();
  }

  /// PageView hanya membangun slide yang sedang tampil, jadi tanpa ini slide
  /// ke-2, ke-3, dst. baru mulai diunduh saat di-swipe. Semua gambar post
  /// dimuat sekaligus begitu halaman dibuka.
  void _precacheAll() {
    final urls = _validMedia
        .map(_urlOf)
        .whereType<String>()
        .where((u) => _precached.add(stableImageKey(u)))
        .toList();
    if (urls.isEmpty) return;
    precacheImages(context, urls, decodeWidth: feedDecodeWidth(context));
  }

  String? _urlOf(MediaUrlModel media) {
    final url = media.url ?? media.idMedia;
    return (url == null || url.isEmpty) ? null : url;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<MediaUrlModel> get _validMedia => widget.mediaUrl
      .where((m) =>
          (m.idMedia != null && m.idMedia!.isNotEmpty) ||
          (m.url != null && m.url!.isNotEmpty))
      .toList();

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final validMedia = _validMedia;

    if (validMedia.isEmpty) return _buildEmptyPlaceholder();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Carousel ─────────────────────────────────────────
        Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: _imageHeight ?? 300,
              child: PageView.builder(
                controller: _pageController,
                itemCount: validMedia.length,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) =>
                    _buildImageItem(validMedia[index]),
              ),
            ),
            if (validMedia.length > 1)
              Positioned(
                top: 12,
                right: 12,
                child: _buildCounter(validMedia.length),
              ),
          ],
        ),

        // ── Action bar (like, save, dot indicator) ───────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Like button
              _ActionButton(
                icon: widget.isLiked ? Icons.favorite : Icons.favorite_border,
                activeColor: Colors.red,
                isActive: widget.isLiked,
                isInProgress: widget.isLikeInProgress,
                onTap: widget.onLike,
              ),
              if (widget.likeCount > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '${widget.likeCount}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
              const SizedBox(width: 12),
              // Save button

              // Dot indicator (centre)
              if (validMedia.length > 1) ...[
                const Spacer(),
                _buildDotIndicator(validMedia.length),
                const Spacer(),
              ] else
                const Spacer(),

              _ActionButton(
                icon: widget.isSaved ? Icons.bookmark : Icons.bookmark_border,
                activeColor: Colors.amber.shade700,
                isActive: widget.isSaved,
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

  Widget _buildImageItem(MediaUrlModel media) {
    final imageUrl = _urlOf(media);
    if (imageUrl == null) return _buildErrorWidget();

    // Provider identik dengan yang di-precache → langsung dari memori.
    final imageProvider =
        appImageProvider(imageUrl, decodeWidth: feedDecodeWidth(context));

    return Image(
      image: imageProvider,
      fit: widget.fit,
      width: double.infinity,
      height: _imageHeight,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame == null) return _buildPlaceholder();
        if (!_isImageLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadImageDimensions(imageProvider);
          });
        }
        return child;
      },
      errorBuilder: (_, __, ___) => _buildErrorWidget(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DIMENSION DETECTION
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadImageDimensions(ImageProvider imageProvider) async {
    if (!mounted || _isImageLoaded) return;

    final stream = imageProvider.resolve(const ImageConfiguration());
    final completer = Completer<void>();
    late ImageStreamListener listener;

    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        final ar = info.image.width / info.image.height;
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
        // Bisa terpanggil sinkron di tengah build (gambar sudah di cache).
        runOutsideBuild(() {
          if (!mounted) return;
          final screenWidth = MediaQuery.of(context).size.width;
          setState(() {
            _imageHeight = screenWidth / ar;
            _isImageLoaded = true;
          });
        });
      },
      onError: (_, __) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
        runOutsideBuild(() {
          if (!mounted) return;
          setState(() {
            _imageHeight = 300;
            _isImageLoaded = true;
          });
        });
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
  // INDICATOR & COUNTER
  // ═══════════════════════════════════════════════════════════

  Widget _buildDotIndicator(int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = _currentIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: isActive ? 20 : 6,
          decoration: BoxDecoration(
            color: isActive ? Constants.primaryColor : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildCounter(int count) {
    return Container(
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
  }

  // ═══════════════════════════════════════════════════════════
  // PLACEHOLDER WIDGETS
  // ═══════════════════════════════════════════════════════════

  // Kotak polos (bukan shimmer) selagi gambar belum siap.
  Widget _buildPlaceholder() => Container(
        width: double.infinity,
        height: _imageHeight ?? 300,
        color: kImagePlaceholderColor,
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
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
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
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════
// ACTION BUTTON (reusable, same pattern as PortofolioCard)
// ═══════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color activeColor;
  final bool isActive;
  final bool isInProgress;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.activeColor,
    required this.isActive,
    required this.isInProgress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: isInProgress
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    isActive ? activeColor : Colors.black38,
                  ),
                ),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  icon,
                  key: ValueKey('$icon$isActive'),
                  size: 26,
                  color: isActive ? activeColor : Colors.black54,
                ),
              ),
      ),
    );
  }
}
