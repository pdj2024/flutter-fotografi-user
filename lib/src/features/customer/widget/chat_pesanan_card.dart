import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';

class ChatPesananCard extends StatelessWidget {
  final PesananModel pesanan;
  final bool isPesanan;
  final PaketModel? paket;
  final String roomId;
  final String customerId;
  final VoidCallback? onTap;
  const ChatPesananCard(
      {super.key,
      required this.pesanan,
      required this.roomId,
      required this.customerId,
      required this.onTap,
      this.paket,
      this.isPesanan = false});

  @override
  Widget build(BuildContext context) {


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
          Text(Helper.formatCurrency(pesanan.harga),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(pesanan.namaPaket,
              style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 2),
          Text("${Helper.toLocalTime(pesanan.tglRealisasi)}, ${Helper.formatTanggal(pesanan.tglRealisasi)}",
              style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 2),
          Text(pesanan.lokasi, style: TextStyle(color: Colors.grey.shade700)),
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
              child: Text("Lihat Pesanan",
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
