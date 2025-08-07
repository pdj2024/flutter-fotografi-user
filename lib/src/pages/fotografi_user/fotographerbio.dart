import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpjnew/src/pages/fotografi_user/models/portofolio_model.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/portofolio_provider.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/vendor_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';

import '../providers/constants.dart';
import 'singlepage.dart';
import 'pilihan_paket.dart';
import '../providers/custom_back_button.dart';
import '../providers/navigation_provider.dart';
import 'single_chat.dart';

class PhotographerBio extends StatefulWidget {
  final String idVendor;
  const PhotographerBio({super.key, required this.idVendor});

  @override
  State<PhotographerBio> createState() => _PhotographerBioState();
}

class _PhotographerBioState extends State<PhotographerBio> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<VendorProvider>().getAll(); // harusnya specify id
      // Jika ingin portofolio initial by vendor, lakukan juga di init
      final filterParams = <String, String>{};
      filterParams['id_vendor'] = widget.idVendor.toString();
      context
          .read<PortofolioProvider>()
          .getAll(); // harusnya specify id vendor
    });
    // You can add any initialization logic here if needed
  }

  Future<void> _doRefresh() async {
    await context.read<VendorProvider>().getAll(); // harusnya specify id vendor
    // Jika ingin refresh portofolio juga, fetch ulang portofolio
    // Bisa pakai filterParams jika API support
    final filterParams = <String, String>{};
    filterParams['id_vendor'] = widget.idVendor.toString();
    await context
        .read<PortofolioProvider>()
        .getAll();
  }

  /// Shimmer util
  Widget _shimmerBox({double? w, double? h, double r = 0}) =>
      Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(r),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final portofolioProviderForFAB = Provider.of<PortofolioProvider>(context);
    final portofolioListForFAB = portofolioProviderForFAB.portofolioList
        .where((p) => p.idVendor == widget.idVendor)
        .toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
        leading: CustomBackButton(),
        title: Consumer<VendorProvider>(
          builder: (context, vendorProvider, _) {
            final vendor = vendorProvider.vendor;
            return Text(
              vendor?.userName ?? "",
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      // body: SafeArea(
      //   child: SingleChildScrollView(
      //     padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      //     child: Column(
      //       crossAxisAlignment: CrossAxisAlignment.start,
      //       children: [
      //         // ---------- Profil Fotografer ----------
      //         Row(
      //           children: [
      //             CircleAvatar(
      //               radius: 30,
      //               backgroundColor: Colors.grey[200],
      //               child: ClipOval(
      //                 child: CachedNetworkImage(
      //                   imageUrl: context.read<NavigationProvider>().ambilGambar(
      //                       '1d98c486-b810-42d8-8779-3b0ca34154ef-image_cropper_1748677884447.jpg'),
      //                   width: 60,
      //                   height: 60,
      //                   fit: BoxFit.cover,
      //                   placeholder: (context, url) =>
      //                       _shimmerBox(w: 60, h: 60, r: 30),
      //                   errorWidget: (context, url, error) =>
      //                       const Icon(Icons.person, size: 30),
      //                 ),
      //               ),
      //             ),
      //             const SizedBox(width: 12),
      //             const Expanded(
      //               child: Column(
      //                 crossAxisAlignment: CrossAxisAlignment.start,
      //                 children: [
      //                   Text(
      //                     'Jordan Langton',
      //                     style: TextStyle(
      //                       fontSize: 16,
      //                       fontWeight: FontWeight.bold,
      //                     ),
      //                   ),
      //                   SizedBox(height: 4),
      //                   Text(
      //                     'Surabaya, Indonesia',
      //                     style: TextStyle(
      //                       fontSize: 13,
      //                       color: Colors.grey,
      //                     ),
      //                   ),
      //                 ],
      //               ),
      //             ),
      //             const Row(
      //               children: [
      //                 Icon(Icons.star, color: Colors.amber, size: 18),
      //                 SizedBox(width: 4),
      //                 Text('4.5',
      //                     style: TextStyle(fontWeight: FontWeight.bold)),
      //               ],
      //             ),
      //           ],
      //         ),
      //         const SizedBox(height: 16),
      //         const Text(
      //           'Fotografer pernikahan dengan gaya dokumenter dan sentuhan '
      //           'sinematik. Siap menangkap momen terbaik Anda.',
      //           style: TextStyle(fontSize: 14, color: Colors.black87),
      //         ),
      //         const SizedBox(height: 20),

      //         // ---------- Tombol Aksi ----------
      //         Row(
      //           children: [
      //             Expanded(
      //               child: SizedBox(
      //                 width: double.infinity,
      //                 height: 44,
      //                 child: ElevatedButton(
      //                   style: ElevatedButton.styleFrom(
      //                     backgroundColor: Constants.primaryColor,
      //                     shape: RoundedRectangleBorder(
      //                       borderRadius: BorderRadius.circular(30),
      //                     ),
      //                   ),
      //                   onPressed: () {
      //                     Navigator.push(
      //                       context,
      //                       MaterialPageRoute(
      //                           builder: (context) => PilihanPaket()),
      //                     );
      //                   },
      //                   child: const Text("Lihat Pilihan Paket",
      //                       style: TextStyle(color: Colors.white)),
      //                 ),
      //               ),
      //             ),
      //             const SizedBox(width: 8),
      //             SizedBox(
      //               height: 44,
      //               width: 44,
      //               child: OutlinedButton(
      //                 style: OutlinedButton.styleFrom(
      //                   side: const BorderSide(color: Constants.primaryColor),
      //                   shape: RoundedRectangleBorder(
      //                     borderRadius: BorderRadius.circular(20),
      //                   ),
      //                   padding: EdgeInsets.zero,
      //                 ),
      //                 onPressed: () {
      //                   context.read<NavigationProvider>().navigateToPage(
      //                         context,
      //                         SingleChat(
      //                             receiverUserName: 'helooo',
      //                             receiverEmail: "hello@gmail.com",
      //                             receiverID: '123'),
      //                         targetTabIndex: 1,
      //                       );
      //                 },
      //                 child: const Icon(Icons.chat_outlined,
      //                     color: Constants.primaryColor),
      //               ),
      //             ),
      //           ],
      //         ),
      //         const SizedBox(height: 15),

      //         // ---------- Grid Portofolio ----------
      //         SingleChildScrollView(
      //           child: GridView.count(
      //             crossAxisCount: 2,
      //             crossAxisSpacing: 8,
      //             mainAxisSpacing: 8,
      //             padding: const EdgeInsets.only(top: 8),
      //             shrinkWrap: true,
      //             physics: const NeverScrollableScrollPhysics(),
      //             children: [
      //               buildPortfolioItem(
      //                   context,
      //                   'a8701826-810b-467e-8fe4-222e10d4bc0b-image_cropper_1748676050844.jpg',
      //                   1),
      //               buildPortfolioItem(
      //                   context,
      //                   'd1ef0fe8-7233-46e7-a69f-33a1d0e39dad-image_cropper_1748676063147.jpg',
      //                   2),
      //               buildPortfolioItem(
      //                   context,
      //                   '380bf81d-0666-4ac7-a08c-8146592ff86e-image_cropper_1748676098660.jpg',
      //                   3),
      //               buildPortfolioItem(
      //                   context,
      //                   'a3640fb0-0ba0-4996-a31c-3d2eff590f75-image_cropper_1748676026618.jpg',
      //                   4),
      //               buildPortfolioItem(
      //                   context,
      //                   '0ae49083-2adc-49ed-b08f-c5f22d65bba6-image_cropper_1748676084421.jpg',
      //                   5),
      //             ],
      //           ),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _doRefresh,
          child: Consumer<VendorProvider>(
            builder: (context, vendorProvider, _) {
              if (vendorProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (vendorProvider.error != null) {
                return Center(child: Text("Error: ${vendorProvider.error}"));
              }
              final vendor = vendorProvider.vendor;
              if (vendor == null) {
                return const Center(child: Text("Data vendor tidak ditemukan"));
              }
              // Ambil list portofolio dari vendor
              // final List<String> portofolios = vendor.portofolio ?? [];
              final portofolioProvider =
                  Provider.of<PortofolioProvider>(context);
              final portofolioList = portofolioProvider.portofolioList
                  .where((p) => p.idVendor == vendor.noId)
                  .toList();

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------- Profil Fotografer ----------
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey[200],
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: context
                                  .read<NavigationProvider>()
                                  .ambilGambar(vendor.idMedia.toString()),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  _shimmerBox(w: 60, h: 60, r: 30),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.person, size: 30),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vendor.namaDisplay,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vendor.kota,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              vendor.rating.toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      // Ganti dengan field bio jika tersedia, atau info lainnya
                      // "Email: ${vendor.email}\n"
                      "Harga Min Paket: ${Constants.formatCurrency(vendor.hargaMinPaket)}\n"
                      "Harga Max Paket: ${Constants.formatCurrency(vendor.hargaMaxPaket)}",
                      // "Tgl dibuat: ${vendor.tglCreated}",
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),

                    // ---------- Tombol Aksi ----------
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => PilihanPaket(
                                            namaVendor: vendor.namaDisplay,
                                            userName: vendor.userName,
                                            kotaVendor: vendor.kota,
                                            ratingVendor: vendor.rating,
                                            idVendor: vendor.noId,
                                            fotoProfil:
                                                vendor.idMedia.toString(),
                                          )),
                                );
                              },
                              child: const Text("Lihat Pilihan Paket",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 44,
                          width: 44,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Constants.primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {
                              context.read<NavigationProvider>().navigateToPage(
                                    context,
                                    SingleChat(
                                        receiverUserName: vendor.userName,
                                        receiverEmail: vendor.email,
                                        receiverID: vendor.noId.toString()),
                                    targetTabIndex: 1,
                                  );
                            },
                            child: const Icon(Icons.chat_outlined,
                                color: Constants.primaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // ---------- List Paket ----------
                    // if (vendor.paket.isNotEmpty)
                    //   Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       const Text(
                    //         "Daftar Paket",
                    //         style: TextStyle(
                    //             fontWeight: FontWeight.bold, fontSize: 16),
                    //       ),
                    //       const SizedBox(height: 8),
                    //       ...vendor.paket.map((paketNama) => Padding(
                    //             padding: const EdgeInsets.only(bottom: 4),
                    //             child: Text("• $paketNama",
                    //                 style: const TextStyle(fontSize: 14)),
                    //           )),
                    //       const SizedBox(height: 16),
                    //     ],
                    //   ),

                    // ---------- Grid Portofolio ----------
                    if (portofolioProvider.isLoading) ...[
                      const SizedBox(height: 32),
                      const Center(child: CircularProgressIndicator()),
                    ] else if (portofolioList.isNotEmpty) ...[
                      const Text(
                        "Portofolio",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        padding: const EdgeInsets.only(top: 8),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: portofolioList.map((p) {
                          final String imgUrl =
                              '${Constants.baseUrl}/api/media/${p.idVendor}/${p.idMedia}';
                          return GestureDetector(
                            onTap: () => context
                                .read<NavigationProvider>()
                                .navigateToPage(
                                  context,
                                  SinglePostPage(noId: p.noId),
                                  targetTabIndex: 0,
                                ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: imgUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(color: Colors.white),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      const Text("Belum ada portofolio."),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),

      floatingActionButton: portofolioListForFAB.length > 1
          ? FloatingActionButton(
              onPressed: _doRefresh,
              tooltip: 'Refresh',
              backgroundColor: Constants.primaryColor,
              child: const Icon(Icons.refresh, color: Colors.white),
            )
          : null,
    );
  }

  // ---------- Item Portofolio ----------
  Widget buildPortfolioItem(BuildContext context, String imagePath, String noId) {
    final String imgUrl =
        context.read<NavigationProvider>().ambilGambar(imagePath);

    return GestureDetector(
      onTap: () => context.read<NavigationProvider>().navigateToPage(
            context,
            SinglePostPage(noId: noId),
            targetTabIndex: 0,
          ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: imgUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(color: Colors.white),
          ),
          errorWidget: (context, url, error) =>
              const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}
