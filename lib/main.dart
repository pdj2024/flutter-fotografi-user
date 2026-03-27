import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/core/services/auth_service_instance.dart';
import 'package:mpjnew/src/core/services/fcm/fcm_service.dart';
import 'package:mpjnew/src/core/services/fcm/models/notification_type.dart';
import 'package:mpjnew/src/core/services/fcm/utils/notification_channel_manager.dart';
import 'package:mpjnew/src/core/services/fcm/utils/notification_helper.dart';
import 'package:mpjnew/src/core/services/version_check_service.dart';
import 'package:mpjnew/src/data/hive_entity/media_url_model.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';
import 'package:mpjnew/src/data/hive_service.dart/pesanan_local_service.dart';
import 'package:mpjnew/src/data/isar/service/chat_isar_service.dart';
import 'package:mpjnew/src/data/isar/service/chat_storage_service.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';
import 'package:mpjnew/src/data/repositories/kota_provider.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/services/kategori_service.dart';
import 'package:mpjnew/src/features/customer/services/kota_service.dart';
import 'package:mpjnew/src/features/customer/services/local_storage_service.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/services/penawaran_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/services/vendor_service.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_page_V2.dart';
import 'package:mpjnew/src/features/customer/view/main_menu.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/kategori_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/order_tab_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/paket_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/penawaran_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/room_chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/vendor_provider.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/customer_service.dart';
import 'package:mpjnew/src/features/customer/services/portofolio_service.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'src/core/routing/navigation_provider.dart';

var companyNameGlobal = 'PT. ABC';

