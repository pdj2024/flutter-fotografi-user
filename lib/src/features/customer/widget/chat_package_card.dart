import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/paket_detail_modal.dart';

class ChatPackageCard extends StatelessWidget {
  final PaketModel paket;
  final bool isMe;
  final VoidCallback onTap;

  const ChatPackageCard({
    super.key,
    required this.isMe,
    required this.paket,
    required this.onTap,
  });

  void _showDetailModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => PackageDetailModal(
        paket: paket,
        onCreateOffer: onTap,
        showOfferButton: isMe, // Only show for sent packages
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Check if description is longer than 3 lines (approximate)
    final hasLongDescription = paket.rincian.length > 120;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => _showDetailModal(context),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 250),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 5),
              bottomRight: Radius.circular(isMe ? 5 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Header with icon and label
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? Constants.primaryColorVendor.withOpacity(0.04)
                      : Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Constants.primaryColorVendor.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.card_giftcard_rounded,
                        size: 16,
                        color: isMe
                            ? Constants.primaryColorVendor
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isMe ? 'Paket Ditanyakan' : 'Paket Ditawarkan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isMe
                              ? Constants.primaryColorVendor
                              : Colors.grey.shade700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ Main content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Package name
                    Text(
                      paket.nama_paket,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.3,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Price with icon
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Constants.primaryColorVendor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        Helper.formatCurrency(paket.harga),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Constants.primaryColorVendor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),

                    // ✅ Description (LIMITED TO 3 LINES)
                    if (paket.rincian.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              paket.rincian,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                              maxLines: 3, // ✅ LIMITED TO 3 LINES
                              overflow: TextOverflow.ellipsis,
                            ),
                            // ✅ Show "read more" indicator if text is truncated
                            if (hasLongDescription) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Lihat selengkapnya...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Constants.primaryColorVendor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _showDetailModal(context),
                    child: Text(
                      "Lihat detail paket",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              )
            ],
          ),
        ),
      ),
    );
  }
}
