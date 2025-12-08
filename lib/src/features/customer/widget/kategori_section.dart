import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/custom_button.dart';
import 'package:mpjnew/src/core/constants/text_style.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/features/customer/view/search_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/kategori_provider.dart';
import 'package:mpjnew/src/features/customer/widget/kategori_button.dart';
import 'package:provider/provider.dart';

class KategoriSection extends StatefulWidget {
  KategoriSection({super.key});

  @override
  State<KategoriSection> createState() => _KategoriSectionState();
}

class _KategoriSectionState extends State<KategoriSection> {
  @override
  void initState() {
    super.initState();
    // ambil data kategori dari provider saat pertama kali build
    Future.microtask(() => context.read<KategoriProvider>().loadKategori());
  }

  @override
  Widget build(BuildContext context) {
    final kategoriProvider = context.watch<KategoriProvider>();
    final kategoriList = kategoriProvider.kategoriList;
    final showAllKategori = kategoriProvider.showAllKategori;
    final isLoading = kategoriProvider.isLoadingKategori;
    final error = kategoriProvider.errorKategori;
    final maxPerRow = kategoriProvider.maxKategoriPerRow;

    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 16 - (8.0 * (maxPerRow - 1))) / maxPerRow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 16,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Kategori Populer",
              style: AppTextStyle.subtitle1,
            ),
            if (kategoriList.length > maxPerRow)
              CustomButton.textButton(
                  onTap: () => kategoriProvider.toggleShowAllKategori(),
                  text: showAllKategori ? "Lebih Sedikit" : "Lihat Semua"),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              maxPerRow,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: ShimmerPlaceholder(width: 56, height: 56, radius: 28),
              ),
            ),
          )
        else if (error != null)
          Center(child: Text("Error: $error"))
        else if (kategoriList.isEmpty)
          const Center(child: Text("Kategori belum tersedia"))
        else if (!showAllKategori)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: kategoriList
                .sublist(0, maxPerRow)
                .map(
                  (kategori) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: KategoriButton(
                      imageUrl: kategori.id_media,
                      label: kategori.nama_kategori,
                      bgColor: Color(0xFFE0E0E0),
                      onTap: () =>
                          context.read<NavigationProvider>().navigateToPage(
                                context,
                                SearchPage(
                                  id_category: kategori.no_id,
                                  nama_category: kategori.nama_kategori,
                                  search: "",
                                ),
                              ),
                    ),
                  ),
                )
                .toList(),
          )
        else
          Column(
            children: kategoriProvider.kategoriRows.map((row) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((kategori) {
                  final imgUrl = kategori.id_media;
                  return SizedBox(
                    width: itemWidth,
                    child: KategoriButton(
                      imageUrl: imgUrl,
                      label: kategori.nama_kategori,
                      bgColor: Color(0xFFE0E0E0),
                      onTap: () =>
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
                              ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
      ],
    );
  }
}
