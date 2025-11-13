import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/widget/portofolio_card.dart';
import 'package:mpjnew/src/pages/fotografi_user/searchpage.dart';
import 'package:provider/provider.dart';

class PortofolioSection extends StatefulWidget {
  PortofolioSection({super.key});

  @override
  State<PortofolioSection> createState() => _PortofolioSectionState();
}

class _PortofolioSectionState extends State<PortofolioSection> {
  @override
  void initState() {
    super.initState();
    // ambil data kategori dari provider saat pertama kali build
    Future.microtask(
        () => context.read<PortofolioProvider>().loadPortofolio(context));
  }

  @override
  Widget build(BuildContext context) {
    final portofolioProvider = context.watch<PortofolioProvider>();
    final portofolioList = portofolioProvider.portofolioList;
    final isLoadingPorto = portofolioProvider.isLoadingPorto;
    final error = portofolioProvider.errorPorto;

    final screenWidth = MediaQuery.of(context).size.width;

    print("======= All Portofolio: ${portofolioList.length}");
    print("Error: $error");

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Header =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Jelajah",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                GestureDetector(
                  onTap: () {
                    context.read<NavigationProvider>().navigateToPage(
                          context,
                          SearchPage(
                            id_category: '',
                            nama_category: '',
                            search: "",
                          ),
                          targetTabIndex: 0,
                          targetPage: "SearchPage",
                          hrsLogin: false,
                        );
                  },
                  child: Text(
                    "Lihat Semua",
                    style: TextStyle(color: Constants.primaryColor),
                  ),
                ),
              ],
            ),
          ),

          // ===== Kondisi Loading =====
          if (isLoadingPorto)
            ...List.generate(5, (index) => _buildShimmerCard()),

          // ===== Kondisi Error =====
          if (!isLoadingPorto && error != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Text('Error: $error'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context
                          .read<PortofolioProvider>()
                          .loadPortofolio(context),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),

          // ===== Kondisi Kosong =====
          if (!isLoadingPorto && error == null && portofolioList.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('Belum ada portofolio')),
            ),

          // ===== Daftar Portofolio =====
          if (!isLoadingPorto && error == null && portofolioList.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: portofolioList.length,
              itemBuilder: (context, index) {
                final p = portofolioList[index];
                final String? mediaUrl = p.mediaUrls.first.url;

                // final String? mediaUrl =
                //     context.read<NavigationProvider>().getMediaUrl(p) ?? '';

                return PortofolioCard(
                  photographerIcon: p.idMediaVendor,
                  imageUrl: mediaUrl,
                  name: p.usernameVendor,
                  rating: p.ratingVendor,
                  noId: p.noId,
                  idVendor: p.idVendor,
                );
              },
            ),
        ],
      ),
    );
  }

  // =============== Widget Helper ===============
  Widget _buildShimmerCard() {
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
          // Shimmer untuk gambar utama
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: const ShimmerPlaceholder(
              height: 160,
              radius: 15,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: const [
                ClipOval(
                  child: ShimmerPlaceholder(width: 32, height: 32, radius: 16),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ShimmerPlaceholder(height: 14, radius: 4),
                ),
                SizedBox(width: 10),
                ShimmerPlaceholder(width: 40, height: 14, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
