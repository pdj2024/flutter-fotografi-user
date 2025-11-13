import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/features/customer/view/customer_home_page.dart';
import 'package:mpjnew/src/pages/fotografi_user/all_chat.dart';
import 'package:mpjnew/src/pages/fotografi_user/all_order.dart';
import 'package:provider/provider.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final provider =
            Provider.of<NavigationProvider>(context, listen: false);
        return await provider.onWillPop();
      },
      child: Scaffold(
        key: const PageStorageKey('MainMenu'),
        body: Consumer<NavigationProvider>(
          builder: (context, navigationProvider, child) {
            return Stack(
              children: [
                _buildOffstageNavigator(0, CustomerHomePage()),
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
