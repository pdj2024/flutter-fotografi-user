import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/repositories/kota_provider.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/view/chat/chat_list_page.dart';
import 'package:mpjnew/src/features/customer/view/account/customer_account_page.dart';
import 'package:mpjnew/src/features/customer/view/history/main_order_page.dart';
import 'package:mpjnew/src/features/customer/view/single_post_page.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
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

  Future<void> handleLoginGoogle(
    BuildContext context,
    String targetPage,
    int tabIndex,
    String? noIdPortofolio,
    String? noIdVendor,
  ) async {
    setState(() => _isLoading = true);

    try {
      final provider = context.read<UserProvider>();
      final navigationProvider = context.read<NavigationProvider>();

      // Login dengan Google
      final result = await provider.checkLoginGoogle(
        role: Constants.customer,
        silent: false,
      );

      if (!mounted) return;

      // Cek hasil login
      if (result.name == 'aktif') {
        print("[UserLogin] ✅ Login successful, initializing services...");

        // ==========================================
        // 1️⃣ Initialize ChatProvider (Connection 1)
        // ==========================================
        try {
          await context.read<ChatProvider>().initWithApiClient(
                userId: provider.customer!.noId,
                userType: Constants.customer,
                hubUrl: "${Constants.baseUrlHub}/api/chathub",
                getToken: () async => await navigationProvider.authService
                    .getIdToken(forceRefresh: true),
              );
          print("[UserLogin] ✅ ChatProvider initialized");
        } catch (e) {
          print("[UserLogin] ⚠️ ChatProvider init error: $e");
          // Continue even if chat fails
        }

        // ==========================================
        // 2️⃣ Initialize HistoryOrderProvider (Connection 2 - Standalone)
        // ==========================================
        try {
          final historyOrderProvider = context.read<HistoryOrderProvider>();

          final historyConnected = await historyOrderProvider.initialize(
            config: HistoryOrderServiceConfig(
              hubUrl: "${Constants.baseUrlHub}/api/chathub",
              role: Constants.customer,
              getToken: () async => await navigationProvider.authService
                  .getIdToken(forceRefresh: true),
            ),
            userId: provider.customer!.noId,
          );

          if (historyConnected) {
            print(
                "[UserLogin] ✅ HistoryOrderProvider initialized with standalone connection");
          } else {
            print("[UserLogin] ⚠️ HistoryOrderProvider connection failed");
          }
        } catch (e) {
          print("[UserLogin] ⚠️ HistoryOrderProvider init error: $e");
          // Continue even if history order fails
        }

        // ==========================================
        // 3️⃣ Load Kota List
        // ==========================================
        try {
          await context.read<KotaProvider>().getAllKotaList();
          print("[UserLogin] ✅ Kota list loaded");
        } catch (e) {
          print("[UserLogin] ⚠️ Kota list load error: $e");
          // Continue even if kota fails
        }

        // Pop halaman login
        Navigator.pop(context);

        // Navigate ke target page
        navigationProvider.navigateToPage(
          context,
          getPageFromString(
            targetPage,
            noIdPortofolio: noIdPortofolio,
            noIdVendor: noIdVendor,
          ),
          targetTabIndex: tabIndex,
        );

        print("[UserLogin] ✅ Navigation completed");
      } else if (result.name == 'nonaktif') {
        CustomSnackbar.showErrorSnackbar(
          context,
          "Akun Anda tidak aktif. Silakan hubungi admin.",
        );
        await provider.logout();
      } else {
        CustomSnackbar.showErrorSnackbar(
          context,
          "Login gagal. Silakan coba lagi.",
        );
        await provider.logout();
      }
    } catch (e, st) {
      print("❌ Error handleLoginGoogle: $e\n$st");
      if (mounted) {
        CustomSnackbar.showErrorSnackbar(
          context,
          "Terjadi kesalahan saat login: $e",
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
            {};
    final String targetPage = args['targetPage'] ?? 'EcommerceHome';
    final int tabIndex = args['tabIndex'] ?? 0;
    final String? noIdPortofolio = args['noIdPortofolio'];
    final String? noIdVendor = args['noIdVendor'];

    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      body: SafeArea(
        child: Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                physics: NeverScrollableScrollPhysics(),
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

                        /// --- Hero Image with Shadow ---
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

                        /// --- Welcome Text with Animation ---
                        SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              Text(
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
                                  disabledBackgroundColor: Colors.grey.shade100,
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
                                    ? SizedBox(
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
            Positioned(
              top: 16,
              left: 16,
              child: CustomBackButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget getPageFromString(String targetPage,
      {String? noIdPortofolio, String? noIdVendor}) {
    print("===== TARGET: $targetPage");
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
        return ChatListPage();
      case 'Tab2':
        return MainOrderPage();
      case 'Tab3':
        return CustomerAccountPage();
      default:
        return SinglePostPage(
          noId: noIdPortofolio ?? 'porto_6',
        );
    }
  }
}
