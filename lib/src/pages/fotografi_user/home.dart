

import 'package:flutter/material.dart';
import 'package:mpjnew/src/pages/fotografi_user/services/kategori_service.dart';
import 'package:mpjnew/src/pages/fotografi_user/services/portofolio_service.dart';

import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/constants.dart';
import '../providers/navigation_provider.dart';
import 'providers/user_provider.dart';
import 'models/portofolio_model.dart';
import 'models/kategori_model.dart';
import 'searchpage.dart';
import 'fotographerbio.dart';
import 'singlepage.dart';

class EcommerceHome extends StatefulWidget {
  const EcommerceHome({super.key});

  @override
  _EcommerceHomeState createState() => _EcommerceHomeState();
}

class _EcommerceHomeState extends State<EcommerceHome> {
  final ScrollController _scrollController = ScrollController();
  bool isScrolled = false;
  bool showAllKategori = false;
  bool firstBuild = true;
 

  // State lokal
  bool isLoadingPorto = true;
  bool isLoadingKategori = true;
  List<PortofolioModel> portofolioList = [];
  List<KategoriModel> kategoriList = [];
  String? errorPorto;
  String? errorKategori;

  Future<void> _doRefresh() async {
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    await loadData(); // ✅ Langsung refresh dari service
  }

  Future<void> _loadCustomerId() async {
    await context.read<UserProvider>().checkLoginGoogle(role: 'customer', silent: true);
    final userId = context.read<UserProvider>().userId;
    print("==== LOADED USER ID: $userId");
  }

  Future<void> loadData() async {
    setState(() {
      isLoadingPorto = true;
      isLoadingKategori = true;
      errorPorto = null;
      errorKategori = null;
    });

    final userId = context.read<UserProvider>().role == 'customer'
        ? context.read<UserProvider>().userId
        : null;

    try {
      final pList = await PortofolioService().getAll(
        id_customer: userId,
        status: 'aktif',
      );
      setState(() => portofolioList = pList);
    } catch (e) {
      setState(() => errorPorto = 'Error memuat portofolio');
    } finally {
      setState(() => isLoadingPorto = false);
    }

    try {
      final kList = await KategoriService().getAll(status: 'aktif');
      setState(() => kategoriList = kList);
    } catch (e) {
      setState(() => errorKategori = 'Error memuat kategori');
    } finally {
      setState(() => isLoadingKategori = false);
    }
  }

