import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/models/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/pesanan_card.dart';
import 'package:provider/provider.dart';

class ProgressOrderSection extends StatelessWidget {
  const ProgressOrderSection({super.key});

  Map<String, List<PesananModel>> groupByStatus(
    List<PesananModel> list,
  ) {
    final Map<String, List<PesananModel>> grouped = {};

    for (final item in list) {
      final status = item.statusProgresPesanan ?? 'lainnya';
      grouped.putIfAbsent(status, () => []);
      grouped[status]!.add(item);
    }

    return grouped;
  }

  String statusLabel(String status) {
    switch (status) {
      case 'persiapan':
        return 'Persiapan';
      case 'progres':
        return 'Sedang Dikerjakan';
      case 'review':
        return 'Menunggu Review';
      case 'revisi':
        return 'Perlu Revisi';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressOrder = context.watch<PesananProvider>().pesananProgress;
    final groupedOrders = groupByStatus(progressOrder);
    final statusKeys = groupedOrders.keys.toList();

    return ListView.builder(
      itemCount: statusKeys.length,
      itemBuilder: (context, index) {
        final status = statusKeys[index];
        final items = groupedOrders[status]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== LABEL STATUS =====
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                top: 12,
              ),
              child: Text(
                Helper.capitalizeFirst(statusLabel(status)),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
              ),
            ),

            // ===== LIST ORDER =====
            ...items.map(
              (item) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: PesananCard(
                  clientName: item.namaVendor ?? "Vendor",
                  kategori: item.namaPaket,
                  dateValue:
                      "${DateFormat("dd/MM/yyyy").format(item.tglRealisasi)} - ${Helper.toLocalTime(item.tglRealisasi)}",
                  location: "${item.lokasi}, ${item.namaKota}",
                  onTap: () {
                    context.read<NavigationProvider>().navigateToPage(
                        context,
                        targetTabIndex: 2,
                        DetailOrderPage(pesananModel: item));
                  },
                  onChatTap: () {
                    print("Chat tap");
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
