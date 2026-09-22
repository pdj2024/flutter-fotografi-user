import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/status_config.dart';
import 'package:mpjnew/src/features/customer/viewmodels/ui_state_provider.dart';
import 'package:mpjnew/src/features/customer/widget/order_status_flow.dart';
import 'package:provider/provider.dart';

class HeaderInfoCard extends StatelessWidget {
  const HeaderInfoCard(
      {super.key,
      required this.status,
      required this.pesanan,
      this.haveComplain = false,});
  final String status;
  final PesananModel pesanan;
  final bool haveComplain;

  StatusConfig _cfg(String status) => getStatus(status);

  @override
  Widget build(BuildContext context) {
    // ── Ambil info dari customerInfoLabel — teks & icon dari satu sumber ──
    final infoLabel = OrderStatusFlow.customerInfoLabel(status);

    StatusConfig cfg = _cfg(status);
    Color borderColor = cfg.color;
    Color bgColor = cfg.bgColor;
    IconData icon = cfg.icon;

    String shortText;
    String fullText = infoLabel.body;

    // Override khusus untuk status persiapan berdasarkan tanggal
    if (haveComplain) {
      // Complain butuh perhatian lebih dari status lain -- warna oranye-
      // kemerahan yang lebih kontras/danger daripada palet status biasa.
      bgColor = const Color(0xFFFFEDE5);
      borderColor = const Color(0xFFEA580C);
      icon = Icons.report_problem_outlined;
      fullText = 'Complain untuk pesanan ini sedang dalam proses. Tim kami akan segera menindaklanjuti.';
    } else if (status == 'persiapan') {
      final now = DateTime.now();
      final tglRealisasi = pesanan.tglRealisasi;
      final today = DateTime(now.year, now.month, now.day);
      final tglShoot = tglRealisasi != null
          ? DateTime(tglRealisasi.year, tglRealisasi.month, tglRealisasi.day)
          : null;

      if (tglShoot == null) {
        fullText = infoLabel.body;
      } else if (today.isBefore(tglShoot)) {
        bgColor = Colors.grey.shade50;
        borderColor = Colors.grey.shade400;
        icon = Icons.schedule_rounded;
        fullText =
            'Pemotretan dijadwalkan pada ${Helper.formatTanggal(tglRealisasi!)}. '
            'Tombol konfirmasi sudah tersedia — tekan kapan saja setelah sesi pemotretan selesai dilaksanakan.';
      } else if (today.isAtSameMomentAs(tglShoot)) {
        icon = Icons.camera_alt_outlined;
        fullText = 'Pemotretan dijadwalkan hari ini. Setelah sesi selesai, '
            'segera tekan tombol Konfirmasi Pemotretan Selesai di bawah '
            'agar vendor dapat mulai mengerjakan hasil foto Anda.';
      } else {
        bgColor = _cfg('proses').bgColor;
        borderColor = _cfg('proses').color;
        icon = Icons.warning_amber_rounded;
        fullText = 'Pemotretan sudah melewati tanggal yang dijadwalkan '
            '(${Helper.formatTanggal(tglRealisasi!)}). '
            'Segera konfirmasi jika sesi telah selesai dilaksanakan.';
      }
    }

    if (fullText.isEmpty) return const SizedBox.shrink();

    // Potong kalimat pertama untuk shortText
    final dotSpace = fullText.indexOf('. ');
    if (dotSpace != -1) {
      shortText = fullText.substring(0, dotSpace + 1);
    } else {
      const maxShort = 60;
      shortText = fullText.length > maxShort
          ? '${fullText.substring(0, maxShort).trimRight()}...'
          : fullText;
    }

    final isExpanded = context.select<UiStateProvider, bool>(
      (p) => p.headerInfoExpanded,
    );

    final bool canExpand = shortText.trim() != fullText.trim();

    return GestureDetector(
      onTap: canExpand
          ? () => context.read<UiStateProvider>().toggleHeaderInfo()
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: borderColor),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedCrossFade(
                    firstChild: Text(
                      shortText,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          height: 1.5),
                    ),
                    secondChild: Text(
                      fullText,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          height: 1.5),
                    ),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                  ),
                ),
              ],
            ),
            if (canExpand) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  isExpanded ? 'Sembunyikan' : 'Selengkapnya',
                  style: TextStyle(
                    fontSize: 12,
                    color: borderColor,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: borderColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
