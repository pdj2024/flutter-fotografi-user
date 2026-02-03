import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/core/services/auth_service_instance.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/auth/view/user_login.dart';
import 'package:mpjnew/src/features/customer/services/device_token_service.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// =========================================================
// ✨ VENDOR NAVIGATION PROVIDER - COMPLETE VERSION
// =========================================================

class NavigationProvider with ChangeNotifier {
  DeviceTokenService deviceTokenService = DeviceTokenService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ─────────────── State
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  String? _statusUser;
  String? get statusUser => _statusUser;

  DateTime? _lastPressedAt;

  // ✅ Bottom Navigation Visibility
  bool _isBottomNavVisible = true;
  bool get isBottomNavVisible => _isBottomNavVisible;

  // 🔑 Storage keys
  static const String _keyStatusUser = 'status_user';
  static const String _keyRole = 'user_role';

  // 📚 Navigation Keys
  final List<GlobalKey<NavigatorState>> navigatorKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  // ✅ Route Observers for each tab
  final List<RouteObserver<PageRoute>> routeObservers = List.generate(
    4,
    (_) => RouteObserver<PageRoute>(),
  );

  // =========================================================
  // 🎨 BOTTOM NAV VISIBILITY
  // =========================================================

  void showBottomNav() {
    if (!_isBottomNavVisible) {
      _isBottomNavVisible = true;
      debugPrint('[NavProvider] 📱 Bottom nav SHOWN');
      notifyListeners();
    }
  }

  void hideBottomNav() {
    if (_isBottomNavVisible) {
      _isBottomNavVisible = false;
      debugPrint('[NavProvider] 🙈 Bottom nav HIDDEN');
      notifyListeners();
    }
  }

  void clearSelectedIndex() {
    _selectedIndex = 0;
    notifyListeners();
  }

  // =========================================================
  // 💾 STORAGE METHODS
  // =========================================================

  Future<void> saveStatusUser(String status) async {
    await _storage.write(key: _keyStatusUser, value: status);
    _statusUser = status;
  }

  Future<String?> getStatusUser() async {
    if (_statusUser != null) return _statusUser;
    _statusUser = await _storage.read(key: _keyStatusUser);
    return _statusUser;
  }

  Future<void> clearStatusUser() async {
    await _storage.delete(key: _keyStatusUser);
    _statusUser = null;
  }

  Future<void> saveRole(String role) async {
    await _storage.write(key: _keyRole, value: role);
    apiClient.setRole(role);
  }

  Future<String?> getRole() async {
    return await _storage.read(key: _keyRole);
  }

  Future<void> clearRole() async {
    await _storage.delete(key: _keyRole);
    apiClient.clearRole();
  }

  // =========================================================
  // 🔐 AUTH METHODS
  // =========================================================

  Future<void> checkLogin(
      BuildContext context, String role, bool silent) async {
    debugPrint("===== [checkLogin] start for role: $role");

    try {
      final userProv = context.read<UserProvider>();

      final status = await userProv.checkLoginGoogle(
        role: role,
        silent: silent,
      );

      if (status == null) {
        debugPrint("❌ Status null, logout");
        await handleLogout(context);
        return;
      }

      _statusUser = status.name;
      await saveStatusUser(_statusUser!);
      await saveRole(role);

      debugPrint("✅ Status updated: $_statusUser, Role: $role");
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint("❌ Error checkLogin: $e");
      debugPrint(stackTrace.toString());
      // await AppLogger.logError(
      //   e,
      //   stackTrace: stackTrace,
      //   tag: 'CheckLogin',
      //   extra: {'page': 'navigation_provider.dart'},
      // );
      await handleLogout(context);
    }
  }

