import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpjnew/src/pages/fotografi_user/models/portofolio_model.dart';

import 'package:mpjnew/src/pages/fotografi_user/services/portofolio_service.dart';
import 'package:mpjnew/src/pages/fotografi_user/services/vendor_service.dart';
import 'package:mpjnew/src/pages/providers/constants.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/navigation_provider.dart';
import '../providers/custom_back_button.dart';
import 'models/vendor_model.dart';
import 'singlepage.dart';
import 'pilihan_paket.dart';
import 'single_chat.dart';

class PhotographerBio extends StatefulWidget {
  final String idVendor;
  const PhotographerBio({super.key, required this.idVendor});

  @override
  State<PhotographerBio> createState() => _PhotographerBioState();
}

class _PhotographerBioState extends State<PhotographerBio> {
  final ScrollController _scrollController = ScrollController();

  bool isLoadingVendor = true;
  bool isLoadingPorto = true;

  final String notFoundUsername = 'vendor-not-found';

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
    });

    try {
      final vendorData = await VendorService().getAll(
        no_id: widget.idVendor,
        status: 'aktif'
      );

      vendor = vendorData.isNotEmpty
          ? vendorData.first
          : VendorModel(
              noId: widget.idVendor,
              username: notFoundUsername,
              namaDisplay: 'Vendor Tidak Ditemukan',
              email: '',
              kota: '-',
              rating: 0,
              portofolio: [],
              paket: [],
              hargaMinPaket: 0,
              hargaMaxPaket: 0,
              tglCreated: DateTime(2000),
              id_media: '',
              deskripsi_bio: '',
            );
    } catch (_) {
      vendor = VendorModel(
        noId: widget.idVendor,
        username: notFoundUsername,
        namaDisplay: 'Vendor Tidak Ditemukan',
        email: '',
        kota: '-',
        rating: 0,
        portofolio: [],
        paket: [],
        hargaMinPaket: 0,
        hargaMaxPaket: 0,
        tglCreated: DateTime(2000),
        id_media: '',
        deskripsi_bio: '',
      );
    }

    if(vendor?.username == notFoundUsername) {

    } else {
        try {
            portofolioList = await PortofolioService().getAll(
            idVendor: widget.idVendor,
            status: 'aktif',
            orderBy: 'tgl_created',
            orderDir: 'desc',
          );
        } catch (_) {
          portofolioList = [];
        }
    }
   

    setState(() {
      isLoadingVendor = false;
      isLoadingPorto = false;
    });
  }

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
          vendor?.username ?? '',
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
                else ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[200],
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: vendor!.id_media ?? '',
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
                      if (vendor!.rating != null && vendor!.rating! > 0)
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              vendor!.rating!.toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                    ],
                  ),
                  if (vendor!.deskripsi_bio != null &&
                      vendor!.deskripsi_bio!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      vendor!.deskripsi_bio!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (vendor!.username != notFoundUsername) ...[
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
                                      userName: vendor!.username,
                                      kotaVendor: vendor!.kota,
                                      ratingVendor: vendor!.rating,
                                      idVendor: vendor!.noId,
                                      fotoProfil: vendor!.id_media ?? '',
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
                                  
                                  context.read<NavigationProvider>().navigateToPage(
                                    context,
                                      SingleChat(
                                            // roomId dikosongin karena kemungkinan besar ini chat baru
                                            roomId: null,
                                            // kirim userIds lawan (vendor.id)
                                           id_lawan: vendor!.noId.toString(),
                                           username_lawan: vendor!.username,
                                           avatar_lawan: vendor!.id_media,
                                           
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
                  ]
                ],
                if (isLoadingPorto)
                  const Center(child: CircularProgressIndicator())
                else if (portofolioList.isNotEmpty) ...[
                  const Text(
                    "Portofolio",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      final firstMedia =
                          mediaList.isNotEmpty ? mediaList.first : null;
                      final isVideo =
                          (firstMedia?.contentType ?? '').startsWith('video');
                      final String? mediaUrl = isVideo
                          ? (firstMedia?.thumbUrl ?? firstMedia?.url)
                          : firstMedia?.url;

                      if (mediaUrl == null) {
                        return const Icon(Icons.broken_image_outlined);
                      }

                      return GestureDetector(
                        onTap: ()  { 
                          // print("====== PINDAH PAGE: " + p.noId);
                           context.read<NavigationProvider>().navigateToPage(
                          context,
                          SinglePostPage(noId: p.noId),
                          targetTabIndex: 0);


                        }
                       ,
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