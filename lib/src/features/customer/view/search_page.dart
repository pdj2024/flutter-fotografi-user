import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';
import 'package:mpjnew/src/features/customer/view/single_post_page.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:mpjnew/src/features/customer/widget/filter_overlay.dart';
import 'package:mpjnew/src/features/customer/services/portofolio_service.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class SearchPage extends StatefulWidget {
  final String id_category;
  final String nama_category;
  final String search;
  final bool autoOpenFilter;

  const SearchPage({
    super.key,
    required this.id_category,
    required this.nama_category,
    required this.search,
    this.autoOpenFilter = false,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  bool _showFilterOverlay = false;
  bool isLoadingPorto = true;
  List<PortofolioModel> portofolioList = [];
  String? errorPorto;
  Map<String, dynamic> filters = {};

  static const int _itemsPerPage = 20;
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _scrollController.addListener(_onScroll);
    filters['nama_kategori'] = widget.nama_category;
    filters['id_kategori'] = widget.id_category;
    _showFilterOverlay = widget.autoOpenFilter;

    Future.microtask(() => loadData());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_isLoadingMore &&
        _hasMoreData &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 400) {
      loadData(loadMore: true);
    }
  }

  int? parseNumber(dynamic value) {
    if (value == null) return null;
    final str =
        value.toString().trim().replaceAll('.', '').replaceAll(',', '.');
    return int.tryParse(str);
  }

  Future<void> loadData({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || !_hasMoreData) return;
      setState(() => _isLoadingMore = true);
    } else {
      _fadeController.reset();
      setState(() {
        isLoadingPorto = true;
        errorPorto = null;
      });
    }

    try {
      final pList = await PortofolioService().getAll(
        status: 'aktif',
        untuk_keperluan: 'search',
        noId: filters['no_id'],
        id_customer: filters['id_customer'],
        idVendor: filters['id_vendor'],
        username: filters['username_vendor'],
        idKategori: filters['id_kategori'],
        hargaPaketMin: parseNumber(filters['min_price']),
        hargaPaketMax: parseNumber(filters['max_price']),
        kota: filters['id_lokasi'],
      );

      if (loadMore) {
        setState(() {
          portofolioList.addAll(pList);
          _hasMoreData = pList.length >= _itemsPerPage;
          _currentPage++;
        });
      } else {
        setState(() => portofolioList = pList);
        _fadeController.forward();
      }

      _precacheImages();
    } catch (e) {
      setState(() => errorPorto = 'Gagal memuat portofolio');
    } finally {
      setState(() {
        isLoadingPorto = false;
        _isLoadingMore = false;
      });
    }
  }

  void _precacheImages() {
    for (final porto in portofolioList.take(12)) {
      if (porto.mediaUrls.isNotEmpty) {
        final url = porto.mediaUrls[0].idMedia;
        if (url != null && url.isNotEmpty) {
          precacheImage(CachedNetworkImageProvider(url), context)
              .catchError((_) {});
        }
      }
    }
  }

  Future<void> _doRefresh() async {
    HapticFeedback.lightImpact();
    _currentPage = 1;
    _hasMoreData = true;
    await loadData();
  }

  Future<void> applyFilter(Map<String, String?> newFilters) async {
    setState(() => _showFilterOverlay = false);
    filters = newFilters;
    _currentPage = 1;
    _hasMoreData = true;
    await loadData();
  }

  bool get _hasActiveFilters =>
      filters['id_vendor'] != null ||
      filters['id_lokasi'] != null ||
      filters['min_price'] != null ||
      filters['max_price'] != null;

  String get _categoryLabel {
    final n = filters['nama_kategori']?.toString().trim() ?? '';
    return n.isEmpty ? 'Semua Kategori' : n;
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _doRefresh,
              color: Constants.primaryColor,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  // Search bar
                  _buildSearchBar(),

                  // Header row
                  _buildHeaderRow(),

                  // Content body — satu widget, kondisi di dalam
                  _buildContentBody(),

                  // Load more indicator
                  if (_isLoadingMore)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Constants.primaryColor,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),

          // Filter overlay
          if (_showFilterOverlay)
            Positioned.fill(
              child: FilterOverlay(
                selectedCategory: filters['id_kategori'] ?? '',
                selectedLocation: filters['id_lokasi'] ?? '',
                selectedPhotographer: filters['id_vendor'] ?? '',
                usernamePhotographer: filters['username_vendor'] ?? '',
                minPrice: (filters['min_price'] ?? '').toString(),
                maxPrice: (filters['max_price'] ?? '').toString(),
                onApply: (f) async => applyFilter(f),
                onReset: (_) async => applyFilter({}),
                onClose: () => setState(() => _showFilterOverlay = false),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SEARCH BAR
  // ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _showFilterOverlay = true);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hasActiveFilters
                  ? Constants.primaryColor
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.055),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(
                Icons.search_rounded,
                size: 19,
                color: _hasActiveFilters
                    ? Constants.primaryColor
                    : Colors.grey.shade400,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _hasActiveFilters
                      ? 'Filter diterapkan'
                      : 'Cari fotografer, kategori...',
                  style: TextStyle(
                    fontSize: 14,
                    color: _hasActiveFilters
                        ? Colors.black87
                        : Colors.grey.shade400,
                    fontWeight:
                        _hasActiveFilters ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              if (_hasActiveFilters)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Constants.primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Aktif',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _hasActiveFilters
                      ? Constants.primaryColor.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 17,
                  color: _hasActiveFilters
                      ? Constants.primaryColor
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HEADER ROW
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Constants.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_camera_outlined,
                    size: 11, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  _categoryLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isLoadingPorto && portofolioList.isNotEmpty)
            Text(
              '${portofolioList.length} hasil',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          const Spacer(),
          if (_hasActiveFilters)
            GestureDetector(
              onTap: () => applyFilter({}),
              child: Row(
                children: [
                  Icon(Icons.close_rounded,
                      size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 2),
                  Text(
                    'Reset',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CONTENT BODY — satu method untuk semua kondisi
  // Semua kondisi (loading/error/empty/grid) dibungkus di sini
  // agar slivers[] selalu punya index yang stabil
  // ─────────────────────────────────────────────────────────────

  Widget _buildContentBody() {
    if (isLoadingPorto) {
      return _buildShimmerInline();
    }
    if (errorPorto != null) {
      return _buildErrorInline();
    }
    if (portofolioList.isEmpty) {
      return _buildEmptyInline();
    }
    return _buildGridInline();
  }

  // ─────────────────────────────────────────────────────────────
  // GRID INLINE — GridView biasa (bukan Sliver), di dalam
  // SliverToBoxAdapter agar index stabil
  // ─────────────────────────────────────────────────────────────

  Widget _buildGridInline() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: portofolioList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (ctx, i) {
            final porto = portofolioList[i];
            return _PortoCard(
              porto: porto,
              onTap: () {
                HapticFeedback.selectionClick();
                ctx.read<PortofolioProvider>().setSelectedPortofolio(porto);
                ctx.read<NavigationProvider>().navigateToPage(
                      ctx,
                      const SinglePostPage(),
                      targetTabIndex: 0,
                      targetPage: 'SinglePostPage',
                    );
              },
              onVendorTap: () {
                ctx.read<NavigationProvider>().navigateToPage(
                      ctx,
                      VendorBioPage(idVendor: porto.idVendor),
                      targetTabIndex: 0,
                      targetPage: 'VendorBioPage',
                    );
              },
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SHIMMER INLINE
  // ─────────────────────────────────────────────────────────────

  Widget _buildShimmerInline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (_, __) => const _ShimmerCard(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // EMPTY INLINE
  // ─────────────────────────────────────────────────────────────

  Widget _buildEmptyInline() {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight * 0.55,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 36,
                  color: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum ada hasil',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coba ubah filter atau\ncari dengan kata kunci lain',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 26),
              GestureDetector(
                onTap: () => applyFilter({}),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded,
                          size: 14, color: Colors.black54),
                      SizedBox(width: 6),
                      Text(
                        'Reset Filter',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
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
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ERROR INLINE
  // ─────────────────────────────────────────────────────────────

  Widget _buildErrorInline() {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight * 0.55,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 46, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              errorPorto ?? 'Terjadi kesalahan',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _doRefresh,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PORTO CARD
//
// Struktur:
//   ┌─────────────────────┐
//   │                     │  AspectRatio 1:1 — gambar cover
//   │       Gambar        │
//   │  [multi badge]      │
//   └─────────────────────┘
//   │ ⬤ username    ›    │  footer ~52px
//   └─────────────────────┘
// ═══════════════════════════════════════════════════════════════

class _PortoCard extends StatelessWidget {
  final PortofolioModel porto;
  final VoidCallback onTap;
  final VoidCallback onVendorTap;

  const _PortoCard({
    required this.porto,
    required this.onTap,
    required this.onVendorTap,
  });

  String get _firstImageUrl =>
      porto.mediaUrls.isNotEmpty ? (porto.mediaUrls[0].idMedia ?? '') : '';

  bool get _hasMultiple => porto.mediaUrls.length > 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gambar — rasio ketat 1:1 ─────────────────────
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _firstImageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _firstImageUrl,
                          fit: BoxFit.cover,
                          maxWidthDiskCache: 600,
                          memCacheWidth: 400,
                          fadeInDuration: const Duration(milliseconds: 200),
                          placeholder: (_, __) => const _ImgShimmer(),
                          errorWidget: (_, __, ___) => _imgFallback(),
                        )
                      : _imgFallback(),

                  // Gradient bawah tipis untuk kedalaman
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.1),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Badge jumlah media
                  if (_hasMultiple)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.collections_rounded,
                                size: 10, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              '${porto.mediaUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Footer vendor ────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: onVendorTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      _Avatar(url: porto.idMediaVendor ?? ''),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              porto.usernameVendor ?? '-',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1C1C1C),
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (porto.namaKategori?.isNotEmpty == true)
                              Text(
                                porto.namaKategori!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  height: 1.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgFallback() => Container(
        color: Colors.grey.shade100,
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey.shade300,
          size: 28,
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// AVATAR
// ═══════════════════════════════════════════════════════════════

class _Avatar extends StatelessWidget {
  final String url;
  const _Avatar({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: Colors.grey.shade100,
        child: Icon(Icons.person, size: 13, color: Colors.grey.shade400),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (_, img) => CircleAvatar(radius: 14, backgroundImage: img),
      maxWidthDiskCache: 80,
      memCacheWidth: 56,
      placeholder: (_, __) =>
          CircleAvatar(radius: 14, backgroundColor: Colors.grey.shade100),
      errorWidget: (_, __, ___) => CircleAvatar(
        radius: 14,
        backgroundColor: Colors.grey.shade100,
        child: Icon(Icons.person, size: 13, color: Colors.grey.shade400),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// IMAGE SHIMMER
// ═══════════════════════════════════════════════════════════════

class _ImgShimmer extends StatelessWidget {
  const _ImgShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(color: Colors.white),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SHIMMER CARD (loading skeleton)
// ═══════════════════════════════════════════════════════════════

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            // Gambar skeleton — 1:1
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
              ),
            ),
            // Footer skeleton
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            height: 9,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
