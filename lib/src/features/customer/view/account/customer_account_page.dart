import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
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
  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
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
                                            width: 82,
                                            height: 82,
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade300,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.person),
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
                                                            ?.namaDisplay ??
                                                        "",
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
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.edit),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Edit Profil',
                                                style: TextStyle(fontSize: 14),
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
                // Center(
                //   child: Text("Likes"),
                // ),
                // Center(
                //   child: Text("Saves"),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
