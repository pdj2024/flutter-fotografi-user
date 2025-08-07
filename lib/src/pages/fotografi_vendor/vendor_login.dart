import 'package:flutter/material.dart';
import 'package:mpjnew/src/pages/fotografi_user/all_chat.dart';
import 'package:mpjnew/src/pages/fotografi_user/all_order.dart';
import 'package:mpjnew/src/pages/fotografi_vendor/biodata.dart';
import 'package:mpjnew/src/pages/fotografi_vendor/vendor_home.dart';
import 'package:mpjnew/src/pages/fotografi_vendor/vendor_status.dart';
import 'package:provider/provider.dart';

import '../fotografi_user/singlepage.dart';
import '../fotografi_user/fotographerbio.dart';
import '../providers/auth_service_fotografi.dart';
import '../providers/constants.dart';

import '../providers/navigation_provider.dart';
import 'vendor_menutama.dart';

class VendorLogin extends StatefulWidget {
  const VendorLogin({super.key});

  @override
  State<VendorLogin> createState() => _VendorLoginState();
}

class _VendorLoginState extends State<VendorLogin> {

 final _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
    final String targetPage = args['targetPage'] ?? 'EcommerceHome';
    final int tabIndex = args['tabIndex'] ?? 0;

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
                      // Camera icon (local asset)
                      Image.asset(
                        'assets/camera_icon_transparent.png',
                        height: availableHeight * 0.07,
                      ),
                      const SizedBox(height: 20),
                      // Image tengah user_login_image.png (local asset)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: Image.asset(
                          'assets/user_login_image.png',
                          width: screenWidth,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Welcome Text
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
                            'Fotografi (VENDOR)',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Constants.primaryColorVendor,
                              fontSize: 28,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // Google Login Button
                   Padding(
  padding: const EdgeInsets.symmetric(horizontal: 25),
  child: TextButton.icon(
    onPressed: () async {
      final idToken = null; // await _auth.authKeGoogle();   // 🔹 AuthService return idToken langsung

      if (idToken != null) {
           final status = await context.read<NavigationProvider>().checkStatusUser(idToken, Constants.vendor);

          if (status.toLowerCase() == 'aktif') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Vendor_MenuUtama()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VendorStatus()));
    }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login dibatalkan atau gagal.")),
        );
      }
    },
    icon: Image.asset(
      'assets/google_icon.png',
      height: 24,
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
)

                    
                    ],
                  ),
                ),
              
              ],
            );
          },
        ),
      ),
    );
  }
}