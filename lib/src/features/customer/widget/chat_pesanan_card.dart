import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';

class ChatPesananCard extends StatelessWidget {
  final PesananModel pesanan;
  final bool isPesanan;
  final PaketModel? paket;
  final String roomId;
  final String customerId;
  final VoidCallback? onTap;

  const ChatPesananCard({
    super.key,
    required this.pesanan,
    required this.roomId,
    required this.customerId,
    required this.onTap,
    this.paket,
    this.isPesanan = false,
  });

  @override
  Widget build(BuildContext context) {
    final tanggal = Helper.formatTanggal(pesanan.tglRealisasi);
    final waktu = Helper.toLocalTime(pesanan.tglRealisasi);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Constants.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pesanan #${pesanan.noTrackingPesanan ?? pesanan.noBukti}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Helper.formatCurrency(pesanan.grandTotal),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Constants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Status Progress Badge
                    if (pesanan.statusBayar == "settlement")
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getProgressStatusColor(),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getProgressStatusText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    // Payment Status Badge
                    if (pesanan.statusBayar != null &&
                        pesanan.statusBayar!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getPaymentStatusColor(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getPaymentStatusIcon(),
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getPaymentStatusText(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Detail informasi
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama Paket
                _buildInfoRow(
                  Icons.inventory_2_outlined,
                  "Paket",
                  pesanan.namaPaket,
                ),
                const SizedBox(height: 12),

                // Tanggal & Waktu
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  "Tanggal Realisasi",
                  "$waktu, $tanggal",
                ),
                const SizedBox(height: 12),

                // Lokasi
                _buildInfoRow(
                  Icons.location_on_outlined,
                  "Lokasi",
                  pesanan.lokasi,
                ),

                // Kota (jika berbeda dengan lokasi)
                if (pesanan.namaKota != null &&
                    pesanan.namaKota!.isNotEmpty &&
                    !pesanan.lokasi
                        .toLowerCase()
                        .contains(pesanan.namaKota!.toLowerCase())) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.location_city_outlined,
                    "Kota",
                    pesanan.namaKota!,
                  ),
                ],

                // Payment Method
                if (pesanan.metodeBayar != null &&
                    pesanan.metodeBayar!.isNotEmpty &&
                    pesanan.statusBayar != "settlement") ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.payment_outlined,
                    "Metode Pembayaran",
                    _formatPaymentMethod(pesanan.metodeBayar!),
                  ),
                ],

                // Expiry Time (untuk pesanan yang belum dibayar)
                if (_shouldShowExpiry()) ...[
                  const SizedBox(height: 12),
                  _buildExpiryInfo(),
                ],

                // Progress Description (jika ada)
                if (pesanan.deskripsiProgresPesanan != null &&
                    pesanan.deskripsiProgresPesanan!.isNotEmpty &&
                    pesanan.statusBayar == "settlement") ...[
                  const SizedBox(height: 12),
                  _buildProgressDescription(),
                ],
              ],
            ),
          ),

          // Tombol Action
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getButtonColor(),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getButtonIcon(), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _getButtonText(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressDescription() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pesanan.deskripsiProgresPesanan!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade900,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowExpiry() {
    return pesanan.expiryTime != null &&
        pesanan.statusBayar?.toLowerCase() == 'belum bayar' &&
        (pesanan.statusProgresPesanan?.toLowerCase() == 'menunggu bayar' ||
            pesanan.statusProgresPesanan == null);
  }

  Widget _buildExpiryInfo() {
    final now = DateTime.now();
    final expiry = pesanan.expiryTime!;
    final isExpired = expiry.isBefore(now);
    final timeLeft = expiry.difference(now);

    String expiryText;
    Color expiryColor;
    IconData expiryIcon;

    if (isExpired) {
      expiryText = "Pembayaran telah kadaluarsa";
      expiryColor = Colors.red;
      expiryIcon = Icons.error_outline;
    } else if (timeLeft.inMinutes < 30) {
      expiryText = "Berakhir dalam ${timeLeft.inMinutes} menit lagi!";
      expiryColor = Colors.red;
      expiryIcon = Icons.warning_amber_rounded;
    } else if (timeLeft.inHours < 1) {
      expiryText = "Berakhir dalam ${timeLeft.inMinutes} menit";
      expiryColor = Colors.orange;
      expiryIcon = Icons.access_time;
    } else if (timeLeft.inHours < 24) {
      expiryText =
          "Berakhir dalam ${timeLeft.inHours} jam ${timeLeft.inMinutes % 60} menit";
      expiryColor = Colors.orange;
      expiryIcon = Icons.access_time;
    } else {
      expiryText =
          "Berakhir ${DateFormat('dd MMM, HH:mm', 'id_ID').format(expiry)}";
      expiryColor = Colors.blue;
      expiryIcon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: expiryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: expiryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            expiryIcon,
            size: 18,
            color: expiryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              expiryText,
              style: TextStyle(
                fontSize: 12,
                color: expiryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // STATUS PROGRESS PESANAN
  // ========================================
  Color _getProgressStatusColor() {
    final status = pesanan.statusProgresPesanan?.toLowerCase() ?? '';

    switch (status) {
      case 'menunggu bayar':
        return Colors.orange;
      case 'persiapan':
        return Colors.blue;
      case 'proses':
        return Colors.indigo;
      case 'review':
        return Colors.purple;
      case 'revisi':
        return Colors.amber;
      case 'selesai':
        return Colors.green;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getProgressStatusText() {
    final status = pesanan.statusProgresPesanan?.toLowerCase() ?? '';

    switch (status) {
      case 'menunggu bayar':
        return 'Menunggu Bayar';
      case 'persiapan':
        return 'Persiapan';
      case 'proses':
        return 'Proses';
      case 'review':
        return 'Review';
      case 'revisi':
        return 'Revisi';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status.isEmpty ? 'Tidak Diketahui' : status;
    }
  }

  // ========================================
  // STATUS BAYAR
  // ========================================
  Color _getPaymentStatusColor() {
    final status = pesanan.statusBayar?.toLowerCase() ?? '';

    switch (status) {
      case 'belum bayar':
        return Colors.orange.shade700;
      case 'settlement':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _getPaymentStatusText() {
    final status = pesanan.statusBayar?.toLowerCase() ?? '';

    switch (status) {
      case 'belum bayar':
        return 'Belum Bayar';
      case 'settlement':
        return 'Lunas';
      default:
        return status.isEmpty ? 'N/A' : status;
    }
  }

  IconData _getPaymentStatusIcon() {
    final status = pesanan.statusBayar?.toLowerCase() ?? '';

    switch (status) {
      case 'belum bayar':
        return Icons.pending_outlined;
      case 'settlement':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  // ========================================
  // BUTTON CONFIGURATION
  // ========================================
  String _getButtonText() {
    final paymentStatus = pesanan.statusBayar?.toLowerCase() ?? '';
    final progressStatus = pesanan.statusProgresPesanan?.toLowerCase() ?? '';

    // Prioritas berdasarkan status pembayaran dan progress
    if (paymentStatus == 'belum bayar' && progressStatus == 'menunggu bayar') {
      return 'Bayar Sekarang';
    } else if (paymentStatus == 'settlement') {
      if (progressStatus == 'selesai') {
        return 'Lihat Detail';
      } else if (progressStatus == 'review' || progressStatus == 'revisi') {
        return 'Cek Progress';
      } else {
        return 'Lihat Progress';
      }
    } else if (progressStatus == 'dibatalkan') {
      return 'Lihat Detail';
    } else {
      return 'Lihat Pesanan';
    }
  }

  Color _getButtonColor() {
    final paymentStatus = pesanan.statusBayar?.toLowerCase() ?? '';
    final progressStatus = pesanan.statusProgresPesanan?.toLowerCase() ?? '';

    if (progressStatus == 'dibatalkan') {
      return Colors.grey;
    } else {
      return Constants.primaryColor;
    }
  }

  IconData _getButtonIcon() {
    final paymentStatus = pesanan.statusBayar?.toLowerCase() ?? '';
    final progressStatus = pesanan.statusProgresPesanan?.toLowerCase() ?? '';

    if (paymentStatus == 'belum bayar' && progressStatus == 'menunggu bayar') {
      return Icons.payment;
    } else if (progressStatus == 'review' || progressStatus == 'revisi') {
      return Icons.rate_review_outlined;
    } else if (progressStatus == 'selesai') {
      return Icons.check_circle_outline;
    } else {
      return Icons.arrow_forward;
    }
  }

  // ========================================
  // UTILITIES
  // ========================================
  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'bca_va':
        return 'BCA Virtual Account';
      case 'bni_va':
        return 'BNI Virtual Account';
      case 'bri_va':
        return 'BRI Virtual Account';
      case 'mandiri_va':
        return 'Mandiri Virtual Account';
      case 'permata_va':
        return 'Permata Virtual Account';
      case 'gopay':
        return 'GoPay';
      case 'qris':
        return 'QRIS';
      case 'shopeepay':
        return 'ShopeePay';
      case 'credit_card':
        return 'Kartu Kredit';
      case 'debit_card':
        return 'Kartu Debit';
      case 'cod':
        return 'Cash on Delivery';
      default:
        return method.toUpperCase();
    }
  }
}
