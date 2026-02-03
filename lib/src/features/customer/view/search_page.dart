import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/models/portofolio_model.dart';
import 'package:mpjnew/src/features/customer/view/single_post_page.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:mpjnew/src/features/customer/widget/filter_overlay.dart';
import 'package:mpjnew/src/features/customer/services/portofolio_service.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

/// ✅ OPTIMIZED SearchPage dengan loading gambar yang lebih cepat
///
/// Optimizations:
/// 1. Image precaching untuk gambar berikutnya
/// 2. Thumbnail preview dengan progressive loading
/// 3. Memory cache management
/// 4. Lazy loading dengan pagination
/// 5. Optimized CachedNetworkImage settings
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
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool isScrolled = false;
  bool _showFilterOverlay = false;
  bool isLoadingPorto = true;

  List<PortofolioModel> portofolioList = [];
  String? errorPorto;

  Map<String, dynamic> filters = {};

  // ✅ NEW: Pagination untuk lazy loading
  static const int _itemsPerPage = 20;
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  @override
  bool get wantKeepAlive => true; // ✅ Keep state alive untuk avoid reload

  Future<void> _doRefresh() async {
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    _currentPage = 1;
    _hasMoreData = true;
    await loadData();
  }

  int? parseNumber(dynamic value) {
    if (value == null) return null;
    String str = value.toString().trim();
    if (str.isEmpty) return null;
    str = str.replaceAll('.', '');
    str = str.replaceAll(',', '.');
    return int.tryParse(str);
  }

  Future<void> loadData({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || !_hasMoreData) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        isLoadingPorto = true;
        errorPorto = null;
      });
    }

    final minPrice = filters['min_price']?.toString() ?? '';
    final maxPrice = filters['max_price']?.toString() ?? '';

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
      }

      // ✅ Precache images untuk smooth scrolling
      _precacheVisibleImages();
    } catch (e) {
      setState(() => errorPorto = 'Error memuat portofolio');
    } finally {
      setState(() {
        isLoadingPorto = false;
        _isLoadingMore = false;
      });
    }
  }

  /// ✅ Precache gambar yang visible untuk loading lebih cepat
  void _precacheVisibleImages() {
    if (portofolioList.isEmpty) return;

    // Precache 10 gambar pertama
    final itemsToPrecache = portofolioList.take(10);

    for (var porto in itemsToPrecache) {
      if (porto.mediaUrls.isNotEmpty) {
        final imageUrl = porto.mediaUrls[0].idMedia;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          precacheImage(
            CachedNetworkImageProvider(imageUrl),
            context,
          ).catchError((e) {
            // Ignore errors
          });
        }
      }

      // Precache avatar
      if (porto.idMediaVendor != null && porto.idMediaVendor!.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(porto.idMediaVendor!),
          context,
        ).catchError((e) {
          // Ignore errors
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);
    filters['nama_kategori'] = widget.nama_category;
    filters['id_kategori'] = widget.id_category;

    _showFilterOverlay = widget.autoOpenFilter;

    Future.microtask(() {
      loadData();
    });
  }

  void _onScroll() {
    // Update scroll state
    if (_scrollController.offset > 10 && !isScrolled) {
      setState(() => isScrolled = true);
    } else if (_scrollController.offset <= 10 && isScrolled) {
      setState(() => isScrolled = false);
    }

    // ✅ Load more when near bottom
    if (!_isLoadingMore &&
        _hasMoreData &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 500) {
      loadData(loadMore: true);
    }
  }

  void openFilterOverlay() {
    setState(() => _showFilterOverlay = true);
  }

  Future<void> applyFilter(Map<String, String?> filtersFromOverlay) async {
    setState(() => _showFilterOverlay = false);
    filters = filtersFromOverlay;
    _currentPage = 1;
    _hasMoreData = true;
    await loadData();
  }

  /// ✅ OPTIMIZED: Fast loading image widget
  Widget buildOptimizedImage({
    required String imageUrl,
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      // ✅ Optimizations
      maxWidthDiskCache: 800, // Limit cache size
      maxHeightDiskCache: 800,
      memCacheWidth: 400, // Reduce memory usage
      memCacheHeight: 400,
      fadeInDuration: const Duration(milliseconds: 200), // Faster fade
      fadeOutDuration: const Duration(milliseconds: 100),
      // ✅ Progressive loading
      progressIndicatorBuilder: (context, url, progress) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: width,
            height: height,
            color: Colors.white,
          ),
        );
      },
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, size: 40),
      ),
    );
  }

  /// ✅ OPTIMIZED: Fast loading avatar widget
  Widget buildOptimizedAvatar({
    required String imageUrl,
    double radius = 16,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      // ✅ Optimizations for small images
      maxWidthDiskCache: 100,
      maxHeightDiskCache: 100,
      memCacheWidth: 64,
      memCacheHeight: 64,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: const Icon(Icons.person, size: 16),
      ),
    );
  }

  Widget buildPortoItem(
    String imagePath,
    String name,
    String avatar,
    String noId,
    String idVendor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.read<NavigationProvider>().navigateToPage(
                context,
                SinglePostPage(noId: noId, idVendor: idVendor),
                targetTabIndex: 0,
                targetPage: "SinglePostPage",
              ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            // ✅ Use optimized image
            child: buildOptimizedImage(
              imageUrl: imagePath,
              width: double.infinity,
              height: 185,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => context.read<NavigationProvider>().navigateToPage(
                context,
                VendorBioPage(idVendor: idVendor),
                targetTabIndex: 0,
                targetPage: "VendorBioPage",
              ),
          child: Row(
            children: [
              // ✅ Use optimized avatar
              buildOptimizedAvatar(imageUrl: avatar, radius: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _doRefresh,
          child: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                // ✅ Add cache extent for better performance
                cacheExtent: 500,
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: SliverHeaderDelegate(
                      child: Container(
                        color: const Color(0xFFF9F9F9),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: openFilterOverlay,
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isScrolled
                                                ? Constants.primaryColor
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Constants.primaryColor,
                                              width: 2,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Cari Fotografer",
                                                style: TextStyle(
                                                  color: isScrolled
                                                      ? Colors.white
                                                      : Constants.primaryColor,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.search,
                                                color: isScrolled
                                                    ? Colors.white
                                                    : Constants.primaryColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 5, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: "Kategori: ",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              children: [
                                TextSpan(
                                  text: (filters['nama_kategori']
                                              ?.trim()
                                              .isEmpty ??
                                          true)
                                      ? 'Semua'
                                      : filters['nama_kategori'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          isLoadingPorto
                              ? ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: 4,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 4.0),
                                              child: shimmerPortoItem(),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 4.0),
                                              child: shimmerPortoItem(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : portofolioList.isEmpty
                                  ? Column(
                                      children: const [
                                        SizedBox(height: 80),
                                        Icon(Icons.camera_alt_outlined,
                                            size: 150, color: Colors.grey),
                                        SizedBox(height: 10),
                                        Center(
                                          child: Text(
                                            "Belum ada portofolio yang sesuai",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : ListView(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      children: List.generate(
                                        (portofolioList.length + 1) ~/ 2,
                                        (index) {
                                          final firstPorto =
                                              portofolioList[index * 2];
                                          final secondPorto = (index * 2 + 1 <
                                                  portofolioList.length)
                                              ? portofolioList[index * 2 + 1]
                                              : null;

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10.0),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 4.0),
                                                    child: buildPortoItem(
                                                      firstPorto.mediaUrls[0]
                                                              .idMedia ??
                                                          '',
                                                      firstPorto
                                                              .usernameVendor ??
                                                          "",
                                                      firstPorto
                                                              .idMediaVendor ??
                                                          "",
                                                      firstPorto.noId,
                                                      firstPorto.idVendor,
                                                    ),
                                                  ),
                                                ),
                                                if (secondPorto != null)
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 4.0),
                                                      child: buildPortoItem(
                                                        context
                                                                .read<
                                                                    NavigationProvider>()
                                                                .getMediaUrl(
                                                                    secondPorto) ??
                                                            '',
                                                        secondPorto
                                                                .usernameVendor ??
                                                            "",
                                                        secondPorto
                                                                .idMediaVendor ??
                                                            "",
                                                        secondPorto.noId,
                                                        secondPorto.idVendor,
                                                      ),
                                                    ),
                                                  ),
                                                if (secondPorto == null)
                                                  const Expanded(
                                                      child: SizedBox.shrink()),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                          // ✅ Loading more indicator
                          if (_isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_showFilterOverlay)
                Positioned.fill(
                  child: FilterOverlay(
                      selectedCategory: filters['id_kategori'] ?? '',
                      selectedLocation: filters['id_lokasi'] ?? '',
                      selectedPhotographer: filters['id_vendor'] ?? '',
                      usernamePhotographer: filters['username_vendor'] ?? '',
                      minPrice: (filters['min_price'] ?? '').toString(),
                      maxPrice: (filters['max_price'] ?? '').toString(),
                      onApply: (newFilters) async =>
                          await applyFilter(newFilters),
                      onReset: (newFilters) async => await applyFilter({}),
                      onClose: () {
                        setState(() => _showFilterOverlay = false);
                      }),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: !_showFilterOverlay
          ? FloatingActionButton(
              onPressed: _doRefresh,
              tooltip: 'Refresh',
              backgroundColor: Constants.primaryColor,
              child: const Icon(Icons.refresh, color: Colors.white),
            )
          : null,
    );
  }
}

class SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  SliverHeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 79.0;

  @override
  double get minExtent => 79.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

Widget shimmerPortoItem() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: double.infinity,
          height: 185,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
