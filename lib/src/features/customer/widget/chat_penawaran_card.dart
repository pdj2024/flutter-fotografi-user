import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';

class ChatPenawaranCard extends StatelessWidget {
  final PenawaranModel penawaran;
  final bool isPesanan;
  final PaketModel? paket;
  final String roomId;
  final String customerId;
  final VoidCallback? onTap;
  const ChatPenawaranCard(
      {super.key,
      required this.penawaran,
      required this.roomId,
      required this.customerId,
      required this.onTap,
      this.paket,
      this.isPesanan = false});

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
              onPressed: onTap,
              child: Text(
                !isPesanan ? "Detail & Pembayaran" : "Lihat Pesanan",
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
