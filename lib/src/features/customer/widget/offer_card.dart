import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/models/ulasan_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/view/paket_ulasan_list_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/room_chat_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_dialog.dart';
import 'package:provider/provider.dart';

class OfferCard extends StatelessWidget {
  final PaketModel paket;
  final String vendorId;
  final bool isPreview;
  final List<UlasanModel>? ulasanList;
  final VoidCallback? onSend;

  const OfferCard({
    super.key,
    required this.paket,
    required this.vendorId,
    this.isPreview = true,
    this.onSend,
    this.ulasanList,
  });

  @override
  Widget build(BuildContext context) {
    final hasUlasan = ulasanList != null && ulasanList!.isNotEmpty;

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
            // Header - Nama Paket & Harga
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    paket.nama_paket,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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

            // Rincian Paket
            ..._buildRincianList(paket.rincian),

            const SizedBox(height: 12),
            // Bagian Ulasan (jika ada)
            if (hasUlasan)
              _buildUlasanSection(context)
            else
              _buildEmptyUlasanSection(),
            const SizedBox(height: 10),

            // Button Lihat Paket
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showDetailDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  overlayColor: Constants.primaryColorVendor.withAlpha(20),
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// ✅ Widget untuk ulasan yang ada
  Widget _buildUlasanSection(BuildContext context) {
    // Hitung rating dari ulasanList yang actual
    final totalUlasan = ulasanList?.length ?? 0;

    double rating = 0.0;
    if (totalUlasan > 0) {
      final totalRating = ulasanList!.fold<int>(
        0,
        (sum, ulasan) => sum + ulasan.rating,
      );
      rating = totalRating / totalUlasan;
    }

    debugPrint(
        '[OfferCard] 📊 Paket ${paket.nama_paket}: $totalUlasan ulasan, rating: $rating');

    return InkWell(
      onTap: () {
        context.read<NavigationProvider>().navigateToPage(
              context,
              PaketUlasanListPage(
                paket: paket,
                initialUlasanList: ulasanList,
              ),
              hrsLogin: true,
              targetTabIndex: 3,
            );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade50,
              Colors.amber.shade100.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.amber.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon & Rating
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: Colors.amber.shade700,
                    size: 22,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Info Ulasan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$totalUlasan ulasan",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getRatingDescription(rating),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Button Arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.amber.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Lihat",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: Colors.amber.shade900,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Widget untuk ulasan kosong
  Widget _buildEmptyUlasanSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.rate_review_outlined,
              color: Colors.grey.shade400,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          // Info Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Belum ada ulasan",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Paket ini belum memiliki ulasan dari customer",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingDescription(double rating) {
    if (rating >= 4.5) return "Sangat Memuaskan";
    if (rating >= 4.0) return "Memuaskan";
    if (rating >= 3.5) return "Baik";
    if (rating >= 3.0) return "Cukup Baik";
    if (rating >= 2.5) return "Kurang Baik";
    return "Perlu Ditingkatkan";
  }

  void _showDetailDialog(BuildContext context) {
    final roomChatProv = context.read<RoomChatProvider>();
    final userProv = context.read<UserProvider>();

    CustomDialog.showDetailPaketDialog(
      context: context,
      paket: paket,
      isAsk: true,
      onSend: () async {
        final currentUserId = userProv.userId;
        if (currentUserId == null) {
          debugPrint('❌ No userId, cannot send');
          return;
        }
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
              Text(
                "• ",
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Constants.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
      if (hasMore)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            "+${list.length - maxLines} item lainnya",
            style: TextStyle(
              fontSize: 13,
              color: Constants.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
    ];
  }
}