  @override
  void initState() {
    super.initState();

    _loadCustomerId(); // silent login Google untuk customer
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      loadData(); // ✅ ganti dari provider ke service langsung
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!firstBuild) {
      loadData(); // ✅ aman dipanggil lagi setelah build
    }
    firstBuild = false;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more di sini kalau pakai pagination
    }
  }



  Widget _shimmerPlaceholder(
      {double? width, double? height, double radius = 0}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget buildCategory(
    String imageUrl,
    String label,
    int bgColor,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: 68,
      height: 110,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Color(bgColor),
              radius: 28,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // border: Border.all(
                  //   color:
                  //       Constants.primaryColor, // Ganti warna sesuai kebutuhan
                  //   width: 1, // Atur ketebalan border
                  // ),
                ),
                child: ClipOval(
                  child: Stack(
                    children: [
                      _shimmerPlaceholder(width: 56, height: 56, radius: 28),
                      Image.network(
                        imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(); // Biarkan shimmer tetap tampil
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                              child:
                                  Icon(Icons.broken_image_outlined, size: 28));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
           
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  
Widget buildKategoriSection(List<KategoriModel> kategoriList) {
  const int maxPerRow = 4;
  final screenWidth = MediaQuery.of(context).size.width;
  final itemWidth = (screenWidth - 16 - (8.0 * (maxPerRow - 1))) / maxPerRow;

  if (showAllKategori) {
    // Bagi ke dalam baris-baris berdasarkan maxPerRow
    List<List<KategoriModel>> rows = [];

    for (int i = 0; i < kategoriList.length;) {
      final remaining = kategoriList.length - i;

      if (remaining == maxPerRow + 1) {
        // Kalau sisa 5 (misal maxPerRow = 4), buat 3 + 2
        rows.add(kategoriList.sublist(i, i + 3));
        rows.add(kategoriList.sublist(i + 3, i + 5));
        i += 5;
      } else {
        final take = remaining >= maxPerRow ? maxPerRow : remaining;
        rows.add(kategoriList.sublist(i, i + take));
        i += take;
      }
    }

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((kategori) {
              final String imgUrl = kategori.id_media;
              return SizedBox(
                width: itemWidth,
                child: buildCategory(
                  imgUrl,
                  kategori.nama_kategori,
                  0xFFE0E0E0,
                  () {
                    context.read<NavigationProvider>().navigateToPage(
                          context,
                          SearchPage(
                            category: kategori.nama_kategori,
                            search: "",
                          ),
                          targetTabIndex: 0,
                          targetPage: "SearchPage",
                          hrsLogin: false,
                        );
                  },
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  } else {
    final limitedKategori = kategoriList.take(maxPerRow).toList();
    return SizedBox(
      height: 110, // Atur tinggi sesuai desain
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: limitedKategori.map((kategori) {
          final String imgUrl = kategori.id_media;
          return SizedBox(
            width: itemWidth,
            child: buildCategory(
              imgUrl,
              kategori.nama_kategori,
              0xFFE0E0E0,
              () {
                context.read<NavigationProvider>().navigateToPage(
                      context,
                      SearchPage(
                        category: kategori.nama_kategori,
                        search: "",
                      ),
                      targetTabIndex: 0,
                      targetPage: "SearchPage",
                      hrsLogin: false,
                    );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}


Widget buildPhotographerCard(
  BuildContext context,
  String photographerIcon,
  String? imageUrl,
  String name,
  double rating, {
  double aspectRatio = 5 / 4,
  required String noId,
  required String idVendor,
}) {
  final nav = context.read<NavigationProvider>();
  final bool isImageValid = imageUrl != null && imageUrl.trim().isNotEmpty;
  final bool isAvatarValid = photographerIcon.trim().isNotEmpty;

  return Container(
    margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => nav.navigateToPage(
            context,
            SinglePostPage(noId: noId),
            targetTabIndex: 0,
            targetPage: 'SinglePostPage',
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: isImageValid
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _shimmerPlaceholder(radius: 15);
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined, size: 40),
                      ),
                    )
                  : _shimmerPlaceholder(radius: 15),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => nav.navigateToPage(
            context,
            PhotographerBio(idVendor: idVendor),
            targetTabIndex: 0,
            targetPage: 'PhotographerBio',
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: isAvatarValid
                        ? Image.network(
                            photographerIcon,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.person, size: 16),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _shimmerPlaceholder(radius: 16);
                            },
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.person, size: 16),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (rating > 0) ...[
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    rating.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}




@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF9F9F9),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _doRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ===================== HEADER FILTER/SEARCH =====================
            SliverPersistentHeader(
              pinned: true,
              delegate: SliverHeaderDelegate(
                child: Container(
                  color: const Color(0xFFF9F9F9),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    context.read<NavigationProvider>().navigateToPage(
                                      context,
                                      SearchPage(
                                        category: "",
                                        search: "",
                                        autoOpenFilter: true,
                                      ),
                                      targetTabIndex: 0,
                                      hrsLogin: false,
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isScrolled ? Constants.primaryColor : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Constants.primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Cari Fotografer",
                                          style: TextStyle(
                                            color: isScrolled ? Colors.white : Constants.primaryColor,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.search,
                                          color: isScrolled ? Colors.white : Constants.primaryColor,
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

            // ===================== KATEGORI DINAMIS =====================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Kategori Populer",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() => showAllKategori = !showAllKategori);
                          },
                          child: Text(
                            showAllKategori ? "Lebih Sedikit" : "Lihat Semua",
                            style: TextStyle(color: Constants.primaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (isLoadingKategori)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          4,
                          (i) => _shimmerPlaceholder(width: 56, height: 56, radius: 28),
                        ),
                      )
                    else if (errorKategori != null)
                      Center(child: Text("Error: $errorKategori"))
                    else if (kategoriList.isEmpty)
                      const Center(child: Text("Kategori belum tersedia"))
                    else
                      buildKategoriSection(kategoriList),

                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Jelajah",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        GestureDetector(
                          onTap: () {
                            // setState(() => showAllKategori = !showAllKategori);
                          },
                          child: Text(
                            "Lihat Semua",
                            style: TextStyle(color: Constants.primaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ===================== DAFTAR PORTOFOLIO =====================
            if (isLoadingPorto)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorPorto != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $errorPorto'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _doRefresh,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
            else if (portofolioList.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('Belum ada portofolio')),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < portofolioList.length) {
                      final p = portofolioList[index];
                      final List<MediaItem> mediaList = p.mediaUrls ?? [];
                      final firstMedia = mediaList.isNotEmpty ? mediaList.first : null;
                      final isVideo = (firstMedia?.contentType ?? '').startsWith('video');
                      final String? mediaUrl =
                          isVideo ? (firstMedia?.thumbUrl ?? firstMedia?.url) : firstMedia?.url;

                      return buildPhotographerCard(
                        context,
                        p.idMediaVendor,
                        mediaUrl,
                        p.usernameVendor,
                        p.ratingVendor,
                        noId: p.noId,
                        idVendor: p.idVendor,
                      );
                    } else {
                      return const SizedBox(); // no pagination yet
                    }
                  },
                  childCount: portofolioList.length,
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _doRefresh,
      tooltip: 'Refresh',
      backgroundColor: Constants.primaryColor,
      child: const Icon(Icons.refresh, color: Colors.white),
    ),
  );
}
}

// --- SliverHeaderDelegate definition ---
class SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  SliverHeaderDelegate({required this.child});
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 64.0 + 15;
  @override
  double get minExtent => 64.0 + 15;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
