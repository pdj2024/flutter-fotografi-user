import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/kategori_provider.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/portofolio_provider.dart';
import 'package:mpjnew/src/pages/fotografi_user/models/kategori_model.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/vendor_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/constants.dart';
import 'singlepage.dart';
import 'user_login.dart';
import 'filter_overlay.dart';
import 'fotographerbio.dart';
import '../providers/navigation_provider.dart';

// class ProfilePage extends StatelessWidget {
//   final String photographerName;
//   const ProfilePage({super.key, required this.photographerName});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(photographerName)),
//       body: Center(child: Text('Welcome to $photographerName\'s profile!')),
//     );
//   }
// }

class SearchPage extends StatefulWidget {
  final String category;
  final String search;
  final bool autoOpenFilter;

  const SearchPage({
    super.key,
    required this.category,
    required this.search,
    this.autoOpenFilter = false,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool isScrolled = false;

  bool isLoggedIn = false;

  final List<Map<String, String>> photographers = [
    {
      'image':
          'a8701826-810b-467e-8fe4-222e10d4bc0b-image_cropper_1748676050844.jpg',
      'name': 'michaelwilliams',
      'avatar':
          '14eac222-0e59-446b-be37-60b222800f5d-image_cropper_1748677848826.jpg'
    },
    {
      'image':
          'd1ef0fe8-7233-46e7-a69f-33a1d0e39dad-image_cropper_1748676063147.jpg',
      'name': 'emilybphotos',
      'avatar':
          '1d98c486-b810-42d8-8779-3b0ca34154ef-image_cropper_1748677884447.jpg'
    },
    {
      'image':
          '380bf81d-0666-4ac7-a08c-8146592ff86e-image_cropper_1748676098660.jpg',
      'name': 'davismiller',
      'avatar':
          '65868b74-ef32-4388-a6e9-c87b86f6541f-image_cropper_1748677941144.jpg'
    },
    {
      'image':
          'a3640fb0-0ba0-4996-a31c-3d2eff590f75-image_cropper_1748676026618.jpg',
      'name': 'amandareedphoto',
      'avatar':
          '355c5d9f-0e1b-4c8f-a715-c388b9d2e21d-image_cropper_1748677911014.jpg'
    },
    {
      'image':
          '0ae49083-2adc-49ed-b08f-c5f22d65bba6-image_cropper_1748676084421.jpg',
      'name': 'sarahleephoto',
      'avatar':
          '175a09b7-bd6e-4b0b-b74c-d06d94d8683e-image_cropper_1748677929955.jpg'
    },
    {
      'image':
          'd9aa9b4b-3d2c-4c15-8888-f2626a11ed19-image_cropper_1748676073533.jpg',
      'name': 'runitadiah',
      'avatar':
          '34442862-aa5d-4e74-8129-43104eb79aa7-image_cropper_1748677842439.jpg'
    },
    {
      'image':
          '1ff6f9ce-c218-4874-9209-734f11e954cb-image_cropper_1748676012077.jpg',
      'name': 'bridalphotos',
      'avatar':
          '16a113e9-a9b3-4590-92a0-979ec358f4a1-image_cropper_1748677918469.jpg'
    },
    {
      'image':
          '6e1fe938-2189-4826-b4c5-d851e3e071ab-image_cropper_1748676001756.jpg',
      'name': 'nikital',
      'avatar':
          'd00c8632-393e-49e8-847f-3c01a4dbf701-image_cropper_1748677823909.jpg'
    },
  ];

  List<String> _filteredSuggestions = [];
  bool _showSuggestions = false;
  bool _showFilterOverlay = false;
  final double _searchBarHeight = 64.0;

  Map<String, dynamic> appliedFilters = {};
  Map<String, dynamic> tempFilters = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<KategoriProvider>().getAll();
      await context.read<VendorProvider>().getAll();

      // Ambil kategori List
      final kategoriList = context.read<KategoriProvider>().kategoriList;

      // Jika ada kategori yang dipilih dari widget.category, filter langsung
      if (widget.category.isNotEmpty) {
        // Ubah kategori ke ID kategori (jika perlu)
        String idKategori = '';
        try {
          final found = kategoriList.firstWhere(
              (k) => k.nama_kategori == widget.category,
              orElse: () => KategoriModel(
                  no_id: 'kategori_1', nama_kategori: '', status: "false", id_media: "media_30"));
          if (found.no_id != 0) idKategori = found.no_id.toString();
        } catch (_) {}

        if (idKategori.isNotEmpty) {
          await context.read<PortofolioProvider>().getAll(
             );
          appliedFilters['category'] = widget.category;
        } else {
          // fallback, tampilkan semua jika idKategori tidak ditemukan
          await context.read<PortofolioProvider>().getAll();
        }
      } else {
        // Jika tidak ada kategori, tampilkan semua
        await context.read<PortofolioProvider>().getAll();
      }

      if (widget.autoOpenFilter) {
        tempFilters = Map<String, dynamic>.from(appliedFilters);
        setState(() {
          _showFilterOverlay = true;
        });
      }
    });
    _scrollController.addListener(_onScroll);
  }

  Future<void> _doRefresh() async {
    final kategoriProvider = context.read<KategoriProvider>();
    final vendorProvider = context.read<VendorProvider>();
    final portofolioProvider = context.read<PortofolioProvider>();

    await kategoriProvider.getAll();
    await vendorProvider.getAll();

    // Ambil kategori List
    final kategoriList = kategoriProvider.kategoriList;

    // Ulangi filter sesuai kategori yang aktif (seperti di initState)
    if ((appliedFilters['category'] ?? widget.category).toString().isNotEmpty) {
      // Ubah kategori ke ID kategori (jika perlu)
      String categoryName = appliedFilters['category'] ?? widget.category;
      String idKategori = '';
      try {
        final found = kategoriList.firstWhere(
            (k) => k.nama_kategori == categoryName,
            orElse: () => KategoriModel(
                no_id: 'kategori_1', nama_kategori: '', status: 'nonaktif', id_media: 'media_30'));
        if (found.no_id != 0) idKategori = found.no_id.toString();
      } catch (_) {}
      if (idKategori.isNotEmpty) {
        await portofolioProvider
            .getAll();
      } else {
        await portofolioProvider.getAll();
      }
    } else {
      await portofolioProvider.getAll();
    }
  }

  String kategoriNameFromId(int idKategori, List<KategoriModel> kategoriList) {
    final found = kategoriList.firstWhere(
      (k) => k.no_id == idKategori,
      orElse: () =>
          KategoriModel(no_id: 'kategori_1', nama_kategori: '', status: 'nonaktif', id_media: 'media_28'),
    );
    return found.nama_kategori;
  }

  String idKategoriFromName(String nama, List<KategoriModel> kategoriList) {
    final found = kategoriList.firstWhere(
      (k) => k.nama_kategori == nama,
      orElse: () =>
          KategoriModel(no_id: 'kategori_1', nama_kategori: '', status: 'nonaktif', id_media: 'media_30'),
    );
    return found.no_id.toString();
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

  void _onSearchChanged() {
    String query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
      });
    } else {
      setState(() {
        // _filteredSuggestions = photographers
        //     .where((p) => p['name']!.toLowerCase().contains(query))
        //     .map((p) => p['name']!)
        //     .toSet()
        //     .toList();
        // _showSuggestions = true;

        // This search is only for suggestions, not for the main list
        _filteredSuggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _submitSearch() {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    context.read<NavigationProvider>().navigateToPage(
          context,
          SearchPage(
            category: widget.category,
            search: keyword,
          ),
          targetTabIndex: 0,
        );
  }

  void openFilterOverlay() {
    tempFilters = Map<String, dynamic>.from(appliedFilters);
    setState(() {
      _showFilterOverlay = true;
    });
  }

  Future<void> applyFilter(Map<String, String?> filters) async {
    appliedFilters = filters;
    setState(() {
      _showFilterOverlay = false;
    });
    final kategoriProvider = context.read<KategoriProvider>();
    final kategoriList = kategoriProvider.kategoriList;
    final filterParams = <String, String>{};
    if (filters['category'] != null && filters['category']!.isNotEmpty) {
      filterParams['id_kategori'] =
          idKategoriFromName(filters['category']!, kategoriList);
    }
    if (filters['location'] != null && filters['location']!.isNotEmpty) {
      filterParams['kota'] = filters['location']!;
    }
    if (filters['photographer'] != null &&
        filters['photographer']!.isNotEmpty) {
      filterParams['username_vendor'] = filters['photographer']!;
    }
    if (filters['minPrice'] != null && filters['minPrice']!.isNotEmpty) {
      filterParams['harga_min'] = filters['minPrice']!;
    }
    if (filters['maxPrice'] != null && filters['maxPrice']!.isNotEmpty) {
      filterParams['harga_max'] = filters['maxPrice']!;
    }
    await context
        .read<PortofolioProvider>()
        .getAll();
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

  Widget buildPhotographerItem(
    String imagePath,
    String name,
    String avatar,
    String noId,
    String idVendor,
  ) {
    final imgUrl = '$imagePath';
    // final String imgUrl =
    //     context.read<NavigationProvider>().ambilGambar(imagePath);
    final String imgAvatarUrl =
        context.read<NavigationProvider>().ambilGambar(avatar);

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
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portofolioProvider = context.watch<PortofolioProvider>();
    final kategoriProvider = context.watch<KategoriProvider>();
    final vendorProvider = context.watch<VendorProvider>();

    final portofolios = portofolioProvider.portofolioList;
    final kategoriList = kategoriProvider.kategoriList;
    final vendorList = vendorProvider.vendorList;

// KATEGORI & KOTA dari semua vendor
    // final categories = kategoriList.map((v) => v.nama_kategori).toList();
    // final locations = vendorList.map((v) => v.kota).toList();

    // Fotografer dari portofolio yang sedang tampil
    final photographers = portofolios
        .map((e) => {
              'name': e.usernameVendor,
              'avatar': e.idMediaVendor.toString(),
              'image': e.idMedia.toString(),
              'noId': e.noId.toString(),
              'idVendor': e.idVendor.toString(),
              'kota': e.kota,
              'rating': e.ratingVendor.toString(),
            })
        .toList();
   

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
                                  text: (appliedFilters['category'] ?? '')
                                          .isNotEmpty
                                      ? appliedFilters['category']
                                      : (widget.category.isNotEmpty
                                          ? widget.category
                                          : 'Semua'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          portofolioProvider.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : portofolios.isEmpty
                                  ? const Center(child: Text('Tidak ada hasil'))
                                  : ListView(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      children: List.generate(
                                        (photographers.length + 1) ~/ 2,
                                        (index) {
                                          final firstPhotographer =
                                              photographers[index * 2];
                                          final secondPhotographer =
                                              (index * 2 + 1 <
                                                      photographers.length)
                                                  ? photographers[index * 2 + 1]
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
                                                        buildPhotographerItem(
                                                      firstPhotographer[
                                                          'image']!,
                                                      firstPhotographer[
                                                          'name']!,
                                                      firstPhotographer[
                                                          'avatar']!,
                                                     
                                                          firstPhotographer[
                                                              'noId']!,
                                                     
                                                          firstPhotographer[
                                                              'idVendor']!,
                                                    ),
                                                  ),
                                                ),
                                                if (secondPhotographer != null)
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 4.0),
                                                      child:
                                                          buildPhotographerItem(
                                                        secondPhotographer[
                                                            'image']!,
                                                        secondPhotographer[
                                                            'name']!,
                                                        secondPhotographer[
                                                            'avatar']!,
                                                       
                                                            secondPhotographer[
                                                                'noId']!,
                                                      
                                                            secondPhotographer[
                                                                'idVendor']!,
                                                      ),
                                                    ),
                                                  ),
                                                if (secondPhotographer == null)
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
                   
                    selectedCategory: tempFilters['category'] ?? '',
                    selectedLocation: tempFilters['location'] ?? '',
                    selectedPhotographer: tempFilters['photographer'] ?? '',
                    minPrice: (tempFilters['minPrice'] ?? '').toString(),
                    maxPrice: (tempFilters['maxPrice'] ?? '').toString(),
                    onApply: (newFilters) async =>
                        await applyFilter(newFilters),
                    onReset: (newFilters) async => await applyFilter({}),
                    onClose: () => setState(() => _showFilterOverlay = false),
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