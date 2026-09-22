import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/info_row.dart';

class LocationSection extends StatelessWidget {
  const LocationSection(
      {super.key, required this.pesanan, this.onExtendDeadline});

  final PesananModel pesanan;

  /// Diisi hanya kalau pesanan sedang di status yang bisa lewat batas
  /// pengerjaan (proses/review/revisi) -- logic API-nya dipegang parent.
  final VoidCallback? onExtendDeadline;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lokasi & Jadwal',
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Tanggal Pemotretan',
                  value: Helper.formatTanggal(pesanan.tglRealisasi)),
              const SizedBox(height: 10),
              InfoRow(
                  icon: Icons.access_time,
                  label: 'Waktu',
                  value: Helper.toLocalTime(pesanan.tglRealisasi)),
              const SizedBox(height: 10),
              InfoRow(
                  icon: Icons.hourglass_bottom_outlined,
                  label: 'Estimasi Pengerjaan',
                  value: Helper.formatEstimasiPengerjaan(
                      pesanan.estimasiPengerjaan)),
              if (pesanan.tglPengerjaanMax != null) ...[
                const SizedBox(height: 10),
                InfoRow(
                  icon: Icons.event_available_outlined,
                  label: 'Batas Pengerjaan',
                  value:
                      '${Helper.formatTanggal(pesanan.tglPengerjaanMax!)}, ${Helper.toLocalTime(pesanan.tglPengerjaanMax!)}',
                  trailing: (onExtendDeadline != null)
                      ? GestureDetector(
                          onTap: onExtendDeadline,
                          child: Text(
                            'Perpanjang',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Constants.primaryColor,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
              const SizedBox(height: 10),
              InfoRow(
                  icon: Icons.location_city_outlined,
                  label: 'Kota',
                  value: pesanan.namaKota ?? '-'),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 18, color: Colors.black45),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Alamat Lengkap',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 2),
                        Text(pesanan.lokasi,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
