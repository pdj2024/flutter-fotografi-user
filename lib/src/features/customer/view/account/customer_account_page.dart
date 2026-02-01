import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/models/customer_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/view/account/edit_account_page.dart';
import 'package:mpjnew/src/features/customer/view/account/portofolio_account_section.dart';
import 'package:mpjnew/src/features/customer/view/account/setting_page.dart';
import 'package:mpjnew/src/features/customer/widget/avatar_circle.dart';
import 'package:provider/provider.dart';

class CustomerAccountPage extends StatefulWidget {
  const CustomerAccountPage({super.key});

  @override
  State<CustomerAccountPage> createState() => _CustomerAccountPageState();
}

class _CustomerAccountPageState extends State<CustomerAccountPage> {
  // ✅ Check if profile is complete
  bool _isProfileComplete(CustomerModel? customer) {
    if (customer == null) return false;

    return customer.namaDisplay.isNotEmpty &&
        customer.kota.isNotEmpty &&
        customer.namaKota.isNotEmpty;
  }

  // ✅ Get missing fields
  List<String> _getMissingFields(CustomerModel? customer) {
    if (customer == null) return ['Semua data'];

    List<String> missing = [];

    if (customer.namaDisplay.isEmpty) {
      missing.add('Nama Lengkap');
    }
    if (customer.userName.isEmpty) {
      missing.add('Username');
    }
    if (customer.kota.isEmpty || customer.namaKota.isEmpty) {
      missing.add('Lokasi');
    }

    return missing;
  }

  // ✅ Calculate profile completion percentage
  int _getProfileCompletionPercentage(CustomerModel? customer) {
    if (customer == null) return 0;

    int total = 3; // Total fields to check
    int filled = 0;

    if (customer.namaDisplay.isNotEmpty) filled++;
    if (customer.kota.isNotEmpty) filled++;
    if (customer.namaKota.isNotEmpty) filled++;

    return ((filled / total) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final customer = userProvider.customer;
    final isProfileComplete = _isProfileComplete(customer);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.black,
                ),
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
        body: NestedScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    (userProvider.isLoading)
                        ? ShimmerPlaceholder(
                            radius: 20,
                            height: 200,
                          )
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
                                                (userProvider.customer
                                                                ?.namaDisplay ==
                                                            ""
                                                        ? userProvider
                                                            .customer!.email[0]
                                                            .toUpperCase()
                                                        : userProvider.customer
                                                            ?.namaDisplay[0]
                                                            .toUpperCase()) ??
                                                    "C".toUpperCase(),
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
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    userProvider.customer
                                                                ?.namaDisplay !=
                                                            ""
                                                        ? userProvider.customer!
                                                            .namaDisplay
                                                        : userProvider.customer
                                                                    ?.email !=
                                                                null
                                                            ? userProvider
                                                                .customer!.email
                                                                .split('@')
                                                                .first
                                                            : 'Customer',
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    userProvider.customer
                                                            ?.namaKota ??
                                                        "",
                                                    style: const TextStyle(
                                                        fontSize: 14),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // ═══════════════════════════════════════
                                // ✅ PROFILE COMPLETION WARNING
                                // ═══════════════════════════════════════
                                if (!userProvider.isLoading &&
                                    !isProfileComplete)
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 22,
                                                      vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.edit),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Edit Profil',
                                                  style:
                                                      TextStyle(fontSize: 14),
                                                ),
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
                    TabBar(
                      overlayColor: WidgetStatePropertyAll(Colors.transparent),
                      indicatorColor: Constants.primaryColorVendor,
                      labelColor: Constants.primaryColorVendor,
                      tabs: [
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
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],

          /// PENTING: jangan bungkus TabBarView dengan Padding (BREAK refresh)
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TabBarView(
              children: [
                PortofolioAccountSection(data: "like"),
                PortofolioAccountSection(data: "save"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // ✅ PROFILE COMPLETION BANNER
  // ═══════════════════════════════════════
  Widget _buildProfileCompletionBanner(CustomerModel? customer) {
    final missingFields = _getMissingFields(customer);

    return Container(
      margin: const EdgeInsets.only(
        top: 16,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Profil Anda Belum Lengkap',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Lengkapi data berikut untuk pengalaman yang lebih baik:',
            style: TextStyle(
              color: Colors.orange.shade800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ...missingFields.map((field) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    field,
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                context.read<NavigationProvider>().navigateToPage(
                      context,
                      EditAccountPage(),
                      targetTabIndex: 3,
                    );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Lengkapi Profil',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
