import 'package:flutter/material.dart';
import 'package:mpjnew/src/pages/fotografi_user/all_chat.dart';
import 'package:mpjnew/src/pages/fotografi_user/all_order.dart';

import 'package:mpjnew/src/pages/fotografi_user/searchpage.dart';
import 'package:mpjnew/src/pages/fotografi_user/services/customer_service.dart';
import 'package:provider/provider.dart';

import '../providers/auth_service_fotografi.dart';
import '../providers/constants.dart';
import 'menutama.dart';
import 'providers/user_provider.dart';
import 'singlepage.dart';
import 'fotographerbio.dart';
import '../providers/navigation_provider.dart';
import 'package:mpjnew/src/pages/core/api_singleton.dart';


class UserLogin extends StatefulWidget {
  const UserLogin({super.key});

  @override
  State<UserLogin> createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  final _auth = AuthService();
  

  final CustomerService _customerService = CustomerService();

 Future<void> handleLoginGoogle(
  BuildContext context,
  String targetPage,
  int tabIndex,
  String? noIdPortofolio,
  String? noIdVendor,
) async {
  try {
    final provider = context.read<UserProvider>();
    await provider.checkLoginGoogle(role: Constants.customer); // ⬅️ gunakan provider

    if (provider.customer != null) {
      // ✅ Login sukses: tutup dialog dan navigasi
      Navigator.of(context).pop();

      context.read<NavigationProvider>().navigateToPage(
            context,
            getPageFromString(
              targetPage,
              noIdPortofolio: noIdPortofolio,
              noIdVendor: noIdVendor,
            ),
            targetTabIndex: tabIndex,
          );
    } else {
      // ❌ Login gagal (silent atau dibatalkan)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login gagal atau dibatalkan.")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Terjadi kesalahan saat login: $e")),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
            {};
    final String targetPage = args['targetPage'] ?? 'EcommerceHome';
    final int tabIndex = args['tabIndex'] ?? 0;
    final String? noIdPortofolio = args['noIdPortofolio'];
    final String? noIdVendor = args['noIdVendor'];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            return Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Image.network(
                        context.read<NavigationProvider>().ambilGambar(
                            'ae07e42b-33e3-4bfa-837f-7227bf92fe93-camera_icon_transparent.png',
                            umum: true),
                        height: availableHeight * 0.07,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.camera_alt,
                              size: availableHeight * 0.07, color: Colors.grey);
                        },
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: Image.network(
                          context.read<NavigationProvider>().ambilGambar(
                              '5595a36d-1307-4a11-83d7-247e5974139b-user_login_image.png',
                              umum: true),
                          width: screenWidth,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: screenWidth,
                              height: screenWidth * 0.6, // misal 3:2 ratio
                              color: Colors.grey[300],
                              child: const Center(
                                  child: Icon(Icons.broken_image,
                                      size: 48, color: Colors.grey)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      Column(
                        children: const [
                          Text(
                            'Selamat Datang di',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Fotografi (CUSTOMER)',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Constants.primaryColor,
                              fontSize: 28,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: TextButton.icon(
                          onPressed: () async {
                            await handleLoginGoogle(context, targetPage,
                                tabIndex, noIdPortofolio, noIdVendor);
                                
                          },
                          icon: Image.network(
                            context.read<NavigationProvider>().ambilGambar(
                                '6642a042-f49a-4f1a-bca7-543457859644-google_icon.png',
                                umum: true),
                            height: 24,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.account_circle,
                                  size: 24, color: Colors.grey);
                            },
                          ),
                          label: const Text(
                            'Masuk dengan Gmail',
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back,
                        size: 24, color: Colors.black),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

  
  }

  Widget getPageFromString(String targetPage,
      {String? noIdPortofolio, String? noIdVendor}) {
    print("===== TARGET: $targetPage");
    switch (targetPage) {
      case 'SinglePostPage':
        return SinglePostPage(
          noId: noIdPortofolio ?? 'porto_6',
        ); // Ganti dengan halaman yang sesuai
      case 'PhotographerBio':
        return PhotographerBio(
          idVendor: noIdVendor ?? 'ven_2',
        ); // Ganti dengan halaman yang sesuai
      // Tambahkan halaman lain sesuai dengan kasusnya

      case 'Tab1':
        return AllChat();
      case 'Tab2':
        return AllOrder();
      default:
        return SinglePostPage(
          noId: noIdPortofolio ?? 'porto_6',
        ); // Default ke halaman SinglePostPage
    }
  }
}
