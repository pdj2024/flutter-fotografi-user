import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/kategori_provider.dart';

import 'package:mpjnew/src/pages/fotografi_user/models/kategori_model.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/vendor_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/constants.dart';
import 'models/portofolio_model.dart';
import 'services/portofolio_service.dart';
import 'singlepage.dart';
import 'user_login.dart';
import 'filter_overlay.dart';
import 'fotographerbio.dart';
import '../providers/navigation_provider.dart';


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

class _SearchPageState extends State<SearchPage> {
  // final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isScrolled = false;

   bool _showFilterOverlay = false;
 
   bool isLoadingPorto = true;
  
  List<PortofolioModel> portofolioList = [];
   String? errorPorto;



 
 
  // final double _searchBarHeight = 64.0;

  Map<String, dynamic> filters = {};
  // Map<String, dynamic> tempFilters = {};
  //  List<String> _filteredSuggestions = [];
  // bool _showSuggestions = false;


 
  Future<void> _doRefresh() async {
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    await loadData(); // ✅ Langsung refresh dari service
  }

  int? parseNumber(dynamic value) {
  if (value == null) return null;

  // pastikan string
  String str = value.toString().trim();

  if (str.isEmpty) return null;

  // normalisasi format
  str = str.replaceAll('.', '');   // buang pemisah ribuan
  str = str.replaceAll(',', '.');  // koma jadi titik

  return int.tryParse(str);
}

  
  Future<void> loadData() async {
    setState(() {
      isLoadingPorto = true;
            errorPorto = null;
        });

     final minPrice = filters?['min_price']?.toString() ?? '';
final maxPrice = filters?['max_price']?.toString() ?? '';

print("======= LOAD DATA: MIN $minPrice");
print("======= LOAD DATA: MAX $maxPrice");

  
    try {
      final pList = await PortofolioService().getAll(
         status: 'aktif',
         untuk_keperluan: 'search',
        noId: filters?['no_id'],
        id_customer: filters?['id_customer'],
        idVendor: filters?['id_vendor'],
        username: filters?['username_vendor'],
        idKategori: filters?['id_kategori'],
         hargaPaketMin: parseNumber(filters?['min_price']),
          hargaPaketMax: parseNumber(filters?['max_price']),
           kota: filters?['id_lokasi']


      
      );
      setState(() => portofolioList = pList);
    } catch (e) {
      print("======= LOAD DATA: ERRORRRRR $e");
  
      setState(() => errorPorto = 'Error memuat portofolio');
    } finally {
      setState(() => isLoadingPorto = false);
    }

      }


  @override
  void initState() {
    super.initState();

      _scrollController.addListener(_onScroll);
      filters?['nama_kategori'] = widget.nama_category;
      filters?['id_kategori'] = widget.id_category;

      _showFilterOverlay = widget.autoOpenFilter;

    Future.microtask(() {
      loadData(); // ✅ ganti dari provider ke service langsung
    });
  }

  void _onScroll() {
    if (_scrollController.offset > 10 && !isScrolled) {
      setState(() {
        isScrolled = true;
      });
    } else if (_scrollController.offset <= 10 && isScrolled) {
      setState(() {
        isScrolled = false;
      });
    }
  }

  // void _onSearchChanged() {
  //   String query = _searchController.text.trim().toLowerCase();
  //   if (query.isEmpty) {
  //     setState(() {
  //       _showSuggestions = false;
  //     });
  //   } else {
  //     setState(() {
       

  //       // This search is only for suggestions, not for the main list
  //       _filteredSuggestions = [];
  //       _showSuggestions = false;
  //     });
  //   }
  // }

  // void _submitSearch() {
  //   final keyword = _searchController.text.trim();
  //   if (keyword.isEmpty) return;

  //   context.read<NavigationProvider>().navigateToPage(
  //         context,
  //         SearchPage(
  //           category: widget.category,
  //           search: keyword,
  //         ),
  //         targetTabIndex: 0,
  //       );
  // }

  void openFilterOverlay() {
    // tempFilters = Map<String, dynamic>.from(appliedFilters);
    setState(() {
      _showFilterOverlay = true;
    });
  }

  Future<void> applyFilter(Map<String, String?> filtersFromOverlay) async {
  
    setState(() {
      _showFilterOverlay = false;
    });
  
    filters = filtersFromOverlay;
    print("========== FROM OVERLAY: " + filters.toString());
     await loadData();
  }

  Widget buildPhotographerCard(
    BuildContext context,
    String photographerName,
    String imageUrl,
    String avatarUrl,
    String kategori,
    String kota,
    String noId,
    String idVendor,
    double rating,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.grey.withOpacity(0.1),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.read<NavigationProvider>().navigateToPage(
                  context,
                  SinglePostPage(noId: noId),
                  targetTabIndex: 0,
                  targetPage: "SinglePostPage",
                ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: AspectRatio(
                aspectRatio: 5 / 4,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined, size: 40),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.read<NavigationProvider>().navigateToPage(
                  context,
                  PhotographerBio(idVendor: idVendor),
                  targetTabIndex: 0,
                  targetPage: "PhotographerBio",
                ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    radius: 16,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: avatarUrl,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 32,
                            height: 32,
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.person, size: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      photographerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    rating.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    final imgUrl = '$imagePath';
    // final String imgUrl =
    //     context.read<NavigationProvider>().ambilGambar(imagePath);
    final String imgAvatarUrl = avatar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.read<NavigationProvider>().navigateToPage(
                context,
                SinglePostPage(
                  noId: noId,
                ),
                targetTabIndex: 0,
                targetPage: "SinglePostPage",
              ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imgUrl,
              width: double.infinity,
              height: 185,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 185,
                    color: Colors.white,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 185,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        size: 48, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => context.read<NavigationProvider>().navigateToPage(
                context,
                PhotographerBio(
                  idVendor: idVendor,
                ),
                targetTabIndex: 0,
                targetPage: "PhotographerBio",
              ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: ClipOval(
                  child: Image.network(
                    imgAvatarUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          color: Colors.white,
                          width: 32,
                          height: 32,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(Icons.error, size: 16),
                      );
                    },
                  ),
                ),
              ),
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
    // _searchController.dispose();
  
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   



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
                                  text: (filters['nama_kategori']?.trim().isEmpty ?? true) 
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
                              ? const Center(child: CircularProgressIndicator())
                              : portofolioList.isEmpty
                                  ? const Center(child: Text('Tidak ada hasil'))
                                  : ListView(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      children: List.generate(
                                        (portofolioList.length + 1) ~/ 2,
                                        (index) {
                                          final firstPorto =
                                              portofolioList[index * 2];
                                          final secondPorto =
                                              (index * 2 + 1 <
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
                                                    child:
                                                        buildPortoItem(
                                                      context.read<NavigationProvider>().getMediaUrl(firstPorto)  ?? '',
                                                      firstPorto.usernameVendor,
                                                      firstPorto.idMediaVendor,
                                                     
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
                                                      child:
                                                          buildPortoItem(
                                                        context.read<NavigationProvider>().getMediaUrl(secondPorto)  ?? '',
                                                      secondPorto.usernameVendor,
                                                      secondPorto.idMediaVendor,
                                                     
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
                    
                    } 
                  ),
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