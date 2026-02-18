import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';
import 'package:mpjnew/src/features/customer/viewmodels/paket_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:mpjnew/src/features/customer/widget/image_post.dart';
import 'package:mpjnew/src/features/customer/widget/offer_card.dart';
import 'package:mpjnew/src/features/customer/widget/post_header.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SinglePostPage extends StatefulWidget {
  const SinglePostPage({super.key});

  @override
  State<SinglePostPage> createState() => _SinglePostPageState();
}

class _SinglePostPageState extends State<SinglePostPage> {
  final ScrollController _scrollController = ScrollController();

  bool _isLoadingData = false;
  String? _currentPortfolioId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _loadData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  // ═══════════════════════════════════════════════════════════
  // LOAD DATA
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadData() async {
    _safeSetState(() => _isLoadingData = true);

    try {
      final portofolioProvider = context.read<PortofolioProvider>();
      final paketProvider = context.read<PaketProvider>();

      var selectedPortfolio = portofolioProvider.selectedPortofolio;
      if (selectedPortfolio == null) return;

      final targetId = selectedPortfolio.noId;
      paketProvider.clearForPortfolio(targetId);

      // Ambil data fresh dari lokal / API
      final fresh = await _getFreshPortfolio(portofolioProvider, targetId);
      if (fresh != null) {
        portofolioProvider.setSelectedPortofolio(fresh);
        selectedPortfolio = fresh;
      }

      _safeSetState(() => _currentPortfolioId = selectedPortfolio!.noId);

      // Load paket
      if (selectedPortfolio!.idPaket.isNotEmpty) {
        await paketProvider.loadPaketsWithUlasan(
          paketIds: selectedPortfolio.idPaket,
          portfolioId: targetId,
          vendorId: selectedPortfolio.idVendor,
        );
      }
    } catch (e, st) {
      debugPrint('[SinglePost] ❌ $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _safeSetState(() => _isLoadingData = false);
    }
  }

  Future<PortofolioModel?> _getFreshPortfolio(
    PortofolioProvider provider,
    String noId,
  ) async {
    try {
      return await provider.getPortfolioById(noId);
    } catch (_) {}
    return provider.selectedPortofolio;
  }

  Future<void> _onRefresh() async {
    try {
      context.read<PaketProvider>().clearForPortfolio(null);
      _safeSetState(() => _currentPortfolioId = null);
      await _loadData();
      if (mounted) {
        CustomSnackbar.showSuccessSnackbar(context, 'Portfolio updated');
      }
    } catch (_) {
      if (mounted) {
        CustomSnackbar.showErrorSnackbar(context, 'Failed to refresh');
      }
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

        final isDataReady =
            _currentPortfolioId == selectedPortfolio.noId;

        // Baca state like/save langsung dari provider (sudah sinkron dengan Hive)
        final isLiked =
            portofolioProvider.isLiked(selectedPortfolio.noId);
        final isSaved =
            portofolioProvider.isSaved(selectedPortfolio.noId);
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
              style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        PostHeader(portofolio: selectedPortfolio),

                        // ImagePost menerima state dari provider langsung
                        // Tidak ada state lokal like/save di page ini
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
                          _ExpandableCaption(
                              caption: selectedPortfolio.caption!),
                          Container(
                            height: 10,
                            color: Colors.grey.shade200,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!isDataReady ||
                      _isLoadingData ||
                      paketProvider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    _buildPaketSection(paketProvider, selectedPortfolio),
                  const SizedBox(height: 20),
                ],
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 10),
              Text(paketProvider.error!, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton(
                  onPressed: _loadData, child: const Text('Retry')),
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
          margin: const EdgeInsets.symmetric(horizontal: 20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white60,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(1, 2)),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
            child: Column(
              children: [
                const Icon(Icons.shelves, size: 100, color: Colors.grey),
                const SizedBox(height: 20),
                const Text('Portofolio ini tidak memiliki paket',
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
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
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Portfolio not found',
                style:
                    TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
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
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _measureOverflow());
  }

  @override
  void didUpdateWidget(_ExpandableCaption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.caption != widget.caption) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _measureOverflow());
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
              onTap: () =>
                  setState(() => _isExpanded = !_isExpanded),
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