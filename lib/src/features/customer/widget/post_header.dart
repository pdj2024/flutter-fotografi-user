import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/models/portofolio_model.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:mpjnew/src/features/customer/widget/avatar_circle.dart';
import 'package:provider/provider.dart';

class PostHeader extends StatelessWidget {
  final PortofolioModel portofolio;
  const PostHeader({super.key, required this.portofolio});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // Semua dibungkus dalam GestureDetector
          Expanded(
            child: GestureDetector(
              onTap: () => context.read<NavigationProvider>().navigateToPage(
                    context,
                    VendorBioPage(idVendor: portofolio.idVendor),
                    targetTabIndex: 0,
                  ),
              child: Row(
                children: [
                  // Avatar
                  AvatarCircle(size: 36, imgUrl: portofolio.idMediaVendor),
                  const SizedBox(width: 12),
                  // Nama + rating
                  Expanded(
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              portofolio.usernameVendor ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              portofolio.namaKategori ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        if (portofolio.ratingVendor != 0) ...[
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 2),
                          Text(
                            portofolio.ratingVendor.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tombol chat
          SizedBox(
            height: 44,
            width: 44,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Constants.primaryColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: EdgeInsets.zero,
              ),
              onPressed: () {
                context.read<NavigationProvider>().navigateToPage(
                      context,
                      RoomChatPage(
                        roomId: null,
                        partnerId: portofolio.idVendor,
                        partnerUsername: portofolio.usernameVendor,
                        partnerAvatarUrl: portofolio.idMediaVendor,
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
    );
  }
}
