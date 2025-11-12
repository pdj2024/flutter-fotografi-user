import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';

class PackageCard extends StatelessWidget {
  final String title;
  final String price;
  final String rincian;
  const PackageCard(
      {super.key,
      required this.title,
      required this.price,
      required this.rincian});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris judul & harga
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul paket - bisa wrap
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  softWrap: true,
                ),
              ),
              const SizedBox(width: 8),
              // Harga - tetap kanan, tidak wrap
              Text(
                price,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Rincian paket - auto wrap & multi-line
          Text(
            rincian,
            style: const TextStyle(fontSize: 13),
            softWrap: true,
          ),

          const SizedBox(height: 12),

          // Tombol di kanan bawah
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                // NavigationProvider().navigateToPage(
                //   context,
                //   SingleChat(
                //     receiverUserName: widget.userName,
                //     receiverEmail: "hello@gmail.com",
                //     receiverID: widget.idVendor,
                //   ),
                //   targetTabIndex: 1,
                // );
              },
              child: const Text(
                'Atur Jadwal',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          
        ],
      ),
    );
  }
}
