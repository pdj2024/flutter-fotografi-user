import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/view/history/finish_order_section.dart';
import 'package:mpjnew/src/features/customer/view/history/main_order_shimmer.dart';
import 'package:mpjnew/src/features/customer/view/history/progress_order_section.dart';
import 'package:mpjnew/src/features/customer/view/history/unpaid_order_section.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/order_tab_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:provider/provider.dart';

/// ✅ FIXED: No more "notifyListeners during build" error
class MainOrderPage extends StatefulWidget {
  const MainOrderPage({super.key});

  @override
  State<MainOrderPage> createState() => _MainOrderPageState();
}

class _MainOrderPageState extends State<MainOrderPage> with TickerProviderStateMixin {
  late TabController _tabController;

  late PesananProvider pesananProvider;
  late HistoryOrderProvider historyOrderProvider;
  bool _isInitialized = false;
  String? _lastInitializedUserId;

  @override
  void initState() {
    super.initState();
    // ✅ CRITICAL FIX: Use addPostFrameCallback
    // This ensures initialization runs AFTER build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndInitialize();
    });

    
    // Ambil initial tab index dari provider
    final orderTabProvider = context.read<OrderTabProvider>();
    _tabController = TabController(
      initialIndex: orderTabProvider.selectedTabIndex,
      length: 2,
      vsync: this,
    );
    orderTabProvider.tabController = _tabController;

    // Listen untuk perubahan tab dari provider
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        orderTabProvider.setSelectedTabIndex(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ ONLY read providers here, DON'T trigger actions
    pesananProvider = context.read<PesananProvider>();
    historyOrderProvider = context.read<HistoryOrderProvider>();
  }

  /// Check login status and initialize if needed
  Future<void> _checkAndInitialize() async {
    final userProvider = context.read<UserProvider>();

    debugPrint("═══════════════════════════════════════");
    debugPrint("[AllOrderPage] 🔍 Checking login...");

    // User not logged in
    if (userProvider.customer == null) {
      debugPrint("[AllOrderPage] ⚠️ User not logged in");

      if (_isInitialized) {
        setState(() {
          _isInitialized = false;
          _lastInitializedUserId = null;
        });
        debugPrint("[AllOrderPage] 🔄 Reset state (logged out)");
      }

      debugPrint("═══════════════════════════════════════");
      return;
    }

    final userId = userProvider.customer!.noId;
    debugPrint(
        "[AllOrderPage] ✅ User logged in: ${userProvider.customer!.namaDisplay}");

    // Already initialized for this user
    if (_isInitialized && _lastInitializedUserId == userId) {
      debugPrint("[AllOrderPage] ℹ️ Already initialized for: $userId");
      debugPrint("═══════════════════════════════════════");
      return;
    }

    debugPrint("[AllOrderPage] 🚀 Initializing for: $userId");
    debugPrint("═══════════════════════════════════════");

    // Initialize
    await _initializeData(userId);

    if (mounted) {
      setState(() {
        _isInitialized = true;
        _lastInitializedUserId = userId;
      });
    }
  }

  /// Initialize pesanan and history
  Future<void> _initializeData(String userId) async {
    debugPrint("───────────────────────────────────────");
    debugPrint("[AllOrderPage] 📦 Loading pesanan...");

    try {
      // ✅ Load pesanan only - FCM will handle real-time updates
      await pesananProvider.loadOrder(context);

      debugPrint(
          "[AllOrderPage] ✅ Pesanan loaded: ${pesananProvider.allPesanan.length}");

      // ✅ Track orders for FCM updates
      if (pesananProvider.allPesanan.isNotEmpty) {
        await _trackOrdersForFCM();
      } else {
        debugPrint("[AllOrderPage] ℹ️ No orders to track");
      }

      debugPrint("[AllOrderPage] ✅ Initialization complete");
      debugPrint("[AllOrderPage] ℹ️ Real-time updates via FCM");
    } catch (e, st) {
      debugPrint("[AllOrderPage] ❌ Error: $e");
      debugPrint("Stack: $st");
    }

    debugPrint("───────────────────────────────────────");
  }

  Future<void> _trackOrdersForFCM() async {
    debugPrint("[AllOrderPage] 📍 Tracking orders for FCM...");

    final allPesanan = pesananProvider.allPesanan;

    for (var i = 0; i < allPesanan.length; i++) {
      final noOrder = allPesanan[i].noBukti;

      // Just mark as tracked - FCM will handle updates
      historyOrderProvider.trackOrder(noOrder);

      debugPrint("[AllOrderPage] ✅ Tracking: $noOrder");
    }

    debugPrint("[AllOrderPage] 📊 Tracking summary:");
    debugPrint("   Total orders tracked: ${allPesanan.length}");
    debugPrint("   Updates: Via FCM");
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Watch providers for reactive updates
    final userProvider = context.watch<UserProvider>();
    final pesananProvider = context.watch<PesananProvider>();

    // Show login prompt if not logged in
    if (userProvider.customer == null) {
      return _buildLoginPrompt();
    }

    // Show pesanan
    return _buildPesananView(pesananProvider);
  }

  /// Build login prompt screen
  Widget _buildLoginPrompt() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
        title: const Text(
          "Pesanan",
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
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "Silakan Login",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Login untuk melihat pesanan Anda",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/user-login',
                  arguments: {
                    'targetPage': 'Tab2',
                    'tabIndex': 2,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Login Sekarang",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build pesanan view
  Widget _buildPesananView(PesananProvider pesananProvider) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 1,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0),
            child: TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Constants.primaryColor,
              indicatorWeight: 2.5,
              isScrollable: false,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                _buildTab("Belum bayar", pesananProvider.pesananUnpaid.length),
                _buildTab("Progress", 0),
                _buildTab("Selesai", 0),
              ],
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              dividerColor: Colors.grey.shade300,
            ),
          ),
        ),
        body: TabBarView(
          children: [
            pesananProvider.isLoadingOrder
                ? const MainOrderShimmer()
                : const UnpaidOrderSection(),
            pesananProvider.isLoadingOrder
                ? const MainOrderShimmer()
                : const ProgressOrderSection(),
            pesananProvider.isLoadingOrder
                ? const MainOrderShimmer()
                : const FinishOrderSection(),
          ],
        ),
      ),
    );
  }

  /// Build tab with badge
  Widget _buildTab(String label, int count) {
    return Tab(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 60),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Stack(
              alignment: Alignment.topRight,
              // mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 82, 82, 1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
