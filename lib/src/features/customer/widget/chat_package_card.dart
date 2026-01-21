import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_dialog.dart';

class ChatPackageCard extends StatelessWidget {
  final PaketModel paket;
  final bool isMe;

  const ChatPackageCard({super.key, required this.isMe, required this.paket});

  @override
  Widget build(BuildContext context) {
    final formattedHarga = NumberFormat("#,###", "id_ID").format(paket.harga);
    final backgroundColor =
        isMe ? Constants.primaryColor.withOpacity(0.1) : Colors.white;
    final innerContainerColor = isMe ? Colors.white : const Color(0xFFF5F5F5);
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final titleText = isMe
        ? "Kamu bertanya tentang paket ini"
        : "Vendor mengajukan paket ini";

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleText,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                CustomDialog.showDetailPaketDialog(
                    context: context, paket: paket);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: innerContainerColor,
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    const BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    )
                  ],
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard,
                        color: Constants.primaryColor, size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            paket.nama_paket,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "IDR $formattedHarga",
                            style: const TextStyle(
                                fontSize: 14,
                                color: Constants.primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
