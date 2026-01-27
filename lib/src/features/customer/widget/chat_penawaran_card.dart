import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';

class ChatPenawaranCard extends StatelessWidget {
  final PenawaranModel penawaran;
  final PaketModel? paket;
  final String roomId;
  final String customerId;
  final VoidCallback? onTap;

  const ChatPenawaranCard({
    super.key,
    required this.penawaran,
    required this.roomId,
    required this.customerId,
    required this.onTap,
    this.paket,
  });

  @override
  Widget build(BuildContext context) {
    final tanggal =
        DateFormat("dd MMM yyyy", "id_ID").format(penawaran.tglRealisasi);
    final waktu = Helper.toLocalTime(penawaran.tglRealisasi);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                        "Penawaran #${penawaran.noTrackingPenawaran}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Helper.formatCurrency(penawaran.harga),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Constants.primaryColor,
                        ),
                      ),
                    ],
                  ),
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
                  penawaran.namaPaket,
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
                  penawaran.lokasi,
                ),

                // Kota (jika berbeda dengan lokasi)
                if (penawaran.namaKota.isNotEmpty &&
                    !penawaran.lokasi
                        .toLowerCase()
                        .contains(penawaran.namaKota.toLowerCase())) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.location_city_outlined,
                    "Kota",
                    penawaran.namaKota,
                  ),
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
                  backgroundColor: Constants.primaryColor,
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
                    const Text(
                      "Lihat Detail & Pembayaran",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
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
}
