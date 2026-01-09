import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/view/history/finish_order_section.dart';
import 'package:mpjnew/src/features/customer/view/history/main_order_shimmer.dart';
import 'package:mpjnew/src/features/customer/view/history/progress_order_section.dart';
import 'package:mpjnew/src/features/customer/view/history/unpaid_order_section.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:provider/provider.dart';

class MainOrderPage extends StatefulWidget {
  const MainOrderPage({super.key});

  @override
  State<MainOrderPage> createState() => _MainOrderPageState();
}

class _MainOrderPageState extends State<MainOrderPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<PesananProvider>()
        .loadOrder(userId: context.read<UserProvider>().userId ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final pesananProvider = context.watch<PesananProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 1,
          title: const Text(
            "Semua Pesan",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,

              indicatorColor: Constants.primaryColor,
              indicatorWeight: 2.5,
              isScrollable: false, // ✅ False agar tab membagi rata layar
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
            pesananProvider.isLoading
                ? const MainOrderShimmer()
                : const UnpaidOrderSection(),
            pesananProvider.isLoading
                ? const MainOrderShimmer()
                : const ProgressOrderSection(),
            pesananProvider.isLoading
                ? const MainOrderShimmer()
                : const FinishOrderSection(),
          ],
        ),
      ),
    );
  }

  // ✅ Widget tab dengan auto-resize text
  Widget _buildTab(String label, int count) {
    return Tab(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 60, // Lebar minimum tab
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                ),
                if (count > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.shade200,
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
            ),
          ),
        ),
      ),
    );
  }
}
