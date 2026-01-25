import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/core/services/auth_service_instance.dart';
import 'package:mpjnew/src/core/services/fcm_service.dart';
import 'package:mpjnew/src/data/hive_entity/chat_message_entity.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/hive_entity/room_chat_entity.dart';
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
import 'package:permission_handler/permission_handler.dart';
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

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await firebaseMessagingBackgroundHandler(message);
}

void main() async {
  // ✅ Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ Initialize Firebase
    await Firebase.initializeApp();
    print("✅ Firebase initialized");

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize FCM
    await FCMService.instance.initialize();

    // ✅ Initialize Hive
    await Hive.initFlutter();
    print("✅ Hive initialized");

    // ✅ Register Hive adapters
    Hive.registerAdapter(ChatMessageEntityAdapter());
    Hive.registerAdapter(RoomChatEntityAdapter());
    Hive.registerAdapter(PaketModelAdapter());
    Hive.registerAdapter(PenawaranModelAdapter());
    Hive.registerAdapter(PesananModelAdapter());
    print("✅ Hive adapters registered");

    // ✅ Initialize AuthService singleton
    await authService.initialize();
    print("✅ AuthService initialized");

    runApp(const MyApp());
  } catch (e, stackTrace) {
    print("❌ Fatal initialization error: $e");
    print(stackTrace);

    // Show error screen
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize app',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ UserProvider dengan initialization
        ChangeNotifierProvider(
          create: (_) {
            final provider = UserProvider(
              customerService: CustomerService(),
              vendorService: VendorService(),
            );
            // Initialize Hive box
            provider.initialize();
            return provider;
          },
        ),

        ChangeNotifierProvider(create: (_) => NavigationProvider()),

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
          create: (_) => PaketProvider(service: PaketService()),
        ),

        ChangeNotifierProvider(
          create: (_) => VendorProvider(service: VendorService()),
        ),

        ChangeNotifierProvider(
          create: (_) =>
              PenawaranProvider(penawaranService: PenawaranService()),
        ),

        ChangeNotifierProvider(
          create: (_) => PesananProvider(pesananService: PesananService()),
        ),

        ChangeNotifierProvider(
          create: (_) => ChatProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => HistoryOrderProvider(),
        ),

        ChangeNotifierProxyProvider<ChatProvider, RoomChatProvider>(
          create: (context) => RoomChatProvider(
            chatProv: context.read<ChatProvider>(),
          ),
          update: (context, chatProvider, previousRoomChatProvider) {
            return previousRoomChatProvider ??
                RoomChatProvider(chatProv: chatProvider);
          },
        ),
      ],
      child: MaterialApp(
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
      ),
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
      print("=== 🚀 APP STARTED ===");

      // ✅ Setup session expired callback
      apiClient.onSessionExpired = () {
        print("🚪 [Main] Session expired, logging out...");
        if (mounted) {
          nav.handleLogout(context);
        }
      };

      // 1️⃣ Try to restore session
      bool sessionRestored = await authService.restoreSession();
      print("Session restored: $sessionRestored");

      if (sessionRestored) {
        print("✅ Session found, restoring user data...");

        // 2️⃣ Restore user session
        final userRestored = await userProv.restoreSession();

        if (userRestored && userProv.customer != null) {
          print("✅ User restored: ${userProv.customer!.namaDisplay}");

          // 3️⃣ Load role from storage
          String? role = await nav.getRole();
          if (role != null) {
            userProv.setRole(role);
            print("✅ Role set: $role");
          }

          // 4️⃣ Verify token is still valid
          try {
            print("🔄 Verifying token...");
            final token = await authService.getIdToken(forceRefresh: false);

            if (token != null) {
              print("✅ Token valid");

              // 5️⃣ Register device token
              try {
                await userProv.deviceTokenService
                    .addDeviceToken(userProv.customer!.noId);
              } catch (e) {
                print("⚠️ Device token registration failed: $e");
              }

              // 6️⃣ Initialize ChatProvider
              try {
                // ✅ REQUEST PERMISSION DULU (Android 13+)
                if (Platform.isAndroid) {
                  final status = await Permission.notification.request();

                  if (status.isDenied) {
                    // Show dialog to ask user
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Izin Notifikasi'),
                          content: Text(
                            'Aplikasi membutuhkan izin notifikasi untuk '
                            'memberi tahu Anda tentang pesan baru.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Nanti'),
                            ),
                            TextButton(
                              onPressed: () {
                                openAppSettings(); // Open settings
                                Navigator.pop(context);
                              },
                              child: Text('Buka Pengaturan'),
                            ),
                          ],
                        ),
                      );
                    }
                  } else if (status.isPermanentlyDenied) {
                    // User permanently denied, show info
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Izin notifikasi ditolak. '
                            'Buka Pengaturan untuk mengaktifkannya.',
                          ),
                          action: SnackBarAction(
                            label: 'Pengaturan',
                            onPressed: () => openAppSettings(),
                          ),
                        ),
                      );
                    }
                  }
                }
                final chatProv = context.read<ChatProvider>();

                chatProv.chatService.getSenderName = (roomId, senderId) {
                  // Ambil nama dari room info yang sudah di-cache
                  final room = chatProv.getRoom(roomId);
                  if (room != null) {
                    // Jika sender adalah partner, ambil nama partner
                    if (senderId == room.partnerId) {
                      return room.usernameLawan ?? 'Unknown User';
                    }
                  }
                  return 'New Message';
                };

                await chatProv.initWithApiClient(
                  userId: userProv.customer!.noId,
                  userType: Constants.customer,
                  hubUrl: "${Constants.baseUrlHub}/api/chathub",
                  getToken: () async =>
                      await authService.getIdToken(forceRefresh: true),
                );
                print("[Main] ✅ ChatProvider initialized");
              } catch (e) {
                print("[Main] ⚠️ ChatProvider init failed: $e");
              }

              // 7️⃣ Initialize HistoryOrderProvider
              try {
                print("[Main] 🔧 Initializing HistoryOrderProvider...");

                final historyOrderProvider =
                    context.read<HistoryOrderProvider>();
                final pesananProvider = context.read<PesananProvider>();

                // ✅ CRITICAL: Connect HistoryOrder → Pesanan BEFORE init
                print(
                    "[Main] 🔗 Connecting HistoryOrderProvider → PesananProvider...");

                historyOrderProvider.onOrderStatusChanged =
                    (noOrder, newStatus) {
                  print("[Main] 📨 Status update received:");
                  print("   Order: $noOrder");
                  print("   Status: $newStatus");
                  print("   Forwarding to PesananProvider...");

                  pesananProvider.updateOrderStatus(noOrder, newStatus);
                };

                print(
                    "[Main] ✅ HistoryOrderProvider ↔ PesananProvider connected");

                final historyConnected = await historyOrderProvider.initialize(
                  config: HistoryOrderServiceConfig(
                    hubUrl: "${Constants.baseUrlHub}/api/chathub",
                    role: Constants.customer,
                    getToken: () async =>
                        await authService.getIdToken(forceRefresh: true),
                  ),
                  userId: userProv.customer!.noId,
                );

                if (historyConnected) {
                  print("[Main] ✅ HistoryOrderProvider initialized");
                } else {
                  print("[Main] ⚠️ HistoryOrderProvider connection failed");
                }
              } catch (e) {
                print("[Main] ⚠️ HistoryOrderProvider init failed: $e");
              }

              print("✅ User logged in, going to MainMenu");
            } else {
              print("⚠️ Token verification failed, need re-login");
              await nav.handleLogout(context);
            }
          } catch (e) {
            print("❌ Token verification error: $e");
            await nav.handleLogout(context);
          }
        } else {
          print("⚠️ Session exists but user data incomplete, need re-login");
          await nav.handleLogout(context);
        }
      } else {
        print("ℹ️ No session found, user not logged in");
        // Set default role for new users
        await nav.saveRole(Constants.customer);
      }

      // 8️⃣ Always go to MainMenu (users can explore without login)
      _startPage = const MainMenu();
    } catch (e, s) {
      print("❌ Initialization error: $e");
      print(s);

      // On error, still go to MainMenu
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
