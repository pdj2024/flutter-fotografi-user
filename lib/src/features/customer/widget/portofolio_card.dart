import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/hive_entity/media_url_model.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';
import 'package:mpjnew/src/features/customer/view/single_post_page.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// PortofolioCard
///
/// Card tidak punya logic API atau Hive sendiri.
/// Semua like/save logic ada di PortofolioProvider.
/// Card hanya:
///   1. Membaca state dari provider via Selector (efisien, tidak rebuild semua)
///   2. Memanggil provider.toggleLike / toggleSave saat user tap
///
/// ✅ UPDATE: Gambar kini mengikuti rasio asli (1:1, 4:3, 16:9, dst.)
///           + carousel swipe jika portofolio punya lebih dari 1 gambar
class PortofolioCard extends StatefulWidget {
  const PortofolioCard({
    Key? key,
    required this.photographerIcon,
    this.imageUrl,
    required this.name,
    this.rating,
    this.aspectRatio = 1.0, // kept for API compat, no longer used internally
    required this.noId,
    required this.idVendor,
    required this.portofolio,
  }) : super(key: key);

  final PortofolioModel portofolio;
  final String photographerIcon;
  final String? imageUrl;
  final String name;
  final int? rating;
  final double aspectRatio; // deprecated — height is now auto-detected
  final String noId;
  final String idVendor;

  @override
  State<PortofolioCard> createState() => _PortofolioCardState();
}

class _PortofolioCardState extends State<PortofolioCard> {
  // ── Carousel ─────────────────────────────────────────────
  int _currentIndex = 0;

  // ── Dynamic image height ──────────────────────────────────
  double? _imageHeight;
  bool _isImageLoaded = false;

