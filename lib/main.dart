import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/core/services/auth_service_instance.dart';
import 'package:mpjnew/src/core/services/fcm/fcm_service.dart';
import 'package:mpjnew/src/data/hive_entity/chat_message_entity.dart';
import 'package:mpjnew/src/data/hive_entity/media_url_model.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';
import 'package:mpjnew/src/data/hive_entity/room_chat_entity.dart';
import 'package:mpjnew/src/data/hive_service.dart/pesanan_local_service.dart';
import 'package:mpjnew/src/data/hive_service.dart/ulasan_local_service.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';
import 'package:mpjnew/src/data/repositories/kota_provider.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/services/kota_service.dart';
import 'package:mpjnew/src/features/customer/services/penawaran_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_page.dart';
import 'package:mpjnew/src/features/customer/view/main_menu.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/kategori_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/order_tab_provider.dart';
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
import 'package:mpjnew/src/features/customer/widget/dialog/custom_dialog.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'src/features/auth/services/user_provider.dart';
import 'src/features/customer/services/customer_service.dart';
import 'src/core/routing/navigation_provider.dart';
import 'src/features/customer/services/portofolio_service.dart';

var companyNameGlobal = 'PT. ABC';

/// ✅ Background message handler (MUST be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('═══════════════════════════════════════════════════');
  debugPrint('[Background] 📨 Message received: ${message.messageId}');
  debugPrint('[Background] Type: ${message.data['type']}');
  debugPrint('═══════════════════════════════════════════════════');

  await FCMService.instance.handleBackgroundMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint("═══════════════════════════════════════════════════");
    debugPrint("🚀 CUSTOMER APP INITIALIZATION START");
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
      Hive.registerAdapter(MediaCacheStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MediaUrlModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(PaketModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(PenawaranModelAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(PesananModelAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(PortofolioModelAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(RoomChatEntityAdapter());
    }
    debugPrint("✅ Hive adapters registered");

    final pesananLocalService = PesananLocalService();
    await pesananLocalService.initialize();

    // ✅ Initialize AuthService singleton
    await authService.initialize();
    debugPrint("✅ AuthService initialized");

    debugPrint("═══════════════════════════════════════════════════");
    debugPrint("✅ INITIALIZATION COMPLETE");
    debugPrint("═══════════════════════════════════════════════════");

    // Run app
    runApp(
      MultiProvider(
        providers: [
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
            create: (_) =>
                PortofolioProvider(portofolioService: PortofolioService()),
          ),
          ChangeNotifierProvider(
            create: (_) => KategoriProvider(KategoriService()),
          ),
          ChangeNotifierProvider(create: (_) => KotaProvider(KotaService())),
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
            create: (_) => PesananProvider(
                pesananService: PesananService(),
                historyService: HistoryOrderService()),
          ),

          // ✅ ChatProvider - No SignalR initialization needed
          ChangeNotifierProvider(create: (_) => ChatProvider()),

          ChangeNotifierProxyProvider<ChatProvider, RoomChatProvider>(
            create: (context) => RoomChatProvider(
              chatProv: context.read<ChatProvider>(),
            ),
            update: (context, chatProvider, previousRoomChatProvider) {
              return previousRoomChatProvider ??
                  RoomChatProvider(chatProv: chatProvider);
            },
          ),

          // ✅ HistoryOrderProvider - No SignalR initialization needed
          ChangeNotifierProvider(
            create: (_) => HistoryOrderProvider()..initialize(),
          ),

          ChangeNotifierProvider(create: (_) => OrderTabProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint("═══════════════════════════════════════════════════");
    debugPrint("❌ FATAL INITIALIZATION ERROR");
    debugPrint("═══════════════════════════════════════════════════");
    debugPrint("Error: $e");
    debugPrint("Stack: $stackTrace");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ✅ Global navigator key for session handling
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // ✅ Setup session expired handler
    _setupSessionExpiredHandler();

    // ✅ Setup FCM callbacks after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupFCMCallbacks(context);
    });

    return MaterialApp(
      title: 'Aplikasi Customer',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Constants.primaryColor,
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

  /// ✅ Setup FCM callbacks for all notification types
  void _setupFCMCallbacks(BuildContext context) {
    debugPrint("═══════════════════════════════════════════════════");
    debugPrint("[Main] 🔧 SETTING UP FCM CALLBACKS");
    debugPrint("═══════════════════════════════════════════════════");

    try {
      // ✅ Set app context for FCM Service
      FCMService.instance.setAppContext(context);
      debugPrint("[Main] ✅ App context set");

      final chatProvider = context.read<ChatProvider>();
      final historyOrderProvider = context.read<HistoryOrderProvider>();
      final pesananProvider = context.read<PesananProvider>();
      final navigationProvider = context.read<NavigationProvider>();

      // ═══════════════════════════════════════════════════
      // 1️⃣ CHAT CALLBACKS
      // ═══════════════════════════════════════════════════

      /// Get sender name for notification
      FCMService.instance.getSenderName = (roomId, senderId) {
        debugPrint("[Main] 🔍 getSenderName called");
        debugPrint("   Room: $roomId, Sender: $senderId");

        try {
          final senderName = chatProvider.getSenderName(roomId, senderId);
          debugPrint("   ✅ Name: $senderName");
          return senderName;
        } catch (e) {
          debugPrint("   ⚠️ Error: $e");
          return 'New Message';
        }
      };

      /// Handle chat message received from FCM
      FCMService.instance.onChatMessageReceived = (ChatModel message) {
        debugPrint("═══════════════════════════════════════════════════");
        debugPrint("[Main] 💬 CHAT MESSAGE FROM FCM");
        debugPrint("═══════════════════════════════════════════════════");
        debugPrint("[Main] Room: ${message.roomId}");
        debugPrint("[Main] Sender: ${message.senderId}");
        debugPrint("[Main] Status: ${message.sendStatus}");
        debugPrint("[Main] Message: ${message.message}");

        try {
          // ✅ Pass to ChatProvider to handle local storage updates
          chatProvider.handleMessageFromFCM(message);
          debugPrint("[Main] ✅ Chat message processed");
        } catch (e, st) {
          debugPrint("[Main] ❌ Error processing chat: $e");
          debugPrint("[Main] Stack: $st");
        }

        debugPrint("═══════════════════════════════════════════════════");
      };

      /// Handle chat notification tapped
      FCMService.instance.onNotificationTapped = (roomId) {
        debugPrint("═══════════════════════════════════════════════════");
        debugPrint("[Main] 👆 CHAT NOTIFICATION TAPPED");
        debugPrint("═══════════════════════════════════════════════════");
        debugPrint("[Main] Room ID: $roomId");

        try {
          final context = navigatorKey.currentContext;
          if (context != null) {
            // ✅ Track room & set active before navigation
            chatProvider.trackRoom(roomId);
            chatProvider.setActiveRoom(roomId);
            FCMService.instance.setActiveRoom(roomId);

            navigationProvider.navigateToPage(
              context,
              RoomChatPage(roomId: roomId),
              targetTabIndex: 1, // Chat tab
              hrsLogin: false,
              transitionType: PageTransitionType.slideRight,
            );

            debugPrint("[Main] ✅ Navigated to room: $roomId");
          } else {
            debugPrint("[Main] ⚠️ Navigator context not available");
          }
        } catch (e, st) {
          debugPrint("[Main] ❌ Error navigating: $e");
          debugPrint("[Main] Stack: $st");
        }

        debugPrint("═══════════════════════════════════════════════════");
      };

      // ═══════════════════════════════════════════════════
      // 2️⃣ PROGRESS CALLBACKS
      // ═══════════════════════════════════════════════════

      /// Handle progress update from FCM
      FCMService.instance.onProgressReceived = (HistoryOrderModel progress) {
        debugPrint("═══════════════════════════════════════════════════");
        debugPrint("[Main] 📊 PROGRESS UPDATE FROM FCM");
        debugPrint("═══════════════════════════════════════════════════");
        debugPrint("[Main] Order: ${progress.noOrder}");
        debugPrint("[Main] Status: ${progress.statusProgressPesanan}");
        debugPrint("[Main] Sender: ${progress.senderId}");
        debugPrint("[Main] Description: ${progress.deskripsi}");

        try {
          // ✅ STEP 1: Update HistoryOrderProvider
          historyOrderProvider.handleProgressFromFCM(progress);
          debugPrint("[Main] ✅ HistoryOrderProvider updated");

          // ✅ STEP 2: Update PesananProvider status
          pesananProvider.updateOrderStatus(
            progress.noOrder,
            progress.statusProgressPesanan,
          );
          debugPrint("[Main] ✅ PesananProvider status updated");

          // ✅ STEP 3: Refresh order list jika diperlukan
          Future.delayed(const Duration(milliseconds: 300), () {
            if (historyOrderProvider.isOrderTracked(progress.noOrder)) {
              // Refresh history dari API untuk ensure consistency
              historyOrderProvider.fetchHistoryForOrder(
                progress.noOrder,
                silent: true, // Silent mode, tidak show loading
              );
              debugPrint("[Main] 🔄 History refreshed from API");
            }
          });
        } catch (e, st) {
          debugPrint("[Main] ❌ Error processing progress: $e");
          debugPrint("[Main] Stack: $st");
        }

        debugPrint("═══════════════════════════════════════════════════");
      };

      /// Handle order notification tapped
      FCMService.instance.onOrderNotificationTapped = (String orderId) {
        debugPrint("═══════════════════════════════════════════════════");
        debugPrint("[Main] 👆 ORDER NOTIFICATION TAPPED");
        debugPrint("═══════════════════════════════════════════════════");
        debugPrint("[Main] Order ID: $orderId");

        try {
          final context = navigatorKey.currentContext;
          if (context == null) {
            debugPrint("[Main] ⚠️ Navigator context not available");
            return;
          }

          // ✅ Track order untuk ensure data tersedia
          historyOrderProvider.trackOrder(orderId);

          // Navigate to DetailOrderPage
          final pesananList = pesananProvider.allPesanan;
          final pesanan = pesananList.firstWhereOrNull(
            (p) => p.noBukti == orderId,
          );

          if (pesanan != null) {
            final navigationProvider = context.read<NavigationProvider>();

            navigationProvider.navigateToPage(
              context,
              DetailOrderPage(pesananModel: pesanan),
              targetTabIndex: 2, // Order tab
              hrsLogin: true,
            );

            debugPrint("[Main] ✅ Navigated to order detail");
          } else {
            debugPrint("[Main] ⚠️ Pesanan not found in list");
          }
        } catch (e, st) {
          debugPrint("[Main] ❌ Error: $e");
          debugPrint("[Main] Stack: $st");
        }

        debugPrint("═══════════════════════════════════════════════════");
      };

      // ═══════════════════════════════════════════════════
      // 3️⃣ LIKE CALLBACKS
      // ═══════════════════════════════════════════════════

      FCMService.instance.onLikeReceived = (portofolioId, userId) {
        debugPrint("═══════════════════════════════════════════════════");
        debugPrint("[Main] ❤️ LIKE RECEIVED FROM FCM");
        debugPrint("═══════════════════════════════════════════════════");
        debugPrint("[Main] Portfolio: $portofolioId");
        debugPrint("[Main] User: $userId");

        try {
          // TODO: Implement like handling for customer
          // - Update portfolio like count in UI
          // - Show in-app notification
          debugPrint("[Main] ℹ️ Like handling (TODO)");
        } catch (e, st) {
          debugPrint("[Main] ❌ Error: $e");
          debugPrint("[Main] Stack: $st");
        }

        debugPrint("═══════════════════════════════════════════════════");
      };

      debugPrint("[Main] ✅ FCM callbacks configured successfully");
      debugPrint("═══════════════════════════════════════════════════");
    } catch (e, st) {
      debugPrint("═══════════════════════════════════════════════════");
      debugPrint("[Main] ❌ ERROR SETTING UP FCM CALLBACKS");
      debugPrint("═══════════════════════════════════════════════════");
      debugPrint("Error: $e");
      debugPrint("Stack: $st");
    }
  }

  /// ✅ Setup session expired handler
  void _setupSessionExpiredHandler() {
    apiClient.onSessionExpired = () {
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('🚪 [MyApp] SESSION EXPIRED');
      debugPrint('═══════════════════════════════════════════════════');

      final context = navigatorKey.currentContext;
      if (context == null) {
        debugPrint('❌ [MyApp] No context available');
        return;
      }

      _handleSessionExpired(context);
    };

    debugPrint('✅ [MyApp] Session expired handler registered');
  }

  /// ✅ Handle session expired
  void _handleSessionExpired(BuildContext context) async {
    debugPrint('🚪 [MyApp] Handling session expired...');

    try {
      // 1. Disconnect FCM & clear data
      FCMService.instance.clearAllMessageGroups();

      final chatProvider = context.read<ChatProvider>();

      // Clear active states
      chatProvider.setActiveRoom(null);
      FCMService.instance.setActiveRoom(null);

      // 2. Logout and clear all data
      final navigationProvider = context.read<NavigationProvider>();
      await navigationProvider.handleLogout(context);

      debugPrint('✅ [MyApp] Logout complete');

      // 3. Wait for logout to complete
      await Future.delayed(const Duration(milliseconds: 300));

      if (!context.mounted) return;
      navigationProvider.popAllToRoot();
      debugPrint('✅ [MyApp] Navigated to MainMenu');

      // 5. Show session expired dialog
      Future.delayed(const Duration(milliseconds: 500), () {
        final currentContext = navigatorKey.currentContext;
        if (currentContext != null && currentContext.mounted) {
          CustomDialog.showWarningDialog(
            context: currentContext,
            title: 'Sesi Berakhir',
            message: 'Sesi Anda telah berakhir. Silahkan login kembali.',
          );
        }
      });
    } catch (e, stackTrace) {
      debugPrint('❌ [MyApp] Error handling session expired: $e');
      debugPrint(stackTrace.toString());

      // Fallback: just navigate to MainMenu
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainMenu()),
          (_) => false,
        );
      }
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
  Widget? _startPage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      debugPrint("═══════════════════════════════════════════════════");
      debugPrint("🚀 LOADING INITIAL DATA");
      debugPrint("═══════════════════════════════════════════════════");

      // ✅ Setup session expired callback
      apiClient.onSessionExpired = () {
        debugPrint("🚪 [Splash] Session expired, logging out...");
        if (mounted) {
          final nav = context.read<NavigationProvider>();
          nav.handleLogout(context);
        }
      };

      // 1️⃣ Try to restore session
      debugPrint("🔄 [Splash] Attempting to restore session...");
      final userProvider = context.read<UserProvider>();
      final sessionRestored = await userProvider.restoreSession();

      debugPrint("   Session restored: $sessionRestored");

      if (sessionRestored && userProvider.customer != null) {
        debugPrint("✅ [Splash] Session restored successfully");
        debugPrint("   User: ${userProvider.customer!.namaDisplay}");

        // 2️⃣ Set role
        await context.read<NavigationProvider>().saveRole(Constants.customer);
        apiClient.setRole(Constants.customer);

        // 3️⃣ ✅ Initialize Chat & History Order Providers (FCM-based)
        debugPrint("🔧 [Splash] Initializing FCM-based providers...");

        final chatProvider = context.read<ChatProvider>();

        // Initialize ChatProvider (loads rooms from API)
        await chatProvider.initialize(
          userId: userProvider.customer!.noId,
          userType: Constants.customer,
        );
        debugPrint("✅ [Splash] ChatProvider initialized");

        // ✅ Register FCM token to backend
        await FCMService.instance.registerToken(userProvider.customer!.noId);
        debugPrint("✅ [Splash] FCM token registered");

        // 4️⃣ Load master data in background
        Future.microtask(() async {
          try {
            await context.read<KotaProvider>().getAllKotaList();
            await context.read<KategoriProvider>().loadKategori();
            debugPrint("✅ [Splash] Master data loaded");
          } catch (e) {
            debugPrint("⚠️ [Splash] Master data load failed: $e");
          }
        });
      } else {
        debugPrint("ℹ️ [Splash] No session found, user not logged in");

        // Set default role for new users
        await context.read<NavigationProvider>().saveRole(Constants.customer);
        apiClient.setRole(Constants.customer);
      }

      // 5️⃣ Always go to MainMenu (users can explore without login)
      _startPage = const MainMenu();

      debugPrint("═══════════════════════════════════════════════════");
      debugPrint("✅ INITIAL DATA LOAD COMPLETE");
      debugPrint("═══════════════════════════════════════════════════");
    } catch (e, stackTrace) {
      debugPrint("═══════════════════════════════════════════════════");
      debugPrint("❌ INITIALIZATION ERROR");
      debugPrint("═══════════════════════════════════════════════════");
      debugPrint("Error: $e");
      debugPrint("Stack: $stackTrace");

      _errorMessage = "Terjadi kesalahan saat memuat aplikasi: $e";
      _startPage = _buildErrorPage();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildErrorPage() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? "Terjadi kesalahan",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadInitialData();
                },
                child: const Text("Coba Lagi"),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainMenu(),
                    ),
                  );
                },
                child: const Text("Lanjut ke Aplikasi"),
              ),
            ],
          ),
        ),
      ),
    );
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

    if (_startPage != null) {
      return _startPage!;
    }

    // Fallback
    return const MainMenu();
  }
}
