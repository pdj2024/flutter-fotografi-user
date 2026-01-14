import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/models/paket_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/room_chat_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_dialog.dart';
import 'package:provider/provider.dart';

class OfferCard extends StatelessWidget {
  final PaketModel paket;
  final String vendorId; // ✅ Tambahkan vendorId
  final bool isPreview;
  final VoidCallback? onSend;

  const OfferCard({
    super.key,
    required this.paket,
    required this.vendorId, // ✅ Required
    this.isPreview = true,
    this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showDetailDialog(context),
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
                SizedBox(width: 10),
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
                onPressed: () => _showDetailDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  overlayColor: Constants.primaryColorVendor.withAlpha(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
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

  void _showDetailDialog(BuildContext context) {
    final roomChatProv = context.read<RoomChatProvider>();
    final userProv = context.read<UserProvider>();

    CustomDialog.showDetailPaketDialog(
      context: context,
      paket: paket,
      isAsk: true,
      onSend: () async {
        // ✅ Send message dengan explicit vendorId
        final currentUserId = userProv.userId;
        if (currentUserId == null) {
          debugPrint('❌ No userId, cannot send');
          return;
        }
        // Callback jika ada
        onSend?.call();
      },
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
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
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
