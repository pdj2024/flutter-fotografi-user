import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/app_image.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/features/customer/view/search_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/kategori_provider.dart';
import 'package:provider/provider.dart';

class KategoriSection extends StatefulWidget {
  const KategoriSection({super.key});

  @override
  State<KategoriSection> createState() => _KategoriSectionState();
}

class _KategoriSectionState extends State<KategoriSection> {
  @override
  Widget build(BuildContext context) {
    final kategoriProvider = context.watch<KategoriProvider>();
    final kategoriList = kategoriProvider.kategoriList;
    final isLoading = kategoriProvider.isLoadingKategori;
    final error = kategoriProvider.errorKategori;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ───────────────────────────────────────
        // const Padding(
        //   padding: EdgeInsets.symmetric(horizontal: 4),
        //   child: Text(
        //     'Kategori',
        //     style: TextStyle(
        //       fontSize: 16,
        //       fontWeight: FontWeight.w700,
        //       letterSpacing: -0.2,
        //     ),
        //   ),
        // ),

        const SizedBox(height: 12),

        // ── Content ──────────────────────────────────────
        if (isLoading)
          _buildShimmer()
        else if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Gagal memuat kategori',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          )
        else if (kategoriList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Kategori belum tersedia',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: kategoriList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final kategori = kategoriList[index];
                final hasImage =
                    kategori.id_media != null && kategori.id_media!.isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    context.read<NavigationProvider>().navigateToPage(
                          context,
                          SearchPage(
                            id_category: kategori.no_id,
                            nama_category: kategori.nama_kategori,
                            search: "",
                          ),
                          targetTabIndex: 0,
                          targetPage: "SearchPage",
                          hrsLogin: false,
                        );
                  },
                  child: Container(
                    width: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.grey.shade300,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // ── Background image ─────────────
                        if (hasImage)
                          AppNetworkImage(
                            url: kategori.id_media!,
                            decodeWidth: decodeWidthFor(context, 150),
                            errorWidget: Container(
                              color: Constants.primaryColor.withOpacity(0.15),
                              child: Center(
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  color:
                                      Constants.primaryColor.withOpacity(0.4),
                                  size: 28,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            color: Constants.primaryColor.withOpacity(0.15),
                            child: Center(
                              child: Icon(
                                Icons.camera_alt_outlined,
                                color: Constants.primaryColor.withOpacity(0.4),
                                size: 28,
                              ),
                            ),
                          ),

                        // ── Dark gradient overlay ────────
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.3, 1.0],
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.9),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── Category name ────────────────
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Text(
                            kategori.nama_kategori,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 8),
      ],
    );
  }

  // ── Shimmer loading ────────────────────────────────────
  Widget _buildShimmer() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => const ShimmerPlaceholder(
          width: 130,
          height: 100,
          radius: 14,
        ),
      ),
    );
  }
}
