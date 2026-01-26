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
import 'package:mpjnew/src/data/models/history_order_model.dart';
import 'package:mpjnew/src/data/repositories/kota_provider.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/services/kota_service.dart';
import 'package:mpjnew/src/features/customer/services/penawaran_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
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

/// ✅ Background message handler (MUST be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[Background Handler] 📨 Message: ${message.messageId}');
  await FCMService.instance.handleBackgroundMessage(message);
}

void main() async {
  // ✅ Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint("═══════════════════════════════════════════════════");
    debugPrint("🚀 APP INITIALIZATION START");
    debugPrint("═══════════════════════════════════════════════════");

    // ✅ Initialize Firebase
    await Firebase.initializeApp();
    debugPrint("✅ Firebase initialized");

    // ✅ Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint("✅ Background message handler registered");

    // ✅ Initialize FCM Service
    await FCMService.instance.initialize();
    debugPrint("✅ FCM Service initialized");
    debugPrint(
        "   Token: ${FCMService.instance.fcmToken ?? 'Not available yet'}");

    // ✅ Initialize Hive
    await Hive.initFlutter();
    debugPrint("✅ Hive initialized");

    // ✅ Register Hive adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ChatMessageEntityAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(RoomChatEntityAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PaketModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(PenawaranModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(PesananModelAdapter());
    }
    debugPrint("✅ Hive adapters registered");

    // ✅ Initialize AuthService singleton
    await authService.initialize();
    debugPrint("✅ AuthService initialized");

    debugPrint("═══════════════════════════════════════════════════");
    debugPrint("✅ INITIALIZATION COMPLETE");
    debugPrint("═══════════════════════════════════════════════════");

    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint("═══════════════════════════════════════════════════");
    debugPrint("❌ FATAL INITIALIZATION ERROR");
    debugPrint("═══════════════════════════════════════════════════");
    debugPrint("Error: $e");
    debugPrint("Stack trace:");
    debugPrint(stackTrace.toString());

    // Show error screen
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart app
                    debugPrint("🔄 Restarting app...");
                  },
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ✅ Navigator key untuk navigation dari notification
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

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
      child: Builder(
        builder: (context) {
          // ✅ Setup FCM callbacks AFTER providers are available
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _setupFCMCallbacks(context);
          });

          return MaterialApp(
            navigatorKey: navigatorKey,
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
        },
      ),
    );
  }

  /// ✅ Setup FCM callbacks with ChatProvider integration
  void _setupFCMCallbacks(BuildContext context) {
    debugPrint("═══════════════════════════════════════════════════");
    debugPrint("[Main] 🔧 Setting up FCM callbacks...");
    debugPrint("═══════════════════════════════════════════════════");

    try {
      final chatProvider = context.read<ChatProvider>();
      final navigationProvider = context.read<NavigationProvider>();

      // ═══════════════════════════════════════════════════
      // 1️⃣ SETUP getSenderName CALLBACK
      // ═══════════════════════════════════════════════════
      FCMService.instance.getSenderName = (roomId, senderId) {
        debugPrint("[Main] 🔍 getSenderName called");
        debugPrint("   Room ID: $roomId");
        debugPrint("   Sender ID: $senderId");

        // Try to get from ChatProvider
        final room = chatProvider.getRoom(roomId);
        if (room != null) {
          final name = room.usernameLawan ?? 'Unknown User';
          debugPrint("   ✅ Sender name: $name");
          return name;
        }

        debugPrint("   ⚠️ Room not found, using default");
        return 'New Message';
      };

      // ═══════════════════════════════════════════════════
      // 2️⃣ SETUP onChatMessageReceived CALLBACK
      // ═══════════════════════════════════════════════════
      FCMService.instance.onChatMessageReceived = (chatMessage) {
        debugPrint("[Main] 💬 FCM Chat message received");
        debugPrint("   Room: ${chatMessage.roomId}");
        debugPrint("   Sender: ${chatMessage.senderId}");
        debugPrint("   Message: ${chatMessage.message}");

        // ChatProvider will handle adding to Hive via SignalR
        // This is just for logging and optional extra handling
      };

      // ═══════════════════════════════════════════════════
      // 3️⃣ SETUP onNotificationTapped CALLBACK
      // ═══════════════════════════════════════════════════
      FCMService.instance.onNotificationTapped = (roomId) {
        debugPrint("[Main] 👆 Notification tapped");
        debugPrint("   Navigating to room: $roomId");

        final context = navigatorKey.currentContext;
        if (context != null) {
          navigationProvider.navigateToPage(
            context,
            RoomChatPage(roomId: roomId),
            targetTabIndex: 1, // Chat tab
            hrsLogin: false,
            transitionType: PageTransitionType.slideRight,
          );
        } else {
          debugPrint("   ⚠️ Navigator context not available");
        }
      };

      // ═══════════════════════════════════════════════════
      // 4️⃣ SETUP onLikeReceived CALLBACK (Optional)
      // ═══════════════════════════════════════════════════
      FCMService.instance.onLikeReceived = (portofolioId, userId) {
        debugPrint("[Main] ❤️ Like received");
        debugPrint("   Portfolio: $portofolioId");
        debugPrint("   User: $userId");

        // TODO: Update portfolio provider or refresh data
        // context.read<PortofolioProvider>().refreshPortfolio(portofolioId);
      };

      // ═══════════════════════════════════════════════════
      // 5️⃣ SETUP onProgressReceived CALLBACK (Optional)
      // ═══════════════════════════════════════════════════
      FCMService.instance.onProgressReceived =
          (HistoryOrderModel progressData) {
        debugPrint(
            "[Main] 📊 Progress: ${progressData.noOrder} → ${progressData.statusProgressPesanan}");

        try {
          // ✅ Update provider
          // context.read<PesananProvider>().handleProgressUpdate(progressData);
        } catch (e) {
          debugPrint("[Main] ❌ Error: $e");
        }
      };

      FCMService.instance.onOrderNotificationTapped = (String orderId) {
        // debugPrint("[Main] 👆 Navigate to: $orderId");

        // Navigator.of(navigatorKey.currentContext!).pushNamed(
        //   '/order-detail',
        //   arguments: {'orderId': orderId},
        // );
      };

      debugPrint("[Main] ✅ FCM callbacks configured successfully");
      debugPrint("═══════════════════════════════════════════════════");
    } catch (e, stackTrace) {
      debugPrint("═══════════════════════════════════════════════════");
      debugPrint("[Main] ❌ Error setting up FCM callbacks");
      debugPrint("═══════════════════════════════════════════════════");
      debugPrint("Error: $e");
      debugPrint("Stack: $stackTrace");
    }
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
      debugPrint("═══════════════════════════════════════════════════");
      debugPrint("🚀 APP STARTED - Loading initial data");
      debugPrint("═══════════════════════════════════════════════════");

      // ✅ Setup session expired callback
      apiClient.onSessionExpired = () {
        debugPrint("🚪 [Main] Session expired, logging out...");
        if (mounted) {
          nav.handleLogout(context);
        }
      };

      // 1️⃣ Try to restore session
      bool sessionRestored = await authService.restoreSession();
      debugPrint("Session restored: $sessionRestored");

      if (sessionRestored) {
        debugPrint("✅ Session found, restoring user data...");

        // 2️⃣ Restore user session
        final userRestored = await userProv.restoreSession();

        if (userRestored && userProv.customer != null) {
          debugPrint("✅ User restored: ${userProv.customer!.namaDisplay}");

          // 3️⃣ Load role from storage
          String? role = await nav.getRole();
          if (role != null) {
            userProv.setRole(role);
            debugPrint("✅ Role set: $role");
          }

          // 4️⃣ Verify token is still valid
          try {
            debugPrint("🔄 Verifying token...");
            final token = await authService.getIdToken(forceRefresh: false);

            if (token != null) {
              debugPrint("✅ Token valid");

              // 5️⃣ Request notification permission (Android 13+)
              await _requestNotificationPermission();

              // 6️⃣ Register device token
              try {
                await userProv.deviceTokenService
                    .addDeviceToken(userProv.customer!.noId);
                debugPrint("✅ Device token registered");
              } catch (e) {
                debugPrint("⚠️ Device token registration failed: $e");
              }

              // 7️⃣ Initialize ChatProvider
              await _initializeChatProvider(userProv);

              // 8️⃣ Initialize HistoryOrderProvider
              await _initializeHistoryOrderProvider(userProv);

              debugPrint("✅ User logged in, going to MainMenu");
            } else {
              debugPrint("⚠️ Token verification failed, need re-login");
              await nav.handleLogout(context);
            }
          } catch (e) {
            debugPrint("❌ Token verification error: $e");
            await nav.handleLogout(context);
          }
        } else {
          debugPrint(
              "⚠️ Session exists but user data incomplete, need re-login");
          await nav.handleLogout(context);
        }
      } else {
        debugPrint("ℹ️ No session found, user not logged in");
        // Set default role for new users
        await nav.saveRole(Constants.customer);
      }

      // 9️⃣ Always go to MainMenu (users can explore without login)
      _startPage = const MainMenu();

      debugPrint("═══════════════════════════════════════════════════");
      debugPrint("✅ INITIAL DATA LOAD COMPLETE");
      debugPrint("═══════════════════════════════════════════════════");
    } catch (e, s) {
      debugPrint("═══════════════════════════════════════════════════");
      debugPrint("❌ INITIALIZATION ERROR");
      debugPrint("═══════════════════════════════════════════════════");
      debugPrint("Error: $e");
      debugPrint("Stack: $s");

      // On error, still go to MainMenu
      _startPage = const MainMenu();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ✅ Request notification permission (Android 13+)
  Future<void> _requestNotificationPermission() async {
    if (!Platform.isAndroid) return;

    try {
      debugPrint("[Main] 🔔 Requesting notification permission...");

      final status = await Permission.notification.request();
      debugPrint("[Main] Permission status: $status");

      if (status.isDenied && mounted) {
        // Show dialog to explain why we need permission
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Izin Notifikasi'),
            content: const Text(
              'Aplikasi membutuhkan izin notifikasi untuk '
              'memberi tahu Anda tentang pesan baru, update pesanan, '
              'dan aktivitas lainnya.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Nanti'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Buka Pengaturan'),
              ),
            ],
          ),
        );
      } else if (status.isPermanentlyDenied && mounted) {
        // User permanently denied
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Izin notifikasi ditolak. '
              'Buka Pengaturan untuk mengaktifkannya.',
            ),
            action: SnackBarAction(
              label: 'Pengaturan',
              onPressed: () => openAppSettings(),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      } else if (status.isGranted) {
        debugPrint("[Main] ✅ Notification permission granted");
      }
    } catch (e) {
      debugPrint("[Main] ⚠️ Error requesting notification permission: $e");
    }
  }

  /// ✅ Initialize ChatProvider with FCM
  Future<void> _initializeChatProvider(UserProvider userProv) async {
    try {
      debugPrint("[Main] 🔧 Initializing ChatProvider...");

      final chatProv = context.read<ChatProvider>();

      // ✅ Setup getSenderName callback for ChatService
      chatProv.chatService.getSenderName = (roomId, senderId) {
        final room = chatProv.getRoom(roomId);
        if (room != null && senderId == room.partnerId) {
          return room.usernameLawan ?? 'Unknown User';
        }
        return 'New Message';
      };

      // Initialize ChatProvider
      await chatProv.initWithApiClient(
        userId: userProv.customer!.noId,
        userType: Constants.customer,
        hubUrl: "${Constants.baseUrlHub}/api/chathub",
        getToken: () async => await authService.getIdToken(forceRefresh: true),
      );

      debugPrint("[Main] ✅ ChatProvider initialized");
    } catch (e, stackTrace) {
      debugPrint("[Main] ❌ ChatProvider init failed: $e");
      debugPrint("[Main] Stack: $stackTrace");
    }
  }

  /// ✅ Initialize HistoryOrderProvider
  Future<void> _initializeHistoryOrderProvider(UserProvider userProv) async {
    try {
      debugPrint("[Main] 🔧 Initializing HistoryOrderProvider...");

      final historyOrderProvider = context.read<HistoryOrderProvider>();
      final pesananProvider = context.read<PesananProvider>();
      await pesananProvider.loadOrder(userId: userProv.customer!.noId);

      // ✅ Connect HistoryOrder → Pesanan
      historyOrderProvider.onOrderStatusChanged = (noOrder, newStatus) {
        debugPrint("[Main] 📨 Order status update:");
        debugPrint("   Order: $noOrder");
        debugPrint("   Status: $newStatus");
        pesananProvider.updateOrderStatus(noOrder, newStatus);
      };

      debugPrint("[Main] ✅ HistoryOrderProvider ↔ PesananProvider connected");

      // Initialize
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
        debugPrint("[Main] ✅ HistoryOrderProvider initialized");
      } else {
        debugPrint("[Main] ⚠️ HistoryOrderProvider connection failed");
      }
    } catch (e, stackTrace) {
      debugPrint("[Main] ❌ HistoryOrderProvider init failed: $e");
      debugPrint("[Main] Stack: $stackTrace");
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
