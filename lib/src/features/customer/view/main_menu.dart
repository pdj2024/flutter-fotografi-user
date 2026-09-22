import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/services/fcm/fcm_service.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/local_storage_service.dart';
import 'package:mpjnew/src/features/customer/view/chat/chat_list_page.dart';
import 'package:mpjnew/src/features/customer/view/account/customer_account_page.dart';
import 'package:mpjnew/src/features/customer/view/customer_home_page.dart';
import 'package:mpjnew/src/features/customer/view/history/main_order_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:mpjnew/src/features/customer/widget/help_fab.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

/// ✨ MAIN MENU - FCM-ONLY VERSION
/// dengan Auto Hide/Show Bottom Nav via RouteObserver
class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  bool _sudahCekLogin = false;

  /// Tab yang pernah dibuka — sekali masuk, tetap di-mount agar state dan
  /// posisi scroll-nya bertahan saat user berpindah tab.
  final Set<int> _mountedTabs = {0};

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final navigationProvider = context.watch<NavigationProvider>();
    final chatProvider = context.watch<ChatProvider>();

    // ✅ Initialize providers sekali saja saat user sudah login
    if (userProvider.customer != null && !_sudahCekLogin) {
      _sudahCekLogin = true;
      Future.microtask(() async {
        await _initializeProviders(context, userProvider, navigationProvider);
      });
    }

    return WillPopScope(
      onWillPop: () async {
        final provider =
            Provider.of<NavigationProvider>(context, listen: false);
        return await provider.onWillPop(context);
      },
      child: SafeArea(
        child: Scaffold(
          key: const PageStorageKey('MainMenu'),
          body: Consumer<NavigationProvider>(
            builder: (context, navigationProvider, child) {
              return Stack(
                children: [
                  _buildOffstageNavigator(0, (_) => CustomerHomePage()),
                  _buildOffstageNavigator(1, (_) => const ChatListPage()),
                  _buildOffstageNavigator(2, (_) => const MainOrderPage()),
                  _buildOffstageNavigator(
                      3, (_) => const CustomerAccountPage()),
                  Consumer<NavigationProvider>(
                    builder: (context, nav, _) {
                      final isHiddenTab = nav.selectedIndex == 1;
                      final isNestedPage = !nav.isBottomNavVisible;

                      if (isHiddenTab || isNestedPage) {
                        return const SizedBox.shrink();
                      }

                      return const Positioned(
                        bottom: 20,
                        right: 16,
                        child: HelpFab(),
                      );
                    },
                  ),
                ],
              );
            },
          ),
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
                                if (chatProvider.totalUnreadCount > 0 &&
                                    userProvider.userId != null)
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
                            child: const Icon(Icons.person),
                          ),
                          label: 'Profile',
                        ),
                      ],
                    );
                  },
                )
              : null,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> _initializeProviders(
    BuildContext context,
    UserProvider userProvider,
    NavigationProvider navigationProvider,
  ) async {
    try {
      debugPrint("═══════════════════════════════════════");
      debugPrint("[MainMenu] 🚀 INITIALIZING");
      debugPrint("═══════════════════════════════════════");

      final customer = userProvider.customer;
      if (customer == null) {
        debugPrint("[MainMenu] ⚠️ customer null, skip init");
        return;
      }

      final chatProv = context.read<ChatProvider>();
      final historyOrderProv = context.read<HistoryOrderProvider>();
      final pesananProv = context.read<PesananProvider>();

      // ── FIX BUG: Pastikan ChatProvider ter-inisiasi ──────────────
      // SplashLogicHandler hanya memanggil initialize() jika session
      // berhasil di-restore. Jika user baru login, ChatProvider masih
      // belum ter-inisiasi → semua method bailout karena _currentUserId=null.
      if (!chatProv.isInitialized) {
        debugPrint("[MainMenu] 🔄 ChatProvider belum init, initializing...");
        await chatProv.initialize(
          userId: customer.noId,
          userType: Constants.customer,
        );
        debugPrint("[MainMenu] ✅ ChatProvider initialized");
      } else {
        debugPrint("[MainMenu] ℹ️ ChatProvider sudah init, skip");
      }

      // ── Request notification permission ──────────────────────────
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        if (status.isDenied && mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Izin Notifikasi'),
              content: const Text(
                'Aplikasi membutuhkan izin notifikasi untuk '
                'memberi tahu Anda tentang pesan baru dan update order.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Nanti'),
                ),
                TextButton(
                  onPressed: () {
                    openAppSettings();
                    Navigator.pop(context);
                  },
                  child: const Text('Buka Pengaturan'),
                ),
              ],
            ),
          );
        } else if (status.isPermanentlyDenied && mounted) {
          CustomSnackbar.showActionSnackbar(
            context,
            "Izin notifikasi ditolak. \nBuka Pengaturan untuk mengaktifkannya.",
            SnackBarAction(
              label: 'Pengaturan',
              onPressed: () => openAppSettings(),
            ),
          );
        }
      }

      // ── Setup FCM callbacks ──────────────────────────────────────
      // CATATAN: MyApp._setupFCMCallbacks() sudah di-set via
      // addPostFrameCallback. Di sini kita OVERRIDE dengan versi
      // yang punya akses ke context MainMenu (lebih fresh).
      // Ini aman karena MainMenu hidup selama app aktif.
      debugPrint("[MainMenu] 🔧 Setting up FCM callbacks...");

      FCMService.instance.getSenderName = (roomId, senderId) {
        return chatProv.getSenderName(roomId, senderId);
      };

      FCMService.instance.onChatMessageReceived = (chatMessage) {
        debugPrint("[MainMenu] 📨 Chat message from FCM");
        chatProv.handleMessageFromFCM(chatMessage);
      };

      FCMService.instance.onProgressReceived = (progressData) {
        debugPrint("[MainMenu] 📊 Order progress from FCM");
        final noOrder = progressData.noOrder;
        if (noOrder != null) {
          historyOrderProv.handleProgressFromFCM(progressData);
          // Full refresh (bukan updateOrderStatus) -- history progres bisa
          // dibuat tanpa status berubah (mis. perpanjang batas pengerjaan),
          // dan updateOrderStatus cuma menambal statusProgresPesanan +
          // deskripsiProgresPesanan secara lokal, field lain seperti
          // tglPengerjaanMax tidak pernah ikut ter-refresh dari situ.
          pesananProv.refreshOrder(noOrder);
        }
      };

      FCMService.instance.onNotificationTapped = (roomId) {
        debugPrint("[MainMenu] 👆 Notification tapped: $roomId");
        chatProv.trackRoom(roomId);
        chatProv.setActiveRoom(roomId);
        FCMService.instance.setActiveRoom(roomId);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          navigationProvider.onItemTapped(1, context);
        });
      };

      debugPrint("[MainMenu] ✅ FCM callbacks configured");

      // ── Load initial data (T2 — background) ──────────────────────
      // Portofolio SENGAJA tidak di-load di sini: splash sudah mem-prefetch-nya
      // (splash_logic_handler _loadInitialData). Memanggil loadPortofolio lagi
      // menyalakan ulang _isLoadingPorto → Home balik ke shimmer tepat setelah
      // splash bilang "Menyiapkan gambar...".
      //
      // loadOrder tidak di-await: tab Pesanan bukan layar pertama, jadi
      // jangan tahan Home hanya untuk itu.
      debugPrint("[MainMenu] 📥 Loading initial data (background)...");
      unawaited(pesananProv.loadOrder(context));

      debugPrint("[MainMenu] ✅ INITIALIZATION COMPLETE");
    } catch (e, st) {
      debugPrint("[MainMenu] ❌ INITIALIZATION ERROR: $e\n$st");
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB HANDLING
  // ═══════════════════════════════════════════════════════════════

  Future<void> _handleTabTap(
    int index,
    BuildContext context,
    int currentIndex,
  ) async {
    final navigationProvider = context.read<NavigationProvider>();
    final userProvider = context.read<UserProvider>();
    final user = userProvider.customer;

    debugPrint("🔘 [MainMenu] Tab $index tapped, current: $currentIndex");

    navigationProvider.onItemTapped(index, context);

    // Refresh jika tap tab yang sama
    if (user != null && currentIndex == index) {
      await _handleTabRefresh(index, context, user);
    }
  }

  Future<void> _handleTabRefresh(
    int index,
    BuildContext context,
    dynamic user,
  ) async {
    debugPrint("🔄 [MainMenu] Refreshing tab $index");

    try {
      switch (index) {
        case 0: // Home
          await context.read<PortofolioProvider>().loadPortofolio(context);
          break;

        case 1: // Chat
          final chatProv = context.read<ChatProvider>();
          await chatProv.loadRooms(forceRefresh: true);
          break;

        case 2: // Order — kembali ke loadOrder (bukan loadOrderOnly)
          await context.read<PesananProvider>().loadOrder(context);
          break;

        case 3: // Profile
          final userProvider = context.read<UserProvider>();
          await userProvider.checkLoginGoogle(
            role: Constants.customer,
            silent: true,
          );

          if (userProvider.customer != null) {
            LocalStorageService.instance.setActiveCustomer(
              userProvider.customer!.noId,
            );
          }

          if (!mounted) return;

          final portoProvider = context.read<PortofolioProvider>();
          await Future.wait([
            portoProvider.refreshLikePortofolio(context),
            portoProvider.refreshSavePortofolio(context),
          ]);
          break;
      }

      debugPrint("✅ [MainMenu] Tab $index refreshed");
    } catch (e, st) {
      debugPrint("❌ [MainMenu] Tab $index refresh error: $e");
      debugPrint("Stack: $st");
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // NAVIGATOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildOffstageNavigator(int index, WidgetBuilder builder) {
    return Consumer<NavigationProvider>(
      builder: (context, provider, _) {
        final isActive = provider.selectedIndex == index;
        if (isActive) _mountedTabs.add(index);

        // Offstage tetap MEM-BUILD child-nya. Dulu keempat tab dibangun di
        // frame pertama, sehingga sync room chat, fetch pesanan, dan sync
        // liked/saved semua jalan bersamaan sementara Home berusaha
        // men-decode gambar. Sekarang tab baru dibangun saat pertama dibuka,
        // lalu dipertahankan supaya state-nya tidak hilang saat pindah tab.
        if (!_mountedTabs.contains(index)) return const SizedBox.shrink();

        return Offstage(
          offstage: !isActive,
          child: Navigator(
            key: provider.navigatorKeys[index],
            observers: [
              provider.routeObservers[index],
              _BottomNavRouteObserver(provider, index),
            ],
            onGenerateRoute: (_) => MaterialPageRoute(builder: builder),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ROUTE OBSERVER — AUTO HIDE/SHOW BOTTOM NAV
// ═══════════════════════════════════════════════════════════════

class _BottomNavRouteObserver extends NavigatorObserver {
  final NavigationProvider provider;
  final int tabIndex;

  _BottomNavRouteObserver(this.provider, this.tabIndex);

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _updateVisibilityAfterPop();
    debugPrint('📍 [Observer] Tab $tabIndex - PUSH: ${route.settings.name}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _updateVisibilityAfterPop();
    debugPrint('📍 [Observer] Tab $tabIndex - POP: ${route.settings.name}');
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    _updateVisibilityAfterPop();
    debugPrint('📍 [Observer] Tab $tabIndex - REMOVE: ${route.settings.name}');
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateVisibilityAfterPop();
    debugPrint('📍 [Observer] Tab $tabIndex - REPLACE');
  }

  void _updateVisibilityAfterPop() {
    if (provider.selectedIndex != tabIndex) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndUpdateVisibility();
    });
  }

  void _checkAndUpdateVisibility() {
    if (navigator == null) return;

    final canPop = navigator!.canPop();
    final shouldShow = !canPop;

    debugPrint(
        '📊 [Observer] Tab $tabIndex: canPop=$canPop, shouldShow=$shouldShow');

    if (provider.isBottomNavVisible != shouldShow) {
      if (shouldShow) {
        provider.showBottomNav();
        debugPrint('📱 [Observer] Tab $tabIndex - Bottom nav SHOWN (at root)');
      } else {
        provider.hideBottomNav();
        debugPrint(
            '🙈 [Observer] Tab $tabIndex - Bottom nav HIDDEN (has stack)');
      }
    }
  }
}
