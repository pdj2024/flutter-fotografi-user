import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/ulasan_model.dart';

class UlasanSection extends StatelessWidget {
  const UlasanSection(
      {super.key,
      required this.pesanan,
      this.ulasan,
      required this.onPressedBerikanUlasan});

  final PesananModel pesanan;
  final UlasanModel? ulasan;
  final VoidCallback onPressedBerikanUlasan;

  @override
  Widget build(BuildContext context) {
    if (ulasan == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressedBerikanUlasan,
          icon: const Icon(Icons.rate_review_outlined, size: 18),
          label: const Text('Berikan Ulasan',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Constants.primaryColor,
            side: BorderSide(color: Constants.primaryColor, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }
    return _buildUlasanCard();
  }

  Widget _buildUlasanCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Constants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.rate_review_rounded,
                    color: Constants.primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ulasan Anda',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      '${Helper.formatTanggal(ulasan!.tglUlasan)}, ${Helper.toLocalTime(ulasan!.tglUlasan)}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ...List.generate(
                  5,
                  (i) => Icon(
                        i < ulasan!.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: i < ulasan!.rating
                            ? Colors.amber
                            : Colors.grey.shade300,
                        size: 22,
                      )),
              const SizedBox(width: 8),
              Text(Helper.getRatingText(ulasan!.rating),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Helper.getRatingColor(ulasan!.rating))),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8)),
            child: Text(ulasan!.isiUlasan,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade800, height: 1.5)),
          ),
          if (ulasan!.adaBalasan == true &&
              ulasan!.isiBalasan != null &&
              ulasan!.isiBalasan!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.reply_rounded,
                          size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text('Balasan Vendor',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(ulasan!.isiBalasan!,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade800,
                          height: 1.5)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
