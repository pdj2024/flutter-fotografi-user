import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/view/chat_list_page.dart';
import 'package:mpjnew/src/features/customer/view/account/customer_account_page.dart';
import 'package:mpjnew/src/features/customer/view/customer_home_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/room_chat_provider.dart';
import 'package:mpjnew/src/pages/fotografi_user/all_order.dart';
import 'package:provider/provider.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  String getValidImage(String? url) {
    if (url == null || url.isEmpty || !url.startsWith('http')) {
      return "https://cdn-icons-png.flaticon.com/512/3276/3276535.png";
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.customer;
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
                _buildOffstageNavigator(1, ChatListPage()),
                _buildOffstageNavigator(2, AllOrder()),
                _buildOffstageNavigator(3, CustomerAccountPage()),
              ],
            );
          },
        ),
        bottomNavigationBar: Consumer<NavigationProvider>(
          builder: (context, navigationProvider, child) {
            int selectedIndex = navigationProvider.selectedIndex;

            return BottomNavigationBar(
              currentIndex: navigationProvider.selectedIndex,
              selectedItemColor: Constants.primaryColor,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              onTap: (index) async {
                navigationProvider.onItemTapped(index, context);
                if (index == 3) {
                  await context
                      .read<UserProvider>()
                      .checkLoginGoogle(role: 'customer');
                  await context
                      .read<PortofolioProvider>()
                      .loadPortofolio(context);
                }

                if (index == 1 && user != null) {
                  final roomProvider = context.read<RoomChatProvider>();
                  final chatProvider = context.read<ChatProvider>();

                  if (roomProvider.activeRoomId != null &&
                      roomProvider.roomInfo != null) {
                    await roomProvider.initChat(
                      roomId: roomProvider.activeRoomId,
                      partnerId: roomProvider.roomInfo!.idLawan,
                    );
                    await roomProvider.loadOfferData();
                  } else {
                    chatProvider.isReady = false;
                    await chatProvider.init(user.noId);
                  }
                }
              },
              items: [
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
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedIndex == 3
                            ? Constants.primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(Icons.person),
                  ),
                  label: 'Profile',
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
        print("testing");
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
