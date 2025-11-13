import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/kategori_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/widget/kategori_section.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/widget/portofolio_section.dart';
import 'package:mpjnew/src/pages/fotografi_user/searchpage.dart';
import 'package:provider/provider.dart';

class CustomerHomePage extends StatefulWidget {
  CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final ScrollController _scrollController = ScrollController();

  bool isScrolled = false;
  bool firstBuild = true;

  Future<void> _doRefresh() async {
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    await loadData(); // ✅ Langsung refresh dari service
  }

  Future<void> _loadCustomerId() async {
    await context
        .read<UserProvider>()
        .checkLoginGoogle(role: 'customer', silent: true);

    // INI OPTIONAL LOGGING AJA
    final userId = context.read<UserProvider>().userId;
    print("==== LOADED USER ID: $userId");
  }

  Future<void> loadData() async {
    try {
      // Pastikan userId sudah di-load
      await _loadCustomerId();

      if (!mounted) return;

      final kategoriProvider = context.read<KategoriProvider>();
      final portofolioProvider = context.read<PortofolioProvider>();

      debugPrint("🔄 Memuat kategori & portofolio...");

      // Jalankan keduanya paralel, tapi tetap aman
      await Future.wait([
        kategoriProvider.loadKategori(),
        portofolioProvider.loadPortofolio(context),
      ]);

      if (!mounted) return;

      debugPrint("✅ Refresh sukses: kategori & portofolio diperbarui");
    } catch (e, st) {
      debugPrint("❌ Error saat refresh: $e");
      debugPrintStack(stackTrace: st);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memuat ulang data")),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

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
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more di sini kalau pakai pagination
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
