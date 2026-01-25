import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/services/auth_service_instance.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/view/chat/chat_list_page.dart';
import 'package:mpjnew/src/features/customer/view/account/customer_account_page.dart';
import 'package:mpjnew/src/features/customer/view/customer_home_page.dart';
import 'package:mpjnew/src/features/customer/view/history/main_order_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:provider/provider.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  @override
  Widget build(BuildContext context) {
    final navigationProvider = context.watch<NavigationProvider>();
    final chatProvider = context.watch<ChatProvider>();

    return WillPopScope(
      onWillPop: () async {
        final provider =
            Provider.of<NavigationProvider>(context, listen: false);
        return await provider.onWillPop(context);
      },
      child: Scaffold(
        key: const PageStorageKey('MainMenu'),
        body: Consumer<NavigationProvider>(
          builder: (context, navigationProvider, child) {
            return Stack(
              children: [
                _buildOffstageNavigator(0, (_) => CustomerHomePage()),
                _buildOffstageNavigator(1, (_) => ChatListPage()),
                _buildOffstageNavigator(2, (_) => MainOrderPage()),
                _buildOffstageNavigator(3, (_) => CustomerAccountPage()),
              ],
            );
          },
        ),
        // ✅ Conditional bottom navigation bar
        bottomNavigationBar: navigationProvider.isBottomNavVisible
            ? Consumer<NavigationProvider>(
                builder: (context, navigationProvider, child) {
                  int selectedIndex = navigationProvider.selectedIndex;

                  return BottomNavigationBar(
                    currentIndex: selectedIndex,
                    selectedItemColor: Constants.primaryColor,
                    unselectedItemColor: Colors.grey,
                    type: BottomNavigationBarType.fixed,
                    onTap: (index) =>
                        _handleTabTap(index, context, selectedIndex),
                    items: [
                      BottomNavigationBarItem(
                        icon: Icon(selectedIndex == 0
                            ? Icons.explore
                            : Icons.explore_outlined),
                        label: 'Jelajah',
                      ),
                      BottomNavigationBarItem(
                        icon: SizedBox(
                          width: 40,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                selectedIndex == 1
                                    ? Icons.chat
                                    : Icons.chat_outlined,
                              ),
                              if (chatProvider.totalUnreadCount > 0)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.shade200,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        chatProvider.totalUnreadCount > 99
                                            ? '99+'
                                            : chatProvider.totalUnreadCount
                                                .toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        label: 'Pesan',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(selectedIndex == 2
                            ? Icons.assignment
                            : Icons.assignment_outlined),
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
              )
            : null, // ✅ Hide bottom nav when navigating to child pages
      ),
    );
  }

  // ✅ Handle tab tap
  Future<void> _handleTabTap(
      int index, BuildContext context, int currentIndex) async {
    final navigationProvider = context.read<NavigationProvider>();
    final userProvider = context.read<UserProvider>();
    final user = userProvider.customer;

    debugPrint("🔘 [MainMenu] Tab $index tapped, current: $currentIndex");
    debugPrint("👤 [MainMenu] User: ${user?.namaDisplay ?? 'Not logged in'}");

    // ✅ Navigation check dilakukan di onItemTapped
    navigationProvider.onItemTapped(index, context);

    // ✅ Refresh logic jika user sudah login DAN tap tab yang sama
    if (user != null && currentIndex == index) {
      await _handleTabRefresh(index, context, user);
    }
  }

  // ✅ Handle refresh saat tap tab yang sama
  Future<void> _handleTabRefresh(
      int index, BuildContext context, dynamic user) async {
    debugPrint("🔄 [MainMenu] Refreshing tab $index");

    switch (index) {
      case 0: // Home/Jelajah
        // Refresh home data if needed
        break;

      case 1: // Chat
        final chatProv = context.read<ChatProvider>();
        await chatProv.initWithApiClient(
          userId: user.noId,
          userType: Constants.customer,
          hubUrl: "${Constants.baseUrlHub}/api/chathub",
          getToken: () async =>
              await authService.getIdToken(forceRefresh: true),
        );
        break;

      case 2: // Order
        context.read<PesananProvider>().loadOrder(userId: user.noId);
        break;

      case 3: // Profile
        await context.read<UserProvider>().checkLoginGoogle(role: 'customer');
        await context.read<PortofolioProvider>().loadPortofolio(context);
        break;
    }
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