import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/pages/fotografi_vendor/image_crop2.dart';
import 'package:mpjnew/src/pages/fotografi_vendor/pemasukan.dart';
import 'package:mpjnew/src/pages/fotografi_vendor/vendor_all_chat.dart';
import 'package:mpjnew/src/pages/fotografi_vendor/vendor_bio.dart';

import 'package:mpjnew/src/pages/fotografi_vendor/vendor_home.dart';
import 'package:provider/provider.dart';

import '../../core/routing/navigation_provider.dart';  // Import NavigationProvider
import 'coba_text_field.dart';
import 'imageupload.dart';
import 'upload_video.dart';
import 'view_gambar.dart';
import 'biodata.dart';


class Vendor_MenuUtama extends StatefulWidget {
  const Vendor_MenuUtama({super.key});

  @override
  State<Vendor_MenuUtama> createState() => _Vendor_MenuUtamaState();
}

class _Vendor_MenuUtamaState extends State<Vendor_MenuUtama> {
   bool _sudahCekLogin = false;

@override
 


  @override
  Widget build(BuildContext context) {

    print("====== >>> MASUK Vendor_MenuUtama build");
 if (!_sudahCekLogin) {
      _sudahCekLogin = true;

      Future.microtask(() {
        final navProvider = Provider.of<NavigationProvider>(context, listen: false);
        navProvider.checkLogin(context, Constants.vendor, currentPage: Vendor_MenuUtama);
      });
    }

    return WillPopScope(
      onWillPop: () async {
        final provider = Provider.of<NavigationProvider>(context, listen: false);
        return await provider.onWillPop();
      },
      child: Scaffold(
        body: Consumer<NavigationProvider>(
          builder: (context, navigationProvider, child) {
           return Stack(
  children: [
   
    _buildOffstageNavigator(0, (_) => VendorHome()),       // Beranda
    _buildOffstageNavigator(1, (_) => VendorAllChat()),    // Pesan
    _buildOffstageNavigator(2, (_) => PemasukanPage()),    // Pemasukan
  ],
);

          },
        ),
        bottomNavigationBar: Consumer<NavigationProvider>(
          builder: (context, navigationProvider, child) {
            int selectedIndex = navigationProvider.selectedIndex;

            return BottomNavigationBar(
              currentIndex: selectedIndex,
              selectedItemColor: Constants.primaryColorVendor,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              onTap: (index) => navigationProvider.onItemTappedVendor(index, context),
              items: [
               BottomNavigationBarItem(
                  icon: Icon(
                    selectedIndex == 0
                        ? Icons.home
                        : Icons.home_outlined,
                  ),
                  label: 'Beranda',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    selectedIndex == 1
                        ? Icons.chat
                        : Icons.chat_outlined,
                  ),
                  label: 'Pesan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    selectedIndex == 2
                        ? Icons.account_balance_wallet
      : Icons.account_balance_wallet_outlined,
                  ),
                  label: 'Pemasukan',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOffstageNavigator(int index, WidgetBuilder builder) {
  return Consumer<NavigationProvider>(
    builder: (context, provider, _) {
      return Offstage(
        offstage: provider.selectedIndex != index,
        child: Navigator(
          key: provider.navigatorKeys[index],
          onGenerateRoute: (_) => MaterialPageRoute(builder: builder),
        ),
      );
    },
  );
}

}
