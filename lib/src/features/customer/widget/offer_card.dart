import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';

class OfferCard extends StatelessWidget {
  final String title;
  final String price;
  final String rincian;
  // final List<String> includes;

  const OfferCard(
      {super.key,
      required this.title,
      required this.price,
      required this.rincian
      // required this.includes,
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text(
            "Rincian",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          // ...includes.map((item) => Padding(
          //       padding: const EdgeInsets.only(bottom: 2),
          //       child: Text("• $item", style: const TextStyle(fontSize: 13)),
          //     )),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              rincian,
              style: const TextStyle(fontSize: 13),
              softWrap: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Constants.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                // context.read<NavigationProvider>().navigateToPage(
                //       context,
                //       SingleChat(
                //         receiverUserName: 'helooo',
                //         receiverEmail: "hello@gmail.com",
                //         receiverID: '123',
                //       ),
                //       targetTabIndex: 1,
                //     );
              },
              child: const Text(
                "Atur Jadwal",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}