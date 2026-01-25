import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/core/services/auth_service_instance.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/auth/view/user_login.dart';
import 'package:mpjnew/src/features/customer/services/device_token_service.dart';
import 'package:mpjnew/src/features/customer/view/single_post_page.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:provider/provider.dart';

// =========================================================
// NAVPROVIDER CUSTOMER - UPGRADED VERSION
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

  // ✅ Bottom Navigation Visibility Control
  bool _isBottomNavVisible = true;
  bool get isBottomNavVisible => _isBottomNavVisible;

  // 🔑 Storage keys
  static const String _keyStatusUser = 'status_user';
  static const String _keyRole = 'user_role';

  // 📚 Navigation History - Track route stack per tab
  final List<GlobalKey<NavigatorState>> navigatorKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  // Track navigation depth per tab (0 = root page)
  final Map<int, int> _tabNavigationDepth = {0: 0, 1: 0, 2: 0, 3: 0};

  int getNavigationDepth(int tabIndex) => _tabNavigationDepth[tabIndex] ?? 0;

  // =========================================================
  // 🎨 BOTTOM NAV VISIBILITY CONTROL
  // =========================================================

  /// Show bottom navigation bar
  void showBottomNav() {
    if (!_isBottomNavVisible) {
      _isBottomNavVisible = true;
      debugPrint('[NavigationProvider] 📱 Bottom nav SHOWN');
      notifyListeners();
    }
  }

  /// Hide bottom navigation bar
  void hideBottomNav() {
    if (_isBottomNavVisible) {
      _isBottomNavVisible = false;
      debugPrint('[NavigationProvider] 🙈 Bottom nav HIDDEN');
      notifyListeners();
    }
  }

  /// Set bottom navigation visibility based on navigation depth
  void updateBottomNavVisibility() {
    final currentDepth = _tabNavigationDepth[_selectedIndex] ?? 0;
    final shouldShow = currentDepth == 0;

    if (_isBottomNavVisible != shouldShow) {
      _isBottomNavVisible = shouldShow;
      debugPrint(
          '[NavigationProvider] 📱 Bottom nav auto-updated: ${shouldShow ? "SHOWN" : "HIDDEN"} (depth: $currentDepth)');
      notifyListeners();
    }
  }

  void clearSelectedIndex() {
    _selectedIndex = 0;
    notifyListeners();
  }

  // =========================================================
  // 💾 SIMPAN & AMBIL STATUS USER
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

  // =========================================================
  // 💾 SIMPAN & AMBIL ROLE
  // =========================================================
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
  // 🔐 CHECK LOGIN
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

      await handleLogout(context);
    }
  }

  // =========================================================
  // 🚪 HANDLE LOGOUT
  // =========================================================
  Future<void> handleLogout(BuildContext context) async {
    debugPrint("===== [handleLogout] start");

    try {
      // 1️⃣ Remove device token jika ada
      final userProv = context.read<UserProvider>();
      if (userProv.customer != null) {
        try {
          await deviceTokenService.removeDeviceToken(userProv.customer!.noId);
        } catch (e, stackTrace) {
          debugPrint("⚠️ Error remove device token: $e");
          debugPrint(stackTrace.toString());
        }
      }

      // 2️⃣ Logout dari Google & hapus data di AuthService
      await authService.logout();

      // 3️⃣ Hapus data lokal di NavigationProvider
      await clearStatusUser();
      await clearRole();
      clearSelectedIndex();
      resetNavigationState();
      showBottomNav(); // ✅ Reset visibility

      // 4️⃣ Clear UserProvider
      userProv.clear();
      popAllToRoot();

      debugPrint("✅ Semua data berhasil dihapus");

      // 5️⃣ Redirect ke login
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const UserLogin()),
          (_) => false,
        );
      }

      debugPrint("===== [handleLogout] selesai");
    } catch (e, stackTrace) {
      debugPrint("❌ Error saat handleLogout: $e");
      debugPrint(stackTrace.toString());

      // Fallback: tetap redirect ke login meskipun ada error
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const UserLogin()),
          (_) => false,
        );
      }
    }
  }

  // =========================================================
  // 🔍 CHECK AUTHENTICATION STATUS
  // =========================================================
  Future<bool> isAuthenticated() async {
    final token = await authService.getIdToken(forceRefresh: false);
    return token != null && token.isNotEmpty;
  }

  // =========================================================
  // 🧭 NAVIGATE TO PAGE WITH AUTH CHECK & ANIMATIONS
  // =========================================================

  void resetNavigationState() {
    _tabNavigationDepth.clear();
    _tabNavigationDepth.addAll({0: 0, 1: 0, 2: 0, 3: 0});
  }

  /// Navigate to a page with slide animation and auto bottom nav control
  Future<void> navigateToPage(
    BuildContext context,
    Widget page, {
    int targetTabIndex = 0,
    bool hrsLogin = true,
    String targetPage = 'EcommerceHome',
    String searchPageArg = '',
    PageTransitionType transitionType = PageTransitionType.slideRight,
  }) async {
    String? noIdPortofolio;
    String? noIdVendor;

    // Extract IDs for logging purposes
    if (page is SinglePostPage) noIdPortofolio = page.noId;
    if (page is VendorBioPage) noIdVendor = page.idVendor;

    debugPrint("═══════════════════════════════════════════════════");
    debugPrint(
        "[navigateToPage] 🎯 TARGET: $targetPage (Tab: $targetTabIndex)");
    debugPrint("[navigateToPage] Current tab: $_selectedIndex");

    // ✅ Cek login menggunakan AuthService
    final isAuth = await isAuthenticated();

    if (!isAuth && hrsLogin) {
      debugPrint("[navigateToPage] 🔒 BELUM LOGIN, redirect ke UserLogin");

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => const UserLogin(),
            settings: RouteSettings(arguments: {
              'targetPage': targetPage,
              'tabIndex': targetTabIndex,
              'noIdPortofolio': noIdPortofolio,
              'noIdVendor': noIdVendor,
              'searchPageArg': searchPageArg,
            }),
          ),
        );
      }
      return;
    }

    debugPrint("[navigateToPage] ✅ SUDAH LOGIN or No login required");

    int targetIndex = targetTabIndex;

    // ✅ FIX: Pindah tab dulu jika berbeda
    final needsTabSwitch = _selectedIndex != targetIndex;

    if (needsTabSwitch) {
      debugPrint(
          "[navigateToPage] 🔄 Switching from tab $_selectedIndex to $targetIndex");
      _selectedIndex = targetIndex;
      notifyListeners();

      // ✅ PENTING: Tunggu frame rebuild selesai
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 50));

      debugPrint("[navigateToPage] ✅ Tab switched to $targetIndex");
    }

    // ✅ Dapatkan navigator untuk target tab
    final navigator = navigatorKeys[targetIndex].currentState;

    if (navigator != null) {
      debugPrint("[navigateToPage] 📄 Pushing page to tab $targetIndex");

      // ✅ Hide bottom nav before navigation
      hideBottomNav();

      // ✅ Increment navigation depth
      _tabNavigationDepth[targetIndex] =
          (_tabNavigationDepth[targetIndex] ?? 0) + 1;

      debugPrint(
          "[navigateToPage] 📊 Tab $targetIndex depth: ${_tabNavigationDepth[targetIndex]}");

      // ✅ Navigate with animation
      await navigator.push(_createPageRoute(page, transitionType));

      // ✅ Final notify to update UI
      notifyListeners();

      debugPrint("[navigateToPage] ✅ Navigation complete");
    } else {
      debugPrint(
          "[navigateToPage] ❌ ERROR: Navigator null for tab $targetIndex!");
      debugPrint("[navigateToPage] Current selected tab: $_selectedIndex");
      debugPrint("[navigateToPage] Target tab: $targetIndex");

      // ✅ Fallback: Coba sekali lagi setelah delay lebih lama
      debugPrint("[navigateToPage] 🔄 Retrying after longer delay...");
      await Future.delayed(const Duration(milliseconds: 200));

      final retryNavigator = navigatorKeys[targetIndex].currentState;
      if (retryNavigator != null) {
        debugPrint("[navigateToPage] ✅ Retry successful!");
        hideBottomNav();
        _tabNavigationDepth[targetIndex] =
            (_tabNavigationDepth[targetIndex] ?? 0) + 1;
        await retryNavigator.push(_createPageRoute(page, transitionType));
        notifyListeners();
      } else {
        debugPrint("[navigateToPage] ❌ Retry failed - Navigator still null");
      }
    }

    debugPrint("═══════════════════════════════════════════════════");
  }

  // =========================================================
  // 🎬 PAGE ROUTE WITH CUSTOM TRANSITIONS
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
  // 📱 BOTTOM NAV METHODS
  // =========================================================

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void pushFullPage(BuildContext context, Widget widget) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => widget),
    );
  }

  void onItemTapped(int index, BuildContext context) async {
    debugPrint("🔘 [NavigationProvider] Tab tapped: $index");

    final isAuth = await isAuthenticated();

    // ✅ Tab 0 (Home/Jelajah) bisa diakses tanpa login
    if (!isAuth && index != 0) {
      debugPrint("🔒 [NavigationProvider] Belum login, redirect ke UserLogin");

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

    // ✅ Change tab and show bottom nav
    if (_selectedIndex != index) {
      _selectedIndex = index;
      showBottomNav();
      resetExitTimer();
      debugPrint("✅ [NavigationProvider] Navigasi ke tab $index");
      notifyListeners();
    } else {
      // ✅ Tapping same tab - pop to root if not already there
      final navigator = navigatorKeys[index].currentState;
      if (navigator != null && _tabNavigationDepth[index]! > 0) {
        navigator.popUntil((route) => route.isFirst);
        _tabNavigationDepth[index] = 0;
        showBottomNav();
        notifyListeners();
      }
    }
  }

  /// ✅ Handle back button manual (dari AppBar/CustomBackButton)

  Future<bool> handleBackButton(BuildContext context) async {
    final currentNavigator = navigatorKeys[_selectedIndex].currentState;

    if (currentNavigator == null) return true;

    bool canPop = await currentNavigator.maybePop();

    if (canPop) {
      // ✅ NULL-SAFE: Ambil current depth dengan default 0
      final currentDepth = _tabNavigationDepth[_selectedIndex] ?? 0;

      // ✅ Decrement jika > 0
      if (currentDepth > 0) {
        _tabNavigationDepth[_selectedIndex] = currentDepth - 1;
      }

      // ✅ Get new depth
      final newDepth = _tabNavigationDepth[_selectedIndex] ?? 0;

      // ✅ Set visibility
      _isBottomNavVisible = (newDepth == 0);

      debugPrint(
          "[handleBackButton] Depth: $currentDepth → $newDepth, Visible: $_isBottomNavVisible");

      notifyListeners();
    }

    return false;
  }

  /// ✅ ALTERNATIVE: Versi simplified tanpa debug log
  Future<bool> handleBackButtonClean(BuildContext context) async {
    final currentNavigator = navigatorKeys[_selectedIndex].currentState;

    if (currentNavigator == null) return true;

    bool canPop = await currentNavigator.maybePop();

    if (canPop) {
      // ✅ Ensure key exists, initialize if not (defensive programming)
      _tabNavigationDepth[_selectedIndex] ??= 0;

      // ✅ Decrement safely
      final currentDepth = _tabNavigationDepth[_selectedIndex]!;
      if (currentDepth > 0) {
        _tabNavigationDepth[_selectedIndex] = currentDepth - 1;
      }

      // ✅ Update visibility
      final newDepth = _tabNavigationDepth[_selectedIndex]!;
      _isBottomNavVisible = (newDepth == 0);

      debugPrint(
          "[handleBackButton] Tab $_selectedIndex: depth $currentDepth → $newDepth, visible: $_isBottomNavVisible");

      notifyListeners();
    }

    return false;
  }

  /// ✅ Handle hardware back button (dari WillPopScope)
  Future<bool> onWillPop(BuildContext context) async {
    final currentNavigator = navigatorKeys[_selectedIndex].currentState;

    if (currentNavigator == null) return true;

    // 1️⃣ Try to pop current page in the tab
    bool didPop = await currentNavigator.maybePop();

    debugPrint(
        "🔙 [onWillPop] Tab: $_selectedIndex, didPop: $didPop, depth: ${_tabNavigationDepth[_selectedIndex]}");

    if (didPop) {
      // ✅ Decrement navigation depth
      if (_tabNavigationDepth[_selectedIndex]! > 0) {
        _tabNavigationDepth[_selectedIndex] =
            _tabNavigationDepth[_selectedIndex]! - 1;
        debugPrint(
            "📊 [onWillPop] Depth after pop: ${_tabNavigationDepth[_selectedIndex]}");
      }

      // ✅ Update bottom nav visibility based on depth
      updateBottomNavVisibility();

      return false; // Prevent system back
    }

    // 2️⃣ Can't pop (already at root) - check current tab
    if (_selectedIndex != 0) {
      // ✅ Not on home tab - switch to home
      debugPrint("🏠 [onWillPop] Pindah ke Home (tab 0)");
      _selectedIndex = 0;
      showBottomNav();
      resetExitTimer();
      notifyListeners();
      return false; // Prevent exit
    }

    // 3️⃣ Already on home tab root - show exit confirmation
    showBottomNav();
    return await _handleExitConfirmation(context);
  }

  /// ✅ Handle konfirmasi keluar dengan double-tap back
  Future<bool> _handleExitConfirmation(BuildContext context) async {
    final now = DateTime.now();

    if (_lastPressedAt == null ||
        now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
      _lastPressedAt = now;

      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tekan sekali lagi untuk keluar'),
          duration: Duration(seconds: 2),
        ),
      );

      return false; // Prevent exit
    }

    // Second back press - allow exit
    return true;
  }

  /// ✅ Reset timer jika user navigasi ke tempat lain
  void resetExitTimer() {
    _lastPressedAt = null;
  }

  NavigatorState? getNavigator(int index) => navigatorKeys[index].currentState;

  void changeTab(int index, BuildContext context, {bool popToRoot = false}) {
    if (popToRoot) {
      navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
      _tabNavigationDepth[index] = 0;
    }

    showBottomNav();
    onItemTapped(index, context);
  }

  Future<void> pushOnTab(int tabIndex, Route route) async {
    await navigatorKeys[tabIndex].currentState?.push(route);

    // ✅ Increment depth and hide bottom nav
    _tabNavigationDepth[tabIndex] = (_tabNavigationDepth[tabIndex] ?? 0) + 1;
    hideBottomNav();
    notifyListeners();
  }

  void popAllToRoot() {
    for (int i = 0; i < navigatorKeys.length; i++) {
      navigatorKeys[i].currentState?.popUntil((r) => r.isFirst);
      _tabNavigationDepth[i] = 0;
    }
    showBottomNav();
    notifyListeners();
  }

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

// =========================================================
// 🎨 PAGE TRANSITION TYPES
// =========================================================
enum PageTransitionType {
  slideRight,
  slideUp,
  fade,
  scale,
  material,
}
