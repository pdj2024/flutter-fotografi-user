import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:mpjnew/src/pages/fotografi_user/providers/paket_provider.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/portofolio_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/constants.dart';
import 'fotographerbio.dart';
import '../providers/custom_back_button.dart';
import '../providers/navigation_provider.dart';
import 'single_chat.dart';

class SinglePostPage extends StatefulWidget {
  final String noId;

  const SinglePostPage({super.key, required this.noId});

  @override
  _SinglePostPageState createState() => _SinglePostPageState();
}

class _SinglePostPageState extends State<SinglePostPage> {
  bool isLiked = false;
  bool isSaved = false;
  final ScrollController _scrollController = ScrollController();

  int _countPaketList = 0;

  Future<void> _refreshDetail() async {
    // await context.read<PortofolioDetailProvider>().fetchDetail(widget.noId);
    // final p = context.read<PortofolioDetailProvider>().detail;
    // if (p != null) {
    //   await context.read<PaketProvider>().fetchByIdList(p.idPaket);
    // }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final detailProvider = context.read<PortofolioProvider>();
      // await detailProvider.fetchDetail(widget.noId);
      // final p = detailProvider.detail;
      // if (p != null) {
      //   // Pilih salah satu, batch lebih efisien jika API support
      //   // await context.read<PaketProvider>().fetchByIdBatch(p.idPaket);
      //   // atau
      //   await context.read<PaketProvider>().fetchByIdList(p.idPaket);
      // }
    });
    // You can fetch the post details here using widget.noId if needed
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildBody(PortofolioProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${provider.error}'),
            ElevatedButton(
              onPressed: () => provider.getAll(), // harusnya per id
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    final p = null;// provider.detail;
    if (p == null) {
      return const Center(child: Text("Data portofolio tidak ditemukan"));
    }
    final imgUrl = '${Constants.baseUrl}/api/media/${p.idVendor}/${p.idMedia}';

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: vendor info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(
                    child: Image.network(
                      context
                          .read<NavigationProvider>()
                          .ambilGambar(p.idMedia.toString()),
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                              width: 32, height: 32, color: Colors.grey[300]),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, size: 20);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        context.read<NavigationProvider>().navigateToPage(
                              context,
                              PhotographerBio(
                                idVendor: p.idVendor,
                              ),
                              targetTabIndex: 0,
                            ),
                    child: Row(
                      children: [
                        Text(
                          p.usernameVendor,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          p.ratingVendor.toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 44,
                  width: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Constants.primaryColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
                      context.read<NavigationProvider>().navigateToPage(
                            context,
                            SingleChat(
                                receiverUserName: p.usernameVendor,
                                receiverEmail: "",
                                receiverID: p.idVendor.toString()),
                            targetTabIndex: 1,
                          );
                    },
                    child: const Icon(Icons.chat_outlined,
                        color: Constants.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          // Gambar utama portofolio
          AspectRatio(
            aspectRatio: 5 / 4,
            child: ClipRRect(
              // borderRadius:
              //     const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                imgUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.grey[300]),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, size: 40),
                ),
              ),
            ),
            // child: ClipRRect(
            //   child: Image.network(
            //     context.read<NavigationProvider>().ambilGambar(imgUrl),
            //     fit: BoxFit.cover,
            //     loadingBuilder: (context, child, loadingProgress) {
            //       if (loadingProgress == null) return child;
            //       return Shimmer.fromColors(
            //         baseColor: Colors.grey[300]!,
            //         highlightColor: Colors.grey[100]!,
            //         child: Container(color: Colors.grey[300]),
            //       );
            //     },
            //     errorBuilder: (context, error, stackTrace) {
            //       return Container(
            //         color: Colors.grey[300],
            //         child: const Center(
            //             child: Icon(Icons.broken_image_outlined,
            //                 size: 48, color: Colors.grey)),
            //       );
            //     },
            //   ),
            // ),
          ),
          // Like, Save
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 9, 16, 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => isLiked = !isLiked);
                  },
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.black,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.chat_bubble_outline, size: 28),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => isSaved = !isSaved);
                  },
                  child: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? Colors.amber : Colors.black,
                    size: 29,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text("${p.likes} likes",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          // Paket
          // OfferCard(
          //   title: "Paket ${p.idKategori}",
          //   price: "IDR ${p.hargaMinPaket}",
          //   includes: ["Jumlah Paket: ${p.jumlahPaket}", "Kota: ${p.kota}"],
          // ),
          Consumer<PaketProvider>(
            builder: (context, paketProvider, _) {
              if (paketProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (paketProvider.error != null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Gagal memuat paket: ${paketProvider.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              if (paketProvider.paketList.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Belum ada paket tersedia."),
                );
              }
              return Column(
                children: paketProvider.paketList.map((paket) {
                  return OfferCard(
                    title: paket.nama_paket,
                    price: Constants.formatCurrency(paket.harga),
                    includes: [
                      if (paket.rincian.isNotEmpty) paket.rincian,
                      "Aktif: ${paket.aktif ? 'Ya' : 'Tidak'}",
                    ],
                  );
                }).toList(),
              );
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    _countPaketList = context.watch<PaketProvider>().paketList.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
        leading: CustomBackButton(),
        title: const Text(
          "Portofolio",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<PortofolioProvider>(
          builder: (context, provider, _) {
            return RefreshIndicator(
              onRefresh: _refreshDetail,
              child: provider.isLoading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                            height: 300,
                            child: Center(child: CircularProgressIndicator())),
                      ],
                    )
                  : _buildBody(provider),
            );
          },
        ),
      ),
      floatingActionButton: (_countPaketList > 1)
          ? FloatingActionButton(
              onPressed: _refreshDetail,
              backgroundColor: Constants.primaryColor,
              child: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh Paket',
            )
          : null,
      // body: SingleChildScrollView(
      //   padding: const EdgeInsets.only(bottom: 20),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       // Header (user info + rating)
      //       Padding(
      //           padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      //           child: Row(
      //             children: [
      //               CircleAvatar(
      //                 radius: 16,
      //                 backgroundColor: Colors.grey[200],
      //                 child: ClipOval(
      //                   child: Image.network(
      //                     context.read<NavigationProvider>().ambilGambar(
      //                         '355c5d9f-0e1b-4c8f-a715-c388b9d2e21d-image_cropper_1748677911014.jpg'),
      //                     width: 32,
      //                     height: 32,
      //                     fit: BoxFit.cover,
      //                     loadingBuilder: (context, child, loadingProgress) {
      //                       if (loadingProgress == null) return child;
      //                       return Shimmer.fromColors(
      //                         baseColor: Colors.grey[300]!,
      //                         highlightColor: Colors.grey[100]!,
      //                         child: Container(
      //                           width: 32,
      //                           height: 32,
      //                           color: Colors.grey[300],
      //                         ),
      //                       );
      //                     },
      //                     errorBuilder: (context, error, stackTrace) {
      //                       return const Icon(Icons.person, size: 20);
      //                     },
      //                   ),
      //                 ),
      //               ),
      //               const SizedBox(width: 12),
      //               Expanded(
      //                 child: GestureDetector(
      //                   onTap: () =>
      //                       context.read<NavigationProvider>().navigateToPage(
      //                             context,
      //                             PhotographerBio(),
      //                             targetTabIndex: 0,
      //                           ),
      //                   child: Row(
      //                     children: [
      //                       const Text(
      //                         "Jordan Langton",
      //                         style: TextStyle(
      //                             fontWeight: FontWeight.bold, fontSize: 16),
      //                       ),
      //                       const SizedBox(width: 6),
      //                       const Icon(Icons.star,
      //                           color: Colors.amber, size: 16),
      //                       const SizedBox(width: 2),
      //                       const Text(
      //                         "4.5",
      //                         style: TextStyle(
      //                             fontWeight: FontWeight.bold, fontSize: 16),
      //                       ),
      //                     ],
      //                   ),
      //                 ),
      //               ),
      //               SizedBox(
      //                 height: 44,
      //                 width: 44,
      //                 child: OutlinedButton(
      //                   style: OutlinedButton.styleFrom(
      //                     side: const BorderSide(color: Constants.primaryColor),
      //                     shape: RoundedRectangleBorder(
      //                       borderRadius: BorderRadius.circular(20),
      //                     ),
      //                     padding: EdgeInsets.zero,
      //                   ),
      //                   onPressed: () {
      //                     context.read<NavigationProvider>().navigateToPage(
      //                           context,
      //                           SingleChat(
      //                               receiverUserName: 'helooo',
      //                               receiverEmail: "hello@gmail.com",
      //                               receiverID: '123'),
      //                           targetTabIndex: 1,
      //                         );
      //                   },
      //                   child: const Icon(Icons.chat_outlined,
      //                       color: Constants.primaryColor),
      //                 ),
      //               ),
      //             ],
      //           )),
      //       AspectRatio(
      //         aspectRatio: 5 / 4, // 5:4 width:height
      //         child: ClipRRect(
      //           child: Image.network(
      //             context.read<NavigationProvider>().ambilGambar(
      //                 'a3640fb0-0ba0-4996-a31c-3d2eff590f75-image_cropper_1748676026618.jpg'),
      //             fit: BoxFit.cover,
      //             loadingBuilder: (context, child, loadingProgress) {
      //               if (loadingProgress == null) return child;
      //               return Shimmer.fromColors(
      //                 baseColor: Colors.grey[300]!,
      //                 highlightColor: Colors.grey[100]!,
      //                 child: Container(
      //                   color: Colors.grey[300],
      //                 ),
      //               );
      //             },
      //             errorBuilder: (context, error, stackTrace) {
      //               return Container(
      //                 color: Colors.grey[300],
      //                 child: const Center(
      //                   child: Icon(Icons.broken_image_outlined,
      //                       size: 48, color: Colors.grey),
      //                 ),
      //               );
      //             },
      //           ),
      //         ),
      //       ),

      //       // Like, Comment, Save
      //       Padding(
      //         padding: const EdgeInsets.fromLTRB(16, 9, 16, 4),
      //         child: Row(
      //           children: [
      //             GestureDetector(
      //               onTap: () {
      //                 setState(() {
      //                   isLiked = !isLiked;
      //                 });
      //               },
      //               child: Icon(
      //                 isLiked ? Icons.favorite : Icons.favorite_border,
      //                 color: isLiked ? Colors.red : Colors.black,
      //                 size: 28,
      //               ),
      //             ),
      //             const SizedBox(width: 16),
      //             const Icon(
      //               Icons.chat_bubble_outline,
      //               size: 28,
      //             ),
      //             const Spacer(),
      //             GestureDetector(
      //               onTap: () {
      //                 setState(() {
      //                   isSaved = !isSaved;
      //                 });
      //               },
      //               child: Icon(
      //                 isSaved ? Icons.bookmark : Icons.bookmark_border,
      //                 color: isSaved ? Colors.amber : Colors.black,
      //                 size: 29,
      //               ),
      //             ),
      //           ],
      //         ),
      //       ),

      //       const Padding(
      //         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      //         child: Text("2,516 likes",
      //             style: TextStyle(fontWeight: FontWeight.bold)),
      //       ),

      //       const OfferCard(
      //         title: "Paket Wedding",
      //         price: "IDR 500,000",
      //         includes: [
      //           "3 jam, 50 png",
      //           "Hasil via Google Drive",
      //           "Termasuk Jasa Edit",
      //         ],
      //       ),
      //       // buildPackageCard(
      //       //   title: "Wedding Package",
      //       //   price: "IDR 500,000",
      //       //   duration: "6 jam",
      //       //   photos: "200 foto",
      //       // ),
      //     ],
      //   ),
      // ),
    );
  }
}

class OfferCard extends StatelessWidget {
  final String title;
  final String price;
  final List<String> includes;

  const OfferCard({
    super.key,
    required this.title,
    required this.price,
    required this.includes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(price, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          const Text("Rincian", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...includes.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text("• $item", style: const TextStyle(fontSize: 13)),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                context.read<NavigationProvider>().navigateToPage(
                      context,
                      SingleChat(
                          receiverUserName: 'helooo',
                          receiverEmail: "hello@gmail.com",
                          receiverID: '123'),
                      targetTabIndex: 1,
                    );
              },
              child: const Text("Atur Jadwal",
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildPackageCard({
  required String title,
  required String price,
  required String duration,
  required String photos,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
      ],
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text(price,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("• $duration"),
                Text("• $photos"),
                const Text("• Google Drive"),
              ],
            )),
        // const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {},
            child: const Text('Atur Jadwal',
                style: TextStyle(color: Colors.white)),
          ),
        )
      ],
    ),
  );
}
