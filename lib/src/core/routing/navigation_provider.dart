import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/core/services/auth_service_instance.dart';
import 'package:mpjnew/src/data/hive_service.dart/pesanan_local_service.dart';
import 'package:mpjnew/src/data/hive_service.dart/portofolio_local_service.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/auth/view/user_login.dart';
import 'package:mpjnew/src/features/customer/services/local_storage_service.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NavigationProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ─────────────── State
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  String? _statusUser;
  String? get statusUser => _statusUser;

  DateTime? _lastPressedAt;

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
    debugPrint("[checkLogin] 🔐 start for role: $role | silent: $silent");

    try {
      final userProv = context.read<UserProvider>();

      final status = await userProv.checkLoginGoogle(
        role: role,
        silent: silent,
      );

      if (status == null ||
          status.name == 'error' ||
          status.name == 'tokenInvalid') {
        debugPrint("❌ [checkLogin] Status: ${status?.name} → force logout");
        await handleLogout(context);
        return;
      }

      _statusUser = status.name;
      await saveStatusUser(_statusUser!);
      await saveRole(role);

      debugPrint("✅ [checkLogin] Status: $_statusUser");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ [checkLogin] Error: $e");
      await handleLogout(context);
    }
  }

  /// ✅ Logout: clear local storage customer → signOut → navigate
  ///
  /// Urutan ini penting:
  /// 1. clearOnLogout() harus sebelum authService.signOut()
  ///    karena clearOnLogout() masih butuh context (chatProvider)
  /// 2. authService.signOut() setelah data cleared
  /// 3. popAllToRoot() terakhir agar widget masih mounted saat cleanup
  Future<void> handleLogout(BuildContext context) async {
    debugPrint("[handleLogout] 🚪 Starting...");

    try {
      final userProv = context.read<UserProvider>();
      final chatProvider = context.read<ChatProvider>();

      final portoProvider = context.read<PortofolioProvider>();
      portoProvider.clearCustomerData(); // sync, langsung clear in-memory
      debugPrint("[handleLogout] ✅ PortofolioProvider cleared");

      // ✅ 1. Clear semua local storage customer
      //    - Portofolio liked + saved: Hive di-clear + file media dihapus
      //    - Pesanan + history: Hive di-clear
      //    - Chat: stream di-close, Hive box di-tutup (data tetap di disk)
      //    - activeCustomerId di-clear
      await LocalStorageService.instance.clearOnLogout(
        portofolioService: PortofolioLocalService(),
        pesananService: PesananLocalService(),
        chatProvider: chatProvider,
      );
      debugPrint("[handleLogout] ✅ Local storage cleared");

      // ✅ 2. Hapus token + disconnect Google
      await authService.signOut();
      debugPrint("[handleLogout] ✅ AuthService sign-out complete");

      // ✅ 3. Clear sisa state
      await clearStatusUser();
      await clearRole();
      clearSelectedIndex();
      showBottomNav();
      userProv.clear();
      popAllToRoot();

      debugPrint("[handleLogout] ✅ Logout complete");
    } catch (e) {
      debugPrint("❌ [handleLogout] Error: $e");
      // Tetap clear meskipun error
      if (context.mounted) popAllToRoot();
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await authService.getIdToken();
    return token != null && token.isNotEmpty;
  }

  // =========================================================
  // 🚀 NAVIGATE AFTER LOGIN
  // =========================================================

  Future<void> startNavigateCustomer(BuildContext context) async {
    final status = _statusUser ?? await getStatusUser();
    debugPrint("🚀 [startNavigateCustomer] Status: $status");

    if (status == null) {
      debugPrint("❌ Status null");
      if (context.mounted) popAllToRoot();
      return;
    }

    switch (status) {
      case 'aktif':
        debugPrint("➡️ → MainMenu (aktif)");
        if (context.mounted) {
          final userProv = context.read<UserProvider>();
          CustomSnackbar.showSuccessSnackbar(
            context,
            "Selamat Datang, ${userProv.customer?.namaDisplay ?? ""}",
          );
          popAllToRoot();
        }
        break;

      case 'created':
        debugPrint("➡️ → MainMenu (created/new user)");
        if (context.mounted) popAllToRoot();
        break;

      default:
        debugPrint("❌ Unknown status '$status' → logout");
        await handleLogout(context);
    }
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
    String targetPage = 'Home',
    String searchPageArg = '',
    PageTransitionType transitionType = PageTransitionType.slideRight,
    // ✅ TAMBAH: pass identifiers agar UserLogin bisa restore halaman yang benar
    String? noIdPortofolio,
    String? noIdVendor,
  }) async {
    const publicPages = {'SearchPage'};
    final isPublic = publicPages.contains(targetPage) || !hrsLogin;

    if (!isPublic) {
      final isAuth = await isAuthenticated();
      if (!isAuth) {
        debugPrint("[navigateToPage] 🔒 Redirect to login");
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => const UserLogin(),
              settings: RouteSettings(arguments: {
                'targetPage': targetPage,
                'tabIndex': targetTabIndex,
                'searchPageArg': searchPageArg,
                // ✅ FIX: pass noIdPortofolio dan noIdVendor
                // agar UserLogin bisa restore halaman yang benar setelah login
                if (noIdPortofolio != null) 'noIdPortofolio': noIdPortofolio,
                if (noIdVendor != null) 'noIdVendor': noIdVendor,
              }),
            ),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;

    final route = _createPageRoute(page, transitionType);

    if (fullscreen) {
      await Navigator.of(context, rootNavigator: true).push(route);
    } else {
      if (_selectedIndex != targetTabIndex) {
        _selectedIndex = targetTabIndex;
        notifyListeners();
        await WidgetsBinding.instance.endOfFrame;
        await Future.delayed(const Duration(milliseconds: 50));
      }

      final navigator = navigatorKeys[targetTabIndex].currentState;
      if (navigator != null) {
        await navigator.push(route);
      } else {
        await Future.delayed(const Duration(milliseconds: 200));
        await navigatorKeys[targetTabIndex].currentState?.push(route);
      }
    }
  }

  // =========================================================
  // 🎬 PAGE ROUTES
  // =========================================================

  PageRoute _createPageRoute(Widget page, PageTransitionType type) {
    switch (type) {
      case PageTransitionType.slideRight:
        return PageRouteBuilder(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeInOutCubic)),
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );

      case PageTransitionType.slideUp:
        return PageRouteBuilder(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeInOutCubic)),
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );

      case PageTransitionType.fade:
        return PageRouteBuilder(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        );

      case PageTransitionType.scale:
        return PageRouteBuilder(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            return ScaleTransition(
              scale: animation.drive(
                Tween(begin: 0.8, end: 1.0)
                    .chain(CurveTween(curve: Curves.easeInOutCubic)),
              ),
              child: FadeTransition(
                opacity: animation.drive(
                  Tween(begin: 0.0, end: 1.0)
                      .chain(CurveTween(curve: Curves.easeInOutCubic)),
                ),
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

  void onItemTapped(int index, BuildContext context) async {
    debugPrint("🔘 [NavProvider] Tab tapped: $index");

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

    if (_selectedIndex != index) {
      _selectedIndex = index;
      resetExitTimer();
      notifyListeners();
    }
  }

  void onItemTappedVendor(int index, BuildContext context) =>
      onItemTapped(index, context);

  void changeTab(int index, BuildContext context, {bool popToRoot = false}) {
    if (popToRoot) {
      navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
    }
    onItemTapped(index, context);
  }

  void popAllToRoot() {
    debugPrint("🔙 [NavProvider] Pop all to root");
    for (int i = 0; i < navigatorKeys.length; i++) {
      navigatorKeys[i].currentState?.popUntil((r) => r.isFirst);
    }
    showBottomNav();
    notifyListeners();
  }

  Future<void> pushOnTab(int tabIndex, Route route) async {
    await navigatorKeys[tabIndex].currentState?.push(route);
  }

  Future<bool> onWillPop(BuildContext context) async {
    final currentNavigator = navigatorKeys[_selectedIndex].currentState;
    if (currentNavigator == null) return true;

    final didPop = await currentNavigator.maybePop();
    if (didPop) return false;

    if (_selectedIndex != 0) {
      _selectedIndex = 0;
      showBottomNav();
      resetExitTimer();
      notifyListeners();
      return false;
    }

    showBottomNav();
    return await _handleExitConfirmation(context);
  }

  Future<bool> _handleExitConfirmation(BuildContext context) async {
    final now = DateTime.now();
    if (_lastPressedAt == null ||
        now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
      _lastPressedAt = now;
      CustomSnackbar.showExitAppSnackbar(
          context, 'Tekan sekali lagi untuk keluar');
      return false;
    }
    return true;
  }

  void resetExitTimer() => _lastPressedAt = null;

  NavigatorState? getNavigator(int index) => navigatorKeys[index].currentState;

  // =========================================================
  // 🛠️ UTILITY METHODS
  // =========================================================

  String formatDateLabel(DateTime? date, {bool showTodaysJam = false}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    date ??= now;
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return showTodaysJam
          ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
          : "Hari ini";
    }
    if (messageDate == today.subtract(const Duration(days: 1)))
      return "Kemarin";
    return DateFormat("d MMM yyyy", "id_ID").format(date);
  }

  String ambilGambar(String img, {bool umum = false}) {
    return umum
        ? "https://fotoapi.pdj.web.id/api/files/umum@gmail.com/$img"
        : "https://fotoapi.pdj.web.id/api/files/finance.pdj@gmail.com/$img";
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

enum PageTransitionType { slideRight, slideUp, fade, scale, material }
