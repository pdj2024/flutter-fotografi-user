import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/data/repositories/kota_provider.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/services/kota_service.dart';
import 'package:mpjnew/src/features/customer/services/penawaran_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/view/main_menu.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/kategori_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/penawaran_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
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
import 'src/core/routing/navigation_provider.dart';
import 'src/features/customer/services/portofolio_service.dart';

var companyNameGlobal = 'PT. ABC';

final localizationsDelegates = <LocalizationsDelegate>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider(
            customerService: CustomerService(),
            vendorService: VendorService(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),

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

        ChangeNotifierProvider(
          create: (_) => PesananProvider(pesananService: PesananService()),
        ),

        /// ✅ ChatProvider tetap ada di root
        ChangeNotifierProvider(
          create: (_) => ChatProvider(),
        ),

        /// ✅ HistoryOrderProvider di root (untuk standalone connection)
        ChangeNotifierProvider(
          create: (_) => HistoryOrderProvider(),
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
    final userProv = Provider.of<UserProvider>(context, listen: false);

    try {
      print("=== 🚀 APLIKASI DIMULAI ===");

      // 1️⃣ Cek apakah ada session tersimpan
      bool sessionRestored = await nav.authService.restoreSession();

      if (sessionRestored) {
        print("✅ Session ditemukan, mencoba restore user data...");

        // 2️⃣ Load user data dari storage
        await userProv.loadUserData();

        // 3️⃣ Validasi apakah data user berhasil di-load
        if (userProv.customer != null) {
          print(
              "✅ User data berhasil di-load: ${userProv.customer!.namaDisplay}");

          // 4️⃣ Load role dari storage
          String? role = await nav.getRole();
          if (role != null) {
            userProv.setRole(role);
            print("✅ Role di-set: $role");
          }

          // 5️⃣ Refresh token (silent login) untuk mendapatkan token terbaru
          try {
            print("🔄 Melakukan silent login untuk refresh token...");
            final newToken =
                await nav.authService.getIdToken(forceRefresh: true);

            if (newToken != null) {
              print("✅ Token berhasil di-refresh");

              // 6️⃣ Register device token
              await userProv.deviceTokenService
                  .addDeviceToken(userProv.customer!.noId);

              // ==========================================
              // 7️⃣ Initialize ChatProvider (Connection 1)
              // ==========================================
              final chatProv = context.read<ChatProvider>();
              await chatProv.initWithApiClient(
                userId: userProv.customer!.noId,
                userType: Constants.customer,
                hubUrl: "${Constants.baseUrlHub}/api/chathub",
                getToken: () async =>
                    await nav.authService.getIdToken(forceRefresh: true),
              );
              print("[Main] ✅ ChatProvider initialized");

              // ==========================================
              // 8️⃣ Initialize HistoryOrderProvider (Connection 2 - Standalone)
              // ==========================================
              final historyOrderProvider = context.read<HistoryOrderProvider>();
              final historyConnected = await historyOrderProvider.initialize(
                config: HistoryOrderServiceConfig(
                  hubUrl: "${Constants.baseUrlHub}/api/chathub",
                  role: Constants.customer,
                  getToken: () async =>
                      await nav.authService.getIdToken(forceRefresh: true),
                ),
                userId: userProv.customer!.noId,
              );

              if (historyConnected) {
                print("[Main] ✅ HistoryOrderProvider initialized with standalone connection");
              } else {
                print("[Main] ⚠️ HistoryOrderProvider connection failed");
              }

              print("✅ User sudah login, langsung ke MainMenu");
            } else {
              print("⚠️ Gagal refresh token, perlu login ulang");
              await nav.handleLogout(context);
            }
          } catch (e) {
            print("❌ Error saat refresh token: $e");
            await nav.handleLogout(context);
          }
        } else {
          print(
              "⚠️ Session ada tapi user data tidak lengkap, perlu login ulang");
          await nav.handleLogout(context);
        }
      } else {
        print("ℹ️ Tidak ada session, user belum pernah login");
        // Set role default untuk user baru
        await nav.saveRole(Constants.customer);
      }

      // 9️⃣ Selalu arahkan ke MainMenu (user bisa explore tanpa login)
      _startPage = const MainMenu();
    } catch (e, s) {
      print("❌ Error saat init: $e");
      print(s);

      // Jika ada error, tetap arahkan ke MainMenu
      _startPage = const MainMenu();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Constants.primaryColor),
              ),
              SizedBox(height: 16),
              Text(
                "Memuat aplikasi...",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return _startPage;
  }
}