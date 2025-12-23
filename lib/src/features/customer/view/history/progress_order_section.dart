import 'package:flutter/cupertino.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/order_card.dart';
import 'package:provider/provider.dart';

class ProgressOrderSection extends StatelessWidget {
  const ProgressOrderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final progressOrder = context.watch<PesananProvider>().pesananProgress;
    return ListView.builder(
      itemCount: progressOrder.length,
      itemBuilder: (context, index) {
        final item = progressOrder[index];
        return OrderCard(
          pesanan: item,
          onTap: () {
            context.read<NavigationProvider>().navigateToPage(
                  context,
                  targetTabIndex: 2,
                  DetailOrderPage(pesananModel: item),
                );
          },
        );
      },
    );
  }
}
