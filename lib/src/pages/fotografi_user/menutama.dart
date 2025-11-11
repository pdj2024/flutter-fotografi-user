import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'all_chat.dart';
import 'all_order.dart';
import 'home.dart';
import '../providers/navigation_provider.dart';  // Import NavigationProvider
import 'video_player.dart';

class Ecommerce_MenuUtama extends StatelessWidget {
  const Ecommerce_MenuUtama({super.key});

  @override
  Widget build(BuildContext context) {
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
                _buildOffstageNavigator(0, EcommerceHome()),
                _buildOffstageNavigator(1, AllChat()),
                _buildOffstageNavigator(2, AllOrder()),
              ],
            );
          },
        ),
        bottomNavigationBar: Consumer<NavigationProvider>(
          builder: (context, navigationProvider, child) {
            return BottomNavigationBar(
              currentIndex: navigationProvider.selectedIndex,
              selectedItemColor: Constants.primaryColor,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              onTap: (index) => navigationProvider.onItemTapped(index, context),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.explore),
                  label: 'Jelajah',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_outlined),
                  label: 'Pesan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment_outlined),
                  label: 'Order',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOffstageNavigator(int index, Widget page) {
  return Consumer<NavigationProvider>(
    builder: (context, provider, _) {
      return Offstage(
        offstage: provider.selectedIndex != index,
        child: Navigator(
          key: provider.navigatorKeys[index],
          onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => page),
        ),
      );
    },
  );
}

}
