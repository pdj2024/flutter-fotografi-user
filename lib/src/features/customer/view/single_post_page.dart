import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/paket_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:mpjnew/src/features/customer/widget/image_post.dart';
import 'package:mpjnew/src/features/customer/widget/offer_card.dart';
import 'package:mpjnew/src/features/customer/widget/post_header.dart';
import 'package:mpjnew/src/features/customer/services/portofolio_service.dart';
import 'package:provider/provider.dart';

class SinglePostPage extends StatefulWidget {
  const SinglePostPage({super.key});

  @override
  State<SinglePostPage> createState() => _SinglePostPageState();
}

class _SinglePostPageState extends State<SinglePostPage> {
  final ScrollController _scrollController = ScrollController();

  bool _isLoadingData = false;
  bool isLiked = false;
  bool isSaved = false;
  int likeCount = 0;

  // ✅ FIX: Track portfolio ID yang sedang ditampilkan
  // Ini mencegah data lama dari porto sebelumnya tampil di porto baru
  String? _currentPortfolioId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _loadData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  // ═══════════════════════════════════════════════════════════
  // LOAD DATA
  // ═══════════════════════════════════════════════════════════
  Future<void> _loadData() async {
    _safeSetState(() => _isLoadingData = true);

    try {
      final portofolioProvider = context.read<PortofolioProvider>();
      final paketProvider = context.read<PaketProvider>();
      final userProvider = context.read<UserProvider>();

      var selectedPortfolio = portofolioProvider.selectedPortofolio;
      if (selectedPortfolio == null) return;

      final targetId = selectedPortfolio.noId;

      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('[SinglePost] ⚡ Loading portfolio: $targetId');

      // ✅ FIX 1: Reset PaketProvider sebelum load porto baru
      // Ini memastikan data lama TIDAK tampil di porto baru
      paketProvider.clearForPortfolio(targetId);

      // ✅ Step 1: Get fresh portfolio
      final freshPortfolio = await _getFreshPortfolio(
        portofolioProvider,
        targetId,
      );

      if (freshPortfolio != null) {
        portofolioProvider.setSelectedPortofolio(freshPortfolio);
        selectedPortfolio = freshPortfolio;
      }

      // ✅ Step 2: Set current portfolio ID setelah confirmed
      _safeSetState(() => _currentPortfolioId = selectedPortfolio!.noId);

      // ✅ Step 3: Like/Save state
      final customer = userProvider.customer;
      if (customer != null) {
        _safeSetState(() {
          isLiked = customer.likes.contains(selectedPortfolio?.noId);
          isSaved = customer.saves.contains(selectedPortfolio?.noId);
          likeCount = selectedPortfolio?.likes ?? 0;
        });
      }

      // ✅ Step 4: Load pakets + ulasan HANYA untuk porto ini
      if (selectedPortfolio!.idPaket.isNotEmpty) {
        debugPrint('[SinglePost] 📥 Paket IDs: ${selectedPortfolio.idPaket}');

        await paketProvider.loadPaketsWithUlasan(
          paketIds: selectedPortfolio.idPaket,
          portfolioId: targetId, // ✅ Pass portfolioId untuk validasi
          vendorId: selectedPortfolio.idVendor,
        );

        debugPrint('[SinglePost] ✅ Loaded ${paketProvider.paketList.length} pakets');
      } else {
        debugPrint('[SinglePost] ℹ️ Porto $targetId has no pakets');
      }

      debugPrint('═══════════════════════════════════════════════════');
    } catch (e, st) {
      debugPrint('[SinglePost] ❌ Load error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _safeSetState(() => _isLoadingData = false);
    }
  }

  Future<PortofolioModel?> _getFreshPortfolio(
    PortofolioProvider provider,
    String noId,
  ) async {
    try {
      final cached = await provider.getPortfolioById(noId);
      if (cached != null) return cached;
    } catch (_) {}
    return provider.selectedPortofolio;
  }

  Future<void> _onRefresh() async {
    try {
      final portofolioProvider = context.read<PortofolioProvider>();
      final currentPortfolio = portofolioProvider.selectedPortofolio;
      if (currentPortfolio != null) {
        final freshPortfolio =
            await portofolioProvider.getPortfolioById(currentPortfolio.noId);
        if (freshPortfolio != null) {
          portofolioProvider.setSelectedPortofolio(freshPortfolio);
        }
      }
      // ✅ Force full reload
      context.read<PaketProvider>().clearForPortfolio(null);
      _safeSetState(() => _currentPortfolioId = null);
      await _loadData();
      if (mounted) CustomSnackbar.showSuccessSnackbar(context, "Portfolio updated");
    } catch (e) {
      if (mounted) CustomSnackbar.showErrorSnackbar(context, "Failed to refresh");
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Consumer2<PortofolioProvider, PaketProvider>(
      builder: (context, portofolioProvider, paketProvider, _) {
        final selectedPortfolio = portofolioProvider.selectedPortofolio;

        if (selectedPortfolio == null) {
          return _buildEmptyScaffold();
        }

        // ✅ FIX 2: Guard — jangan tampilkan paket jika data belum siap
        // untuk portfolio ini. Cegah tampilnya data porto lama.
        final isDataReady = _currentPortfolioId == selectedPortfolio.noId;

        return Scaffold(
          backgroundColor: const Color(0xFFF9F9F9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF9F9F9),
            elevation: 1,
            title: const Text(
              "Portofolio",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PostHeader(portofolio: selectedPortfolio),

                  ImagePost(
                    mediaUrl: selectedPortfolio.mediaUrls,
                    enablePreload: true,
                  ),

                  _buildLikeSaveRow(selectedPortfolio),

                  const SizedBox(height: 10),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Paket portofolio",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ✅ FIX 3: Hanya render paket jika data sudah siap untuk porto ini
                  if (!isDataReady || _isLoadingData || paketProvider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    _buildPaketSection(paketProvider, selectedPortfolio),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD PAKET SECTION
  // ═══════════════════════════════════════════════════════════
  Widget _buildPaketSection(
    PaketProvider paketProvider,
    PortofolioModel portfolio,
  ) {
    if (paketProvider.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 10),
              Text(paketProvider.error!, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    // ✅ FIX 4: Filter paket — HANYA paket yang ada di porto ini
    final portfolioPaketIds = portfolio.idPaket.toSet();
    final filteredPakets = paketProvider.paketList
        .where((p) => portfolioPaketIds.contains(p.no_id))
        .toList();

    if (portfolio.idPaket.isEmpty || filteredPakets.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white60,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(1, 2))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
            child: Column(
              children: [
                const Icon(Icons.shelves, size: 100, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  "Portofolio ini tidak memiliki paket",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Kembali",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredPakets.length,
      itemBuilder: (context, index) {
        final paket = filteredPakets[index];

        // ✅ FIX 5: Ulasan HANYA untuk paket ini, bukan paket lain
        final ulasanList = paketProvider.getUlasanForPaket(paket.no_id);

        debugPrint('[SinglePost] Render paket ${paket.no_id}: ${ulasanList.length} ulasan');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: OfferCard(
            // ✅ FIX 6: Key gabungan portfolioId + paketId
            // Memaksa Flutter rebuild widget saat pindah porto
            key: ValueKey('${portfolio.noId}_${paket.no_id}'),
            ulasanList: ulasanList,
            paket: paket,
            vendorId: portfolio.idVendor,
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LIKE & SAVE
  // ═══════════════════════════════════════════════════════════
  Widget _buildLikeSaveRow(PortofolioModel portfolio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _handleLikeToggle(portfolio),
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.black,
                  size: 28,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _handleSaveToggle(portfolio),
                child: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? Colors.amber : Colors.black,
                  size: 29,
                ),
              ),
            ],
          ),
        ),
        if (likeCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "$likeCount likes",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _handleLikeToggle(PortofolioModel portfolio) async {
    if (!mounted) return;
    final prevLiked = isLiked;
    final prevCount = likeCount;
    _safeSetState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });
    try {
      final userId = context.read<UserProvider>().userId;
      if (userId == null) throw Exception('User not logged in');
      await PortofolioService().action(
        no_id: userId,
        id_portofolio: portfolio.noId,
        action_type: isLiked ? "like" : "unlike",
      );
    } catch (e) {
      if (!mounted) return;
      _safeSetState(() {
        isLiked = prevLiked;
        likeCount = prevCount;
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _handleSaveToggle(PortofolioModel portfolio) async {
    if (!mounted) return;
    final prevSaved = isSaved;
    _safeSetState(() => isSaved = !isSaved);
    try {
      final userId = context.read<UserProvider>().userId;
      if (userId == null) throw Exception('User not logged in');
      await PortofolioService().action(
        no_id: userId,
        id_portofolio: portfolio.noId,
        action_type: isSaved ? "save" : "unsave",
      );
    } catch (e) {
      if (!mounted) return;
      _safeSetState(() => isSaved = prevSaved);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Widget _buildEmptyScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
        title: const Text(
          "Portofolio",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Portfolio not found',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}