import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/models/paket_model.dart';
import 'package:mpjnew/src/data/models/portofolio_model.dart';
import 'package:mpjnew/src/features/customer/view/room_chat_page.dart';
import 'package:provider/provider.dart';

class OfferCard extends StatelessWidget {
  final PaketModel paket;
  final PortofolioModel portofolio;
  // final List<String> includes;

  const OfferCard({
    super.key,
    required this.portofolio,
    required this.paket,
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
            paket.nama_paket,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Helper.formatCurrency(paket.harga),
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
              paket.rincian,
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
                context.read<NavigationProvider>().navigateToPage(
                      context,
                      RoomChatPage(
                        roomId: null,
                        partnerId: portofolio.idVendor,
                        partnerUsername: portofolio.usernameVendor,
                        partnerAvatarUrl: portofolio.idMediaVendor,
                        paket: paket,
                      ),
                      targetTabIndex: 1,
                    );
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