  Future<void> handleLogout(BuildContext context) async {
    debugPrint("===== [handleLogout] start");

    try {
      final userProv = context.read<UserProvider>();
      if (userProv.customer != null) {
        try {
          await deviceTokenService.removeDeviceToken(userProv.customer!.noId);
        } catch (e, stackTrace) {
          debugPrint("⚠️ Error remove device token: $e");
          // await AppLogger.logError(
          //   e,
          //   stackTrace: stackTrace,
          //   tag: 'removeDeviceToken',
          //   extra: {'page': 'navigation_provider.dart'},
          // );
        }
      }

      await authService.signOut();
      await clearStatusUser();
      await clearRole();
      clearSelectedIndex();
      showBottomNav();

      userProv.clear();
      popAllToRoot();

      debugPrint("✅ Semua data berhasil dihapus");

      if (context.mounted) {
        popAllToRoot();
      }

      debugPrint("===== [handleLogout] selesai");
    } catch (e, stackTrace) {
      debugPrint("❌ Error saat handleLogout: $e");

      if (context.mounted) {
        popAllToRoot();
      }
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await authService.getIdToken();
    return token != null && token.isNotEmpty;
  }

  // =========================================================
  // 🧭 NAVIGATION METHODS
  // =========================================================

  Future<void> navigateToPage(
    BuildContext context,
    Widget page, {
    int targetTabIndex = 0,
    bool hrsLogin = true,
    bool fullscreen = false,
    String targetPage = 'VendorHome',
    String searchPageArg = '',
    PageTransitionType transitionType = PageTransitionType.slideRight,
  }) async {
    debugPrint("═══════════════════════════════════════════════════");
    debugPrint(
        "[navigateToPage] 🎯 TARGET: $targetPage (fullscreen: $fullscreen)");

    // ✅ Check auth
    final isAuth = await isAuthenticated();

    if (!isAuth && hrsLogin) {
      debugPrint("[navigateToPage] 🔒 Redirect to login");

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => const UserLogin(),
            settings: RouteSettings(arguments: {
              'targetPage': 'userLogin',
              'tabIndex': 0,
            }),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final route = _createPageRoute(page, transitionType);

    if (fullscreen) {
      // ✅ Fullscreen: Use root navigator
      await Navigator.of(context, rootNavigator: true).push(route);
      debugPrint("[navigateToPage] ✅ Fullscreen complete");
    } else {
      // ✅ Nested: Use tab navigator
      int targetIndex = targetTabIndex;

      // Switch tab if needed
      if (_selectedIndex != targetIndex) {
        debugPrint(
            "[navigateToPage] 🔄 Switching tab $_selectedIndex → $targetIndex");
        _selectedIndex = targetIndex;
        notifyListeners();

        await WidgetsBinding.instance.endOfFrame;
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Get navigator
      final navigator = navigatorKeys[targetIndex].currentState;

      if (navigator != null) {
        debugPrint("[navigateToPage] 📄 Pushing to tab $targetIndex");
        await navigator.push(route);
        debugPrint("[navigateToPage] ✅ Complete");
      } else {
        debugPrint("[navigateToPage] ❌ Navigator null, retrying...");

        await Future.delayed(const Duration(milliseconds: 200));
        final retryNavigator = navigatorKeys[targetIndex].currentState;

        if (retryNavigator != null) {
          await retryNavigator.push(route);
        } else {
          debugPrint("[navigateToPage] ❌ Retry failed");
        }
      }
    }

    debugPrint("═══════════════════════════════════════════════════");
  }

  // =========================================================
  // 🎬 PAGE ROUTES
  // =========================================================

  PageRoute _createPageRoute(Widget page, PageTransitionType type) {
    switch (type) {
      case PageTransitionType.slideRight:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );

      case PageTransitionType.slideUp:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );

      case PageTransitionType.fade:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
        );

      case PageTransitionType.scale:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOutCubic;
            var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
              CurveTween(curve: curve),
            );
            var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            return ScaleTransition(
              scale: animation.drive(scaleTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );

      default:
        return MaterialPageRoute(builder: (_) => page);
    }
  }

