import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/models/customer_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/local_storage_service.dart';
import 'package:mpjnew/src/features/customer/view/account/edit_account_page.dart';
import 'package:mpjnew/src/features/customer/view/account/portofolio_account_section.dart';
import 'package:mpjnew/src/features/customer/view/account/setting_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/widget/avatar_circle.dart';
import 'package:mpjnew/src/features/customer/widget/refresh_header.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class CustomerAccountPage extends StatefulWidget {
  const CustomerAccountPage({super.key});

  @override
  State<CustomerAccountPage> createState() => _CustomerAccountPageState();
}

class _CustomerAccountPageState extends State<CustomerAccountPage>
    with SingleTickerProviderStateMixin {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  late final TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_currentTab != _tabController.index) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool _isProfileComplete(CustomerModel? customer) {
    if (customer == null) return false;
    return customer.namaDisplay.isNotEmpty &&
        customer.kota.isNotEmpty &&
        customer.namaKota.isNotEmpty;
  }

  List<String> _getMissingFields(CustomerModel? customer) {
    if (customer == null) return ['Semua data'];
    List<String> missing = [];
    if (customer.namaDisplay.isEmpty) missing.add('Nama Lengkap');
    if (customer.userName.isEmpty) missing.add('Username');
    if (customer.kota.isEmpty || customer.namaKota.isEmpty) {
      missing.add('Lokasi');
    }
    return missing;
  }

  String _resolveDisplayName(CustomerModel? customer) {
    if (customer == null) return 'Customer';
    if (customer.namaDisplay.isNotEmpty) return customer.namaDisplay;
    if (customer.email.isNotEmpty) return customer.email.split('@').first;
    return 'Customer';
  }

  String _resolveAvatarInitial(CustomerModel? customer) {
    if (customer == null) return 'C';
    if (customer.namaDisplay.isNotEmpty) {
      return customer.namaDisplay[0].toUpperCase();
    }
    if (customer.email.isNotEmpty) return customer.email[0].toUpperCase();
    return 'C';
  }

  String _resolveUsername(CustomerModel? customer) {
    if (customer == null) return 'Customer';
    if (customer.userName.isNotEmpty) return customer.userName;
    return 'Customer';
  }

  Future<void> _onRefresh() async {
    if (!mounted) {
      _refreshController.refreshCompleted();
      return;
    }
    try {
      final userProvider = context.read<UserProvider>();
      LocalStorageService.instance
          .setActiveCustomer(userProvider.customer!.noId);
      final portofolioProvider = context.read<PortofolioProvider>();

      await Future.wait([
        userProvider.checkLoginGoogle(role: Constants.customer),
        portofolioProvider.refreshLikePortofolio(context),
        portofolioProvider.refreshSavePortofolio(context),
      ]);
      _refreshController.refreshCompleted();
    } catch (e) {
      debugPrint('[CustomerAccount] ❌ Refresh error: $e');
      _refreshController.refreshFailed();
    }
  }

  void _showSwitchAccountSheet(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final customer = userProvider.customer;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Current account
                if (customer != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Constants.primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Constants.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        // ✅ Initial avatar, tidak ada foto untuk customer
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              Constants.primaryColor.withOpacity(0.15),
                          child: Text(
                            _resolveAvatarInitial(customer),
                            style: TextStyle(
                              color: Constants.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _resolveUsername(customer),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                customer.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.check_circle_rounded,
                          color: Constants.primaryColor,
                          size: 22,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 14),

                // Switch account button (placeholder)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      // TODO: Implementasi switch account
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Fitur switch akun sedang dalam pengembangan'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                    label: const Text('Ganti Akun'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<PortofolioProvider>();
    final userProvider = context.watch<UserProvider>();
    final customer = userProvider.customer;
    final isProfileComplete = _isProfileComplete(customer);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        centerTitle: true,
        title: userProvider.isLoading
            ? const ShimmerPlaceholder(radius: 10)
            : GestureDetector(
                onTap: () => _showSwitchAccountSheet(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _resolveUsername(customer),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.black,
                      size: 22,
                    ),
                  ],
                ),
              ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.black),
              onPressed: () {
                context.read<NavigationProvider>().navigateToPage(
                      context,
                      SettingPage(),
                      targetTabIndex: 3,
                      hrsLogin: true,
                    );
              },
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: SmartRefresher(
          controller: _refreshController,
          onRefresh: _onRefresh,
          physics: const AlwaysScrollableScrollPhysics(),
          header: buildRefreshHeader(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: userProvider.isLoading
                      ? const ShimmerPlaceholder(radius: 20, height: 180)
                      : _buildProfileSection(
                          userProvider, customer, isProfileComplete),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    overlayColor:
                        const WidgetStatePropertyAll(Colors.transparent),
                    indicatorColor: Constants.primaryColor,
                    labelColor: Constants.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Tab(text: "Disukai"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Tab(text: "Disimpan"),
                      ),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                child: IndexedStack(
                  index: _currentTab,
                  children: const [
                    _TabContent(data: 'like'),
                    _TabContent(data: 'save'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Profile Section — IG-style
  // ════════════════════════════════════════════════════════════

  Widget _buildProfileSection(
    UserProvider userProvider,
    CustomerModel? customer,
    bool isProfileComplete,
  ) {
    // ✅ Semua data dari CustomerModel, bukan VendorModel
    final namaDisplay = _resolveDisplayName(customer);
    final namaKota = customer?.namaKota ?? '';

    final portofolioProvider = context.read<PortofolioProvider>();
    final totalLikes = portofolioProvider.portofolioLikelist.length;
    final totalSaves = portofolioProvider.portofolioSaveList.length;

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar + Stats row ─────────────────────────
          Row(
            children: [
              // ── Avatar ─────────────────────────────────
              // ── Avatar ─────────────────────────────────
              GestureDetector(
                onTap: () {
                  context.read<NavigationProvider>().navigateToPage(
                        context,
                        EditAccountPage(),
                        targetTabIndex: 3,
                      );
                },
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: Constants.primaryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _resolveAvatarInitial(customer),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Constants.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // ── Nama + Kota + Stats ────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Display
                    Text(
                      namaDisplay,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // ✅ Nama kota di bawah nama display
                    // if (namaKota.isNotEmpty)
                    //   Padding(
                    //     padding: const EdgeInsets.only(top: 2),
                    //     child: Row(
                    //       children: [
                    //         Icon(
                    //           Icons.location_on_outlined,
                    //           size: 11,
                    //           color: Colors.grey.shade500,
                    //         ),
                    //         const SizedBox(width: 2),
                    //         Flexible(
                    //           child: Text(
                    //             namaKota,
                    //             style: TextStyle(
                    //               fontSize: 11,
                    //               color: Colors.grey.shade500,
                    //               height: 1.3,
                    //             ),
                    //             maxLines: 1,
                    //             overflow: TextOverflow.ellipsis,
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),

                    const SizedBox(height: 8),

                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: _StatColumn(
                            value: _formatCount(totalLikes),
                            label: 'disukai',
                          ),
                        ),
                        Expanded(
                          child: _StatColumn(
                            value: _formatCount(totalSaves),
                            label: 'disimpan',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Profile completion or Edit button ──────────
          if (!isProfileComplete)
            _buildProfileCompletionBanner(customer)
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<NavigationProvider>().navigateToPage(
                        context,
                        EditAccountPage(),
                        targetTabIndex: 3,
                      );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Edit Profil',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Profile Completion Banner
  // ════════════════════════════════════════════════════════════

  Widget _buildProfileCompletionBanner(CustomerModel? customer) {
    final missingFields = _getMissingFields(customer);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_outline,
                    color: Colors.blue.shade700, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lengkapi Profil Anda',
                      style: TextStyle(
                        color: Colors.grey.shade900,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${missingFields.length} informasi belum dilengkapi',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...missingFields.map((field) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(field,
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 13)),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.read<NavigationProvider>().navigateToPage(
                      context,
                      EditAccountPage(),
                      targetTabIndex: 3,
                    );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                side: BorderSide(color: Colors.blue.shade300, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Lengkapi Sekarang',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Format count helper
  // ════════════════════════════════════════════════════════════

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 10000) {
      final val = count / 1000;
      return val == val.roundToDouble()
          ? '${val.toInt()}rb'
          : '${val.toStringAsFixed(1)}rb';
    }
    if (count < 1000000) return '${(count / 1000).round()}rb';
    final val = count / 1000000;
    return val == val.roundToDouble()
        ? '${val.toInt()}jt'
        : '${val.toStringAsFixed(1)}jt';
  }
}

// ══════════════════════════════════════════════════════════════
// STAT COLUMN WIDGET
// ══════════════════════════════════════════════════════════════

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final bool isText;

  const _StatColumn({
    required this.value,
    required this.label,
    this.isText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isText)
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          )
        else
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// STICKY TAB BAR DELEGATE
// ══════════════════════════════════════════════════════════════

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF9F9F9),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate old) => tabBar != old.tabBar;
}

// ══════════════════════════════════════════════════════════════
// TAB CONTENT WRAPPER
// ══════════════════════════════════════════════════════════════

class _TabContent extends StatefulWidget {
  final String data;
  const _TabContent({required this.data});

  @override
  State<_TabContent> createState() => _TabContentState();
}

class _TabContentState extends State<_TabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        PortofolioAccountSection(data: widget.data),
      ],
    );
  }
}
