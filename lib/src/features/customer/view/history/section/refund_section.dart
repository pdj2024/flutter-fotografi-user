import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/models/refund_transaksi_model.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/expandable_card.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/info_row.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/price_row.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/status_config.dart';

/// Rincian pengembalian dana pesanan yang dibatalkan, dari TransaksiRefund.
class RefundSection extends StatefulWidget {
  const RefundSection({super.key, required this.transaksi});

  final RefundTransaksiModel transaksi;

  @override
  State<RefundSection> createState() => _RefundSectionState();
}

class _RefundSectionState extends State<RefundSection> {
  bool isExpanded = false;

  // Warna badge memakai config refund yang sudah ada di status_config.
  StatusConfig get _cfg => getStatus(
        'dibatalkan',
        isRefundProcessing: !widget.transaksi.isPaid,
        isRefundDone: widget.transaksi.isPaid,
      );

  String get _label => widget.transaksi.isPaid
      ? 'Dana Sudah Dikembalikan'
      : 'Dana Sedang Diproses';

  String get _nominalCustomer => widget.transaksi.adaDanaCustomer
      ? Helper.formatCurrency(widget.transaksi.refundCust)
      : 'Tidak ada dana yang dikembalikan';

  Widget _badge() {
    final cfg = _cfg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cfg.color.withOpacity(0.4)),
      ),
      child: Text(
        _label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: cfg.color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaksi;
    return ExpandableCard(
      title: 'Pengembalian Dana',
      isExpanded: isExpanded,
      onToggle: () => setState(() => isExpanded = !isExpanded),
      summaryWidget: !isExpanded
          ? Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _badge(),
                  Flexible(
                    child: Text(
                      _nominalCustomer,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: t.adaDanaCustomer ? 15 : 12,
                        fontWeight: FontWeight.bold,
                        color: t.adaDanaCustomer
                            ? Constants.primaryColorVendor
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (t.adaDanaCustomer) ...[
            Align(alignment: Alignment.centerLeft, child: _badge()),
            const SizedBox(height: 12),
          ],
          if (t.refundTime != null) ...[
            InfoRow(
              label: 'Waktu Pengajuan',
              value: '${Helper.formatTanggal(t.refundTime!)}, '
                  '${Helper.toLocalTime(t.refundTime!)}',
              icon: Icons.schedule_outlined,
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          PriceRow(
            label: 'Jumlah refund',
            value: _nominalCustomer,
            isBold: true,
            valueColor: t.adaDanaCustomer
                ? Constants.primaryColorVendor
                : Colors.grey.shade600,
          ),
          if (t.isProses && t.adaDanaCustomer) ...[
            const SizedBox(height: 10),
            Text(
              'Dana diproses maksimal 2x24 jam. Jika belum diterima, '
              'silakan hubungi customer service.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
