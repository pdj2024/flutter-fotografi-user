import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';

class ChatPackageCard extends StatelessWidget {
  final String namaPaket;
  final int hargaPaket;
  final bool isMe;

  const ChatPackageCard(
      {super.key,
      required this.namaPaket,
      required this.hargaPaket,
      required this.isMe});

  @override
  Widget build(BuildContext context) {
    final formattedHarga = NumberFormat("#,###", "id_ID").format(hargaPaket);
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isMe
              ? null
              : [
                  const BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleText,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: innerContainerColor,
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
                          namaPaket,
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
          ],
        ),
      ),
    );
  }
}
