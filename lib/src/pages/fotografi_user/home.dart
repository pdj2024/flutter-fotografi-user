

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/constants.dart';
import '../providers/navigation_provider.dart';
import 'providers/user_provider.dart';
import 'providers/portofolio_provider.dart';
import 'models/portofolio_model.dart';
import 'models/kategori_model.dart';
import 'providers/kategori_provider.dart';
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
  bool _showAllKategori = false;
  bool _firstBuild = true; // Tambahkan flag

  Future<void> _doRefresh() async {
  await _scrollController.animateTo(
    0,
    duration: const Duration(milliseconds: 400),
    curve: Curves.easeInOut,
  );

  final userProvider = context.read<UserProvider>();
  final idCustomer = userProvider.role == 'customer' ? userProvider.userId : null;

  await context.read<KategoriProvider>().getAll();
  await context.read<PortofolioProvider>().getAll(id_customer: idCustomer);
}

Future<void> _loadCustomerId() async {
  await context.read<UserProvider>().checkLoginGoogle(role: 'customer', silent: true);
  final userId = context.read<UserProvider>().userId;
  print("==== LOADED USER ID: $userId");
}

@override
void initState() {
  super.initState();

  _loadCustomerId(); // silent login Google untuk customer
  _scrollController.addListener(_onScroll);

  Future.microtask(() {
    final userProvider = context.read<UserProvider>();
    final idCustomer = userProvider.role == 'customer' ? userProvider.userId : null;

    context.read<KategoriProvider>().getAll();
    context.read<PortofolioProvider>().getAll(id_customer: idCustomer);
  });
}

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (!_firstBuild) {
    final userProvider = context.read<UserProvider>();
    final idCustomer = userProvider.role == 'customer' ? userProvider.userId : null;

    context.read<KategoriProvider>().getAll();
    context.read<PortofolioProvider>().getAll(id_customer: idCustomer);
  }
  _firstBuild = false;
}

@override
void dispose() {
  _scrollController.removeListener(_onScroll);
  _scrollController.dispose();
  super.dispose();
}

  void _onScroll() {
    final provider = context.read<PortofolioProvider>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // if (provider.hasMore && !provider.isLoadingMore) {
      //   provider.loadMore();
      // }
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
    if (_showAllKategori) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        children: kategoriList.map((kategori) {
          final String imgUrl =
              kategori.id_media;
          return SizedBox(
            width: (MediaQuery.of(context).size.width - 64) / 4,
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
      );
    } else {
      final limitedKategori = kategoriList.take(4).toList();
      return SizedBox(
        height: 110, // Atur tinggi sesuai kebutuhan
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: limitedKategori.map((kategori) {
            final String imgUrl =
                kategori.id_media;
            return buildCategory(
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
          onRefresh: () async {
            final userProvider = context.read<UserProvider>();
            final idCustomer = userProvider.role == 'customer' ? userProvider.userId : null;

            await context.read<KategoriProvider>().getAll();
            await context.read<PortofolioProvider>().getAll(id_customer: idCustomer);
          },
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
                                    onTap: () {
                                      context
                                          .read<NavigationProvider>()
                                          .navigateToPage(
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
                                      duration:
                                          const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isScrolled
                                            ? Constants.primaryColor
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
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
              // ===================== KATEGORI DINAMIS =====================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                     
                      const SizedBox(height: 16),
                      const Text(
                        "Kategori Populer",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Consumer<KategoriProvider>(
                        builder: (context, kategoriProvider, _) {
                          if (kategoriProvider.isLoading) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                4,
                                (i) => _shimmerPlaceholder(
                                    width: 56, height: 56, radius: 28),
                              ),
                            );
                          }
                          if (kategoriProvider.error != null) {
                            return Center(
                                child:
                                    Text("Error: ${kategoriProvider.error}"));
                          }
                          if (kategoriProvider.kategoriList.isEmpty) {
                            return const Center(
                                child: Text("Kategori belum tersedia"));
                          }
                          return buildKategoriSection(kategoriProvider.kategoriList);
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Jelajah",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(
                                  () => _showAllKategori = !_showAllKategori);
                            },
                            child: Text(
                              _showAllKategori
                                  ? "Lebih Sedikit"
                                  : "Lihat Semua",
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
              Consumer<PortofolioProvider>(
                builder: (context, portofolioProvider, _) {
                  if (portofolioProvider.isLoading) {
                    return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()));
                  }
                  if (portofolioProvider.error != null) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: ${portofolioProvider.error}'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () async {
                                final userProvider = context.read<UserProvider>();
                                final idCustomer = userProvider.role == 'customer' ? userProvider.userId : null;

                                await context.read<PortofolioProvider>().getAll(id_customer: idCustomer);
                              },
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (portofolioProvider.portofolioList.isEmpty) {
                    return const SliverFillRemaining(
                        child: Center(child: Text('Belum ada portofolio')));
                  }
                 return SliverList(
  delegate: SliverChildBuilderDelegate(
    (context, index) {
      if (index < portofolioProvider.portofolioList.length) {
        final p = portofolioProvider.portofolioList[index];

        final List<MediaItem> mediaList = p.mediaUrls ?? [];

        
// print("PASANG 1: " + (mediaList.toString()));

final firstMedia = mediaList.isNotEmpty ? mediaList.first : null;

// print("PASANG 2: ${firstMedia?.url ?? 'null ini'}");

final isVideo = (firstMedia?.contentType ?? '').startsWith('video');

// print("PASANG 3: " + isVideo.toString());

final String? mediaUrl = isVideo
    ? (firstMedia?.thumbUrl ?? firstMedia?.url)
    : firstMedia?.url;

// print("PASANG 4: " + (mediaUrl ?? 'null ini'));

       

return buildPhotographerCard(
  context,
  p.idMediaVendor, // avatar fotografer
  mediaUrl,
  p.usernameVendor,
  p.ratingVendor,
  noId: p.noId,
  idVendor: p.idVendor,
);
      } else {
        return false // portofolioProvider.hasMore
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            : const SizedBox();
      }
    },
    childCount: portofolioProvider.portofolioList.length + 0,
  ),
);



                },
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
