import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/view/history/finished_order_page';
import 'package:mpjnew/src/features/customer/view/history/webview_page.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/ulasan_dialog.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_page.dart';
import 'package:mpjnew/src/features/customer/view/payment/waiting_payment_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mpjnew/src/core/constants/status_progres_constant.dart';

// ═══════════════════════════════════════════════════════════════
// STATUS CONFIG — menggunakan StatusProgresConstant
// Tambah import: status_progres_constant.dart
// ═══════════════════════════════════════════════════════════════

// Wrapper agar tetap bisa dipakai dgn dot-notation di seluruh file
class _StatusConfig {
  final Color color;
  final Color bgColor; // warna bg = color.withOpacity(0.10)
  final String label;
  final IconData icon;

  const _StatusConfig({
    required this.color,
    required this.bgColor,
    required this.label,
    required this.icon,
  });
}

/// Resolve status → _StatusConfig
/// Prioritas: StatusProgresConstant (sumber tunggal kebenaran)
/// Fallback: menunggu bayar (tidak ada di constant)
_StatusConfig _getStatus(String status) {
  // ── menunggu bayar — tidak ada di StatusProgresConstant ──
  if (status.toLowerCase() == 'menunggu bayar') {
    return const _StatusConfig(
      color: Color(0xFF2563EB), // Blue-600
      bgColor: Color(0xFFEFF6FF), // Blue-50
      label: 'Belum Bayar',
      icon: Icons.payment_outlined,
    );
  }

  // ── Cari di StatusProgresConstant ──
  final found = StatusProgresConstant.statusOptions.firstWhere(
    (s) => s['value'] == status.toLowerCase(),
    orElse: () => <String, dynamic>{},
  );

  if (found.isEmpty) {
    return const _StatusConfig(
      color: Color(0xFF64748B),
      bgColor: Color(0xFFF1F5F9),
      label: 'Proses',
      icon: Icons.hourglass_empty_outlined,
    );
  }

  final Color c = found['color'] as Color;
  return _StatusConfig(
    color: c,
    bgColor: Color.fromRGBO(
      (c.red).clamp(0, 255),
      (c.green).clamp(0, 255),
      (c.blue).clamp(0, 255),
      0.10,
    ),
    label: found['label'] as String,
    icon: found['icon'] as IconData,
  );
}

// ═══════════════════════════════════════════════════════════════
// MAIN ORDER PAGE
// ═══════════════════════════════════════════════════════════════

class MainOrderPage extends StatefulWidget {
  const MainOrderPage({super.key});

  @override
  State<MainOrderPage> createState() => _MainOrderPageState();
}

class _MainOrderPageState extends State<MainOrderPage> {
  // Filter: null = semua aktif
  String? _selectedFilter; // null = 'semua', atau nilai status

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

