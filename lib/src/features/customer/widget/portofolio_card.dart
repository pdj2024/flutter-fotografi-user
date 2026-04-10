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

class PortofolioCard extends StatefulWidget {
  const PortofolioCard({
    Key? key,
    required this.photographerIcon,
    this.imageUrl,
    required this.name,
    this.rating,
    this.aspectRatio = 1.0,
    required this.noId,
    required this.idVendor,
    required this.portofolio,
  }) : super(key: key);

  final PortofolioModel portofolio;
  final String photographerIcon;
  final String? imageUrl;
  final String name;
  final double? rating;
  final double aspectRatio;
  final String noId;
  final String idVendor;

  @override
  State<PortofolioCard> createState() => _PortofolioCardState();
}

class _PortofolioCardState extends State<PortofolioCard> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _isCaptionExpanded = false;

  // Aspect ratio ditentukan dari gambar pertama portofolio.
  // Cache global (per URL) agar tidak re-resolve saat card di-scroll ulang.
  static final Map<String, double> _ratioCache = {};
  static const double _defaultRatio = 4 / 3;
  double? _resolvedRatio;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Baca cache secara SINKRON — tidak perlu setState, tidak ganggu animasi.
    // Async resolve hanya dipanggil jika URL belum pernah dilihat sebelumnya.
    final media = _validMedia;
    if (media.isNotEmpty) {
      final url = media[0].idMedia!;
      if (_ratioCache.containsKey(url)) {
        _resolvedRatio = _ratioCache[url]; // langsung, tanpa setState
      } else {
        _resolveAspectRatioAsync(url);     // async hanya untuk URL baru
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Hanya dipanggil untuk URL yang belum pernah dilihat (tidak ada di cache).
  /// setState dipanggil tepat sekali per URL baru — tidak pernah saat scroll
  /// atau saat animasi refresh SmartRefresher sedang berjalan.
  Future<void> _resolveAspectRatioAsync(String url) async {
    try {
      final provider = CachedNetworkImageProvider(url);
      final stream = provider.resolve(const ImageConfiguration());
      final completer = Completer<double>();

      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool _) {
          final ratio = info.image.width / info.image.height;
          _ratioCache[url] = ratio;
          if (!completer.isCompleted) completer.complete(ratio);
          stream.removeListener(listener);
        },
        onError: (_, __) {
          if (!completer.isCompleted) completer.complete(_defaultRatio);
          stream.removeListener(listener);
        },
      );

      stream.addListener(listener);

      final ratio = await completer.future
          .timeout(const Duration(seconds: 5), onTimeout: () => _defaultRatio);

      if (mounted) setState(() => _resolvedRatio = ratio);
    } catch (_) {
      if (mounted) setState(() => _resolvedRatio = _defaultRatio);
    }
  }

  String? get _plainCaption {
    final c = widget.portofolio.caption;
    if (c == null || c.trim().isEmpty) return null;
    return c.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  List<MediaUrlModel> get _validMedia => widget.portofolio.mediaUrls
      .where((m) => m.idMedia != null && m.idMedia!.isNotEmpty)
      .toList();

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
          context,
          const SinglePostPage(),
          hrsLogin: true,
          targetTabIndex: 0,
          targetPage: 'SinglePostPage',
          noIdPortofolio: porto.noId,
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
            // ── Gambar carousel ───────────────────────────────────────
            // Ratio dikunci ke gambar pertama portofolio (bukan per-gambar).
            // Saat ratio belum resolve: pakai defaultRatio (4:3) sebagai placeholder.
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: _resolvedRatio ?? _defaultRatio,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: media.isEmpty ? 1 : media.length,
                      // PageScrollPhysics: horizontal swipe ke PageView,
                      // vertical drag diteruskan ke parent ListView tanpa konflik
                      physics: const PageScrollPhysics(),
                      onPageChanged: (index) =>
                          setState(() => _currentIndex = index),
                      itemBuilder: (context, index) {
                        if (media.isEmpty) return _buildNoImagePlaceholder();
                        return _buildImageItem(media[index]);
                      },
                    ),
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

            // ── Dot indicator ──────────────────────────────────────────
            if (media.length > 1) ...[
              const SizedBox(height: 8),
              Center(child: _buildDotIndicator(media.length)),
            ],

            // ── Like / Save row ────────────────────────────────────────
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
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            widget.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (widget.rating != null &&
                                            widget.rating! > 0) ...[
                                          const SizedBox(width: 10),
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
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            Helper.formatTanggal(
                                                widget.portofolio.lastUpdated ??
                                                    widget.portofolio.tglCreated),
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
                                        Flexible(
                                          child: Text(
                                            widget.portofolio.namaKategori ?? '',
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                                : () async {
                                    await provider.toggleLike(
                                      context: context,
                                      porto: porto,
                                    );
                                  },
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
                                : () async {
                                    await provider.toggleSave(
                                      context: context,
                                      porto: porto,
                                    );
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Caption ────────────────────────────────────────────────
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
                          "u": Style(
                              textDecoration: TextDecoration.underline),
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

  // ── Image item ────────────────────────────────────────────────────────

  Widget _buildImageItem(MediaUrlModel media) {
    return CachedNetworkImage(
      imageUrl: media.idMedia!,
      fit: BoxFit.cover,
      width: double.infinity,
      memCacheWidth: 1080,
      maxWidthDiskCache: 1080,
      placeholder: (_, __) => const _ImageShimmer(),
      errorWidget: (_, __, ___) => _buildErrorPlaceholder(),
    );
  }

  // ── Indicators ────────────────────────────────────────────────────────

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
            color:
                isActive ? Constants.primaryColor : Colors.grey.shade300,
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
          const Icon(Icons.photo_library_outlined,
              color: Colors.white, size: 13),
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

  // ── Placeholders ──────────────────────────────────────────────────────

  Widget _buildErrorPlaceholder() => Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Icon(Icons.broken_image_outlined,
              size: 40, color: Colors.grey.shade400),
        ),
      );

  Widget _buildNoImagePlaceholder() => Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(Icons.image_not_supported_outlined,
              size: 40, color: Colors.grey.shade400),
        ),
      );

  Widget _defaultAvatar() => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Icon(Icons.person, size: 16, color: Colors.grey.shade400),
      );
}

// ── Image shimmer (stateless, tidak perlu setState) ───────────────────────

class _ImageShimmer extends StatelessWidget {
  const _ImageShimmer();

  @override
  Widget build(BuildContext context) {
    return const ShimmerPlaceholder(
      width: double.infinity,
      height: double.infinity,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STATE MODEL untuk Selector
// ═══════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════
// ACTION BUTTON
// ═══════════════════════════════════════════════════════════════════════

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
