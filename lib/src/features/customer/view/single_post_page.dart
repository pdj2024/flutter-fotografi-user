import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';
import 'package:mpjnew/src/features/customer/viewmodels/paket_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/widget/image_post.dart';
import 'package:mpjnew/src/features/customer/widget/offer_card.dart';
import 'package:mpjnew/src/features/customer/widget/post_header.dart';
import 'package:mpjnew/src/features/customer/widget/refresh_header.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:url_launcher/url_launcher.dart';

class SinglePostPage extends StatefulWidget {
  const SinglePostPage({super.key});

  @override
  State<SinglePostPage> createState() => _SinglePostPageState();
}

class _SinglePostPageState extends State<SinglePostPage> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final ScrollController _scrollController = ScrollController();

  // ✅ FIX: Pisahkan loading state
  // _isPaketLoading  → hanya untuk section paket (bawah)
  // Gambar TIDAK bergantung pada loading state apapun — langsung render
  // dari selectedPortofolio yang sudah ada saat halaman dibuka.
  bool _isPaketLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadPaket();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // LOAD DATA
  // ═══════════════════════════════════════════════════════════

  // ✅ FIX: _loadPaket hanya load paket — gambar TIDAK ditunggu.
  // selectedPortofolio sudah di-set oleh caller (VendorBioPage / grid item)
  // sebelum navigate ke halaman ini, jadi gambar bisa langsung tampil.
  Future<void> _loadPaket() async {
    if (!mounted) return;

    final portofolioProvider = context.read<PortofolioProvider>();
    final paketProvider = context.read<PaketProvider>();
    final selectedPortfolio = portofolioProvider.selectedPortofolio;

    if (selectedPortfolio == null) return;

    setState(() => _isPaketLoading = true);

    try {
      paketProvider.clearForPortfolio(selectedPortfolio.noId);

      if (selectedPortfolio.idPaket.isNotEmpty) {
        await paketProvider.loadPaketsWithUlasan(
          paketIds: selectedPortfolio.idPaket,
          portfolioId: selectedPortfolio.noId,
          vendorId: selectedPortfolio.idVendor,
        );
      }
    } catch (e) {
      debugPrint('[SinglePost] ❌ loadPaket error: $e');
    } finally {
      if (mounted) setState(() => _isPaketLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    if (!mounted) {
      _refreshController.refreshCompleted();
      return;
    }
    try {
      await _loadPaket();
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Consumer2<PortofolioProvider, PaketProvider>(
      builder: (context, portofolioProvider, paketProvider, _) {
        final selectedPortfolio = portofolioProvider.selectedPortofolio;

        if (selectedPortfolio == null) return _buildEmptyScaffold();

        // ✅ FIX: Tidak ada isDataReady check — gambar SELALU tampil
        // karena selectedPortofolio sudah tersedia sebelum halaman dibuka.
        final isLiked = portofolioProvider.isLiked(selectedPortfolio.noId);
        final isSaved = portofolioProvider.isSaved(selectedPortfolio.noId);
        final isLikeInProgress =
            portofolioProvider.isLikeInProgress(selectedPortfolio.noId);
        final isSaveInProgress =
            portofolioProvider.isSaveInProgress(selectedPortfolio.noId);

        return Scaffold(
          backgroundColor: const Color(0xFFF9F9F9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF9F9F9),
            elevation: 1,
            title: const Text(
              'Portofolio',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          body: SmartRefresher(
            controller: _refreshController,
            onRefresh: _onRefresh,
            physics: const AlwaysScrollableScrollPhysics(),
            header: buildRefreshHeader(),
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // ── Gambar + header + caption ─────────────────
                // ✅ Selalu tampil langsung — tidak ada loading gate
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      PostHeader(portofolio: selectedPortfolio),
                      ImagePost(
                        mediaUrl: selectedPortfolio.mediaUrls,
                        enablePreload: true,
                        isLiked: isLiked,
                        isSaved: isSaved,
                        isLikeInProgress: isLikeInProgress,
                        isSaveInProgress: isSaveInProgress,
                        likeCount: selectedPortfolio.likes,
                        onLike: isLikeInProgress
                            ? null
                            : () => portofolioProvider.toggleLike(
                                  context: context,
                                  porto: selectedPortfolio,
                                ),
                        onSave: isSaveInProgress
                            ? null
                            : () => portofolioProvider.toggleSave(
                                  context: context,
                                  porto: selectedPortfolio,
                                ),
                      ),
                      if (selectedPortfolio.caption != null &&
                          selectedPortfolio.caption!.isNotEmpty) ...[
                        _ExpandableCaption(caption: selectedPortfolio.caption!),
                        Container(height: 10, color: Colors.grey.shade200),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Paket section ─────────────────────────────
                // ✅ Loading spinner HANYA di sini, bukan seluruh halaman
                if (_isPaketLoading || paketProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _buildPaketSection(paketProvider, selectedPortfolio),

                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PAKET SECTION
  // ═══════════════════════════════════════════════════════════

  Widget _buildPaketSection(
    PaketProvider paketProvider,
    PortofolioModel portfolio,
  ) {
    if (paketProvider.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 10),
              Text(paketProvider.error!, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton(
                  onPressed: _loadPaket, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }

    final portfolioPaketIds = portfolio.idPaket.toSet();
    final filteredPakets = paketProvider.paketList
        .where((p) => portfolioPaketIds.contains(p.no_id))
        .toList();

    if (filteredPakets.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 6, offset: Offset(1, 2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
            child: Column(
              children: [
                const Icon(Icons.shelves, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Portofolio ini tidak memiliki paket',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Kembali',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredPakets.length,
      itemBuilder: (context, index) {
        final paket = filteredPakets[index];
        final ulasanList = paketProvider.getUlasanForPaket(paket.no_id);
        return OfferCard(
          key: ValueKey('${portfolio.noId}_${paket.no_id}'),
          ulasanList: ulasanList,
          paket: paket,
          vendorId: portfolio.idVendor,
        );
      },
    );
  }

  Widget _buildEmptyScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
        title: const Text('Portofolio',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Portofolio tidak ditemukan',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// _ExpandableCaption
// ═══════════════════════════════════════════════════════════════

class _ExpandableCaption extends StatefulWidget {
  final String caption;

  const _ExpandableCaption({required this.caption});

  @override
  State<_ExpandableCaption> createState() => _ExpandableCaptionState();
}

class _ExpandableCaptionState extends State<_ExpandableCaption> {
  bool _isExpanded = false;
  bool _hasOverflow = false;

  static const _collapsedLines = 3;
  static const _baseStyle = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: Colors.black87,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureOverflow());
  }

  @override
  void didUpdateWidget(_ExpandableCaption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.caption != widget.caption) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureOverflow());
    }
  }

  void _measureOverflow() {
    if (!mounted) return;
    final plainText = _stripHtml(widget.caption);
    final maxWidth = MediaQuery.of(context).size.width - 40;

    final tp = TextPainter(
      text: TextSpan(text: plainText, style: _baseStyle),
      maxLines: _collapsedLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    if (tp.didExceedMaxLines != _hasOverflow) {
      setState(() => _hasOverflow = tp.didExceedMaxLines);
    }
  }

  String _stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]*>'), '').trim();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Html(
            data: Helper.formatCaption(widget.caption),
            style: {
              "body": Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                maxLines: _isExpanded ? null : _collapsedLines,
                fontSize: FontSize(14),
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
          if (_hasOverflow) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded ? 'Lebih sedikit' : 'Selengkapnya',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