  // ── Filter logic ────────────────────────────────────────────
  // Filtering dilakukan di sini, bukan di build
  List<PesananModel> get _filteredOrders {
    final provider = context.read<PesananProvider>();
    // Active = belum bayar + semua progress (bukan selesai)
    final active = [
      ...provider.pesananUnpaid,
      ...provider.pesananProgress,
    ];
    // Sort by tglRealisasi desc (paling baru di atas)
    active.sort((a, b) => b.tglRealisasi.compareTo(a.tglRealisasi));

    if (_selectedFilter == null) return active;
    return active
        .where((o) =>
            (o.statusProgresPesanan ?? 'menunggu bayar') == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    if (userProvider.customer == null) return _buildLoginPrompt();

    // Watch untuk reactive rebuild
    context.watch<PesananProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _checkAndInit,
          color: Constants.primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── App bar ──────────────────────────────────────
              SliverToBoxAdapter(child: _buildHeader()),

              // ── Summary cards ─────────────────────────────────
              SliverToBoxAdapter(child: _buildSummaryRow()),

              // ── Filter chips ──────────────────────────────────
              SliverToBoxAdapter(child: _buildFilterChips()),

              // ── Order list ────────────────────────────────────
              SliverToBoxAdapter(child: _buildOrderList()),

              // ── Link ke pesanan selesai ──────────────────────
              SliverToBoxAdapter(child: _buildFinishedLink()),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Text(
            'Pesanan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F0F0F),
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          // Shortcut ke pesanan selesai
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
        ],
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'Total Aktif',
              value: totalAktif,
              color: const Color(0xFF0F0F0F),
              bgColor: Colors.white,
              icon: Icons.receipt_long_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryCard(
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
            child: _SummaryCard(
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final chip = chips[i];
          final value = chip['value'] as String?;
          final label = chip['label'] as String;
          final isSelected = _selectedFilter == value;
          final cfg = value != null ? _getStatus(value) : null;

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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
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

    if (isLoading) return _buildSkeletonList();

    final orders = _filteredOrders;

    if (orders.isEmpty) return _buildEmpty();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: orders
            .map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OrderCard(
                    order: o,
                    onTap: () =>
                        context.read<NavigationProvider>().navigateToPage(
                              context,
                              DetailOrderPage(pesananModel: o),
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
                    onPay: () {
                      if (o.linkSnap == null) {
                        context.read<NavigationProvider>().navigateToPage(
                              context,
                              targetTabIndex: 2,
                              WaitingPaymentPage(paymentData: o),
                            );
                      } else {
                        context.read<NavigationProvider>().navigateToPage(
                              context,
                              targetTabIndex: 2,
                              WebviewPage(url: o.linkSnap!),
                            );
                      }
                    },
                    onReview: () => showDialog(
                      context: context,
                      builder: (_) => UlasanDialog(
                        pesanan: o,
                        onSuccess: () async {
                          // Reload list setelah submit ulasan
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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

  // ─────────────────────────────────────────────────────────────
  // EMPTY & SKELETON
  // ─────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 32,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _selectedFilter == null
                  ? 'Belum ada pesanan aktif'
                  : 'Tidak ada pesanan ${_getStatus(_selectedFilter!).label.toLowerCase()}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            if (_selectedFilter != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _selectedFilter = null),
                child: Text(
                  'Lihat semua',
                  style: TextStyle(
                    fontSize: 13,
                    color: Constants.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _SkeletonCard(),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LOGIN PROMPT
  // ─────────────────────────────────────────────────────────────

  Widget _buildLoginPrompt() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F2),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 40,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Masuk dulu, yuk!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F0F0F),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login untuk melihat pesanan Anda',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/user-login',
                      arguments: {'targetPage': 'Tab2', 'tabIndex': 2},
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Login Sekarang',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SUMMARY CARD
// ═══════════════════════════════════════════════════════════════

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAYMENT TIMER STATUS — sama persis dengan pesanan_card.dart
// ═══════════════════════════════════════════════════════════════

class PaymentTimerStatus {
  final bool isExpired;
  final Duration? remainingTime;

  const PaymentTimerStatus({
    required this.isExpired,
    this.remainingTime,
  });
}

// ═══════════════════════════════════════════════════════════════
// ORDER CARD — StatefulWidget dengan countdown timer
//
// Struktur:
//   ┌─ Status bar (warna per status) ───────────────────────┐
//   │  [icon] Label Status          #ID singkat             │
//   ├───────────────────────────────────────────────────────┤
//   │  Avatar  Nama Vendor                                  │
//   │          [paket badge]                                │
//   │  ─────────────────────────────────────                │
//   │  📅 Tanggal  •  Waktu                                 │
//   │  📍 Lokasi                                            │
//   │  ┌── Payment Timer Banner ──────────────────────────┐ │
//   │  │ (hanya tampil jika menunggu bayar)               │ │
//   │  └──────────────────────────────────────────────────┘ │
//   │  [Chat]  [Bayar Sekarang / Detail / Beri Ulasan]      │
//   └───────────────────────────────────────────────────────┘
// ═══════════════════════════════════════════════════════════════

class _OrderCard extends StatefulWidget {
  final PesananModel order;
  final VoidCallback onTap;
  final VoidCallback onChat;
  final VoidCallback onPay;
  final VoidCallback onReview;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onChat,
    required this.onPay,
    required this.onReview,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  PaymentTimerStatus? _timerStatus;
  Timer? _updateTimer;

  static const _timeout = Duration(minutes: 5);

  String get _statusStr =>
      widget.order.statusProgresPesanan ?? 'menunggu bayar';
  bool get _isUnpaid => _statusStr == 'menunggu bayar';
  bool get _isReview => _statusStr == 'review';

  @override
  void initState() {
    super.initState();
    if (_isUnpaid) {
      _loadTimerStatus();
      _startPeriodicUpdate();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicUpdate() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _loadTimerStatus();
    });
  }

  Future<void> _loadTimerStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final noBukti = widget.order.noBukti;
    final storageKey = 'payment_start_$noBukti';
    final statusKey = 'payment_status_$noBukti';

    final storedTime = prefs.getString(storageKey);
    final paymentStatus = prefs.getString(statusKey);

    if (!mounted) return;

    if (storedTime == null) {
      // Belum mulai pembayaran
      setState(() {
        _timerStatus = const PaymentTimerStatus(
          isExpired: false,
          remainingTime: null,
        );
      });
      return;
    }

    final startTime = DateTime.parse(storedTime);
    final elapsed = DateTime.now().difference(startTime);
    final remaining = _timeout - elapsed;

    if (remaining.inSeconds <= 0 || paymentStatus == 'expired') {
      // Auto-mark expired
      if (paymentStatus != 'expired') {
        await prefs.setString(statusKey, 'expired');
      }
      setState(() {
        _timerStatus = const PaymentTimerStatus(
          isExpired: true,
          remainingTime: Duration.zero,
        );
      });
    } else {
      setState(() {
        _timerStatus = PaymentTimerStatus(
          isExpired: false,
          remainingTime: remaining,
        );
      });
    }
  }

  /// Dipanggil saat user tap "Bayar" — mulai/reset timer
  Future<void> _startPaymentTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final noBukti = widget.order.noBukti;
    await prefs.setString(
        'payment_start_$noBukti', DateTime.now().toIso8601String());
    await prefs.remove('payment_status_$noBukti');
    await _loadTimerStatus();
    widget.onPay();
  }

  /// Dipanggil saat user tap "Coba Lagi" setelah expired
  Future<void> _retryPayment() async {
    final prefs = await SharedPreferences.getInstance();
    final noBukti = widget.order.noBukti;
    await prefs.setString(
        'payment_start_$noBukti', DateTime.now().toIso8601String());
    await prefs.remove('payment_status_$noBukti');
    await _loadTimerStatus();
    widget.onPay();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _getStatus(_statusStr);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Status bar ───────────────────────────────────────
          _buildStatusBar(cfg),

          // ── Body ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vendor + paket
                _buildVendorRow(),

                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 12),

                // Tanggal & lokasi
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  text:
                      '${Helper.formatTanggal(widget.order.tglRealisasi)}  •  ${Helper.toLocalTime(widget.order.tglRealisasi)}',
                ),
                const SizedBox(height: 5),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: widget.order.lokasi,
                ),

                // Progress status banner — tampil untuk semua status KECUALI menunggu bayar
                if (!_isUnpaid) ...[
                  const SizedBox(height: 12),
                  _buildProgressBanner(),
                ],

                // Payment Timer Banner — hanya tampil jika menunggu bayar
                if (_isUnpaid && _timerStatus != null) ...[
                  const SizedBox(height: 12),
                  _buildPaymentBanner(),
                ],

                const SizedBox(height: 14),

                // Action buttons row
                _buildActionRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Status bar ────────────────────────────────────────────────
  Widget _buildStatusBar(_StatusConfig cfg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cfg.bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(cfg.icon, size: 14, color: cfg.color),
          const SizedBox(width: 6),
          Text(
            cfg.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cfg.color,
            ),
          ),
          const Spacer(),
          Text(
            '#${widget.order.noTrackingPesanan}',
            style: TextStyle(
              fontSize: 11,
              color: cfg.color.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Vendor row ────────────────────────────────────────────────
  Widget _buildVendorRow() {
    return Row(
      children: [
        _VendorAvatar(url: widget.order.idMediaVendor ?? ''),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.order.namaVendor ?? 'Vendor',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F0F0F),
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Constants.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.order.namaPaket,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Constants.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Progress Status Banner — persiapan / proses / review / revisi ──
  Widget _buildProgressBanner() {
    final cfg = _getStatus(_statusStr);
    final deskripsi = widget.order.deskripsiProgresPesanan ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cfg.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cfg.color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cfg.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(cfg.icon, size: 14, color: cfg.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cfg.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cfg.color,
                  ),
                ),
                if (deskripsi.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    deskripsi,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: cfg.color.withOpacity(0.85),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Payment Timer Banner ──────────────────────────────────────
  Widget _buildPaymentBanner() {
    final status = _timerStatus!;

    // 1. Belum mulai timer (remainingTime == null)
    if (status.remainingTime == null) {
      return _PaymentBannerContainer(
        color: Colors.blue.shade700,
        bgColor: Colors.blue.shade50,
        borderColor: Colors.blue.shade200,
        icon: Icons.payment_outlined,
        iconBgColor: Colors.blue.shade100,
        title: 'Menunggu Pembayaran',
        subtitle: 'Tap "Bayar Sekarang" untuk melanjutkan',
        trailing: null,
      );
    }

    // 2. Expired
    if (status.isExpired) {
      return _PaymentBannerContainer(
        color: Colors.red.shade700,
        bgColor: Colors.red.shade50,
        borderColor: Colors.red.shade200,
        icon: Icons.timer_off_outlined,
        iconBgColor: Colors.red.shade100,
        title: 'Waktu Pembayaran Habis',
        subtitle: 'Tap "Coba Lagi" untuk memulai ulang',
        trailing: null,
      );
    }

    // 3. Timer aktif — tampilkan countdown
    final remaining = status.remainingTime!;
    final isWarning = remaining.inSeconds < 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWarning
              ? [Colors.red.shade400, Colors.red.shade500]
              : [Colors.orange.shade400, Colors.orange.shade500],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isWarning ? Colors.red : Colors.orange).withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.timer_outlined, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Pembayaran Sedang Diproses',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Countdown pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              Helper.formatDuration(remaining),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isWarning ? Colors.red.shade700 : Colors.orange.shade700,
                letterSpacing: 0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Action buttons row ────────────────────────────────────────
  Widget _buildActionRow() {
    // Tentukan tombol primary berdasarkan status + timer
    Widget primaryButton;

    if (_isUnpaid) {
      final status = _timerStatus;

      if (status == null) {
        // Loading timer, disable sementara
        primaryButton = _PrimaryButton(
          icon: Icons.payment_rounded,
          label: 'Bayar Sekarang',
          onTap: widget.onPay,
          color: const Color(0xFF1565C0),
        );
      } else if (status.isExpired) {
        // Expired → Coba Lagi (orange)
        primaryButton = _PrimaryButton(
          icon: Icons.refresh_rounded,
          label: 'Coba Lagi',
          onTap: _retryPayment,
          color: Colors.orange.shade700,
        );
      } else if (status.remainingTime != null) {
        // Timer aktif → Lanjut Bayar (orange)
        primaryButton = _PrimaryButton(
          icon: Icons.payment_rounded,
          label: 'Lanjut Bayar',
          onTap: widget.onPay,
          color: Colors.orange.shade700,
        );
      } else {
        // Belum mulai → Bayar Sekarang (biru)
        primaryButton = _PrimaryButton(
          icon: Icons.payment_rounded,
          label: 'Bayar Sekarang',
          onTap: _startPaymentTimer,
          color: const Color(0xFF1565C0),
        );
      }
    } else if (_isReview) {
      primaryButton = _PrimaryButton(
        icon: Icons.rate_review_rounded,
        label: 'Beri Ulasan',
        onTap: widget.onReview,
        color: const Color(0xFF8B5CF6), // Sesuai StatusProgresConstant review
      );
    } else {
      primaryButton = _PrimaryButton(
        icon: Icons.arrow_forward_rounded,
        label: 'Detail',
        onTap: widget.onTap,
        color: Constants.primaryColor,
      );
    }

    return Row(
      children: [
        // Chat — selalu ada
        _OutlineButton(
          icon: Icons.chat_outlined,
          label: 'Chat',
          onTap: widget.onChat,
          color: Colors.grey.shade700,
          borderColor: Colors.grey.shade300,
        ),
        const SizedBox(width: 8),
        Expanded(child: primaryButton),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAYMENT BANNER CONTAINER — reusable untuk state belum bayar & expired
// ═══════════════════════════════════════════════════════════════

class _PaymentBannerContainer extends StatelessWidget {
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _PaymentBannerContainer({
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SKELETON CARD
// ═══════════════════════════════════════════════════════════════

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _ShimmerBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 38,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 14, color: Colors.white),
                            const SizedBox(height: 6),
                            Container(
                                height: 10, width: 80, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(height: 10, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 140, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final Widget child;
  const _ShimmerBox({required this.child});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
          stops: [
            (_anim.value - 0.3).clamp(0.0, 1.0),
            _anim.value.clamp(0.0, 1.0),
            (_anim.value + 0.3).clamp(0.0, 1.0),
          ],
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════

class _VendorAvatar extends StatelessWidget {
  final String url;
  const _VendorAvatar({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: Constants.primaryColor.withOpacity(0.15),
        child: Icon(Icons.person, size: 20, color: Constants.primaryColor),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: NetworkImage(url),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color borderColor;

  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
