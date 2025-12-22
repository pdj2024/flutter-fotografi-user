import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/models/paket_model.dart';
import 'package:mpjnew/src/data/models/penawaran_model.dart';
import 'package:mpjnew/src/features/customer/view/payment/detail_pembayaran_page.dart';
import 'package:provider/provider.dart';

class ChatPaymentCard extends StatelessWidget {
  final PenawaranModel penawaran;
  final PaketModel? paket;
  final String roomId;
  final String customerId;
  const ChatPaymentCard(
      {super.key,
      required this.penawaran,
      required this.roomId,
      required this.customerId,
      this.paket});

  @override
  Widget build(BuildContext context) {
    final tanggal =
        DateFormat("dd MMM yyyy", "id_ID").format(penawaran.tglRealisasi);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Helper.formatCurrency(penawaran.harga),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(penawaran.namaPaket,
              style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 2),
          Text("${Helper.toLocalTime(penawaran.tglRealisasi)}, $tanggal",
              style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 2),
          Text(penawaran.lokasi, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                context.read<NavigationProvider>().navigateToPage(
                    context,
                    targetTabIndex: 2,
                    DetailPembayaranPage(
                      penawaranId: penawaran.noId,
                    ));
              },
              child: const Text(
                "Detail & Pembayaran",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
