import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
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
  final int? rating;
  final double aspectRatio;
  final String noId;
  final String idVendor;

  @override
  State<PortofolioCard> createState() => _PortofolioCardState();
}

class _PortofolioCardState extends State<PortofolioCard> {
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

  void _measureCaption() {
    final caption = _plainCaption;
    if (caption == null || caption.isEmpty) return;

    final maxWidth = MediaQuery.of(context).size.width - 40;
    final tp = TextPainter(
      text: TextSpan(
        text: caption,
        style: const TextStyle(
            fontSize: 13, height: 1.45, color: Colors.black87),
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

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    final porto = widget.portofolio;
    final bool isImageValid =
        widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty;
    final bool isAvatarValid = widget.photographerIcon.trim().isNotEmpty;
    final bool hasMultipleMedia = porto.mediaUrls.length > 1;
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
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
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
            // ── Gambar ────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: widget.aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: isImageValid ? widget.imageUrl! : '',
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ShimmerPlaceholder(),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey.shade400,
                          size: 36,
                        ),
                      ),
                    ),
                    if (hasMultipleMedia)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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
                                '${porto.mediaUrls.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Like / Save row ───────────────────────────
            // Selector: hanya rebuild bagian ini saat state like/save berubah
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
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (widget.portofolio.namaKategori !=
                                        null) ...[
                                      Text(
                                        widget.portofolio.namaKategori!,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ]
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
                      // ── Action buttons ───────────────────
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

            // ── Caption ───────────────────────────────────
            if (caption != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
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
                            maxLines:
                                _isCaptionExpanded ? null : 2,
                            fontSize: FontSize(14),
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
                    if (_captionHasOverflow) ...[
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () => setState(() =>
                            _isCaptionExpanded = !_isCaptionExpanded),
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