import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/services/agreement_check_service.dart';
import 'package:mpjnew/src/core/services/fcm/fcm_service.dart';
import 'package:mpjnew/src/data/repositories/kota_provider.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/local_storage_service.dart';
import 'package:mpjnew/src/features/customer/view/account/legal_page.dart';
import 'package:mpjnew/src/features/customer/view/chat/chat_list_page.dart';
import 'package:mpjnew/src/features/customer/view/account/customer_account_page.dart';
import 'package:mpjnew/src/features/customer/view/history/main_order_page.dart';
import 'package:mpjnew/src/features/customer/view/single_post_page.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:collection/collection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

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
  late Animation<double> _imageScaleAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _imageScaleAnimation = Tween<double>(begin: 1.1, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════
  // LOGIN LOGIC
  // ════════════════════════════════════════════════════════════

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
      debugPrint("═══════════════════════════════════════");
      debugPrint("🔐 [UserLogin] Starting Google login...");

      final provider = context.read<UserProvider>();
      final navigationProvider = context.read<NavigationProvider>();
      final chatProv = context.read<ChatProvider>();
      final pesananProv = context.read<PesananProvider>();

      final result = await provider.checkLoginGoogle(
        role: Constants.customer,
        silent: false,
      );

      if (!mounted) return;

      debugPrint("📊 [UserLogin] Login result: ${result.name}");

      if (result.name == 'aktif') {
        debugPrint(
            "✅ [UserLogin] Login successful: ${provider.customer?.namaDisplay}");

        LocalStorageService.instance.setActiveCustomer(provider.customer!.noId);

        // Gelombang 1: permission + chatProvider init
        await Future.wait([
          _requestNotificationPermission(context),
          _initializeChatProvider(context, provider, chatProv),
        ]);

        // Gelombang 2: order, FCM, kota, liked/saved
        await Future.wait([
          _initializeHistoryOrderProvider(context, pesananProv),
          _registerFCMToken(provider),
          _loadKotaList(context),
          _loadLikedAndSaved(context, provider),
        ]);

        // Gelombang 3: refresh portofolio dengan userId agar status like/save
        // tampil benar. Harus SETELAH gelombang 2 karena _syncLikedAndSavedFromLocal
        // membaca dari list yang baru diisi oleh _loadLikedAndSaved.
        if (mounted) {
          try {
            await context.read<PortofolioProvider>().loadPortofolio(
                  context,
                  preloadImages: false, // gambar sudah di-cache saat guest
                );
            debugPrint(
                "[UserLogin] ✅ Portofolio refreshed with like/save status");
          } catch (e) {
            debugPrint(
                "[UserLogin] ⚠️ Portofolio refresh error (non-fatal): $e");
          }
        }

        debugPrint("✅ [UserLogin] All services initialized");
        debugPrint("═══════════════════════════════════════");

        // Gate persetujuan dokumen legal — harus SEBELUM Navigator.pop,
        // karena setelah pop context halaman ini sudah tidak valid untuk
        // menampilkan dialog. Data customer di sini selalu fresh dari
        // getAll saat login, jadi tidak perlu refresh ulang.
        if (mounted) {
          await AgreementCheckService.ensure(context, refreshOnMismatch: false);
        }

        if (!mounted) return;
        Navigator.pop(context, true);

        final targetWidget = getPageFromString(
          targetPage,
          noIdPortofolio: noIdPortofolio,
          noIdVendor: noIdVendor,
        );

        if (targetPage.startsWith('Tab')) {
          navigationProvider.setSelectedIndex(tabIndex);
          navigationProvider.showBottomNav();
        } else {
          await navigationProvider.navigateToPage(
            context,
            targetWidget,
            targetTabIndex: tabIndex,
            hrsLogin: false,
          );
        }
      } else if (result.name == 'nonaktif') {
        debugPrint("⚠️ [UserLogin] Account inactive");
        if (!mounted) return;
        CustomSnackbar.showErrorSnackbar(
          context,
          "Akun Anda tidak aktif. Silakan hubungi admin.",
        );
        await provider.logout();
        if (mounted) Navigator.pop(context, false);
      } else {
        debugPrint("❌ [UserLogin] Login failed: ${result.name}");
        if (!mounted) return;
        CustomSnackbar.showErrorSnackbar(
          context,
          "Login gagal. Silakan coba lagi.",
        );
        await provider.logout();
        if (mounted) Navigator.pop(context, false);
      }
    } catch (e, st) {
      debugPrint("❌ [UserLogin] Error: $e\n$st");
      if (mounted) {
        CustomSnackbar.showErrorSnackbar(
          context,
          "Terjadi kesalahan saat login: $e",
        );
        Navigator.pop(context, false);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ════════════════════════════════════════════════════════════
  // INIT HELPERS
  // ════════════════════════════════════════════════════════════

  Future<void> _loadLikedAndSaved(
      BuildContext context, UserProvider provider) async {
    try {
      final portoProvider = context.read<PortofolioProvider>();
      await Future.wait([
        portoProvider.loadLikedPortofolio(context: context, syncFromApi: true),
        portoProvider.loadSavedPortofolio(context: context, syncFromApi: true),
      ]);
    } catch (e) {
      debugPrint("[UserLogin] ⚠️ Load liked/saved error: $e");
    }
  }

  Future<void> _requestNotificationPermission(BuildContext context) async {
    if (!Platform.isAndroid) return;
    try {
      final status = await Permission.notification.request();
      if (status.isDenied && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Izin Notifikasi'),
            content: const Text(
              'Aplikasi membutuhkan izin notifikasi untuk '
              'memberi tahu Anda tentang pesan baru dan update pesanan.',
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
      }
    } catch (e) {
      debugPrint("[UserLogin] ⚠️ Notification permission error: $e");
    }
  }

  Future<void> _initializeChatProvider(
    BuildContext context,
    UserProvider provider,
    ChatProvider chatProv,
  ) async {
    try {
      await chatProv.initialize(
        userId: provider.customer!.noId,
        userType: Constants.customer,
      );
    } catch (e) {
      debugPrint("[UserLogin] ⚠️ ChatProvider init error: $e");
    }
  }

  /// Cukup warm up daftar order (Status_Progress_Pesanan +
  /// Deskripsi_Progress_Pesanan sudah ikut di setiap order) -- TIDAK lagi
  /// men-track semua order untuk fetch timeline history-nya satu-satu.
  /// Timeline lengkap tetap lazy per halaman Detail Order.
  Future<void> _initializeHistoryOrderProvider(
    BuildContext context,
    PesananProvider pesananProv,
  ) async {
    try {
      await pesananProv.loadOrderOnly(context);
    } catch (e) {
      debugPrint("[UserLogin] ⚠️ PesananProvider init error: $e");
    }
  }

  Future<void> _registerFCMToken(UserProvider provider) async {
    try {
      await FCMService.instance.registerToken(provider.customer!.noId);
    } catch (e) {
      debugPrint("[UserLogin] ⚠️ FCM token registration error: $e");
    }
  }

  Future<void> _loadKotaList(BuildContext context) async {
    try {
      await context.read<KotaProvider>().getAllKotaList();
    } catch (e) {
      debugPrint("[UserLogin] ⚠️ Kota list load error: $e");
    }
  }

  // ════════════════════════════════════════════════════════════
  // BUILD — Full-screen image background layout
  // ════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
            {};
    final String targetPage = args['targetPage'] ?? 'CustomerHome';
    final int tabIndex = args['tabIndex'] ?? 0;
    final String? noIdPortofolio = args['noIdPortofolio'];
    final String? noIdVendor = args['noIdVendor'];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, false);
      },
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // ═══════════════════════════════════════════
              // LAYER 1: Full-screen background image
              // ═══════════════════════════════════════════
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _imageScaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _imageScaleAnimation.value,
                      child: child,
                    );
                  },
                  child: Image.asset(
                    'assets/login_image_2.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // ═══════════════════════════════════════════
              // LAYER 2: Gradient overlay
              // ═══════════════════════════════════════════
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.3, 0.55, 1.0],
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.92),
                      ],
                    ),
                  ),
                ),
              ),

              // ═══════════════════════════════════════════
              // LAYER 3: Back button
              // ═══════════════════════════════════════════
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),

              // ═══════════════════════════════════════════
              // LAYER 4: Content at bottom
              // ═══════════════════════════════════════════
              Positioned.fill(
                child: SafeArea(
                  child: Column(
                    children: [
                      const Spacer(),

                      // ── Welcome text ─────────────────────
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Temukan Fotografer\nTerbaik Anda',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Jelajahi portofolio, bandingkan paket, dan '
                                  'pesan fotografer profesional untuk momen spesial Anda.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 14.5,
                                    height: 1.55,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Google Login button ───────────────
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: SizedBox(
                              width: double.infinity,
                              height: 58,
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
                                      Colors.white.withOpacity(0.6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
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
                                            height: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Masuk dengan Google',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Legal links ───────────────────────
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                Text(
                                  'Dengan masuk, Anda menyetujui ',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LegalPage(
                                          type: LegalType.terms),
                                    ),
                                  ),
                                  child: Text(
                                    'Syarat & Ketentuan',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 12,
                                      height: 1.5,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                          Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                                Text(
                                  ' dan ',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LegalPage(
                                          type: LegalType.privacy),
                                    ),
                                  ),
                                  child: Text(
                                    'Kebijakan Privasi',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 12,
                                      height: 1.5,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                          Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                                Text(
                                  ' kami',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // PAGE ROUTING
  // ════════════════════════════════════════════════════════════

  Widget getPageFromString(
    String targetPage, {
    String? noIdPortofolio,
    String? noIdVendor,
  }) {
    switch (targetPage) {
      case 'SinglePostPage':
        final portoProvider = context.read<PortofolioProvider>();
        if (noIdPortofolio != null && noIdPortofolio.isNotEmpty) {
          final porto = portoProvider.portofolioList
              .firstWhereOrNull((p) => p.noId == noIdPortofolio);
          if (porto != null) {
            portoProvider.setSelectedPortofolio(porto);
          }
        }
        return const SinglePostPage();

      case 'VendorBioPage':
        return VendorBioPage(idVendor: noIdVendor ?? 'ven_2');
      case 'Tab1':
        return const ChatListPage();
      case 'Tab2':
        return const MainOrderPage();
      case 'Tab3':
        return const CustomerAccountPage();
      default:
        return const SinglePostPage();
    }
  }
}
