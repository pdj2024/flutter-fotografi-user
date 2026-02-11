import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/kategori_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/paket_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:mpjnew/src/features/customer/widget/image_post.dart';
import 'package:mpjnew/src/features/customer/widget/offer_card.dart';
import 'package:mpjnew/src/features/customer/widget/post_header.dart';
import 'package:mpjnew/src/features/customer/services/portofolio_service.dart';
import 'package:provider/provider.dart';

/// ═══════════════════════════════════════════════════════════════
/// SINGLE POST PAGE - OPTIMIZED ⚡
///
/// Improvements:
/// - ✅ Cache-first portfolio loading
/// - ✅ Efficient paket & ulasan loading (filtered by paket IDs only!)
/// - ✅ Background image preloading
/// - ✅ Like/Save state management
/// - ✅ Pull-to-refresh support
/// ═══════════════════════════════════════════════════════════════

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
    if (mounted) {
      setState(fn);
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// OPTIMIZED DATA LOADING
  /// ═══════════════════════════════════════════════════════════
  Future<void> _loadData() async {
    _safeSetState(() {
      _isLoadingData = true;
    });

    try {
      final portofolioProvider = context.read<PortofolioProvider>();
      final paketProvider = context.read<PaketProvider>();
      final userProvider = context.read<UserProvider>();

      var selectedPortfolio = portofolioProvider.selectedPortofolio;

      if (selectedPortfolio == null) {
        debugPrint('[SinglePost] ⚠️ No portfolio selected');
        return;
      }

      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('[SinglePost] ⚡ Loading data (OPTIMIZED)');
      debugPrint('[SinglePost] Portfolio: ${selectedPortfolio.noId}');

      // ✅ STEP 1: Get fresh portfolio from cache (if available)
      final freshPortfolio = await _getFreshPortfolio(
        portofolioProvider,
        selectedPortfolio.noId,
      );

      if (freshPortfolio != null) {
        portofolioProvider.setSelectedPortofolio(freshPortfolio);
        selectedPortfolio = freshPortfolio;

        debugPrint('[SinglePost] ✅ Using fresh portfolio');
        debugPrint(
            '[SinglePost] Cached media: ${freshPortfolio.cachedMedia.length}/${freshPortfolio.mediaUrls.length}');
      }

      // ✅ STEP 2: Initialize like/save state
      final customer = userProvider.customer;
      if (customer != null) {
        _safeSetState(() {
          isLiked = customer.likes.contains(selectedPortfolio?.noId);
          isSaved = customer.saves.contains(selectedPortfolio?.noId);
          likeCount = selectedPortfolio?.likes ?? 0;
        });

        debugPrint('[SinglePost] Like status: $isLiked');
        debugPrint('[SinglePost] Save status: $isSaved');
      }

      // ✅ STEP 3: Load pakets with ulasan (filtered by paket IDs only!)
      if (selectedPortfolio.idPaket.isNotEmpty) {
        debugPrint('[SinglePost] 📥 Loading pakets & ulasan...');
        debugPrint('[SinglePost]    Paket IDs: ${selectedPortfolio.idPaket}');

        // ✅ NEW: Only fetch ulasan for these specific pakets
        await paketProvider.loadPaketsWithUlasan(
          paketIds: selectedPortfolio.idPaket,
        );

        debugPrint('[SinglePost] ✅ Loaded:');
        debugPrint('[SinglePost]    Pakets: ${paketProvider.paketList.length}');

        // Count pakets with/without ulasan
        int withUlasan = 0;
        int withoutUlasan = 0;
        for (var paket in paketProvider.paketList) {
          final ulasan = paketProvider.getUlasanForPaket(paket.no_id);
          if (ulasan.isEmpty) {
            withoutUlasan++;
          } else {
            withUlasan++;
          }
        }

        debugPrint('[SinglePost]    With ulasan: $withUlasan');
        debugPrint('[SinglePost]    Without ulasan: $withoutUlasan');
      } else {
        debugPrint('[SinglePost] ℹ️ No pakets in this portfolio');
      }

      debugPrint('═══════════════════════════════════════════════════');
    } catch (e, st) {
      debugPrint('[SinglePost] ❌ Load error: $e');
      debugPrint(st.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _safeSetState(() {
        _isLoadingData = false;
      });
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// GET FRESH PORTFOLIO - Priority: Cache → Memory
  /// ═══════════════════════════════════════════════════════════
  Future<PortofolioModel?> _getFreshPortfolio(
    PortofolioProvider provider,
    String noId,
  ) async {
    // ✅ Priority 1: Get from cache (with cache info)
    try {
      final cached = await provider.getPortfolioById(noId);

      if (cached != null) {
        debugPrint('[SinglePost] 📦 Using cached portfolio');
        return cached;
      }
    } catch (e) {
      debugPrint('[SinglePost] No cached version: $e');
    }

    // ✅ Priority 2: Already in memory
    debugPrint('[SinglePost] 📋 Using portfolio from provider');
    return provider.selectedPortofolio;
  }

  /// ═══════════════════════════════════════════════════════════
  /// PULL TO REFRESH
  /// ═══════════════════════════════════════════════════════════
  Future<void> _onRefresh() async {
    try {
      final portofolioProvider = context.read<PortofolioProvider>();
      final paketProvider = context.read<PaketProvider>();

      debugPrint('[SinglePost] 🔄 Pull-to-refresh...');

      // Full refresh
      await portofolioProvider.refreshSinglePortofolio(
        context,
        paketProvider: paketProvider,
      );

      // Reload data
      await _loadData();

      if (mounted) {
        CustomSnackbar.showSuccessSnackbar(context, "Portfolio updated");
      }
    } catch (e) {
      debugPrint('[SinglePost] ❌ Refresh error: $e');

      if (mounted) {
        CustomSnackbar.showErrorSnackbar(context, "Failed to refresh");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PortofolioProvider, PaketProvider>(
      builder: (context, portofolioProvider, paketProvider, _) {
        final selectedPortfolio = portofolioProvider.selectedPortofolio;

        // ═══════════════════════════════════════════════════════
        // NO PORTFOLIO SELECTED
        // ═══════════════════════════════════════════════════════
        if (selectedPortfolio == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9F9F9),
            appBar: AppBar(
              backgroundColor: const Color(0xFFF9F9F9),
              elevation: 1,
              title: const Text(
                "Portofolio",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Portfolio not found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
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

        // ═══════════════════════════════════════════════════════
        // NORMAL VIEW
        // ═══════════════════════════════════════════════════════
        return Scaffold(
          backgroundColor: const Color(0xFFF9F9F9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF9F9F9),
            elevation: 1,
            title: const Text(
              "Portofolio",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
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
                  // Portfolio Header
                  PostHeader(portofolio: selectedPortfolio),

                  // ✅ Portfolio Images (with preloading!)
                  ImagePost(
                    mediaUrl: selectedPortfolio.mediaUrls,
                    enablePreload: true, // Auto-preload all images
                  ),

                  // Like & Save Row
                  _buildLikeSaveRow(selectedPortfolio),

                  const SizedBox(height: 10),

                  // Paket Section Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Paket portofolio",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Paket List
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

  /// ═══════════════════════════════════════════════════════════
  /// BUILD PAKET SECTION
  /// ═══════════════════════════════════════════════════════════
  Widget _buildPaketSection(
    PaketProvider paketProvider,
    PortofolioModel portfolio,
  ) {
    // Loading state
    if (_isLoadingData || paketProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Error state
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
              Text(
                paketProvider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (paketProvider.paketList.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white60,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(1, 2),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 30,
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.shelves,
                  size: 100,
                  color: Colors.grey,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Portofolio ini tidak memiliki paket",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Kembali",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ Paket list with ulasan
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: paketProvider.paketList.length,
      itemBuilder: (context, index) {
        final paket = paketProvider.paketList[index];

        // ✅ Get ulasan for this paket (may be empty!)
        final ulasanList = paketProvider.getUlasanForPaket(paket.no_id);

        if (ulasanList.isEmpty) {
          debugPrint('[SinglePost] Paket ${paket.no_id}: No ulasan yet');
        } else {
          debugPrint(
              '[SinglePost] Paket ${paket.no_id}: ${ulasanList.length} ulasan');
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: OfferCard(
            key: ValueKey(paket.no_id),
            ulasanList: ulasanList, // ✅ Can be empty!
            paket: paket,
            vendorId: portfolio.idVendor,
          ),
        );
      },
    );
  }

  /// ═══════════════════════════════════════════════════════════
  /// BUILD LIKE & SAVE ROW
  /// ═══════════════════════════════════════════════════════════
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

        // Show likes count if > 0
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

  /// ═══════════════════════════════════════════════════════════
  /// LIKE/SAVE HANDLERS
  /// ═══════════════════════════════════════════════════════════

  /// Handle like toggle
  Future<void> _handleLikeToggle(PortofolioModel portfolio) async {
    if (!mounted) return;

    final prevLiked = isLiked;
    final prevCount = likeCount;

    // Optimistic update
    _safeSetState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    try {
      final userId = context.read<UserProvider>().userId;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      await PortofolioService().action(
        no_id: userId,
        id_portofolio: portfolio.noId,
        action_type: isLiked ? "like" : "unlike",
      );

      debugPrint('[SinglePost] ✅ Like toggled: $isLiked');
    } catch (e) {
      debugPrint('[SinglePost] ❌ Error toggling like: $e');

      // Rollback on error
      if (!mounted) return;

      _safeSetState(() {
        isLiked = prevLiked;
        likeCount = prevCount;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah like: $e')),
        );
      }
    }
  }

  /// Handle save toggle
  Future<void> _handleSaveToggle(PortofolioModel portfolio) async {
    if (!mounted) return;

    final prevSaved = isSaved;

    // Optimistic update
    _safeSetState(() {
      isSaved = !isSaved;
    });

    try {
      final userId = context.read<UserProvider>().userId;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      await PortofolioService().action(
        no_id: userId,
        id_portofolio: portfolio.noId,
        action_type: isSaved ? "save" : "unsave",
      );

      debugPrint('[SinglePost] ✅ Save toggled: $isSaved');
    } catch (e) {
      debugPrint('[SinglePost] ❌ Error toggling save: $e');

      // Rollback on error
      if (!mounted) return;

      _safeSetState(() {
        isSaved = prevSaved;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah save: $e')),
        );
      }
    }
  }
}
