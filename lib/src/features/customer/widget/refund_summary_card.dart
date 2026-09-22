import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/models/refund_info_model.dart';
import 'package:mpjnew/src/data/models/refund_rule_model.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/refund_rules_sheet.dart';

/// Ringkasan pengembalian dana: sisa waktu, aturan yang berlaku, dan nominal
/// yang diterima customer. Dipakai BERSAMA oleh dialog konfirmasi batal dan
/// RefundFormPage supaya angka & kalimat yang dilihat user identik di kedua
/// layar — jangan disalin ulang di salah satunya.
///
/// [info] null berarti server gagal dihubungi; kartu berubah jadi peringatan
/// bahwa nominal belum bisa dipastikan (pembatalan tetap boleh lanjut).
class RefundSummaryCard extends StatelessWidget {
  const RefundSummaryCard(
      {super.key, required this.info, this.rules, this.refundInfo});

  final RefundInfoModel? info;
  final List<RefundRuleModel>? rules;
  final RefundInfoModel? refundInfo;

  @override
  Widget build(BuildContext context) {
    final data = info;
    if (data == null) return const _RefundInfoUnavailable();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(
            Icons.schedule_rounded,
            'Sisa waktu sebelum pemotretan',
            _sisaWaktu(data.jamRemain),
            isValueBold: true,
          ),
          const SizedBox(height: 12),
          _infoRow(
              Icons.gavel_rounded,
              'Ketentuan yang berlaku',
              '• Refund Customer: ${_persen(data.persen)}\n'
                  '• Hak Vendor: ${_persen(100 - data.persen)}',
              trailing: (rules != null && rules!.isNotEmpty)
                  ? GestureDetector(
                      onTap: () => showRefundRulesSheet(
                            context,
                            rules!,
                            tierAktifId: refundInfo?.idRefund,
                          ),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(Icons.info_outline_rounded,
                            size: 16, color: Constants.primaryColor),
                      ))
                  : null),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dana yang dikembalikan',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.adaDanaKembali
                          ? Helper.formatCurrency(data.refundCustomer)
                          : 'Tidak ada dana yang dikembalikan',
                      style: TextStyle(
                        fontSize: data.adaDanaKembali ? 20 : 15,
                        color: data.adaDanaKembali
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.adaDanaKembali
                          ? 'Nominal di luar biaya administrasi dan biaya platform.'
                          : 'Sesuai ketentuan, seluruh pembayaran menjadi hak vendor.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 50 → "50%", 12.5 → "12.5%".
  String _persen(double p) =>
      '${p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toString()}%';

  /// `Helper.formatEstimasiPengerjaan` mengasumsikan jam non-negatif — sisa
  /// waktu minus akan keluar sebagai angka aneh karena modulo Dart selalu
  /// positif, jadi kasus lewat jadwal ditangani terpisah.
  String _sisaWaktu(double jamRemain) {
    if (jamRemain <= 0) return 'Jadwal pemotretan sudah lewat';
    return Helper.formatEstimasiPengerjaan(jamRemain.floor());
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Widget? trailing, bool isValueBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (trailing != null) trailing
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: !isValueBold ? Colors.black87 : Constants.primaryColor,
                  fontWeight: !isValueBold ? FontWeight.w500 : FontWeight.w900,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RefundInfoUnavailable extends StatelessWidget {
  const _RefundInfoUnavailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: Color(0xFFD97706)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nominal pengembalian dana belum bisa ditampilkan saat ini. '
              'Pembatalan tetap bisa dilanjutkan dan nominalnya akan '
              'dihitung oleh admin.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.brown.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
