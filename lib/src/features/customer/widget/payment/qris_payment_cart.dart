import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:permission_handler/permission_handler.dart';

class QrisPaymentCard extends StatelessWidget {
  final String qrUrl;
  final int amount;
  const QrisPaymentCard({super.key, required this.qrUrl, required this.amount});

  Future<void> _downloadQrCode(BuildContext context) async {
    if (qrUrl.isEmpty) {
      CustomSnackbar.showErrorSnackbar(context, "QR Code tidak tersedia!");
      return;
    }

    try {
      // Show loading

      // Request storage permission (for Android)
      var status = await Permission.storage.request();
      if (status.isDenied) {
        if (!context.mounted) return;
        CustomSnackbar.showErrorSnackbar(
            context, "Izin penyimpanan diperlukan untuk mengunduh QR Code");

        return;
      }

      // Download image
      final response = await http.get(Uri.parse(qrUrl));

      if (response.statusCode == 200) {
        // Save to gallery
        final result = await ImageGallerySaver.saveImage(
          response.bodyBytes,
          quality: 100,
          name: "QRIS_Payment_${DateTime.now().millisecondsSinceEpoch}",
        );

        if (!context.mounted) return;

        if (result['isSuccess'] == true) {
          CustomSnackbar.showSuccessSnackbar(
              context, "QR Code berhasil disimpan");
        } else {
          throw Exception("Gagal menyimpan gambar");
        }
      } else {
        throw Exception("Gagal mengunduh QR Code");
      }
    } catch (e) {
      if (!context.mounted) return;
      CustomSnackbar.showErrorSnackbar(
          context, "Gagal mengunduh QR Code: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: Color(0xFF7C3AED),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "QRIS",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Scan dengan e-wallet",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: qrUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            qrUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF7C3AED),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.qr_code_2,
                                  size: 60,
                                  color: Color(0xFFD1D5DB),
                                ),
                              );
                            },
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.qr_code_2,
                            size: 60,
                            color: Color(0xFFD1D5DB),
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Download Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadQrCode(context),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text(
                      "Unduh QR Code",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                      side: const BorderSide(
                          color: Color(0xFF7C3AED), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Total Amount
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF7C3AED).withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Bayar",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        Helper.formatCurrency(amount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Instructions
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Cara Pembayaran",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 10),
                _buildInstruction("Buka e-wallet (GoPay, OVO, DANA, dll)"),
                _buildInstruction("Pilih Scan QR atau Bayar"),
                _buildInstruction("Scan QR di atas atau upload dari galeri"),
                _buildInstruction("Konfirmasi pembayaran", isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF7C3AED),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
