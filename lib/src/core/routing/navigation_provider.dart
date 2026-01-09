import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/features/auth/services/auth_service.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/auth/view/user_login.dart';
import 'package:mpjnew/src/features/customer/services/device_token_service.dart';
import 'package:mpjnew/src/features/customer/view/single_post_page.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:provider/provider.dart';

class NavigationProvider with ChangeNotifier {
  DeviceTokenService deviceTokenService = DeviceTokenService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // ✅ Gunakan singleton AuthService
  final AuthService _authService = AuthService();

  // ─────────────── State
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  String? _statusUser;
  String? get statusUser => _statusUser;

  // 🔑 Storage keys
  static const String _keyStatusUser = 'status_user';
  static const String _keyRole = 'user_role';

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
    print("===== [checkLogin] start for role: $role");

    try {
      final userProv = context.read<UserProvider>();

      final status = await userProv.checkLoginGoogle(
        role: role,
        silent: silent,
      );

      if (status == null) {
        print("❌ Status null, logout");
        await handleLogout(context);
        return;
      }

      _statusUser = status.name;
      await saveStatusUser(_statusUser!);
      await saveRole(role);

      print("✅ Status updated: $_statusUser, Role: $role");
      notifyListeners();
    } catch (e, s) {
      print("❌ Error checkLogin: $e");
      print(s);
      await handleLogout(context);
    }
  }

  // =========================================================
  // 🚪 HANDLE LOGOUT
  // =========================================================
  Future<void> handleLogout(BuildContext context) async {
    print("===== [handleLogout] start");

    try {
      final userProv = context.read<UserProvider>();

      await userProv.logout();

      await clearStatusUser();
      await clearRole();
      clearSelectedIndex();
      resetNavigationHistory();

      print("✅ Semua data berhasil dihapus");

      // Redirect ke login
      popAllToRoot();

      print("===== [handleLogout] selesai");
    } catch (e, s) {
      print("❌ Error saat handleLogout: $e");
      print(s);

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
    // ✅ Gunakan AuthService singleton
    final token = await _authService.getIdToken(forceRefresh: false);
    return token != null && token.isNotEmpty;
  }

  // =========================================================
  // 📱 BOTTOM NAV METHODS
  // =========================================================
  final List<GlobalKey<NavigatorState>> navigatorKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );
  final List<int> _navigationHistory = [0];

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
    final isAuth = await isAuthenticated();

    // ✅ Tab 0 (Home) bisa diakses tanpa login
    if (!isAuth && index != 0) {
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
      _navigationHistory.add(index);
      notifyListeners();
    }
  }

  void onItemTappedVendor(int index, BuildContext context) async {
    final isAuth = await isAuthenticated();

    if (!isAuth && index != 0) {
      return;
    }

    if (_selectedIndex != index) {
      _selectedIndex = index;
      _navigationHistory.add(index);
      notifyListeners();
    }
  }

  Future<bool> onWillPop() async {
    final currentNavigator = navigatorKeys[_selectedIndex].currentState;

    if (currentNavigator == null) return true;

    bool didPop = await currentNavigator.maybePop();

    if (didPop) {
      if (_navigationHistory.length >= 2) {
        int previousIndex = _navigationHistory[_navigationHistory.length - 2];
        _navigationHistory.removeLast();
        if (previousIndex != _selectedIndex) {
          _selectedIndex = previousIndex;
        }
        notifyListeners();
      }
      return false;
    }

    if (_navigationHistory.length >= 2) {
      _navigationHistory.removeLast();
      final previousIndex = _navigationHistory.last;

      if (previousIndex != _selectedIndex) {
        _selectedIndex = previousIndex;
      }

      notifyListeners();
      return false;
    }

    return true;
  }

  NavigatorState? getNavigator(int index) => navigatorKeys[index].currentState;

  void changeTab(int index, BuildContext context, {bool popToRoot = false}) {
    if (popToRoot) {
      navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
    }
    onItemTapped(index, context);
  }

  Future<void> pushOnTab(int tabIndex, Route route) async {
    navigatorKeys[tabIndex].currentState?.push(route);
  }

  void popAllToRoot() {
    for (var key in navigatorKeys) {
      key.currentState?.popUntil((r) => r.isFirst);
    }
  }

  void resetNavigationHistory() {
    _navigationHistory.clear();
    _navigationHistory.add(0);
  }

  Future<void> navigateToPage(
    BuildContext context,
    Widget page, {
    int targetTabIndex = 0,
    bool hrsLogin = true,
    String targetPage = 'EcommerceHome',
    String searchPageArg = '',
  }) async {
    String? noIdPortofolio;
    String? noIdVendor;

    if (page is SinglePostPage) noIdPortofolio = page.noId;
    if (page is VendorBioPage) noIdVendor = page.idVendor;

    print("====================== TARGET: $targetPage");

    // ✅ Gunakan singleton AuthService
    final isAuth = await isAuthenticated();

    if (!isAuth && hrsLogin) {
      print("🔒 BELUM LOGIN, redirect ke UserLogin");
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => UserLogin(),
          settings: RouteSettings(arguments: {
            'targetPage': targetPage,
            'tabIndex': targetTabIndex,
            'noIdPortofolio': noIdPortofolio,
            'noIdVendor': noIdVendor,
            'searchPageArg': searchPageArg,
          }),
        ),
      );
      return;
    }

    print("✅ SUDAH LOGIN");

    int targetIndex = targetTabIndex;

    navigatorKeys[targetIndex].currentState?.push(
          MaterialPageRoute(builder: (_) => page),
        );
    await Future.delayed(const Duration(milliseconds: 50));

    _selectedIndex = targetIndex;
    _navigationHistory.add(targetIndex);
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