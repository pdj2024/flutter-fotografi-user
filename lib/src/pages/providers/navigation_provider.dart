import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/pages/core/api_singleton.dart';
import 'package:mpjnew/src/pages/fotografi_user/fotographerbio.dart';
import 'package:mpjnew/src/pages/fotografi_user/menutama.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/portofolio_provider.dart';
import 'package:mpjnew/src/pages/pilih_role.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fotografi_user/providers/user_provider.dart';
import '../fotografi_user/singlepage.dart';
import '../fotografi_user/user_login.dart';
import '../fotografi_vendor/biodata.dart';
import '../fotografi_vendor/vendor_login.dart';
import '../fotografi_vendor/vendor_menutama.dart';
import '../fotografi_vendor/vendor_status.dart';
import 'auth_service_fotografi.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'constants.dart';

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
  return prefs.getString('status_user');
}

  
Future<void> checkLogin(BuildContext context, String role, {Type? currentPage}) async {
  print("===== [checkLogin] start for role: $role");

  final auth = AuthService();
  String? idToken;

  // 🔍 Cek token dari cache atau silent login
  idToken = await auth.getIdToken(forceRefresh: false);

  if (idToken == null) {
    print("===== [checkLogin] user belum login, coba silent login...");
    idToken = await auth.login(silent: true);

    if (idToken == null) {
      print("===== [checkLogin] silent login gagal, redirect ke halaman login");

      if (role == Constants.vendor) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VendorLogin()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserLogin()));
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
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VendorStatus()));
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

  // Logout dari Google
  await AuthService().logout();
  print("===== [handleLogout] Logout dari Google selesai");

  // Clear SharedPreferences (role dan status user)
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('role');
  await prefs.remove('statusUser');
  print("===== [handleLogout] SharedPreferences dibersihkan");

  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => const PilihRole()),
  (route) => false,
);

 clearSelectedIndex();



  print("===== [handleLogout] Selesai");
}



Future<String> checkStatusUser(String idToken, String role) async {
  // Kirim idToken ke API dan cek status user di backend
  final status = 'aktif';// await fetchUserStatusFromApi(idToken, role);

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


void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }


  final List<GlobalKey<NavigatorState>> navigatorKeys = List.generate(
    3,
    (_) => GlobalKey<NavigatorState>(),
  );
  final List<int> _navigationHistory = [0]; // Track history of selected indexes

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
    if (context.read<UserProvider>().userId != null || index == 0) {
      // Asumsi tab pertama tidak perlu login (misalnya Home)
      if (_selectedIndex != index) {
        _selectedIndex = index;
        _navigationHistory.add(index);
        notifyListeners();

        // Tambahkan: Refresh portofolio jika pindah ke tab Home (index 0)
        // if (index == 0) {
        //   // Panggil provider fetchPortofolio tanpa filter
        //   Future.microtask(() {
        //     // Pastikan context masih valid, gunakan Provider.of dengan listen: false
        //     // Reset portofolio dan fetch ulang
        //     Provider.of<PortofolioProvider>(context, listen: false).getAll();
        //     Provider.of<PortofolioProvider>(context, listen: false)
        //         .getAll();
        //   });
        // }
      } else {
        // Reset halaman di tab yang sama
        // navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      }
    } else {
      // Jika belum login, navigasi ke halaman login
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
    if (context.read<UserProvider>().userId != null  || index == 0) {
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
  if (page is PhotographerBio) noIdVendor = page.idVendor;

  print("====================== TARGET: $targetPage");

  // ✅ Cek login dari AuthService, bukan dari _isLoggedIn yang tidak akurat
  final idToken = await AuthService().getIdToken(); // atau authKeGoogle(silent: true)
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

  navigatorKeys[targetIndex].currentState?.push(
    MaterialPageRoute(builder: (_) => page),
  );
  await Future.delayed(const Duration(milliseconds: 50));

  _selectedIndex = targetIndex;
  _navigationHistory.add(targetIndex);
  notifyListeners();
}


  Future<void> vendorNavigateToPage(BuildContext context, Widget page,
      {int targetTabIndex = 0,
      bool hrsLogin = true,
      String targetPage = 'VendorHome'}) async {
    if (context.read<UserProvider>().userId == null  && hrsLogin) {
      // Menggunakan root navigator agar login tampil di layar penuh terpisah
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => VendorLogin(),
          settings: RouteSettings(arguments: {
            'targetPage': targetPage,
            'tabIndex': targetTabIndex,
          }),
        ),
      );
      return;
    }

    int targetIndex = targetTabIndex;

    navigatorKeys[targetIndex].currentState?.push(
          MaterialPageRoute(builder: (context) => page),
        );
    await Future.delayed(Duration(milliseconds: 50));

    _selectedIndex = targetIndex;
    _navigationHistory.add(targetIndex); // <== INI BENAR
    notifyListeners();
  }

 

  Future<void> startNavigateVendor(BuildContext context) async {
  final status = (await getStatusUser())?.toLowerCase();

  print("====== STATUS: $status");

  switch (status) {
    case 'notregistered':
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BiodataPage()),
      );
      break;
    case 'pending':
    case 'rejected':
    case 'nonaktif':
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => VendorStatus()),
      );
      break;
    case 'accepted':
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => Vendor_MenuUtama()),
      );
      break;
    default:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status tidak dikenali: $status')),
      );
  }
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
