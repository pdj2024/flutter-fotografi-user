import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/pages/fotografi_user/detil_bayar.dart';
import 'package:provider/provider.dart';

class ChatPaymentCard extends StatelessWidget {
  final int harga;
  final DateTime? tglRealisasi;
  final String lokasi;
  const ChatPaymentCard(
      {super.key,
      required this.harga,
      this.tglRealisasi,
      required this.lokasi});

  @override
  Widget build(BuildContext context) {
    final formattedHarga = NumberFormat("#,###", "id_ID").format(harga);
    String jam = "-";
    String tanggal = "-";
    if (tglRealisasi != null) {
      jam = "${DateFormat("HH:mm").format(tglRealisasi!)} WIB";
      tanggal = DateFormat("dd MMM yyyy", "id_ID").format(tglRealisasi!);
    }

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(vertical: 4),
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
          Text("IDR $formattedHarga",
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text("$jam, $tanggal", style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 2),
          Text(lokasi, style: TextStyle(color: Colors.grey.shade700)),
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
                context
                    .read<NavigationProvider>()
                    .pushFullPage(context, DetilBayar());
              },
              child: const Text("BAYAR",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
