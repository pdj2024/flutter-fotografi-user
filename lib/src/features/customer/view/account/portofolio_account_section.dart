import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/view/single_post_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:provider/provider.dart';

class PortofolioAccountSection extends StatefulWidget {
  final String data; // like / save
  const PortofolioAccountSection({super.key, required this.data});

  @override
  State<PortofolioAccountSection> createState() =>
      _PortofolioAccountSectionState();
}

class _PortofolioAccountSectionState extends State<PortofolioAccountSection> {
  bool isLoading = false;

  Future<void> refresh(BuildContext context) async {
    setState(() {
      isLoading = true;
    });
    await context.read<UserProvider>().checkLoginGoogle(role: 'customer');
    await context.read<PortofolioProvider>().loadPortofolio(context);
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PortofolioProvider>(
      builder: (context, portofolioProvider, _) {
        final dataList = widget.data == 'like'
            ? portofolioProvider.portofolioLikelist
            : portofolioProvider.portofolioSaveList;

        // STATE LOADING
        if (isLoading) {
          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (_, __) => ShimmerPlaceholder(radius: 15),
          );
        }

        // STATE KOSONG
        if (dataList.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => refresh(context),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                Icon(Icons.camera_alt_outlined, size: 150, color: Colors.grey),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    "Belum ada portoflio",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // STATE NORMAL
        return RefreshIndicator(
          onRefresh: () => refresh(context),
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8),
            itemCount: dataList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final p = dataList[index];
              final mediaList = p.mediaUrls;

              final firstMedia = mediaList.isNotEmpty ? mediaList.first : null;
              final isVideo =
                  (firstMedia?.contentType ?? '').startsWith('video');
              final mediaUrl = isVideo
                  ? (firstMedia?.thumbUrl ?? firstMedia?.url)
                  : firstMedia?.url;

              if (mediaUrl == null) {
                return const Icon(Icons.broken_image_outlined);
              }

              return GestureDetector(
                onTap: () {
                  context.read<NavigationProvider>().navigateToPage(
                        context,
                        SinglePostPage(noId: p.noId, idVendor: p.idVendor),
                        hrsLogin: true,
                        targetTabIndex: 3,
                      );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade200,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: mediaUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => ShimmerPlaceholder(radius: 10),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