  // ── Caption ──────────────────────────────────────────────
  bool _isCaptionExpanded = false;
  bool _captionHasOverflow = true;
  static const int _captionMaxLines = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measureCaption();
    });
  }

  // ── Caption helpers ───────────────────────────────────────

  void _measureCaption() {
    final caption = _plainCaption;
    if (caption == null || caption.isEmpty) return;

    final maxWidth = MediaQuery.of(context).size.width - 40;
    final tp = TextPainter(
      text: TextSpan(
        text: caption,
        style:
            const TextStyle(fontSize: 13, height: 1.45, color: Colors.black87),
      ),
      maxLines: _captionMaxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    if (tp.didExceedMaxLines != _captionHasOverflow) {
      if (mounted) setState(() => _captionHasOverflow = tp.didExceedMaxLines);
    }
  }

  String? get _plainCaption {
    final c = widget.portofolio.caption;
    if (c == null || c.trim().isEmpty) return null;
    return c.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  // ── Image dimension detection (same logic as ImagePost) ───

  Future<void> _loadImageDimensions(ImageProvider imageProvider) async {
    if (!mounted || _isImageLoaded) return;

    final stream = imageProvider.resolve(const ImageConfiguration());
    final completer = Completer<void>();
    late ImageStreamListener listener;

    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!mounted) return;
        final screenWidth = MediaQuery.of(context).size.width;
        final ar = info.image.width / info.image.height;
        if (mounted) {
          setState(() {
            _imageHeight = screenWidth / ar;
            _isImageLoaded = true;
          });
        }
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
      onError: (_, __) {
        if (!mounted) return;
        if (mounted) {
          setState(() {
            _imageHeight = 300;
            _isImageLoaded = true;
          });
        }
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
    );

    stream.addListener(listener);

    // Timeout fallback
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

  // ── Carousel helpers ──────────────────────────────────────

  List<MediaUrlModel> get _validMedia => widget.portofolio.mediaUrls
      .where((m) => m.idMedia != null && m.idMedia!.isNotEmpty)
      .toList();

  void _onSwipe(DragEndDetails details) {
    final media = _validMedia;
    if (media.length <= 1) return;

    if (details.primaryVelocity! < -300 && _currentIndex < media.length - 1) {
      setState(() {
        _currentIndex++;
        // Reset height so next image can recalculate its own ratio
        _isImageLoaded = false;
        _imageHeight = null;
      });
    } else if (details.primaryVelocity! > 300 && _currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isImageLoaded = false;
        _imageHeight = null;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    final porto = widget.portofolio;
    final media = _validMedia;
    final bool isAvatarValid = widget.photographerIcon.trim().isNotEmpty;
    final String? caption = _plainCaption;

    return GestureDetector(
      onTap: () {
        context.read<PortofolioProvider>().setSelectedPortofolio(porto);
        nav.navigateToPage(
          hrsLogin: true,
          context,
          const SinglePostPage(),
          targetTabIndex: 0,
          targetPage: 'SinglePostPage',
        );
      },
      child: Container(
        margin: const EdgeInsets.only(left: 10, right: 10, bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black.withOpacity(0.07),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gambar carousel ──────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: GestureDetector(
                onHorizontalDragEnd: _onSwipe,
                child: Container(
                  width: double.infinity,
                  color: Colors.grey.shade50,
                  // Use detected height; fall back to 300 while loading
                  height: _imageHeight ?? 300,
                  child: Stack(
                    children: [
                      // ── Animated image switch ──────────────
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: media.isEmpty
                            ? _buildNoImagePlaceholder()
                            : _buildImageItem(
                                media[_currentIndex],
                                key: ValueKey('${porto.noId}_$_currentIndex'),
                              ),
                      ),

                      // ── Counter badge (top-right) ──────────
                      if (media.length > 1)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: _buildCounterBadge(media.length),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Dot indicator ────────────────────────────────
            if (media.length > 1) ...[
              const SizedBox(height: 8),
              Center(child: _buildDotIndicator(media.length)),
            ],

            // ── Like / Save row ───────────────────────────────
            Selector<PortofolioProvider, _LikeSaveState>(
              selector: (_, provider) => _LikeSaveState(
                isLiked: provider.isLiked(porto.noId),
                isSaved: provider.isSaved(porto.noId),
                isLikeInProgress: provider.isLikeInProgress(porto.noId),
                isSaveInProgress: provider.isSaveInProgress(porto.noId),
              ),
              builder: (context, state, _) {
                final provider = context.read<PortofolioProvider>();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            nav.navigateToPage(
                              context,
                              VendorBioPage(idVendor: widget.idVendor),
                              targetTabIndex: 0,
                              targetPage: 'VendorBioPage',
                            );
                          },
                          child: Row(
                            children: [
                              // Avatar
                              ClipOval(
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: isAvatarValid
                                      ? CachedNetworkImage(
                                          imageUrl: widget.photographerIcon,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) =>
                                              const ShimmerPlaceholder(
                                                  radius: 15),
                                          errorWidget: (_, __, ___) =>
                                              _defaultAvatar(),
                                        )
                                      : _defaultAvatar(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          Helper.formatTanggal(
                                              widget.portofolio.lastUpdated ??
                                                  widget.portofolio.tglCreated),
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 5),
                                          width: 3,
                                          height: 3,
                                          decoration: const BoxDecoration(
                                            color: Colors.grey,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Text(
                                          widget.portofolio.namaKategori!,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.rating != null &&
                                  widget.rating! > 0) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 2),
                                Text(
                                  widget.rating.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // ── Action buttons ─────────────────────
                      Row(
                        children: [
                          _ActionButton(
                            icon: state.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            activeColor: Colors.red,
                            isActive: state.isLiked,
                            isInProgress: state.isLikeInProgress,
                            onTap: state.isLikeInProgress
                                ? null
                                : () => provider.toggleLike(
                                      context: context,
                                      porto: porto,
                                    ),
                          ),
                          const SizedBox(width: 4),
                          _ActionButton(
                            icon: state.isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            activeColor: Colors.amber.shade700,
                            isActive: state.isSaved,
                            isInProgress: state.isSaveInProgress,
                            onTap: state.isSaveInProgress
                                ? null
                                : () => provider.toggleSave(
                                      context: context,
                                      porto: porto,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Caption ────────────────────────────────────────
            if (caption != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Divider(color: Colors.grey.shade300),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: Html(
                        data: Helper.formatCaption(porto.caption!),
                        style: {
                          "body": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            maxLines: _isCaptionExpanded ? null : 2,
                            fontSize: FontSize(12),
                            lineHeight: LineHeight(1.5),
                            color: Colors.black87,
                          ),
                          "b": Style(fontWeight: FontWeight.bold),
                          "i": Style(fontStyle: FontStyle.italic),
                          "u": Style(textDecoration: TextDecoration.underline),
                          "a": Style(
                            color: Colors.blue,
                            textDecoration: TextDecoration.none,
                            fontWeight: FontWeight.w500,
                          ),
                        },
                        onLinkTap: (url, attributes, element) async {
                          if (url == null) return;
                          await launchUrl(Uri.parse(url),
                              mode: LaunchMode.externalApplication);
                        },
                      ),
                    ),
                    if (_captionHasOverflow) ...[
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () => setState(
                            () => _isCaptionExpanded = !_isCaptionExpanded),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isCaptionExpanded
                                  ? 'Lebih sedikit'
                                  : 'Selengkapnya',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 2),
                            AnimatedRotation(
                              turns: _isCaptionExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 220),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 15,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // IMAGE ITEM
  // ═══════════════════════════════════════════════════════════

  Widget _buildImageItem(MediaUrlModel media, {Key? key}) {
    return CachedNetworkImage(
      key: key,
      imageUrl: media.idMedia!,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, __) => _buildShimmerPlaceholder(),
      errorWidget: (_, __, ___) => _buildErrorPlaceholder(),
      fadeInDuration: const Duration(milliseconds: 280),
      fadeOutDuration: const Duration(milliseconds: 150),
      memCacheWidth: 1080,
      maxWidthDiskCache: 1080,
      imageBuilder: (context, imageProvider) {
        // Detect dimensions on first load of each image
        if (!_isImageLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadImageDimensions(imageProvider);
          });
        }
        return Image(
          image: imageProvider,
          fit: BoxFit.cover,
          width: double.infinity,
          height: _imageHeight,
          errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // INDICATOR & BADGE
  // ═══════════════════════════════════════════════════════════

  Widget _buildDotIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildCounterBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            color: Colors.white,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            '${_currentIndex + 1}/$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PLACEHOLDER WIDGETS
  // ═══════════════════════════════════════════════════════════

  Widget _buildShimmerPlaceholder() => ShimmerPlaceholder(
        width: double.infinity,
        height: _imageHeight ?? 300,
      );

  Widget _buildErrorPlaceholder() => Container(
        width: double.infinity,
        height: _imageHeight ?? 300,
        color: Colors.grey.shade100,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
        ),
      );

  Widget _buildNoImagePlaceholder() => Container(
        width: double.infinity,
        height: 300,
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
        ),
      );

  Widget _defaultAvatar() => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Icon(Icons.person, size: 16, color: Colors.grey.shade400),
      );
}

// ═══════════════════════════════════════════════════════════
// STATE MODEL untuk Selector
// ═══════════════════════════════════════════════════════════

class _LikeSaveState {
  final bool isLiked;
  final bool isSaved;
  final bool isLikeInProgress;
  final bool isSaveInProgress;

  const _LikeSaveState({
    required this.isLiked,
    required this.isSaved,
    required this.isLikeInProgress,
    required this.isSaveInProgress,
  });

  @override
  bool operator ==(Object other) =>
      other is _LikeSaveState &&
      other.isLiked == isLiked &&
      other.isSaved == isSaved &&
      other.isLikeInProgress == isLikeInProgress &&
      other.isSaveInProgress == isSaveInProgress;

  @override
  int get hashCode =>
      Object.hash(isLiked, isSaved, isLikeInProgress, isSaveInProgress);
}

// ═══════════════════════════════════════════════════════════
// ACTION BUTTON
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
                width: 20,
                height: 20,
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
                  size: 24,
                  color: isActive ? activeColor : Colors.black54,
                ),
              ),
      ),
    );
  }
}
