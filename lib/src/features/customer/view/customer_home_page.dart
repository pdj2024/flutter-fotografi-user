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
    with WidgetsBindingObserver { // ✅ Add observer
  final ScrollController _scrollController = ScrollController();

  bool isScrolled = false;
  bool firstBuild = true;

  // ✅ Track visible portfolios for smart preloading
  int _lastPreloadIndex = 0;
  static const int _preloadThreshold = 5; // Preload when 5 items before end

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // ✅ Listen to app lifecycle
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadCustomerId();

      if (!mounted) return;

      final userId = context.read<UserProvider>().userId;
      if (userId == null || userId.isEmpty) {
        debugPrint("⚠️ Belum login, skip loadData()");
        return;
      }

      // 🔒 Pastikan hanya 1 pemanggilan data di awal
      await loadData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    
    // ✅ Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // ✅ Cancel preloads when leaving page
    _cancelPreloads();
    
    super.dispose();
  }

  // ✅ Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final portofolioProvider = context.read<PortofolioProvider>();
    
    switch (state) {
      case AppLifecycleState.paused:
        // App goes to background - pause preloading to save battery
        debugPrint("[HomePage] ⏸️ App paused - pausing preloads");
        portofolioProvider.pausePreloads();
        break;
        
      case AppLifecycleState.resumed:
        // App returns to foreground - resume preloading
        debugPrint("[HomePage] ▶️ App resumed - resuming preloads");
        portofolioProvider.resumePreloads();
        break;
        
      default:
        break;
    }
  }

  Future<void> _doRefresh() async {
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    await loadData();
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

      debugPrint("═══════════════════════════════════════════════════");
      debugPrint("[HomePage] 🔄 Loading data...");

      // ✅ Load kategori & portofolio dengan preloading enabled
      await Future.wait([
        kategoriProvider.loadKategori(),
        portofolioProvider.loadPortofolio(
          context,
          preloadImages: true, // ✅ Enable background preloading
        ),
      ]);

      if (!mounted) return;

      debugPrint("[HomePage] ✅ Data loaded successfully");
      
      // ✅ Print preload stats
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

  void _onScroll() {
    // ✅ Smart preloading based on scroll position
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _preloadNextBatch();
    }
  }

  // ✅ Preload next batch of portfolios
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

    debugPrint("[HomePage] 🚀 Preloading next batch (${nextBatch.length} portfolios)");
    
    // Preload in background
    portofolioProvider.preloadService.preloadPortfolios(
      nextBatch,
      priorityCount: 10,
    );
  }

  // ✅ Cancel all pending preloads
  void _cancelPreloads() {
    try {
      final portofolioProvider = context.read<PortofolioProvider>();
      portofolioProvider.cancelPreloads();
      debugPrint("[HomePage] 🛑 Preloads cancelled");
    } catch (e) {
      debugPrint("[HomePage] ⚠️ Error cancelling preloads: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _doRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ===================== HEADER FILTER/SEARCH =====================
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverHeaderDelegate(
                  child: Container(
                    color: const Color(0xFFF9F9F9),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      context
                                          .read<NavigationProvider>()
                                          .navigateToPage(
                                            context,
                                            SearchPage(
                                              id_category: "",
                                              nama_category: '',
                                              search: "",
                                              autoOpenFilter: true,
                                            ),
                                            targetTabIndex: 0,
                                            hrsLogin: false,
                                          );
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isScrolled
                                            ? Constants.primaryColor
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Constants.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Cari Fotografer",
                                            style: TextStyle(
                                              color: isScrolled
                                                  ? Colors.white
                                                  : Constants.primaryColor,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.search,
                                            color: isScrolled
                                                ? Colors.white
                                                : Constants.primaryColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ===================== KATEGORI DINAMIS =====================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: KategoriSection(),
                ),
              ),

              // ===================== DAFTAR PORTOFOLIO =====================
              PortofolioSection(),
              
              // ✅ Add loading indicator at bottom when preloading
              SliverToBoxAdapter(
                child: Consumer<PortofolioProvider>(
                  builder: (context, provider, child) {
                    final stats = provider.getPreloadStats();
                    final isPreloading = stats['isPreloading'] as bool;
                    final queueLength = stats['queueLength'] as int;
                    
                    if (!isPreloading || queueLength == 0) {
                      return const SizedBox.shrink();
                    }
                    
                    return Container(
                      padding: const EdgeInsets.all(16),
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
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _doRefresh,
        tooltip: 'Refresh',
        backgroundColor: Constants.primaryColor,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}

class SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  SliverHeaderDelegate({required this.child});
  
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 64.0 + 15;
  
  @override
  double get minExtent => 64.0 + 15;
  
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}