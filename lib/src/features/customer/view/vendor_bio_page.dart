import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/models/portofolio_model.dart';
import 'package:mpjnew/src/data/models/vendor_model.dart';
import 'package:mpjnew/src/pages/fotografi_user/pilihan_paket.dart';
import 'package:mpjnew/src/pages/fotografi_user/services/portofolio_service.dart';
import 'package:mpjnew/src/pages/fotografi_user/services/vendor_service.dart';
import 'package:mpjnew/src/pages/fotografi_user/single_chat.dart';
import 'package:mpjnew/src/pages/fotografi_user/singlepage.dart';
import 'package:mpjnew/src/pages/providers/custom_back_button.dart';
import 'package:provider/provider.dart';

class VendorBioPage extends StatefulWidget {
  final String idVendor;

  const VendorBioPage({super.key, required this.idVendor});

  @override
  State<VendorBioPage> createState() => _VendorBioPageState();
}

class _VendorBioPageState extends State<VendorBioPage> {
  final ScrollController _scrollController = ScrollController();

  bool isLoadingVendor = true;
  bool isLoadingPorto = true;

  final String notFoundUsername = 'vendor-not-found';

  late VendorModel vendor;
  List<PortofolioModel> portofolioList = [];

  Future<void> _fetchData() async {
    setState(() {
      isLoadingVendor = true;
      isLoadingPorto = true;
    });

    try {
      final vendorData =
          await VendorService().getAll(no_id: widget.idVendor, status: 'aktif');

      vendor = vendorData.isNotEmpty
          ? vendorData.first
          : VendorModel(
              no_id: widget.idVendor,
              user_name: notFoundUsername,
              nama_display: 'Vendor Tidak Ditemukan',
              email: '',
              kota: '-',
              rating: 0,
              portofolio: [],
              paket: [],
              hargaMinPaket: 0,
              hargaMaxPaket: 0,
              tgl_created: DateTime(2000),
              id_media: '',
              deskripsi_bio: '',
            );
    } catch (_) {
      vendor = VendorModel(
        no_id: widget.idVendor,
        user_name: notFoundUsername,
        nama_display: 'Vendor Tidak Ditemukan',
        email: '',
        kota: '-',
        rating: 0,
        portofolio: [],
        paket: [],
        hargaMinPaket: 0,
        hargaMaxPaket: 0,
        tgl_created: DateTime(2000),
        id_media: '',
        deskripsi_bio: '',
      );
    }

    if (vendor.user_name == notFoundUsername) {
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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
        leading: CustomBackButton(),
        title: Text(
          vendor.user_name,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                  Row(children: [
                    ShimmerPlaceholder(width: 60, height: 60, radius: 30)
                  ])
                else ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[200],
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: vendor.id_media,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => ShimmerPlaceholder(
                                width: 60, height: 60, radius: 30),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  vendor.nama_display,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (vendor.rating > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star,
                                            color: Colors.amber, size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          vendor.rating.toString(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  )
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              vendor.kota,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (vendor.deskripsi_bio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      vendor.deskripsi_bio,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (vendor.user_name != notFoundUsername) ...[
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
                                      namaVendor: vendor.nama_display,
                                      userName: vendor.user_name,
                                      kotaVendor: vendor.kota,
                                      ratingVendor: vendor.rating,
                                      idVendor: vendor.no_id,
                                      fotoProfil: vendor.id_media,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                "Lihat Pilihan Paket",
                                style: TextStyle(color: Colors.white),
                              ),
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
                                      id_lawan: vendor.no_id.toString(),
                                      username_lawan: vendor.user_name,
                                      avatar_lawan: vendor.id_media,
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
                  const Center(
                    child: Column(
                      children: [
                        ShimmerPlaceholder(
                          height: 100,
                          width: 100,
                          radius: 10,
                        ),
                      ],
                    ),
                  )
                else if (portofolioList.isNotEmpty) ...[
                  const Text(
                    "Portofolio",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: portofolioList.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                    ),
                    itemBuilder: (context, index) {
                      final p = portofolioList[index];
                      final List<MediaItem> mediaList = p.mediaUrls;
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
                        onTap: () {
                          context.read<NavigationProvider>().navigateToPage(
                              context, SinglePostPage(noId: p.noId),
                              targetTabIndex: 0);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: Colors.blue,
                            image: !isVideo
                                ? DecorationImage(
                                    image: NetworkImage(mediaUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: isVideo
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      mediaUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.broken_image_outlined),
                                    ),
                                    const Center(
                                      child: Icon(Icons.play_circle_fill,
                                          color: Colors.white, size: 32),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
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
