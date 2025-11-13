import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/models/portofolio_model.dart';
import 'package:mpjnew/src/data/models/vendor_model.dart';
import 'package:mpjnew/src/features/customer/view/single_post_page.dart';
import 'package:mpjnew/src/features/customer/widget/shimmer/shimmer_vendor_bio.dart';
import 'package:mpjnew/src/features/customer/widget/vendor_bio_card.dart';
import 'package:mpjnew/src/pages/fotografi_user/services/portofolio_service.dart';
import 'package:mpjnew/src/pages/fotografi_user/services/vendor_service.dart';
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
              idMedia: '',
              deskripsiBio: '',
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
        idMedia: '',
        deskripsiBio: '',
      );
    }

    if (vendor.username == notFoundUsername) {
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
          vendor.username,
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

                // Vendor Bio
                if (isLoadingVendor)
                  ShimmerVendorBio()
                else 
                  VendorBioCard(vendor: vendor, isListPackagePage: false,),

                // Vendor Portofolio
                if (isLoadingPorto)
                  GridView.builder(
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
                      return ShimmerPlaceholder(
                        radius: 5,
                      );
                    },
                  )
                // const Center(
                //   child: Column(
                //     children: [
                //       Expanded(
                //         child: AspectRatio(
                //           aspectRatio: 1,
                //           child: ShimmerPlaceholder(
                //             radius: 10,
                //           ),
                //         ),
                //       ),
                //       Expanded(
                //         child: AspectRatio(
                //           aspectRatio: 1,
                //           child: ShimmerPlaceholder(
                //             radius: 10,
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // )
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
                              color: Colors.grey.shade200,
                              image: DecorationImage(
                                image: NetworkImage(mediaUrl),
                                fit: BoxFit.cover,
                              )),
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
