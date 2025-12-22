import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/view/history/finish_order_section.dart';
import 'package:mpjnew/src/features/customer/view/history/progress_order_section.dart';
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
            preferredSize: const Size.fromHeight(58),
            child: Container(
              alignment: Alignment.centerLeft,
              child: const TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Constants.primaryColor,
                indicatorWeight: 2.5,
                isScrollable: false,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorPadding: EdgeInsets.zero,
                tabs: [
                  Tab(
                    child: Text("Belum bayar",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Tab(
                    child: Text("Progress",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Tab(
                    child: Text("Selesai",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
                overlayColor: WidgetStatePropertyAll(Colors.transparent),
                dividerColor: Color(0xFFDDDDDD),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            ProgressOrderSection(),
            ProgressOrderSection(),
            FinishOrderSection(),
          ],
        ),
      ),
    );
  }
}
