import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mpjnew/splash_logic_handler.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/core/services/auth_service_instance.dart';
import 'package:mpjnew/src/core/services/fcm/fcm_service.dart';
import 'package:mpjnew/src/core/services/fcm/models/notification_type.dart';
import 'package:mpjnew/src/core/services/fcm/utils/notification_channel_manager.dart';
import 'package:mpjnew/src/core/services/fcm/utils/notification_helper.dart';
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
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/services/penawaran_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/services/vendor_service.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/view/complain/complain_thread_page.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_page_V2.dart';
import 'package:mpjnew/src/features/customer/view/main_menu.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/complain_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/kategori_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/order_tab_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/paket_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/penawaran_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/room_chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/ui_state_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/vendor_provider.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/customer_service.dart';
import 'package:mpjnew/src/features/customer/services/portofolio_service.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'src/core/routing/navigation_provider.dart';

var companyNameGlobal = 'PT. ABC';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  debugPrint('[BGHandler] 📨 Message: ${message.messageId}');
  debugPrint('[BGHandler] 📨 Message: ${message.data}');
  debugPrint('[BGHandler] Type: ${message.data['type']}');

  try {
    final type = NotificationType.fromString(message.data['type']);

    if (type == NotificationType.chat) {
      // Enqueue ke SharedPreferences + kirim status "received" ke API
      final success =
          await ChatStorageService.enqueueBackgroundMessage(message);

      debugPrint(success
          ? '[BGHandler] ✅ Chat enqueued + received status sent'
          : '[BGHandler] ⏭️ Skipped (duplicate/invalid/echo)');

      if (success) {
        await _showBackgroundChatNotification(message);
      }
    } else if (type == NotificationType.progress ||
        type == NotificationType.review ||
        type == NotificationType.complainHeader ||
        type == NotificationType.complainDetail) {
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
    debugPrint('🚀 APP INIT START');

    // ── 1. Firebase — wajib paling pertama ────────────────────────
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('✅ Firebase ready');

    // ── 2. Isar + Hive — paralel ────────────────────────
    await Future.wait([
      ChatIsarService.instance.initialize(),
      Hive.initFlutter().then((_) {
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
      }),
    ]);
    debugPrint('✅ Isar + Hive ready (paralel)');

    // ── 3. PesananLocalService — setelah Hive siap ────────
    final pesananLocalService = PesananLocalService();
    await pesananLocalService.initialize();
    debugPrint('✅ Isar + Hive + PesananLocalService ready (paralel)');

    // ── 3. AuthService — butuh Hive sudah siap ────────────────────
    await authService.initialize();
    final userId = authService.userId;
    if (userId != null) {
      ChatStorageService.instance.setCurrentUser(userId);
    }
    debugPrint('✅ AuthService ready');

    // ── 4. FCMService — butuh Auth sudah siap ─────────────────────
    await FCMService.instance.initialize();
    debugPrint('✅ FCM ready');

    debugPrint('✅ APP INIT COMPLETE');

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
              create: (_) => KategoriProvider(KategoriService())),
          ChangeNotifierProvider(create: (_) => KotaProvider(KotaService())),
          ChangeNotifierProvider(
              create: (_) => PaketProvider(service: PaketService())),
          ChangeNotifierProvider(
              create: (_) => VendorProvider(service: VendorService())),
          ChangeNotifierProvider(
            create: (_) =>
                PenawaranProvider(penawaranService: PenawaranService()),
          ),
          ChangeNotifierProvider(
            create: (_) => PesananProvider(
              pesananService: PesananService(),
              historyService: HistoryOrderService(),
            ),
          ),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => ComplainProvider()),
          ChangeNotifierProxyProvider<ChatProvider, RoomChatProvider>(
            create: (context) =>
                RoomChatProvider(chatProv: context.read<ChatProvider>()),
            update: (_, chatProvider, previous) =>
                previous ?? RoomChatProvider(chatProv: chatProvider),
          ),
          ChangeNotifierProvider(
            create: (_) => HistoryOrderProvider()..initialize(),
          ),
          ChangeNotifierProvider(create: (_) => OrderTabProvider()),
          ChangeNotifierProvider(create: (_) => UiStateProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('❌ FATAL INIT ERROR: $e\n$stackTrace');
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

    // ✅ SATU-SATUNYA titik inject provider ke FCMService.
    //    addPostFrameCallback menjamin widget tree + Provider sudah ready.
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
        textTheme: GoogleFonts.nunitoTextTheme(
          Theme.of(context).textTheme,
        ),
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

  // ─── FCM Callbacks — SATU titik inject, dipanggil sekali setelah build ──

  void _setupFCMCallbacks(BuildContext context) {
    debugPrint('[Main] 🔧 Setting up FCM callbacks...');

    try {
      final chatProvider = context.read<ChatProvider>();
      final historyOrderProvider = context.read<HistoryOrderProvider>();
      final pesananProvider = context.read<PesananProvider>();
      final penawaranProvider = context.read<PenawaranProvider>();
      final complainProvider = context.read<ComplainProvider>();
      final navigationProvider = context.read<NavigationProvider>();

      // ── Inject semua provider ke FCMService ─────────────────────────────
      // Urutan: inject DULU, baru callbacks
      FCMService.instance.setChatProvider(chatProvider);
      FCMService.instance.setHistoryOrderProvider(historyOrderProvider);
      FCMService.instance.setPesananProvider(pesananProvider);
      FCMService.instance.setPenawaranProvider(penawaranProvider);
      FCMService.instance.setComplainProvider(complainProvider);

      // ── getSenderName ────────────────────────────────────────────────────
      FCMService.instance.getSenderName = (roomId, senderId) {
        try {
          return chatProvider.getSenderName(roomId, senderId);
        } catch (_) {
          return 'Pesan baru';
        }
      };

      // ── Chat message (fallback jika _chatProvider null di FCMService) ────
      FCMService.instance.onChatMessageReceived = (message) {
        debugPrint('[Main] 💬 FCM chat fallback: ${message.roomId}');
        try {
          chatProvider.handleMessageFromFCM(message);
        } catch (e, st) {
          debugPrint('[Main] ❌ handleMessageFromFCM error: $e\n$st');
        }
      };

      // ── Tap notifikasi chat → navigasi ke RoomChatPage ───────────────────
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

      // ── Progress ─────────────────────────────────────────────────────────
      FCMService.instance.onProgressReceived = (HistoryOrderModel progress) {
        debugPrint('[Main] 📊 FCM progress: ${progress.noOrder}');
        try {
          historyOrderProvider.handleProgressFromFCM(progress);

          // Untuk status 'review' dan 'revisi', vendor juga mengisi linkUrl
          // di order. refreshOrder() fetch full PesananModel dari API sehingga
          // linkUrl langsung tersedia tanpa user refresh manual.
          // Untuk status lain, cukup update lokal agar lebih cepat.
          final newStatus = progress.statusProgressPesanan;
          if (newStatus == 'review' || newStatus == 'revisi') {
            pesananProvider.refreshOrder(progress.noOrder);
          } else {
            pesananProvider.updateOrderStatus(progress.noOrder, newStatus);
          }

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

      // ── Tap notifikasi order → navigasi ke DetailOrderPage ───────────────
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

      // ── Tap notifikasi complain → navigasi ke ComplainThreadPage ─────────
      FCMService.instance.onComplainNotificationTapped = (noComplain, noOrder) {
        debugPrint(
            '[Main] 👆 Complain notification tapped: noComplain=$noComplain noOrder=$noOrder');
        try {
          final ctx = navigatorKey.currentContext;
          if (ctx == null) return;

          // Tidak perlu panggil onComplainDetailPushReceived/HeaderPushReceived
          // di sini — ComplainThreadPage sendiri akan loadActive() pas dibuka.
          navigationProvider.navigateToPage(
            ctx,
            ComplainThreadPage(noComplain: noComplain, noOrder: noOrder),
            targetTabIndex: 2,
            hrsLogin: true,
          );
        } catch (e, st) {
          debugPrint('[Main] ❌ onComplainNotificationTapped error: $e\n$st');
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
// SPLASH LOGIC HANDLER
// ═══════════════════════════════════════════════════════════════════════════

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

    // Hanya tampilkan untuk pesan baru dari pengirim (bukan echo sendiri)
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
      case NotificationType.complainHeader:
      case NotificationType.complainDetail:
        // Backend kirim title/body siap pakai di data payload (bukan di
        // message.notification), sama seperti di ComplainNotificationHandler.
        channelId = NotificationChannelManager.complainChannelId;
        title = message.data['title']?.toString() ?? 'Complain';
        body = message.data['body']?.toString() ??
            'Ada pembaruan pada complain Anda';
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
