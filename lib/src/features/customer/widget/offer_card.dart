import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/models/paket_model.dart';
import 'package:mpjnew/src/features/customer/viewmodels/room_chat_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_dialog.dart';
import 'package:provider/provider.dart';

class OfferCard extends StatelessWidget {
  final PaketModel paket;
  final bool isPreview;
  final VoidCallback onSend;
  const OfferCard(
      {super.key,
      required this.paket,
      this.isPreview = true,
      required this.onSend});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        context.read<RoomChatProvider>().setTawaranPaket(paket);
        CustomDialog.showDetailPaketDialog(
          context: context,
          paket: paket,
          isAsk: true,
          onSend: onSend,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(1, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// --- TITLE + PRICE + EDIT ICON ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    paket.nama_paket,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  Helper.formatCurrency(paket.harga),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Constants.primaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 10),

            ..._buildRincianList(paket.rincian),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<RoomChatProvider>().setTawaranPaket(paket);
                  CustomDialog.showDetailPaketDialog(
                    context: context,
                    paket: paket,
                    isAsk: true,
                    onSend: onSend,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  overlayColor: Constants.primaryColorVendor.withAlpha(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(15),
                    side: BorderSide(
                      width: 2,
                      color: Constants.primaryColorVendor,
                    ),
                  ),
                ),
                child: Text(
                  "Lihat Paket",
                  style: TextStyle(
                    color: Constants.primaryColorVendor,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRincianList(String rincian, {int maxLines = 3}) {
    final list = rincian.split('\n').where((e) => e.trim().isNotEmpty).toList();

    final visibleItems = list.take(maxLines).toList();
    final hasMore = list.length > maxLines;

    return [
      ...visibleItems.map(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("• ", style: TextStyle(fontSize: 14, height: 1.4)),
              Expanded(
                child: Text(
                  item.trim(),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      /// indikator ada lanjutan
      if (hasMore)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            "+${list.length - maxLines} lainnya",
            style: TextStyle(
              fontSize: 13,
              color: Constants.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
    ];
  }
}
