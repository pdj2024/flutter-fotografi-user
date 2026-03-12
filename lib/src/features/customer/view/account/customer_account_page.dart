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
    if (customer.kota.isEmpty || customer.namaKota.isEmpty)
      missing.add('Lokasi');
    return missing;
  }

  /// Aman dari null — tidak pakai ! operator
  String _resolveDisplayName(UserProvider userProvider) {
    final customer = userProvider.customer;
    if (customer == null) return 'Customer';
    final nama = customer.namaDisplay;
    if (nama.isNotEmpty) return nama;
    final email = customer.email;
    if (email.isNotEmpty) return email.split('@').first;
    return 'Customer';
  }

  /// Inisial huruf pertama untuk avatar — aman dari null & empty string
  String _resolveAvatarInitial(UserProvider userProvider) {
    final customer = userProvider.customer;
    if (customer == null) return 'C';
    if (customer.namaDisplay.isNotEmpty) {
      return customer.namaDisplay[0].toUpperCase();
    }
    if (customer.email.isNotEmpty) {
      return customer.email[0].toUpperCase();
    }
    return 'C';
  }

  Future<void> _onRefresh() async {
    if (!mounted) {
      _refreshController.refreshCompleted();
      return;
    }
    try {
      final userProvider = context.read<UserProvider>();
      LocalStorageService.instance.setActiveCustomer(
        userProvider.customer!.noId,
      );
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

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final customer = userProvider.customer;
    final isProfileComplete = _isProfileComplete(customer);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
        title: userProvider.isLoading
            ? ShimmerPlaceholder(radius: 10)
            : Text(
                (userProvider.customer == null ||
                        userProvider.customer?.userName == "")
                    ? "Customer"
                    : userProvider.customer!.userName,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black),
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
      // ── Pola sama seperti MainOrderPage:
      // SafeArea → SmartRefresher → CustomScrollView → slivers
      body: SafeArea(
        child: SmartRefresher(
          controller: _refreshController,
          onRefresh: _onRefresh,
          physics: const AlwaysScrollableScrollPhysics(),
          header: buildRefreshHeader(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Profil Section ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: userProvider.isLoading
                      ? ShimmerPlaceholder(radius: 20, height: 200)
                      : Container(
                          margin: const EdgeInsets.only(top: 20, bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  userProvider.photoUrl == null
                                      ? Container(
                                          width: 68,
                                          height: 68,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Constants.primaryColorVendor,
                                                Constants.primaryColorVendor
                                                    .withOpacity(0.7),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              _resolveAvatarInitial(
                                                  userProvider),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        )
                                      : AvatarCircle(
                                          size: 82,
                                          imgUrl: userProvider.photoUrl,
                                        ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _resolveDisplayName(userProvider),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          userProvider.customer?.namaKota ?? "",
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // ── Profile completion / Edit button ──
                              if (!userProvider.isLoading && !isProfileComplete)
                                _buildProfileCompletionBanner(customer)
                              else
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            context
                                                .read<NavigationProvider>()
                                                .navigateToPage(
                                                  context,
                                                  EditAccountPage(),
                                                  targetTabIndex: 3,
                                                );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.grey.shade300,
                                            foregroundColor: Colors.black,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 22, vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.edit),
                                              SizedBox(width: 8),
                                              Text('Edit Profil',
                                                  style:
                                                      TextStyle(fontSize: 14)),
                                            ],
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

              // ── TabBar pinned menggunakan SliverPersistentHeader ──
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    overlayColor:
                        const WidgetStatePropertyAll(Colors.transparent),
                    indicatorColor: Constants.primaryColorVendor,
                    labelColor: Constants.primaryColorVendor,
                    tabs: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Tab(text: "Likes"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Tab(text: "Saves"),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Tab content ───────────────────────────────────────
              // Pakai SliverToBoxAdapter + IndexedStack agar KEDUA tab
              // tetap mounted di background (tidak di-dispose saat switch).
              // Ini memastikan loadLiked & loadSaved keduanya tetap jalan
              // dan data save bisa dibuka saat tab di-switch.
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

  Widget _buildProfileCompletionBanner(CustomerModel? customer) {
    final missingFields = _getMissingFields(customer);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_outline,
                    color: Colors.blue.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lengkapi Profil Anda',
                      style: TextStyle(
                          color: Colors.grey.shade900,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
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
          const SizedBox(height: 12),
          Text(
            'Data yang masih perlu dilengkapi:',
            style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ...missingFields.map((field) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.blue.shade400, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Text(field,
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 13)),
                  ],
                ),
              )),
          const SizedBox(height: 14),
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Lengkapi Sekarang',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Delegate untuk TabBar yang sticky/pinned di dalam CustomScrollView ───────
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  // tinggi = tinggi TabBar + padding bawah 10px
  @override
  double get minExtent => tabBar.preferredSize.height + 10;

  @override
  double get maxExtent => tabBar.preferredSize.height + 10;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF9F9F9),
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}

// ── _TabContent: wrapper agar PortofolioAccountSection bisa scroll ────────────
// Dibungkus CustomScrollView agar grid-nya scrollable di dalam IndexedStack.
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
      physics: const NeverScrollableScrollPhysics(), // scroll dihandle parent
      slivers: [
        PortofolioAccountSection(data: widget.data),
      ],
    );
  }
}
