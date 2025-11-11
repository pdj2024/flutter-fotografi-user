import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/pages/fotografi_user/menutama.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/chat_provider.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/kategori_provider.dart';

import 'package:mpjnew/src/pages/fotografi_user/providers/paket_provider.dart';

import 'package:mpjnew/src/pages/fotografi_user/providers/vendor_provider.dart';
import 'package:mpjnew/src/pages/fotografi_user/services/kategori_service.dart';
import 'package:mpjnew/src/pages/fotografi_user/services/paket_service.dart';
import 'package:mpjnew/src/pages/fotografi_user/services/vendor_service.dart';
import 'package:mpjnew/src/pages/fotografi_vendor/biodata.dart';
import 'package:provider/provider.dart';

import 'src/pages/fotografi_user/providers/user_provider.dart';
import 'src/pages/fotografi_user/services/customer_service.dart';
import 'src/pages/providers/auth_service_fotografi.dart';
import 'src/pages/providers/navigation_provider.dart';
import 'src/pages/fotografi_vendor/vendor_login.dart';
import 'src/pages/fotografi_vendor/vendor_status.dart';
import 'src/pages/fotografi_vendor/vendor_menutama.dart';
import 'src/pages/fotografi_user/providers/portofolio_provider.dart';
import 'src/pages/fotografi_user/services/portofolio_service.dart';
import 'src/pages/pilih_role.dart';

import 'src/pages/core/api_singleton.dart'; // ← pakai ini

/// ✅ API Client: semua request HTTP lewat sini
import 'package:http/http.dart' as http;

var companyNameGlobal = 'PT. ABC';

final localizationsDelegates = <LocalizationsDelegate>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  /// ✅ Buat API Client sekali aja

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),

        /// ✅ Semua service pake ApiClient, jadi token & baseUrl tersentralisasi
        ChangeNotifierProvider(
          create: (_) => UserProvider(
              customerService: CustomerService(),
              vendorService: VendorService(),
              authService: AuthService()),
        ),

        ChangeNotifierProvider(
          create: (_) => KategoriProvider(
            service: KategoriService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PaketProvider(
            service: PaketService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => VendorProvider(
            service: VendorService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PortofolioProvider(
            service: PortofolioService(),
          ),
        ),

        /// ✅ ChatProvider tetap ada di root, tapi connect nanti saat login / buka chat
        ChangeNotifierProvider(
          create: (_) => ChatProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.light,
        ).copyWith(
          surface: Colors.white,
          surfaceTint: Colors.transparent,
        ),
      ),
      home: const SplashLogicHandler(),
    );
  }
}

class SplashLogicHandler extends StatefulWidget {
  const SplashLogicHandler({super.key});

  @override
  State<SplashLogicHandler> createState() => _SplashLogicHandlerState();
}

class _SplashLogicHandlerState extends State<SplashLogicHandler> {
  bool _isLoading = true;
  late Widget _startPage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final nav = Provider.of<NavigationProvider>(context, listen: false);
    // await nav.restoreLoginState(); ABAIKAN DULU

    // final role = null;
    final role = await context.read<NavigationProvider>().getRole();

    // Tiap buka app, logout dulu
    await context.read<NavigationProvider>().handleLogout(context);

    print("================= MAIN.DART: ROLE = $role");

    // User diarahkan memilih ROLE
    if (role == null || role.isEmpty) {
      _startPage = const PilihRole();
    } else if (role == Constants.customer) {
      _startPage = const Ecommerce_MenuUtama();
    } else if (role == Constants.vendor) {
      _startPage = const Vendor_MenuUtama();
    }
    setState(() {
      _isLoading = false;
    });
  }

  // ✅ Tambahkan ini supaya loading selesai dan UI update

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Memuat aplikasi...", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    } else {
      return _startPage;
    }
  }
}
