import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';

class OrderCard extends StatelessWidget {
  final PesananModel pesanan;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.onTap,
    required this.pesanan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        // ⭐ kunci utama
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// LEFT CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pesanan.namaPaket,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pesanan.namaVendor ?? "",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Helper.formatCurrency(pesanan.harga),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            /// RIGHT CONTENT (TIME TOP - BUTTON BOTTOM)
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// ⏰ TIME (TOP RIGHT)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    Helper.toLocalTime(
                      pesanan.updatedAt ?? pesanan.createdAt!,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),

                /// 🔘 BUTTON (BOTTOM RIGHT)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      onPressed: onTap,
                      child: const Text(
                        "Detil",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
