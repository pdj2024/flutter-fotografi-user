import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/models/vendor_model.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:mpjnew/src/features/customer/view/vendor_list_package_page.dart';
import 'package:provider/provider.dart';

class VendorBioCard extends StatelessWidget {
  final VendorModel vendor;
  final bool isListPackagePage;

  const VendorBioCard({
    super.key,
    required this.vendor,
    this.isListPackagePage = false,
  });

  @override
  Widget build(BuildContext context) {
    final String notFoundUsername = 'vendor-not-found';

    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 16),
      child: GestureDetector(
        onTap: () => NavigationProvider().navigateToPage(
          context,
          VendorBioPage(idVendor: vendor.noId),
          targetTabIndex: 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: vendor.idMedia,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          ShimmerPlaceholder(width: 60, height: 60, radius: 30),
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
                            vendor.namaDisplay,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.kota,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                          if (isListPackagePage)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: SizedBox(
                                height: 40,
                                width: 40,
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
                                    context
                                        .read<NavigationProvider>()
                                        .navigateToPage(
                                          context,
                                          RoomChatPage(
                                            roomId: null,
                                            partnerId: vendor.noId,
                                            partnerUsername: vendor.username,
                                            partnerAvatarUrl: vendor.idMedia,
                                          ),
                                          targetTabIndex: 1,
                                        );
                                  },
                                  child: const Icon(
                                    Icons.chat_outlined,
                                    color: Constants.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Deskripsi Vendor
            /** 
             * Menampilkan Deskripsi Vendor Ketika:
             * 1. withListPackage = false
             * 2. vendor.deskripsiBio != ''
            */
            if (!isListPackagePage && vendor.deskripsiBio != '') ...[
              const SizedBox(height: 16),
              Text(
                vendor.deskripsiBio,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
            if (vendor.username != notFoundUsername && !isListPackagePage) ...[
              const SizedBox(height: 20),
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
                              builder: (context) => VendorListPackagePage(
                                vendor: vendor,
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
                        side: const BorderSide(color: Constants.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        context.read<NavigationProvider>().navigateToPage(
                              context,
                              RoomChatPage(
                                roomId: null,
                                partnerId: vendor.noId,
                                partnerUsername: vendor.username,
                                partnerAvatarUrl: vendor.idMedia,
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
            ]
          ],
        ),
      ),
    );
  }
}