  // =========================================================
  // 📱 TAB NAVIGATION
  // =========================================================

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      resetExitTimer();
      notifyListeners();
    }
  }

  /// ✅ Vendor tab handler
  void onItemTappedVendor(int index, BuildContext context) async {
    debugPrint("🔘 [NavProvider] Vendor tab tapped: $index");

    // Check auth
    final isAuth = await isAuthenticated();

    if (!isAuth && index != 0) {
      debugPrint("🔒 [NavProvider] Redirect to login");

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => const UserLogin(),
            settings: RouteSettings(arguments: {
              'targetPage': 'Tab$index',
              'tabIndex': index,
            }),
          ),
        );
      }
      return;
    }

    // Handle tab navigation
    if (_selectedIndex != index) {
      debugPrint("🔀 [NavProvider] Switching tab $_selectedIndex → $index");
      _selectedIndex = index;
      resetExitTimer();
      notifyListeners();
    } else {
      debugPrint("🔄 [NavProvider] Same tab tapped ($index)");
      // Refresh handled by VendorBottomNav._handleTabRefresh
    }
  }

  /// ✅ Generic tab handler (alias)
  void onItemTapped(int index, BuildContext context) async {
    onItemTappedVendor(index, context);
  }

  /// ✅ Change tab (with optional pop to root)
  void changeTab(int index, BuildContext context, {bool popToRoot = false}) {
    debugPrint("🔄 [NavProvider] changeTab to $index (popToRoot: $popToRoot)");

    if (popToRoot) {
      navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
    }

    onItemTappedVendor(index, context);
  }

  /// ✅ Pop all navigators to root
  void popAllToRoot() {
    debugPrint("🔙 [NavProvider] Pop all navigators to root");

    for (int i = 0; i < navigatorKeys.length; i++) {
      navigatorKeys[i].currentState?.popUntil((r) => r.isFirst);
    }

    showBottomNav();
    notifyListeners();
  }

  /// ✅ Push on specific tab
  Future<void> pushOnTab(int tabIndex, Route route) async {
    await navigatorKeys[tabIndex].currentState?.push(route);
  }

  /// ✅ WillPop handler
  Future<bool> onWillPop(BuildContext context) async {
    final currentNavigator = navigatorKeys[_selectedIndex].currentState;

    if (currentNavigator == null) return true;

    bool didPop = await currentNavigator.maybePop();

    debugPrint("🔙 [onWillPop] Tab: $_selectedIndex, didPop: $didPop");

    if (didPop) {
      // Successfully popped
      return false;
    }

    // Can't pop - switch to home if not already there
    if (_selectedIndex != 0) {
      debugPrint("🏠 [onWillPop] Switch to home");
      _selectedIndex = 0;
      showBottomNav();
      resetExitTimer();
      notifyListeners();
      return false;
    }

    // Already at home - exit confirmation
    showBottomNav();
    return await _handleExitConfirmation(context);
  }

  Future<bool> _handleExitConfirmation(BuildContext context) async {
    final now = DateTime.now();

    if (_lastPressedAt == null ||
        now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
      _lastPressedAt = now;

      CustomSnackbar.showExitAppSnackbar(
        context,
        'Tekan sekali lagi untuk keluar',
      );

      return false;
    }

    return true;
  }

  void resetExitTimer() {
    _lastPressedAt = null;
  }

  NavigatorState? getNavigator(int index) => navigatorKeys[index].currentState;

  // =========================================================
  // 🛠️ UTILITY METHODS
  // =========================================================

  String formatDateLabel(DateTime? date, {bool showTodaysJam = false}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (date == null) {
      date = now;
    }

    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      if (showTodaysJam) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return "Hari ini";
      }
    }

    if (messageDate == today.subtract(const Duration(days: 1))) {
      return "Kemarin";
    }

    return DateFormat("d MMM yyyy", "id_ID").format(date);
  }

  String ambilGambar(String img, {bool umum = false}) {
    if (umum) {
      return "https://fotoapi.pdj.web.id/api/files/umum@gmail.com/$img";
    }
    return "https://fotoapi.pdj.web.id/api/files/finance.pdj@gmail.com/$img";
  }

  String? getMediaUrl(dynamic p) {
    final mediaList = p.mediaUrls ?? [];
    final firstMedia = mediaList.isNotEmpty ? mediaList.first : null;
    final isVideo = (firstMedia?.contentType ?? '').startsWith('video');
    return isVideo
        ? (firstMedia?.thumbUrl ?? firstMedia?.url)
        : firstMedia?.url;
  }
}

enum PageTransitionType {
  slideRight,
  slideUp,
  fade,
  scale,
  material,
}