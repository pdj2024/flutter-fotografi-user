import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/services/auth_service_instance.dart';
import 'package:mpjnew/src/data/repositories/kota_provider.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/view/chat/chat_list_page.dart';
import 'package:mpjnew/src/features/customer/view/account/customer_account_page.dart';
import 'package:mpjnew/src/features/customer/view/history/main_order_page.dart';
import 'package:mpjnew/src/features/customer/view/single_post_page.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

/// ============================================
/// 🔐 UserLogin - FIXED VERSION
/// ============================================
/// Changes:
/// 1. ✅ Compatible with new AuthService API
/// 2. ✅ Removed forceRefresh parameter
/// 3. ✅ Better error handling
/// 4. ✅ Cleaner initialization flow
/// ============================================

class UserLogin extends StatefulWidget {
  const UserLogin({super.key});

  @override
  State<UserLogin> createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// ✅ Handle Google Login - Compatible with new AuthService
  Future<void> handleLoginGoogle(
    BuildContext context,
    String targetPage,
    int tabIndex,
    String? noIdPortofolio,
    String? noIdVendor,
  ) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      print("═══════════════════════════════════════");
      print("🔐 [UserLogin] Starting Google login...");

      final provider = context.read<UserProvider>();
      final navigationProvider = context.read<NavigationProvider>();
      final chatProv = context.read<ChatProvider>();

      // ✅ Login with Google (uses new AuthService.signIn())
      final result = await provider.checkLoginGoogle(
        role: Constants.customer,
        silent: false,
      );

      if (!mounted) return;

      print("📊 [UserLogin] Login result: ${result.name}");

      // ==========================================
      // CHECK LOGIN RESULT
      // ==========================================

