import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_page_V2.dart';
import 'package:mpjnew/src/features/customer/view/history/finished_order_page.dart';
import 'package:mpjnew/src/features/customer/view/history/webview_page.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/empty_order.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/order_history_card.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/skeleton_card.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/status_config.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/summary_card.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/ulasan_dialog.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_page.dart';
import 'package:mpjnew/src/features/customer/view/payment/waiting_payment_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/widget/refresh_header.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

// ═══════════════════════════════════════════════════════════════
// MAIN ORDER PAGE
// ═══════════════════════════════════════════════════════════════

class MainOrderPage extends StatefulWidget {
  const MainOrderPage({super.key});

  @override
  State<MainOrderPage> createState() => _MainOrderPageState();
}

class _MainOrderPageState extends State<MainOrderPage> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  String? _selectedFilter;

  bool _isInitialized = false;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndInit());
  }

  Future<void> _checkAndInit() async {
    final userProvider = context.read<UserProvider>();
    if (userProvider.customer == null) return;

    final userId = userProvider.customer!.noId;
    if (_isInitialized && _lastUserId == userId) return;

    await context.read<PesananProvider>().loadOrder(context);

    if (mounted) {
      setState(() {
        _isInitialized = true;
        _lastUserId = userId;
      });
    }
  }

  List<PesananModel> get _filteredOrders {
    final provider = context.read<PesananProvider>();
    final active = [
      ...provider.pesananUnpaid,
      ...provider.pesananProgress,
    ];
    active.sort((a, b) => b.tglRealisasi.compareTo(a.tglRealisasi));

    if (_selectedFilter == null) return active;
    return active
        .where((o) =>
            (o.statusProgresPesanan ?? 'menunggu bayar') == _selectedFilter)
        .toList();
  }

  Future<void> _onRefresh() async {
    if (!mounted) {
      _refreshController.refreshCompleted();
      return;
    }
    try {
      await Future.wait([
        // _checkAndInit(),
        context.read<PesananProvider>().loadOrder(context),
      ]);
      _refreshController.refreshCompleted();
    } catch (e) {
      debugPrint('[MainOrderPage] ❌ Refresh error: $e');
      _refreshController.refreshFailed();
    }
  }

  // ── Buka payment page ──────────────────────────────────────────────────
  //
  // Menggunakan Navigator.push biasa (bukan navigateToPage) agar back button
  // kembali ke MainOrderPage tanpa mereset tab atau stack navigasi.
  //
  // Alur:
  //   linkSnap ada  → WebviewPage (Snap Midtrans)
  //                     ↳ error/user minta fallback → WaitingPaymentPage (core)
  //   linkSnap null → WaitingPaymentPage (core)
  void _openPayment(PesananModel o) {
    if (o.linkSnap != null) {
      context.read<NavigationProvider>().navigateToPage(
            context,
            WebviewPage(
              url: o.linkSnap!,
              paymentData: o,
            ),
            targetTabIndex: 2,
          );
    } else {
      context.read<NavigationProvider>().navigateToPage(
            context,
            WaitingPaymentPage(paymentData: o),
            targetTabIndex: 2,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<PesananProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        title: const Text(
          'Pesanan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F0F0F),
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => context.read<NavigationProvider>().navigateToPage(
                  context,
                  FinishedOrderPage(),
                  targetTabIndex: 2,
                  targetPage: 'FinishedOrderPage',
                  hrsLogin: true,
                ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text(
                    'Selesai',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F0F0F),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: SafeArea(
        child: SmartRefresher(
          controller: _refreshController,
          onRefresh: _onRefresh,
          physics: const AlwaysScrollableScrollPhysics(),
          header: buildRefreshHeader(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildSummaryRow()),
              SliverToBoxAdapter(child: _buildFilterChips()),
              SliverToBoxAdapter(child: _buildOrderList()),
              SliverToBoxAdapter(child: _buildFinishedLink()),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SUMMARY CARDS
  // ─────────────────────────────────────────────────────────────

  Widget _buildSummaryRow() {
    final provider = context.read<PesananProvider>();
    final totalAktif =
        provider.pesananUnpaid.length + provider.pesananProgress.length;
    final unpaid = provider.pesananUnpaid.length;
    final inProgress = provider.pesananProgress.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
      child: Row(
        children: [
          Expanded(
            child: SummaryCard(
              label: 'Total Aktif',
              value: totalAktif,
              color: const Color(0xFF0F0F0F),
              bgColor: Colors.white,
              icon: Icons.receipt_long_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SummaryCard(
              label: 'Belum Bayar',
              value: unpaid,
              color: const Color(0xFF1565C0),
              bgColor: const Color(0xFFE3F2FD),
              icon: Icons.payment_outlined,
              onTap: () => setState(() => _selectedFilter = 'menunggu bayar'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SummaryCard(
              label: 'Diproses',
              value: inProgress,
              color: const Color(0xFF00838F),
              bgColor: const Color(0xFFE0F7FA),
              icon: Icons.camera_outlined,
              onTap: () => setState(() => _selectedFilter = null),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FILTER CHIPS
  // ─────────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    final chips = [
      {'value': null, 'label': 'Semua'},
      {'value': 'menunggu bayar', 'label': 'Belum Bayar'},
      {'value': 'persiapan', 'label': 'Persiapan'},
      {'value': 'proses', 'label': 'Proses'},
      {'value': 'review', 'label': 'Review'},
      {'value': 'revisi', 'label': 'Revisi'},
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final chip = chips[i];
          final value = chip['value'];
          final label = chip['label'] as String;
          final isSelected = _selectedFilter == value;
          final cfg = value != null ? getStatus(value) : null;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedFilter = value);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (cfg?.color ?? const Color(0xFF0F0F0F))
                    : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? (cfg?.color ?? const Color(0xFF0F0F0F))
                      : Colors.grey.shade200,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (cfg?.color ?? Colors.black).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ORDER LIST
  // ─────────────────────────────────────────────────────────────

  Widget _buildOrderList() {
    final provider = context.read<PesananProvider>();
    final isLoading = provider.isLoadingOrder;

    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonCard(),
            ),
          ),
        ),
      );
    }

    final orders = _filteredOrders;

    if (orders.isEmpty) {
      return EmptyOrder(onTap: () => setState(() => _selectedFilter = null));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
      child: Column(
        children: orders
            .map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OrderHistoryCard(
                    order: o,
                    onTap: () =>
                        context.read<NavigationProvider>().navigateToPage(
                              context,
                              DetailOrderPageV2(pesananModel: o),
                              // DetailOrderPage(pesananModel: o),
                              targetTabIndex: 2,
                              targetPage: 'DetailOrderPage',
                              hrsLogin: true,
                            ),
                    onChat: () =>
                        context.read<NavigationProvider>().navigateToPage(
                              context,
                              RoomChatPage(partnerId: o.idVendor),
                              targetTabIndex: 1,
                              targetPage: 'RoomChatPage',
                            ),
                    // ── Payment: Navigator.push biasa agar back = kembali ke sini
                    onPay: () => _openPayment(o),
                    onReview: () => showDialog(
                      context: context,
                      builder: (_) => UlasanDialog(
                        pesanan: o,
                        onSuccess: () async {
                          await context
                              .read<PesananProvider>()
                              .loadOrder(context);
                        },
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LINK KE PESANAN SELESAI
  // ─────────────────────────────────────────────────────────────

  Widget _buildFinishedLink() {
    final count = context.read<PesananProvider>().pesananSelesai.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
      child: GestureDetector(
        onTap: () => context.read<NavigationProvider>().navigateToPage(
              context,
              FinishedOrderPage(),
              targetTabIndex: 2,
              targetPage: 'FinishedOrderPage',
              hrsLogin: true,
            ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 20,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pesanan Selesai',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F0F0F),
                      ),
                    ),
                    Text(
                      count > 0
                          ? '$count pesanan telah selesai'
                          : 'Belum ada pesanan selesai',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
