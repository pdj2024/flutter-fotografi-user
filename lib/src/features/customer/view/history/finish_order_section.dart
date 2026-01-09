import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/pesanan_card.dart';
import 'package:provider/provider.dart';

class FinishOrderSection extends StatelessWidget {
  const FinishOrderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final progressOrder = context.watch<PesananProvider>().pesananSelesai;
    return ListView.builder(
      itemCount: progressOrder.length,
      itemBuilder: (context, index) {
        final item = progressOrder[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: PesananCard(
            clientName: item.namaVendor ?? "Vendor",
            kategori: item.namaPaket,
            dateValue: DateFormat("dd MMMM yyyy").format(item.tglRealisasi),
            timeValue: Helper.toLocalTime(item.tglRealisasi),
            location: item.lokasi,
            statusProgress: item.statusProgresPesanan ?? "proses",
            deskripsiProgress: item.deskripsiProgresPesanan ?? "",
            onTap: () {
              context.read<NavigationProvider>().navigateToPage(
                    context,
                    targetTabIndex: 2,
                    DetailOrderPage(pesananModel: item),
                  );
            },
          ),
        );
      },
    );
  }
}