      if (result.name == 'aktif') {
        print("✅ [UserLogin] Login successful!");
        print("   User: ${provider.customer?.namaDisplay}");

        // ==========================================
        // 1️⃣ REQUEST NOTIFICATION PERMISSION (Android 13+)
        // ==========================================
        await _requestNotificationPermission(context);

        // ==========================================
        // 2️⃣ INITIALIZE ChatProvider
        // ==========================================
        await _initializeChatProvider(context, provider, chatProv);

        // ==========================================
        // 3️⃣ INITIALIZE HistoryOrderProvider
        // ==========================================
        await _initializeHistoryOrderProvider(context, provider);

        // ==========================================
        // 4️⃣ LOAD KOTA LIST
        // ==========================================
        await _loadKotaList(context);

        if (!mounted) return;

        print("✅ [UserLogin] All services initialized");
        print("═══════════════════════════════════════");

        // ✅ Pop login page with success = true
        Navigator.pop(context, true);

        // ✅ Navigate to target page
        final targetWidget = getPageFromString(
          targetPage,
          noIdPortofolio: noIdPortofolio,
          noIdVendor: noIdVendor,
        );

        // ✅ If target is tab page, switch tab
        if (targetPage.startsWith('Tab')) {
          navigationProvider.setSelectedIndex(tabIndex);
          navigationProvider.showBottomNav();
        } else {
          // ✅ If target is detail page, navigate
          await navigationProvider.navigateToPage(
            context,
            targetWidget,
            targetTabIndex: tabIndex,
            hrsLogin: false, // Already logged in
          );
        }

        print("✅ [UserLogin] Navigation completed");
      } else if (result.name == 'nonaktif') {
        print("⚠️  [UserLogin] Account inactive");

        if (!mounted) return;

        CustomSnackbar.showErrorSnackbar(
          context,
          "Akun Anda tidak aktif. Silakan hubungi admin.",
        );

        await provider.logout();

        // ✅ Pop with false (login failed)
        if (mounted) {
          Navigator.pop(context, false);
        }
      } else {
        print("❌ [UserLogin] Login failed: ${result.name}");

        if (!mounted) return;

        CustomSnackbar.showErrorSnackbar(
          context,
          "Login gagal. Silakan coba lagi.",
        );

        await provider.logout();

        // ✅ Pop with false (login failed)
        if (mounted) {
          Navigator.pop(context, false);
        }
      }
    } catch (e, st) {
      print("═══════════════════════════════════════");
      print("❌ [UserLogin] Error during login");
      print("═══════════════════════════════════════");
      print("Error: $e");
      print("Stack: $st");

      if (mounted) {
        CustomSnackbar.showErrorSnackbar(
          context,
          "Terjadi kesalahan saat login: $e",
        );

        // ✅ Pop with false (error)
        Navigator.pop(context, false);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ✅ Request notification permission (Android 13+)
  Future<void> _requestNotificationPermission(BuildContext context) async {
    if (!Platform.isAndroid) return;

    try {
      print("[UserLogin] 🔔 Requesting notification permission...");

      final status = await Permission.notification.request();
      print("[UserLogin] Permission status: $status");

      if (status.isDenied && mounted) {
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
        print("[UserLogin] ✅ Notification permission granted");
      }
    } catch (e) {
      print("[UserLogin] ⚠️  Notification permission error: $e");
    }
  }

  /// ✅ Initialize ChatProvider
  Future<void> _initializeChatProvider(
    BuildContext context,
    UserProvider provider,
    ChatProvider chatProv,
  ) async {
    try {
      print("[UserLogin] 🔧 Initializing ChatProvider...");

      // Setup getSenderName callback
      chatProv.chatService.getSenderName = (roomId, senderId) {
        final room = chatProv.getRoom(roomId);
        if (room != null && senderId == room.partnerId) {
          return room.usernameLawan ?? 'Unknown User';
        }
        return 'New Message';
      };

      // ✅ Changed: Removed forceRefresh parameter
      await chatProv.initWithApiClient(
        userId: provider.customer!.noId,
        userType: Constants.customer,
        hubUrl: "${Constants.baseUrlHub}/api/chathub",
        getToken: () async => await authService.getIdToken(),
      );

      print("[UserLogin] ✅ ChatProvider initialized");
    } catch (e) {
      print("[UserLogin] ⚠️  ChatProvider init error: $e");
      // Don't throw - allow app to continue without chat
    }
  }

  /// ✅ Initialize HistoryOrderProvider
  Future<void> _initializeHistoryOrderProvider(
    BuildContext context,
    UserProvider provider,
  ) async {
    try {
      print("[UserLogin] 🔧 Initializing HistoryOrderProvider...");

      final historyOrderProvider = context.read<HistoryOrderProvider>();
      final pesananProvider = context.read<PesananProvider>();

      await pesananProvider.loadOrder(userId: provider.customer!.noId);

      // Connect HistoryOrder → Pesanan
      historyOrderProvider.onOrderStatusChanged = (noOrder, newStatus) {
        print("[UserLogin] 📨 Order status update: $noOrder → $newStatus");
        pesananProvider.updateOrderStatus(noOrder, newStatus);
      };

      // ✅ Changed: Removed forceRefresh parameter
      final historyConnected = await historyOrderProvider.initialize(
        config: HistoryOrderServiceConfig(
          hubUrl: "${Constants.baseUrlHub}/api/chathub",
          role: Constants.customer,
          getToken: () async => await authService.getIdToken(),
        ),
        userId: provider.customer!.noId,
      );

      if (historyConnected) {
        print("[UserLogin] ✅ HistoryOrderProvider initialized");
      } else {
        print("[UserLogin] ⚠️  HistoryOrderProvider connection failed");
      }
    } catch (e) {
      print("[UserLogin] ⚠️  HistoryOrderProvider init error: $e");
      // Don't throw - allow app to continue
    }
  }

  /// ✅ Load Kota list
  Future<void> _loadKotaList(BuildContext context) async {
    try {
      print("[UserLogin] 🔧 Loading Kota list...");

      await context.read<KotaProvider>().getAllKotaList();

      print("[UserLogin] ✅ Kota list loaded");
    } catch (e) {
      print("[UserLogin] ⚠️  Kota list load error: $e");
      // Don't throw - allow app to continue
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
            {};
    final String targetPage = args['targetPage'] ?? 'CustomerHome';
    final int tabIndex = args['tabIndex'] ?? 0;
    final String? noIdPortofolio = args['noIdPortofolio'];
    final String? noIdVendor = args['noIdVendor'];

    return WillPopScope(
      // ✅ When user presses back, return false (cancelled)
      onWillPop: () async {
        Navigator.pop(context, false);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        body: SafeArea(
          child: Stack(
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        children: [
                          const SizedBox(height: 30),

                          /// --- Animated Logo ---
                          SlideTransition(
                            position: _slideAnimation,
                            child: Hero(
                              tag: 'app_logo',
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Image.asset(
                                  'assets/camera_icon_transparent.png',
                                  height: 50,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// --- Hero Image ---
                          SlideTransition(
                            position: _slideAnimation,
                            child: ClipRRect(
                              child: Image.asset(
                                'assets/user_login_image.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          /// --- Welcome Text ---
                          SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                const Text(
                                  'Selamat Datang di',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      Constants.primaryColor,
                                      Constants.primaryColor.withOpacity(0.8),
                                    ],
                                  ).createShader(bounds),
                                  child: const Text(
                                    'Fotografi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Constants.primaryColor,
                                      fontSize: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          /// --- Google Sign In Button ---
                          SlideTransition(
                            position: _slideAnimation,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () async {
                                          await handleLoginGoogle(
                                            context,
                                            targetPage,
                                            tabIndex,
                                            noIdPortofolio,
                                            noIdVendor,
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black87,
                                    disabledBackgroundColor:
                                        Colors.grey.shade100,
                                    minimumSize: const Size.fromHeight(60),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: Colors.grey.shade200,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Constants.primaryColor,
                                            ),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/google_icon.png',
                                              height: 26,
                                            ),
                                            const SizedBox(width: 14),
                                            const Text(
                                              'Masuk dengan Google',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          /// --- Terms & Privacy ---
                          SlideTransition(
                            position: _slideAnimation,
                            child: Text(
                              'Dengan masuk, Anda menyetujui Syarat & Ketentuan\ndan Kebijakan Privasi kami',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ Back button - returns false when pressed
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get page widget from string identifier
  Widget getPageFromString(
    String targetPage, {
    String? noIdPortofolio,
    String? noIdVendor,
  }) {
    print("[UserLogin] 🎯 Target page: $targetPage");

    switch (targetPage) {
      case 'SinglePostPage':
        return SinglePostPage(
          noId: noIdPortofolio ?? 'porto_6',
        );
      case 'VendorBioPage':
        return VendorBioPage(
          idVendor: noIdVendor ?? 'ven_2',
        );
      case 'Tab1':
        return const ChatListPage();
      case 'Tab2':
        return const MainOrderPage();
      case 'Tab3':
        return const CustomerAccountPage();
      default:
        return SinglePostPage(
          noId: noIdPortofolio ?? 'porto_6',
        );
    }
  }
}
