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

  // ── Aspect ratio cache ──────────────────────────────────────────────────
  // Cache GLOBAL per URL — sekali resolve, tidak pernah resolve lagi.
  static final Map<String, double> _ratioCache = {};

  // null = belum diketahui → tampilkan _AdaptiveImage (shimmer → gambar)
  // >0   = sudah diketahui → langsung render AspectRatio + PageView
  double? _resolvedRatio;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    final media = _validMedia;
    if (media.isEmpty) {
      _resolvedRatio = 4 / 3;
      return;
    }

    final url = media[0].idMedia!;
    // Cache HIT: assign sinkron sebelum build pertama — tidak ada shimmer
    if (_ratioCache.containsKey(url)) {
      _resolvedRatio = _ratioCache[url];
    }
    // Cache MISS: biarkan null → _AdaptiveImage yang akan callback
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Dipanggil oleh _AdaptiveImage tepat saat pixel gambar pertama selesai
  /// di-decode. Karena sumber datanya adalah ImageInfo dari gambar yang sudah
  /// ada di Flutter image cache, tidak ada jeda antara gambar muncul dan
  /// ukuran card berubah.
  void _onRatioResolved(String url, double ratio) {
    _ratioCache[url] = ratio;
    if (mounted && _resolvedRatio != ratio) {
      setState(() => _resolvedRatio = ratio);
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
    final String? firstUrl = media.isNotEmpty ? media[0].idMedia : null;

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
            // ── Gambar carousel ─────────────────────────────────────────
            //
            // FLOW:
            // 1. Cache MISS → _resolvedRatio null
            //    → tampilkan _AdaptiveImage (shimmer → gambar natural size)
            //    → saat gambar decode, callback _onRatioResolved dipanggil
            //    → setState → _resolvedRatio terisi → rebuild ke mode 2
            //
            // 2. Cache HIT atau setelah callback
            //    → langsung render AspectRatio dengan ratio yang benar
            //    → PageView aktif untuk multi-gambar
            //
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: _resolvedRatio == null
                  ? (firstUrl != null
                      ? _AdaptiveImage(
                          url: firstUrl,
                          onRatioResolved: (r) => _onRatioResolved(firstUrl, r),
                        )
                      : _NoImageBox(height: 220))
                  : AspectRatio(
                      aspectRatio: _resolvedRatio!,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: media.isEmpty ? 1 : media.length,
                            physics: const PageScrollPhysics(),
                            onPageChanged: (i) =>
                                setState(() => _currentIndex = i),
                            itemBuilder: (context, index) {
                              if (media.isEmpty) return const _NoImageBox();
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

            // ── Dot indicator ───────────────────────────────────────────
            if (_resolvedRatio != null && media.length > 1) ...[
              const SizedBox(height: 8),
              Center(child: _buildDotIndicator(media.length)),
            ],

            // ── Like / Save row ─────────────────────────────────────────
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
                          onTap: () => nav.navigateToPage(
                            context,
                            VendorBioPage(idVendor: widget.idVendor),
                            targetTabIndex: 0,
                            targetPage: 'VendorBioPage',
                          ),
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
                                              _DefaultAvatar(),
                                        )
                                      : _DefaultAvatar(),
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
                                      children: [
                                        Flexible(
                                          child: Text(
                                            Helper.formatTanggal(widget
                                                    .portofolio.lastUpdated ??
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
                                            widget.portofolio.namaKategori ??
                                                '',
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
                                : () async => provider.toggleLike(
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
                                : () async => provider.toggleSave(
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

            // ── Caption ─────────────────────────────────────────────────
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

  Widget _buildImageItem(MediaUrlModel media) {
    return CachedNetworkImage(
      imageUrl: media.idMedia!,
      fit: BoxFit.cover,
      width: double.infinity,
      memCacheWidth: 1080,
      maxWidthDiskCache: 1080,
      placeholder: (_, __) => const _ImageShimmer(),
      errorWidget: (_, __, ___) => _ErrorBox(),
    );
  }

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
}

// ═══════════════════════════════════════════════════════════════════════════
// _AdaptiveImage
//
// Menampilkan gambar DAN mendeteksi ratio pada saat gambar selesai di-decode.
// Teknik: CachedNetworkImage.imageBuilder dipanggil tepat saat ImageInfo
// tersedia di memori → resolve ratio dari sana → tidak ada race condition.
// ═══════════════════════════════════════════════════════════════════════════

class _AdaptiveImage extends StatefulWidget {
  final String url;
  final void Function(double ratio) onRatioResolved;

  const _AdaptiveImage({
    required this.url,
    required this.onRatioResolved,
  });

  @override
  State<_AdaptiveImage> createState() => _AdaptiveImageState();
}

class _AdaptiveImageState extends State<_AdaptiveImage> {
  bool _reported = false;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: widget.url,
      fit: BoxFit.cover,
      width: double.infinity,
      memCacheWidth: 1080,
      maxWidthDiskCache: 1080,
      // imageBuilder dipanggil HANYA saat gambar sudah di-decode sempurna.
      // Di sini kita baca dimensi asli → callback ke parent → parent setState.
      imageBuilder: (context, imageProvider) {
        if (!_reported) {
          _reported = true;
          _readRatio(imageProvider);
        }
        return Image(
          image: imageProvider,
          fit: BoxFit.cover,
          width: double.infinity,
        );
      },
      placeholder: (_, __) => const SizedBox(
        height: 220,
        width: double.infinity,
        child: ShimmerPlaceholder(width: double.infinity, height: 220),
      ),
      errorWidget: (_, __, ___) => _ErrorBox(height: 220),
    );
  }

  /// Baca width/height dari ImageProvider yang sudah ada di Flutter image cache.
  /// Karena imageBuilder sudah dipanggil, gambar PASTI ada di cache → listener
  /// akan fire hampir seketika (synchronous-like).
  void _readRatio(ImageProvider provider) {
    final stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        if (h > 0) widget.onRatioResolved(w / h);
        stream.removeListener(listener);
      },
      onError: (_, __) {
        widget.onRatioResolved(4 / 3);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
  }
}

// ── Reusable small widgets ─────────────────────────────────────────────────

class _ImageShimmer extends StatelessWidget {
  const _ImageShimmer();

  @override
  Widget build(BuildContext context) => const ShimmerPlaceholder(
        width: double.infinity,
        height: double.infinity,
      );
}

class _NoImageBox extends StatelessWidget {
  final double? height;
  const _NoImageBox({this.height});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Container(
          color: Colors.grey.shade200,
          child: Center(
            child: Icon(Icons.image_not_supported_outlined,
                size: 40, color: Colors.grey.shade400),
          ),
        ),
      );
}

class _ErrorBox extends StatelessWidget {
  final double? height;
  const _ErrorBox({this.height});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Container(
          color: Colors.grey.shade100,
          child: Center(
            child: Icon(Icons.broken_image_outlined,
                size: 40, color: Colors.grey.shade400),
          ),
        ),
      );
}

class _DefaultAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Icon(Icons.person, size: 16, color: Colors.grey.shade400),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// STATE MODEL untuk Selector
// ═══════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════
// ACTION BUTTON
// ═══════════════════════════════════════════════════════════════════════════

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
