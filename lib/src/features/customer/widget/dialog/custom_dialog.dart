import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/models/metode_pembayaran_model.dart';
import 'package:mpjnew/src/data/models/paket_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/room_chat_provider.dart';
import 'package:mpjnew/src/features/customer/widget/payment_option.dart';
import 'package:provider/provider.dart';

class CustomDialog {
  static Future<void> showDetailPaketDialog({
    required BuildContext context,
    required PaketModel paket,
    bool isAsk = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final roomChatProvider = context.read<RoomChatProvider>();
        roomChatProvider.messageController.clear();

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: const Color(0xfff9f9f9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ICON
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Constants.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.card_giftcard,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // TITLE
                      Center(
                        child: Text(
                          paket.nama_paket,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      _detailItem("Harga", Helper.formatCurrency(paket.harga)),
                      const SizedBox(height: 10),

                      _detailItem("Rincian", paket.rincian),

                      const SizedBox(height: 20),

                      // MODE BERTANYA
                      if (isAsk)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller:
                                      roomChatProvider.messageController,
                                  // ✅ Auto expand kebawah
                                  minLines: 1,
                                  maxLines: 5,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                  cursorColor: Constants.primaryColor,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 16),
                                    hintText: "Tanyakan sesuatu...",
                                    filled: true,
                                    fillColor: const Color(0xFFE8E8E8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable:
                                    roomChatProvider.messageController,
                                builder: (context, value, _) {
                                  final hasText = value.text.trim().isNotEmpty;

                                  return AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    transitionBuilder: (child, anim) =>
                                        ScaleTransition(
                                            scale: anim, child: child),
                                    child: hasText
                                        ? IconButton(
                                            key: const ValueKey("sendButton"),
                                            icon: const Icon(Icons.send,
                                                color: Constants.primaryColor),
                                            onPressed: () async {
                                              final userId = context
                                                  .read<UserProvider>()
                                                  .userId!;

                                              Navigator.pop(context);
                                              roomChatProvider
                                                  .setTawaranPaket(paket);
                                              roomChatProvider.activeRoomId =
                                                  null;
                                              roomChatProvider.vendorId =
                                                  paket.id_vendor;

                                              await roomChatProvider
                                                  .sendMessage(
                                                currentUserId: userId,
                                              );

                                              context
                                                  .read<NavigationProvider>()
                                                  .navigateToPage(
                                                    context,
                                                    RoomChatPage(
                                                      partnerId:
                                                          paket.id_vendor,
                                                    ),
                                                  );
                                            },
                                          )
                                        : const SizedBox.shrink(),
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Constants.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Tutup",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  static Widget _detailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  static Future<void> showDetailPenawaranDialog({
    required BuildContext context,
    required PaketModel paket,
    bool isAsk = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final roomChatProvider = context.read<RoomChatProvider>();
        roomChatProvider.messageController.clear();

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: const Color(0xfff9f9f9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ICON
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Constants.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.card_giftcard,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // TITLE
                      Center(
                        child: Text(
                          paket.nama_paket,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      _detailItem("Harga", Helper.formatCurrency(paket.harga)),
                      const SizedBox(height: 10),

                      _detailItem("Rincian", paket.rincian),

                      const SizedBox(height: 20),

                      // MODE BERTANYA
                      if (isAsk)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller:
                                      roomChatProvider.messageController,
                                  // ✅ Auto expand kebawah
                                  minLines: 1,
                                  maxLines: 5,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                  cursorColor: Constants.primaryColor,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 16),
                                    hintText: "Tanyakan sesuatu...",
                                    filled: true,
                                    fillColor: const Color(0xFFE8E8E8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable:
                                    roomChatProvider.messageController,
                                builder: (context, value, _) {
                                  final hasText = value.text.trim().isNotEmpty;

                                  return AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    transitionBuilder: (child, anim) =>
                                        ScaleTransition(
                                            scale: anim, child: child),
                                    child: hasText
                                        ? IconButton(
                                            key: const ValueKey("sendButton"),
                                            icon: const Icon(Icons.send,
                                                color: Constants.primaryColor),
                                            onPressed: () async {
                                              final userId = context
                                                  .read<UserProvider>()
                                                  .userId!;

                                              Navigator.pop(context);
                                              roomChatProvider
                                                  .setTawaranPaket(paket);
                                              roomChatProvider.activeRoomId =
                                                  null;
                                              roomChatProvider.vendorId =
                                                  paket.id_vendor;

                                              await roomChatProvider
                                                  .sendMessage(
                                                currentUserId: userId,
                                              );

                                              context
                                                  .read<NavigationProvider>()
                                                  .navigateToPage(
                                                    context,
                                                    RoomChatPage(
                                                      partnerId:
                                                          paket.id_vendor,
                                                    ),
                                                  );
                                            },
                                          )
                                        : const SizedBox.shrink(),
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Constants.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Tutup",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  static void showPaymentMethodDialog({
    required BuildContext context,
    required List<MetodePembayaranModel> metodePembayaran,
    required String? currentKodeMetode,
    required Function(String kode, String text, int fee) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                Constants.primaryColorVendor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.payment_rounded,
                            color: Constants.primaryColorVendor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Metode Pembayaran",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Pilih metode yang Anda inginkan",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: Colors.grey.shade200),

                  // List
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: metodePembayaran.length,
                      itemBuilder: (context, index) {
                        final metode = metodePembayaran[index];
                        final isSelected =
                            currentKodeMetode == metode.caraBayar;

                        return PaymentOption(
                          title: metode.display,
                          subtitle: metode.deskripsi,
                          fee: metode.fee,
                          method: metode.caraBayar,
                          isSelected: isSelected,
                          onTap: () {
                            onSelected(
                              metode.caraBayar,
                              metode.display,
                              metode.fee,
                            );
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
