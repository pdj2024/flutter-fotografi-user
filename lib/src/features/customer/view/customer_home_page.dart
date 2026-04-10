import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/features/customer/view/search_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/kategori_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/widget/kategori_section.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/widget/portofolio_section.dart';
import 'package:provider/provider.dart';

class CustomerHomePage extends StatefulWidget {
  CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage>
    with WidgetsBindingObserver {
  // ✅ Satu ScrollController — tidak ada pihak ketiga yang ikut campur
  final ScrollController _scrollController = ScrollController();
  int _lastPreloadIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadCustomerId();
      if (!mounted) return;
      final userId = context.read<UserProvider>().userId;
      if (userId == null || userId.isEmpty) {
        debugPrint("⚠️ Belum login, skip loadData()");
        return;
      }
      await loadData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _cancelPreloads();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final portofolioProvider = context.read<PortofolioProvider>();
    switch (state) {
      case AppLifecycleState.paused:
        portofolioProvider.pausePreloads();
        break;
      case AppLifecycleState.resumed:
        portofolioProvider.resumePreloads();
        break;
      default:
        break;
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _preloadNextBatch();
    }
  }

  // ✅ RefreshIndicator native — return Future, tidak perlu controller
  Future<void> _onRefresh() async {
    if (!mounted) return;
    try {
      await loadData();
    } catch (e) {
      debugPrint('[HomePage] ❌ Refresh error: $e');
    }
  }

  Future<void> _loadCustomerId() async {
    await context
        .read<UserProvider>()
        .checkLoginGoogle(role: 'customer', silent: true);
    final userId = context.read<UserProvider>().userId;
    debugPrint("[HomePage] User ID: $userId");
  }

  Future<void> loadData() async {
    try {
      await _loadCustomerId();
      if (!mounted) return;

      final kategoriProvider = context.read<KategoriProvider>();
      final portofolioProvider = context.read<PortofolioProvider>();

      _lastPreloadIndex = 0;

      debugPrint("═══════════════════════════════════════════════════");
      debugPrint("[HomePage] 🔄 Loading data...");

      await Future.wait([
        kategoriProvider.loadKategori(),
        portofolioProvider.loadPortofolio(context, preloadImages: true),
      ]);

      if (!mounted) return;

      debugPrint("[HomePage] ✅ Data loaded successfully");
      final stats = portofolioProvider.getPreloadStats();
      debugPrint("[HomePage] 📊 Preload stats: $stats");
      debugPrint("═══════════════════════════════════════════════════");
    } catch (e, st) {
      debugPrint("[HomePage] ❌ Error loading data: $e");
      debugPrintStack(stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memuat ulang data")),
        );
      }
    }
  }

  void _preloadNextBatch() {
    final portofolioProvider = context.read<PortofolioProvider>();
    final portfolios = portofolioProvider.portofolioList;
    if (portfolios.isEmpty) return;

    final nextIndex = _lastPreloadIndex + 10;
    if (nextIndex >= portfolios.length) {
      debugPrint("[HomePage] ℹ️ All portfolios already queued for preload");
      return;
    }

    final nextBatch = portfolios.skip(_lastPreloadIndex).take(10).toList();
    _lastPreloadIndex = nextIndex;

    debugPrint(
        "[HomePage] 🚀 Preloading next batch (${nextBatch.length} portfolios)");

    portofolioProvider.preloadService.preloadPortfolios(
      nextBatch,
      priorityCount: 10,
    );
  }

  void _cancelPreloads() {
    try {
      final portofolioProvider = context.read<PortofolioProvider>();
      portofolioProvider.cancelPreloads();
    } catch (e) {
      debugPrint("[HomePage] ⚠️ Error cancelling preloads: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // ── Search bar sticky ─────────────────────────────────────
            _ModernSearchBar(
              onTap: () {
                context.read<NavigationProvider>().navigateToPage(
                      context,
                      SearchPage(
                        id_category: "",
                        nama_category: '',
                        search: "",
                        autoOpenFilter: true,
                      ),
                      targetTabIndex: 0,
                      targetPage: 'SearchPage',
                    );
              },
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                // ✅ Warna sesuai primary app
                color: Constants.primaryColor,
                backgroundColor: Colors.white,
                // ✅ displacement kecil agar indikator tidak terlalu jauh
                displacement: 20,
                child: ListView(
                  controller: _scrollController,
                  // ✅ Hanya satu physics di sini, tidak dobel
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    // ── Kategori ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: KategoriSection(),
                    ),

                    // ── Portofolio ────────────────────────────────────
                    const PortofolioSection(),

                    // ── Preload indicator ─────────────────────────────
                    Consumer<PortofolioProvider>(
                      builder: (context, provider, child) {
                        final stats = provider.getPreloadStats();
                        final isPreloading = stats['isPreloading'] as bool;
                        final queueLength = stats['queueLength'] as int;

                        if (!isPreloading || queueLength == 0) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Constants.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Memuat gambar... ($queueLength)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// _ModernSearchBar — tidak ada perubahan
// ═══════════════════════════════════════════════════════════════════════

class _ModernSearchBar extends StatefulWidget {
  final VoidCallback onTap;

  const _ModernSearchBar({required this.onTap});

  @override
  State<_ModernSearchBar> createState() => _ModernSearchBarState();
}

class _ModernSearchBarState extends State<_ModernSearchBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Constants.primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, _) {
            final glow = 0.06 + (_pulseAnim.value * 0.07);

            return Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primary.withOpacity(0.18 + glow),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(15),
                      ),
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: primary.withOpacity(0.85),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cari Fotografer',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Lokasi, nama, atau kategori...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
