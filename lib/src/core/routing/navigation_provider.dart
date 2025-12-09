import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/features/customer/view/single_post_page.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/services/user_provider.dart';
import '../../features/auth/view/user_login.dart';
import '../../features/auth/services/auth_service.dart';

class NavigationProvider with ChangeNotifier {
  // ─────────────── State
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

//  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  void clearSelectedIndex() async {
    _selectedIndex = 0;
    notifyListeners();
  }

  Future<void> saveStatusUser(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('status_user', status);
  }

  Future<String?> getStatusUser() async {
    final prefs = await SharedPreferences.getInstance();
    return 'aktif';
    //return prefs.getString('status_user');
  }

  Future<void> checkLogin(BuildContext context, String role,
      {Type? currentPage}) async {
    print("===== [checkLogin] start for role: $role");

    final auth = AuthService();
    String? idToken;

    // 🔍 Cek token dari cache atau silent login
    idToken = await auth.getIdToken(forceRefresh: false);

    if (idToken == null) {
      print("===== [checkLogin] user belum login, coba silent login...");
      idToken = await auth.login(silent: true);

      if (idToken == null) {
        print(
            "===== [checkLogin] silent login gagal, redirect ke halaman login");

        if (role == Constants.customer) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const UserLogin()));
        }
        return;
      }
    } else {
      print("===== [checkLogin] sudah login, pakai token cache");
    }

    print("===== [checkLogin] ambil status user dari backend");
    final status = await checkStatusUser(idToken, role);

    if (status.toLowerCase() == 'nonaktif') {
      print("===== [checkLogin] status == nonaktif, redirect ke VendorStatus");
      // Navigator.pushReplacement(
      //     context, MaterialPageRoute(builder: (_) => const VendorStatus()));
      return;
    } else {
      print("===== [checkLogin] sudah aktif, lanjut ke halaman saat ini");
    }

    notifyListeners();

    // ⛔ Jangan redirect ke halaman yang sama
    print("===== [checkLogin] selesai");
  }

  Future<void> handleLogout(BuildContext context) async {
    print("===== [handleLogout] Mulai logout");

    try {
      // 1️⃣ Hapus semua data lokal dulu (role, status user, dsb)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('role');
      await prefs.remove('statusUser');
      print("===== [handleLogout] SharedPreferences dibersihkan");

      // 2️⃣ Hapus role dari API client agar header ikut bersih
      apiClient.clearRole();

      // 3️⃣ Logout dari Google
      await context.read<UserProvider>().logout();
      // await AuthService().logout();
      print("===== [handleLogout] Logout Google selesai");

      // 4️⃣ Reset navigation index atau state lain
      resetNavigationHistory();
      clearSelectedIndex();

      print("===== [handleLogout] Selesai ====");
    } catch (e, s) {
      print("❌ Error saat handleLogout: $e");
      print(s);
    }
  }

  Future<String> checkStatusUser(String idToken, String role) async {
    // Kirim idToken ke API dan cek status user di backend
    final status = 'aktif'; // await fetchUserStatusFromApi(idToken, role);

    return status;
  }

  Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);

    apiClient.setRole(role);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  String formatDateLabel(DateTime? date, {bool showTodaysJam = false}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (date == null) {
      date = now;
    }

    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      if (showTodaysJam) {
        // Tampilkan jam
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return "Hari ini";
      }
    }

    if (messageDate == today.subtract(const Duration(days: 1))) {
      return "Kemarin";
    }

    // Format dengan singkatan bulan dan locale Indonesia
    return DateFormat("d MMM yyyy", "id_ID").format(date); // Contoh: 6 Mei 2025
  }

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  final List<GlobalKey<NavigatorState>> navigatorKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );
  final List<int> _navigationHistory = [0]; // Track history of selected indexes

  void resetNavigationHistory() {
    _navigationHistory.clear();
    _navigationHistory.add(0);
  }

  void pushFullPage(BuildContext context, Widget widget) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => widget,
        settings: RouteSettings(arguments: {
          // 'targetPage': 'Tab' + index.toString(),
          // 'tabIndex': index,
        }),
      ),
    );
  }

  void onItemTapped(int index, BuildContext context) {
    final customer = context.read<UserProvider>().customer;
    if (customer != null || index == 0) {
      // Asumsi tab pertama tidak perlu login (misalnya Home)
      if (_selectedIndex != index) {
        _selectedIndex = index;
        _navigationHistory.add(index);
        notifyListeners();

        // Tambahkan: Refresh portofolio jika pindah ke tab Home (index 0)
        if (index == 0) {
          // Panggil provider fetchPortofolio tanpa filter
          Future.microtask(() {
            // Reset portofolio dan fetch ulang
            context.read<PortofolioProvider>().loadPortofolio(context);
          });
        }
      } else {
        // Reset halaman di tab yang sama
        // navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      }
    } else {
      // Jika belum login, navigasi ke halaman login
      popAllToRoot();
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => UserLogin(),
          settings: RouteSettings(arguments: {
            'targetPage': 'Tab$index',
            'tabIndex': index,
          }),
        ),
      );
    }
  }

  void onItemTappedVendor(int index, BuildContext context) {
    if (context.read<UserProvider>().userId != null || index == 0) {
      // Asumsi tab pertama tidak perlu login (misalnya Home)
      if (_selectedIndex != index) {
        _selectedIndex = index;
        _navigationHistory.add(index);
        notifyListeners();
      } else {
        // Reset halaman di tab yang sama
        // navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      }
    } else {}
  }

  Future<bool> onWillPop() async {
    final currentNavigator = navigatorKeys[_selectedIndex].currentState!;

    // 1. Coba pop halaman di tab saat ini
    bool didPop = await currentNavigator.maybePop();

    if (didPop) {
      // 1a. Jika berhasil pop, cek apakah pindah tab diperlukan
      if (_navigationHistory.length >= 2) {
        int previousIndex = _navigationHistory[_navigationHistory.length - 2];
        _navigationHistory.removeLast();
        if (previousIndex != _selectedIndex) {
          _selectedIndex = previousIndex;
        }
        notifyListeners();
      }

      return false; // Kita handle sendiri
    }

    // 2. Tidak bisa pop → cek apakah kita bisa kembali ke tab sebelumnya
    if (_navigationHistory.length >= 2) {
      _navigationHistory.removeLast();
      final previousIndex = _navigationHistory.last;

      if (previousIndex != _selectedIndex) {
        _selectedIndex = previousIndex;
        // pindah tab saja, biarkan stack-nya
      }

      notifyListeners();

      return false; // Kita handle sendiri
    }
    notifyListeners();
    // 3. Tidak bisa pop dan tidak ada tab sebelumnya → izinkan keluar app
    return true;
  }

  /// Access any navigator directly
  NavigatorState? getNavigator(int index) => navigatorKeys[index].currentState;

  /// Change tab programmatically
  void changeTab(int index, BuildContext context, {bool popToRoot = false}) {
    if (popToRoot) {
      navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
    }
    onItemTapped(index, context);
  }

  /// Push a route on a specific tab
  Future<void> pushOnTab(int tabIndex, Route route) async {
    navigatorKeys[tabIndex].currentState?.push(route);
  }

  /// Clear all stacks
  void popAllToRoot() {
    for (var key in navigatorKeys) {
      key.currentState?.popUntil((r) => r.isFirst);
    }
  }

  String ambilGambar(String img, {bool umum = false}) {
    if (umum) {
      return "https://fotoapi.pdj.web.id/api/files" +
          "/" +
          "umum@gmail.com" +
          "/" +
          img;
    }

    return "https://fotoapi.pdj.web.id/api/files" +
        "/" +
        'finance.pdj@gmail.com' +
        "/" +
        img;
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

    // ✅ Cek login dari AuthService, bukan dari _isLoggedIn yang tidak akurat
    final idToken =
        await AuthService().getIdToken(); // atau authKeGoogle(silent: true)
    final sudahLogin = idToken != null;

    if (!sudahLogin && hrsLogin) {
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
    print("==== HISTORY: $_navigationHistory");

    int targetIndex = targetTabIndex;

    print(
        "🔑 navigatorKeys[targetIndex].currentState: ${navigatorKeys[targetIndex].currentState}");

    navigatorKeys[targetIndex].currentState?.push(
          MaterialPageRoute(builder: (_) => page),
        );
    await Future.delayed(const Duration(milliseconds: 50));

    _selectedIndex = targetIndex;
    _navigationHistory.add(targetIndex);
    notifyListeners();
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
