import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/data/repositories/kota_provider.dart';
import 'package:mpjnew/src/features/customer/services/kota_service.dart';
import 'package:mpjnew/src/features/customer/services/penawaran_service.dart';
import 'package:mpjnew/src/features/customer/view/main_menu.dart';
import 'package:mpjnew/src/features/customer/viewmodels/kategori_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/penawaran_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';

import 'package:mpjnew/src/features/customer/viewmodels/paket_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/room_chat_provider.dart';

import 'package:mpjnew/src/features/customer/viewmodels/vendor_provider.dart';
import 'package:mpjnew/src/features/customer/services/kategori_service.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/services/vendor_service.dart';
import 'package:provider/provider.dart';

import 'src/features/auth/services/user_provider.dart';
import 'src/features/customer/services/customer_service.dart';
import 'src/features/auth/services/auth_service.dart';
import 'src/core/routing/navigation_provider.dart';
import 'src/features/customer/services/portofolio_service.dart';

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
            authService: AuthService(),
          ),
        ),

        // Provider untuk portofolio yang mengambil userProvider dari atasnya
        ChangeNotifierProvider(
          create: (_) => PortofolioProvider(
            portofolioService: PortofolioService(),
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => KategoriProvider(KategoriService()),
        ),

        ChangeNotifierProvider(
          create: (_) => KotaProvider(KotaService()),
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
          create: (_) =>
              PenawaranProvider(penawaranService: PenawaranService()),
        ),

        /// ✅ ChatProvider tetap ada di root, tapi connect nanti saat login / buka chat
        ChangeNotifierProvider(
          create: (_) => ChatProvider(),
        ),

        ChangeNotifierProxyProvider3<PaketProvider, PenawaranProvider,
            ChatProvider, RoomChatProvider>(
          create: (_) => RoomChatProvider(
            paketProv: _.read<PaketProvider>(),
            penawaranProv: _.read<PenawaranProvider>(),
            chatProv: _.read<ChatProvider>(),
          ),
          update: (_, pkt, pen, chat, prev) {
            prev?.updateDependencies(
              paketProv: pkt,
              penawaranProv: pen,
              chatProv: chat,
            );
            return prev!;
          },
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final nav = Provider.of<NavigationProvider>(context, listen: false);

    try {
      String? role = await nav.getRole();
      print("================= MAIN.DART: ROLE Sebelum Logout = $role");

      // 1️⃣ Logout dulu sepenuhnya
      print("=== LOGOUT DIMULAI ===");
      await nav.handleLogout(context);
      print("=== LOGOUT SELESAI ===");

      // 2️⃣ Setelah logout selesai, set kembali ke Customer (untuk versi demo saja)
      await nav.saveRole(Constants.customer);
      print("================= MAIN.DART: ROLE = $role");

      _startPage = const MainMenu();
    } catch (e, s) {
      print("❌ Error saat init: $e");
      print(s);
      _startPage = const Scaffold(
        body: Center(child: Text("Terjadi kesalahan saat memuat data")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
