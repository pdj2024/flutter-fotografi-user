import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/features/auth/widget/role_card.dart';

// Import your destination pages
import '../../../pages/fotografi_vendor/vendor_menutama.dart';
import 'package:provider/provider.dart';
import '../../../core/routing/navigation_provider.dart';
import '../../../pages/fotografi_user/menutama.dart';

class PilihRole extends StatelessWidget {
  const PilihRole({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final cardWidth = screenWidth * 0.42;
    final spacing = screenWidth * 0.03;

    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final imageHeight = availableHeight * 0.07;
            final spacingAfterImage = availableHeight * 0.07;
            final cardHeight = availableHeight * 0.48;
            final String imgUrl = 'assets/camera_icon_transparent.png';

            return Column(
              children: [
                const SizedBox(height: 30),
                Image.asset(
                  imgUrl,
                  height: imageHeight,
                ),
                SizedBox(height: spacingAfterImage),
                const Text(
                  'Pilih Peran Anda',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RoleCard(
                      image: 'assets/fotografer_editted.jpg',
                      title: 'Sebagai\nFotografer',
                      width: cardWidth,
                      height: cardHeight,
                      onTap: () async {
                        // ✅ simpan role
                        await context
                            .read<NavigationProvider>()
                            .saveRole(Constants.vendor);
                        // ✅ arahkan ke halaman vendor, ganti push jadi pushReplacement biar tidak bisa back
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Vendor_MenuUtama(),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: spacing),
                    RoleCard(
                      image: 'assets/family3.png',
                      title: 'Sebagai\nPengguna',
                      width: cardWidth,
                      height: cardHeight,
                      onTap: () async {
                        // ✅ simpan role
                        await context
                            .read<NavigationProvider>()
                            .saveRole(Constants.customer);
                        // ✅ arahkan ke halaman user
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Ecommerce_MenuUtama(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize
                          .min, // Ensures the column takes up only the necessary space
                      children: [
                        RichText(
                          text: const TextSpan(
                            text: 'Selamat Datang di',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(height: 2), // Adds space between the two texts
                        RichText(
                          text: const TextSpan(
                            text: 'Fotografi',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Constants.primaryColor,
                              fontSize: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