// ═══════════════════════════════════════════════════════════════════════════
// BACKGROUND HANDLER — TOP-LEVEL (wajib, bukan method class)
//
// ✅ Nama fungsi diperbarui dari firebaseMessagingBackgroundHandler
//    Hanya boleh akses: SharedPreferences, http, Isar (dengan init manual)
//    TIDAK BOLEH akses: Provider, BuildContext, widget tree
// ═══════════════════════════════════════════════════════════════════════════

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  debugPrint('[BGHandler] 📨 Message: ${message.messageId}');
  debugPrint('[BGHandler] Type: ${message.data['type']}');

  try {
    final type = NotificationType.fromString(message.data['type']);

    if (type == NotificationType.chat) {
      // ✅ Enqueue ke SharedPreferences + HTTP update status → "received"
      // Isar diinisialisasi otomatis di dalam ChatStorageService.enqueueBackgroundMessage
      final success =
          await ChatStorageService.enqueueBackgroundMessage(message);

      debugPrint(success
          ? '[BGHandler] ✅ Chat enqueued + received status sent'
          : '[BGHandler] ⏭️ Skipped (duplicate/invalid/echo)');

      if (success) {
        await _showBackgroundChatNotification(message);
      }
    } else if (type == NotificationType.progress ||
        type == NotificationType.review) {
      await _showBackgroundNonChatNotification(message, type);
    }
  } catch (e, st) {
    debugPrint('[BGHandler] ❌ Error: $e\n$st');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════════════════

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('🚀 CUSTOMER APP INITIALIZATION START');
    debugPrint('═══════════════════════════════════════════════════');

    // ── 1. Firebase ────────────────────────────────────────────────────────
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');

    // ✅ Daftarkan background handler SEBELUM runApp
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('✅ Background message handler registered');

    // ── 2. Isar ────────────────────────────────────────────────────────────
    // Harus sebelum Hive dan sebelum runApp
    await ChatIsarService.instance.initialize();
    debugPrint('✅ Isar initialized');

    // ── 3. Hive ────────────────────────────────────────────────────────────
    await Hive.initFlutter();
    debugPrint('✅ Hive initialized');

    // typeId 0 (ChatMessage) dan 7 (RoomChat) sudah pindah ke Isar
    // Adapter Hive yang tersisa: media, paket, penawaran, pesanan, portofolio
    if (!Hive.isAdapterRegistered(1))
      Hive.registerAdapter(MediaCacheStatusAdapter());
    if (!Hive.isAdapterRegistered(2))
      Hive.registerAdapter(MediaUrlModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(PaketModelAdapter());
    if (!Hive.isAdapterRegistered(4))
      Hive.registerAdapter(PenawaranModelAdapter());
    if (!Hive.isAdapterRegistered(5))
      Hive.registerAdapter(PesananModelAdapter());
    if (!Hive.isAdapterRegistered(6))
      Hive.registerAdapter(PortofolioModelAdapter());
    debugPrint('✅ Hive adapters registered');

    // ── 4. Local services ──────────────────────────────────────────────────
    final pesananLocalService = PesananLocalService();
    await pesananLocalService.initialize();
    debugPrint('✅ PesananLocalService initialized');

    // ── 5. AuthService ─────────────────────────────────────────────────────
    await authService.initialize();
    final userId = authService.userId;
    if (userId != null) {
      // Set current user agar ChatStorageService bisa bedakan
      // pesan sendiri (echo) vs pesan masuk (incoming)
      ChatStorageService.instance.setCurrentUser(userId);
      debugPrint('✅ ChatStorageService user set: $userId');
    }
    debugPrint('✅ AuthService initialized');

    // ── 6. FCM ─────────────────────────────────────────────────────────────
    // ✅ TIDAK perlu FcmChatProvider lagi
    // FCMService akan di-inject ChatProvider setelah initialize() via setChatProvider()
    await FCMService.instance.initialize();
    debugPrint('✅ FCM Service initialized');

    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('✅ INITIALIZATION COMPLETE');
    debugPrint('═══════════════════════════════════════════════════');

    runApp(
      MultiProvider(
        providers: [
          // ✅ HAPUS: ChangeNotifierProvider.value(value: fcmChatProvider)
          // FcmChatProvider sudah tidak dipakai

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
          ChangeNotifierProvider(create: (_) => KotaProvider(KotaService())),
          ChangeNotifierProvider(
            create: (_) => PaketProvider(service: PaketService()),
          ),
          ChangeNotifierProvider(
            create: (_) => VendorProvider(service: VendorService()),
          ),
          ChangeNotifierProvider(
            create: (_) => PenawaranProvider(
              penawaranService: PenawaranService(),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => PesananProvider(
              pesananService: PesananService(),
              historyService: HistoryOrderService(),
            ),
          ),

          // ✅ ChatProvider — Isar offline-first edition
          // FCMService.setChatProvider() dipanggil otomatis di ChatProvider.initialize()
          ChangeNotifierProvider(create: (_) => ChatProvider()),

          // ✅ RoomChatProvider — hanya butuh ChatProvider sekarang
          // FcmChatProvider sudah dihapus dari dependency
          ChangeNotifierProxyProvider<ChatProvider, RoomChatProvider>(
            create: (context) => RoomChatProvider(
              chatProv: context.read<ChatProvider>(),
            ),
            update: (_, chatProvider, previous) {
              return previous ?? RoomChatProvider(chatProv: chatProvider);
            },
          ),

          ChangeNotifierProvider(
            create: (_) => HistoryOrderProvider()..initialize(),
          ),
          ChangeNotifierProvider(create: (_) => OrderTabProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('❌ FATAL INITIALIZATION ERROR');
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('Error: $e');
    debugPrint('Stack: $stackTrace');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MY APP
// ═══════════════════════════════════════════════════════════════════════════

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    _setupSessionExpiredHandler();

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

  // ─── FCM Callbacks ────────────────────────────────────────────────────────

  void _setupFCMCallbacks(BuildContext context) {
    debugPrint('[Main] 🔧 Setting up FCM callbacks...');

    try {
      // FCMService.instance.setAppContext(context);

      final chatProvider = context.read<ChatProvider>();
      final historyOrderProvider = context.read<HistoryOrderProvider>();
      final pesananProvider = context.read<PesananProvider>();
      final navigationProvider = context.read<NavigationProvider>();

      // ── Inject providers ke FCMService ──────────────────────────────────
      //
      // ✅ setChatProvider() akan rebuild ChatNotificationHandler agar
      //    onMessageReceived → ChatProvider.handleMessageFromFCM (Isar path)
      //    onUpdateMessageStatus → ChatProvider.updateMessageStatus (API + Isar)
      FCMService.instance.setChatProvider(chatProvider);
      FCMService.instance.setHistoryOrderProvider(historyOrderProvider);
      FCMService.instance.setPesananProvider(pesananProvider);

      // ✅ getSenderName — nama pengirim untuk notifikasi
      FCMService.instance.getSenderName = (roomId, senderId) {
        try {
          return chatProvider.getSenderName(roomId, senderId);
        } catch (e) {
          return 'Pesan baru';
        }
      };

      // ✅ onChatMessageReceived — callback fallback jika ChatProvider belum diinjeksi
      // Biasanya tidak dipanggil karena setChatProvider() sudah di atas,
      // tapi tetap disediakan sebagai safety net
      FCMService.instance.onChatMessageReceived = (message) {
        debugPrint('[Main] 💬 FCM chat fallback: ${message.roomId}');
        try {
          chatProvider.handleMessageFromFCM(message);
        } catch (e, st) {
          debugPrint('[Main] ❌ handleMessageFromFCM fallback error: $e\n$st');
        }
      };

      // ✅ onNotificationTapped — navigasi ke RoomChatPage saat notif di-tap
      FCMService.instance.onNotificationTapped = (roomId) {
        debugPrint('[Main] 👆 Chat notification tapped: $roomId');
        try {
          final ctx = navigatorKey.currentContext;
          if (ctx == null) return;

          chatProvider.trackRoom(roomId);
          chatProvider.setActiveRoom(roomId);
          FCMService.instance.setActiveRoom(roomId);

          navigationProvider.navigateToPage(
            ctx,
            RoomChatPage(roomId: roomId),
            targetTabIndex: 1,
            hrsLogin: false,
            transitionType: PageTransitionType.slideRight,
          );
        } catch (e, st) {
          debugPrint('[Main] ❌ onNotificationTapped error: $e\n$st');
        }
      };

      // ── Progress ────────────────────────────────────────────────────────

      FCMService.instance.onProgressReceived = (HistoryOrderModel progress) {
        debugPrint('[Main] 📊 FCM progress: ${progress.noOrder}');
        try {
          historyOrderProvider.handleProgressFromFCM(progress);
          pesananProvider.updateOrderStatus(
            progress.noOrder,
            progress.statusProgressPesanan,
          );
          Future.delayed(const Duration(milliseconds: 300), () {
            if (historyOrderProvider.isOrderTracked(progress.noOrder)) {
              historyOrderProvider.fetchHistoryForOrder(
                progress.noOrder,
                silent: true,
              );
            }
          });
        } catch (e, st) {
          debugPrint('[Main] ❌ onProgressReceived error: $e\n$st');
        }
      };

      FCMService.instance.onOrderNotificationTapped = (String orderId) {
        debugPrint('[Main] 👆 Order notification tapped: $orderId');
        try {
          final ctx = navigatorKey.currentContext;
          if (ctx == null) return;

          historyOrderProvider.trackOrder(orderId);

          final pesanan = pesananProvider.allPesanan
              .firstWhereOrNull((p) => p.noBukti == orderId);

          if (pesanan != null) {
            navigationProvider.navigateToPage(
              ctx,
              DetailOrderPageV2(pesananModel: pesanan),
              targetTabIndex: 2,
              hrsLogin: true,
            );
          } else {
            debugPrint('[Main] ⚠️ Pesanan $orderId tidak ditemukan');
          }
        } catch (e, st) {
          debugPrint('[Main] ❌ onOrderNotificationTapped error: $e\n$st');
        }
      };

      debugPrint('[Main] ✅ FCM callbacks configured');
    } catch (e, st) {
      debugPrint('[Main] ❌ _setupFCMCallbacks error: $e\n$st');
    }
  }

  // ─── Session Expired ──────────────────────────────────────────────────────

  void _setupSessionExpiredHandler() {
    apiClient.onSessionExpired = () {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      _handleSessionExpired(ctx);
    };

    authService.onSessionExpired = () {
      debugPrint('🚪 [MyApp] AuthService session expired');
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      _handleSessionExpired(ctx);
    };

    debugPrint('✅ Session expired handlers registered');
  }

  void _handleSessionExpired(BuildContext context) async {
    debugPrint('🚪 [MyApp] Handling session expired...');
    try {
      FCMService.instance.clearAllMessageGroups();

      final chatProvider = context.read<ChatProvider>();
      chatProvider.setActiveRoom(null);
      FCMService.instance.setActiveRoom(null);

      // Clear Isar chat data saat session expired
      await chatProvider.clearAll();
      await ChatStorageService.instance.clearAll();

      final navigationProvider = context.read<NavigationProvider>();
      await navigationProvider.handleLogout(context);

      await Future.delayed(const Duration(milliseconds: 300));
      if (!context.mounted) return;

      navigationProvider.popAllToRoot();
    } catch (e, st) {
      debugPrint('❌ [MyApp] _handleSessionExpired error: $e\n$st');
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainMenu()),
          (_) => false,
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SPLASH LOGIC HANDLER - Customer
// ═══════════════════════════════════════════════════════════════════════════

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
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('🚀 LOADING INITIAL DATA');
      debugPrint('═══════════════════════════════════════════════════');

      apiClient.onSessionExpired = () {
        debugPrint('🚪 [Splash] Session expired');
        if (mounted) context.read<NavigationProvider>().handleLogout(context);
      };

      // ── Cek versi app ──────────────────────────────────────────────────
      debugPrint('🔄 Checking app version...');
      final versionResult = await VersionCheckService().checkVersion();
      if (!mounted) return;

      if (!versionResult.isCompatible) {
        debugPrint('⚠️ Version incompatible — showing update dialog');
        await VersionCheckService.showUpdateDialogIfNeeded(
            context, versionResult);
        return;
      }
      debugPrint('✅ Version check passed');

      // ── Restore session ────────────────────────────────────────────────
      debugPrint('🔄 Restoring session...');
      final userProvider = context.read<UserProvider>();
      final sessionRestored = await userProvider.restoreSession();
      debugPrint('   Session restored: $sessionRestored');

      if (sessionRestored && userProvider.customer != null) {
        debugPrint('✅ Session restored: ${userProvider.customer!.namaDisplay}');

        await context.read<NavigationProvider>().saveRole(Constants.customer);
        apiClient.setRole(Constants.customer);

        LocalStorageService.instance.setActiveCustomer(
          userProvider.customer!.noId,
        );

        // Set current user di ChatStorageService
        // Penting: harus sebelum initialize ChatProvider
        // agar persistForegroundMessage bisa bedakan own message vs incoming
        ChatStorageService.instance.setCurrentUser(userProvider.customer!.noId);

        // ✅ Initialize ChatProvider (Isar offline-first)
        // Di dalam initialize(), FCMService.setChatProvider(this) dipanggil otomatis
        final chatProvider = context.read<ChatProvider>();
        await chatProvider.initialize(
          userId: userProvider.customer!.noId,
          userType: Constants.customer,
        );
        debugPrint('✅ ChatProvider initialized');

        // Register FCM token ke backend
        await FCMService.instance.registerToken(userProvider.customer!.noId);
        debugPrint('✅ FCM token registered');

        Future.microtask(() async {
          try {} catch (e) {
            debugPrint('⚠️ Load liked/saved on restore error: $e');
          }
        });

        // Load master data di background (tidak blocking splash)
        Future.microtask(() async {
          try {
            final portoProvider = context.read<PortofolioProvider>();
            final kotaProvider = context.read<KotaProvider>();
            final kategoriProvider = context.read<KategoriProvider>();

            await Future.wait(
              [
                portoProvider.loadLikedPortofolio(
                  context: context,
                  syncFromApi: true,
                ),
                portoProvider.loadSavedPortofolio(
                  context: context,
                  syncFromApi: true,
                ),
                kotaProvider.getAllKotaList(),
                kategoriProvider.loadKategori(),
              ],
            );
            debugPrint('✅ Liked & saved portofolio loaded on restore');
            debugPrint('✅ Master data loaded');
          } catch (e) {
            debugPrint('⚠️ Master data error: $e');
          }
        });
      } else {
        debugPrint('ℹ️ No session — user not logged in');
        await context.read<NavigationProvider>().saveRole(Constants.customer);
        apiClient.setRole(Constants.customer);
      }

      _startPage = const MainMenu();

      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('✅ INITIAL DATA LOAD COMPLETE');
      debugPrint('═══════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      debugPrint('❌ INITIALIZATION ERROR: $e');
      debugPrint('Stack: $stackTrace');
      _errorMessage = 'Terjadi kesalahan saat memuat aplikasi: $e';
      _startPage = _buildErrorPage();
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Terjadi kesalahan',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                child: const Text('Coba Lagi'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainMenu()),
                ),
                child: const Text('Lanjut ke Aplikasi'),
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
                'Memuat aplikasi...',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ),
      );
    }

    return _startPage ?? const MainMenu();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BACKGROUND NOTIFICATION HELPERS
// ═══════════════════════════════════════════════════════════════════════════

Future<void> _showBackgroundChatNotification(RemoteMessage message) async {
  try {
    final plugin = FlutterLocalNotificationsPlugin();
    await NotificationChannelManager.createAllChannels(plugin);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_pacific_data_jaya'),
      iOS: DarwinInitializationSettings(),
    );
    await plugin.initialize(initSettings);

    final detail = _parseDetail(message.data['detail']);
    final messageId = detail['message_id'] as String? ?? '';
    final roomId = detail['room_id'] as String? ?? '';
    final senderId = detail['sender_id'] as String? ?? '';
    final messageText = detail['message'] as String? ?? '';
    final jenisPesan = detail['jenis_pesan'] as String? ?? 'text';
    final sendStatus = detail['send_status'] as String? ?? 'sent';

    // Hanya tampilkan notif untuk pesan baru dari orang lain (status sent)
    if (sendStatus != 'sent') return;
    if (messageId.isEmpty || roomId.isEmpty) return;

    final displayText = _formatContent(messageText, jenisPesan);

    final androidDetails = AndroidNotificationDetails(
      NotificationChannelManager.chatChannelId,
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: 'ic_stat_pacific_data_jaya',
      enableVibration: true,
      playSound: true,
      autoCancel: true,
      groupKey: 'sender_$senderId',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final payload = NotificationHelper.createPayload({
      'type': 'chat',
      'roomId': roomId,
      'messageId': messageId,
      'senderId': senderId,
    });

    await plugin.show(
      NotificationHelper.generateNotificationId(senderId),
      'Pesan baru',
      displayText,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );

    debugPrint('[BGHandler] 🔔 Chat notif shown: $roomId');
  } catch (e) {
    debugPrint('[BGHandler] ⚠️ _showBackgroundChatNotification: $e');
  }
}

Future<void> _showBackgroundNonChatNotification(
  RemoteMessage message,
  NotificationType type,
) async {
  try {
    final plugin = FlutterLocalNotificationsPlugin();
    await NotificationChannelManager.createAllChannels(plugin);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_pacific_data_jaya'),
      iOS: DarwinInitializationSettings(),
    );
    await plugin.initialize(initSettings);

    String channelId;
    String title;
    String body;

    switch (type) {
      case NotificationType.progress:
        channelId = NotificationChannelManager.progressChannelId;
        title = message.notification?.title ?? 'Update Progress';
        body = message.notification?.body ?? 'Ada update progress pesanan';
        break;
      case NotificationType.review:
        channelId = NotificationChannelManager.reviewChannelId;
        title = message.notification?.title ?? 'Ulasan Baru';
        body = message.notification?.body ?? 'Kamu mendapat ulasan baru';
        break;
      default:
        return;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId,
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_pacific_data_jaya',
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await plugin.show(
      message.hashCode.abs() % 2147483647,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  } catch (e) {
    debugPrint('[BGHandler] ⚠️ _showBackgroundNonChatNotification: $e');
  }
}

// ─── JSON Helpers ──────────────────────────────────────────────────────────

Map<String, dynamic> _parseDetail(dynamic raw) {
  if (raw == null) return {};
  if (raw is Map<String, dynamic>) return raw;
  try {
    final decoded = jsonDecode(raw.toString());
    return decoded is Map<String, dynamic> ? decoded : {};
  } catch (_) {
    return {};
  }
}

String _formatContent(String message, String jenisPesan) {
  if (message.isNotEmpty) return message;
  switch (jenisPesan) {
    case 'paket':
      return '📦 Mengirim paket';
    case 'penawaran':
      return '💼 Mengirim penawaran';
    case 'pesanan':
      return '🧾 Mengirim pesanan';
    case 'image':
      return '🖼️ Mengirim gambar';
    default:
      return 'Pesan baru';
  }
}
