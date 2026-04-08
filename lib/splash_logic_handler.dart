import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/core/services/fcm/fcm_service.dart';
import 'package:mpjnew/src/core/services/version_check_service.dart';
import 'package:mpjnew/src/data/isar/service/chat_storage_service.dart';
import 'package:mpjnew/src/data/repositories/kota_provider.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/local_storage_service.dart';
import 'package:mpjnew/src/features/customer/view/main_menu.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/kategori_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:provider/provider.dart';

// ============================================================
// Splash Logic Handler - Customer
// ============================================================

class SplashLogicHandler extends StatefulWidget {
  const SplashLogicHandler({super.key});

  @override
  State<SplashLogicHandler> createState() => _SplashLogicHandlerState();
}

class _SplashLogicHandlerState extends State<SplashLogicHandler>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  Widget? _startPage;
  String _loadingMessage = 'Mempersiapkan aplikasi...';
  String? _errorMessage;

  // ── Animation controllers ──────────────────────────
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _fadeOutController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _fadeOutOpacity;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeOutOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeIn),
    );

    _logoController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  void _updateMessage(String msg) {
    if (mounted) setState(() => _loadingMessage = msg);
  }

  // ════════════════════════════════════════════════════════════
  // LOADING LOGIC
  // ════════════════════════════════════════════════════════════

  Future<void> _loadInitialData() async {
    try {
      debugPrint('🚀 LOADING INITIAL DATA (Customer)');

      apiClient.onSessionExpired = () {
        if (mounted) context.read<NavigationProvider>().handleLogout(context);
      };

      // 0️⃣ Version check
      _updateMessage('Memeriksa versi aplikasi...');
      final versionResult = await VersionCheckService().checkVersion();
      if (!mounted) return;

      if (!versionResult.isCompatible) {
        await VersionCheckService.showUpdateDialogIfNeeded(
            context, versionResult);
        return;
      }

      // 1️⃣ Restore session
      _updateMessage('Memulihkan sesi...');
      final userProvider = context.read<UserProvider>();
      final sessionRestored = await userProvider.restoreSession();
      if (!mounted) return;

      if (sessionRestored && userProvider.customer != null) {
        final customer = userProvider.customer!;
        debugPrint('✅ Session: ${customer.namaDisplay}');

        // 2️⃣ Setup role & storage
        _updateMessage('Menyiapkan akun Anda...');
        await context.read<NavigationProvider>().saveRole(Constants.customer);
        apiClient.setRole(Constants.customer);
        LocalStorageService.instance.setActiveCustomer(customer.noId);
        ChatStorageService.instance.setCurrentUser(customer.noId);

        // 3️⃣ Chat + FCM (paralel)
        _updateMessage('Menghubungkan layanan...');
        final chatProvider = context.read<ChatProvider>();
        await Future.wait([
          chatProvider.initialize(
            userId: customer.noId,
            userType: Constants.customer,
          ),
          FCMService.instance.registerToken(customer.noId),
        ]);
        debugPrint('✅ ChatProvider + FCM token ready');

        // 4️⃣ Master data (background, non-blocking)
        _updateMessage('Memuat data...');
        Future.microtask(() async {
          if (!mounted) return;
          try {
            final portoProvider = context.read<PortofolioProvider>();
            await Future.wait([
              portoProvider.loadLikedPortofolio(
                  context: context, syncFromApi: true),
              portoProvider.loadSavedPortofolio(
                  context: context, syncFromApi: true),
              context.read<KotaProvider>().getAllKotaList(),
              context.read<KategoriProvider>().loadKategori(),
            ]);
            debugPrint('✅ Master data loaded');
          } catch (e) {
            debugPrint('⚠️ Master data error: $e');
          }
        });
      } else {
        debugPrint('ℹ️ No session — guest mode');
        await context.read<NavigationProvider>().saveRole(Constants.customer);
        apiClient.setRole(Constants.customer);
      }

      _updateMessage('Hampir selesai...');
      _startPage = const MainMenu();
      debugPrint('✅ INITIAL DATA LOAD COMPLETE');
    } catch (e, stackTrace) {
      debugPrint('❌ INIT ERROR: $e\n$stackTrace');
      _errorMessage = 'Terjadi kesalahan saat memuat aplikasi';
      _startPage = _buildErrorPage();
    } finally {
      if (mounted) {
        await _fadeOutController.forward();
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildErrorPage() {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  _logoController.reset();
                  _logoController.forward();
                  _fadeOutController.reset();
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

  // ════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF3b3add),
        body: FadeTransition(
          opacity: _fadeOutOpacity,
          child: SafeArea(
            child: SizedBox.expand(
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // ── Logo ───────────────────────────────
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Image.asset(
                        'assets/icon.png',
                        width: 250,
                        height: 250,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── App name ───────────────────────────
                  // FadeTransition(
                  //   opacity: _textOpacity,
                  //   child: const Text(
                  //     'Fotografi',
                  //     style: TextStyle(
                  //       fontSize: 24,
                  //       fontWeight: FontWeight.w700,
                  //       color: Colors.white,
                  //       letterSpacing: -0.5,
                  //     ),
                  //   ),
                  // ),

                  const Spacer(flex: 2),

                  // ── Dot loader + message ───────────────
                  FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DotLoader(
                          controller: _pulseController,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _loadingMessage,
                            key: ValueKey(_loadingMessage),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return _startPage ?? const MainMenu();
  }
}

// ============================================================
// Dot Loader
// ============================================================

class _DotLoader extends StatelessWidget {
  final AnimationController controller;
  final Color color;

  const _DotLoader({
    required this.controller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (controller.value + i * 0.33) % 1.0;
            final opacity =
                0.25 + 0.75 * ((math.sin(phase * math.pi * 2) + 1) / 2);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
