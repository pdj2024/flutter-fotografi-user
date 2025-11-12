import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:mpjnew/src/pages/fotografi_user/singlepage.dart';
import 'package:provider/provider.dart';

class PortofolioCard extends StatelessWidget {
  const PortofolioCard({
    Key? key,
    required this.photographerIcon,
    this.imageUrl,
    required this.name,
    required this.rating,
    this.aspectRatio = 5 / 4,
    required this.noId,
    required this.idVendor,
  }) : super(key: key);

  final String photographerIcon;
  final String? imageUrl;
  final String name;
  final double rating;
  final double aspectRatio;
  final String noId;
  final String idVendor;

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    final bool isImageValid = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final bool isAvatarValid = photographerIcon.trim().isNotEmpty;

    print("IS IMAGE VALID: $isImageValid");
    if (isImageValid == false) print(imageUrl);
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
          GestureDetector(
            onTap: () => nav.navigateToPage(
              context,
              SinglePostPage(noId: noId),
              targetTabIndex: 0,
              targetPage: 'SinglePostPage',
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: isImageValid
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return ShimmerPlaceholder(radius: 15);
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child:
                              const Icon(Icons.broken_image_outlined, size: 40),
                        ),
                      )
                    : ShimmerPlaceholder(radius: 15),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => nav.navigateToPage(
              context,
              VendorBioPage(idVendor: idVendor),
              targetTabIndex: 0,
              targetPage: 'VendorBioPage',
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: isAvatarValid
                          ? Image.network(
                              photographerIcon,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(Icons.person, size: 16),
                              ),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return ShimmerPlaceholder(radius: 16);
                              },
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.person, size: 16),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (rating > 0) ...[
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
