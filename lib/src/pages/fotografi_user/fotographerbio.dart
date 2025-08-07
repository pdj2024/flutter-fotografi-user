import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpjnew/src/pages/fotografi_user/models/portofolio_model.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/portofolio_provider.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/vendor_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';

import '../providers/constants.dart';
import 'models/vendor_model.dart';
import 'services/portofolio_service.dart';
import 'services/vendor_service.dart';
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
  final ScrollController _scrollController = ScrollController();

 // State
  bool isLoadingVendor = true;
  bool isLoadingPorto = true;
  String? errorVendor;
  String? errorPorto;

  VendorModel? vendor;
  List<PortofolioModel> portofolioList = [];


 @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoadingVendor = true;
      isLoadingPorto = true;
      errorVendor = null;
      errorPorto = null;
    });

    try {
      final vendorData = await VendorService().getAll(
        no_id: widget.idVendor,
        status: 'aktif',
      );

      setState(() {
        vendor = vendorData.isNotEmpty ? vendorData.first : null;
        isLoadingVendor = false;
      });
    } catch (e) {
      setState(() {
        errorVendor = e.toString();
        isLoadingVendor = false;
      });
    }

    try {
      final portoData = await PortofolioService().getAll(
        idVendor: widget.idVendor,
        status: 'aktif',
        orderBy: 'tgl_created',
        orderDir: 'desc',
      );

      setState(() {
        portofolioList = portoData;
        isLoadingPorto = false;
      });
    } catch (e) {
      setState(() {
        errorPorto = e.toString();
        isLoadingPorto = false;
      });
    }
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
        leading: CustomBackButton(),
        title: Text(
          vendor?.userName ?? '',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoadingVendor)
                  Row(children: [_shimmerBox(w: 60, h: 60, r: 30)])
                else if (errorVendor != null)
                  Text("Error: $errorVendor")
                else if (vendor != null) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[200],
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: NavigationProvider().ambilGambar(
                                vendor!.idMedia.toString()),
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
                              vendor!.namaDisplay,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              vendor!.kota,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey),
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
                            vendor!.rating.toString(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Harga Min Paket: ${Constants.formatCurrency(vendor!.hargaMinPaket)}\n"
                    "Harga Max Paket: ${Constants.formatCurrency(vendor!.hargaMaxPaket)}",
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Aksi
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
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
                                    namaVendor: vendor!.namaDisplay,
                                    userName: vendor!.userName,
                                    kotaVendor: vendor!.kota,
                                    ratingVendor: vendor!.rating,
                                    idVendor: vendor!.noId,
                                    fotoProfil:
                                        vendor!.idMedia.toString(),
                                  ),
                                ),
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
                            NavigationProvider().navigateToPage(
                              context,
                              SingleChat(
                                receiverUserName: vendor!.userName,
                                receiverEmail: vendor!.email,
                                receiverID: vendor!.noId.toString(),
                              ),
                              targetTabIndex: 1,
                            );
                          },
                          child: const Icon(Icons.chat_outlined,
                              color: Constants.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // ---------- PORTOFOLIO ----------
                if (isLoadingPorto)
                  const Center(child: CircularProgressIndicator())
                else if (errorPorto != null)
                  Text("Error: $errorPorto")
                else if (portofolioList.isNotEmpty) ...[
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
                        final List<MediaItem> mediaList = p.mediaUrls ?? [];
                        final firstMedia = mediaList.isNotEmpty ? mediaList.first : null;
                        final isVideo = (firstMedia?.contentType ?? '').startsWith('video');
                        final String? mediaUrl = isVideo
                            ? (firstMedia?.thumbUrl ?? firstMedia?.url)
                            : firstMedia?.url;

                         if (mediaUrl == null) {
                          return const Icon(Icons.broken_image_outlined);
                        }
                        
                        


          
                      return GestureDetector(
                        onTap: () => NavigationProvider().navigateToPage(
                          context,
                          SinglePostPage(noId: p.noId),
                          targetTabIndex: 0,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: mediaUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => _shimmerBox(),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ] else
                  const Text("Belum ada portofolio."),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


  // ---------- Item Portofolio ----------
  Widget buildPortfolioItem(BuildContext context, String imagePath, String noId) {
    final String imgUrl = imagePath;
        //context.read<NavigationProvider>().ambilGambar(imagePath);

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

