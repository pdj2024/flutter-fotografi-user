import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/expandable_card.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/status_config.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:provider/provider.dart';

class ProgressSection extends StatefulWidget {
  const ProgressSection({super.key, required this.pesanan});

  final PesananModel pesanan;

  @override
  State<ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<ProgressSection> {
  StatusConfig _cfg(String status) => getStatus(status);

  @override
  Widget build(BuildContext context) {
    bool isProgressExpanded = true;

    return Consumer<HistoryOrderProvider>(
      builder: (context, hp, _) {
        final histories = hp.getHistoryForOrder(widget.pesanan.noBukti);
        final isLoadingH = hp.isLoadingOrder(widget.pesanan.noBukti);
        final errorH = hp.getErrorForOrder(widget.pesanan.noBukti);

        if (isLoadingH && histories.isEmpty) return _buildProgressShimmer();
        if (errorH != null && histories.isEmpty) {
          return _buildProgressError(errorH, widget.pesanan.noBukti,
              () => hp.fetchHistoryForOrder(widget.pesanan.noBukti));
        }

        final revisiNumberMap = <int, int>{};
        int revisiCount = 0;
        for (int i = histories.length - 1; i >= 0; i--) {
          if (histories[i].statusProgressPesanan == 'revisi') {
            revisiCount++;
            revisiNumberMap[i] = revisiCount;
          }
        }

        return ExpandableCard(
          title: 'Riwayat Progress',
          isExpanded: isProgressExpanded,
          onToggle: () =>
              setState(() => isProgressExpanded = !isProgressExpanded),
          summaryWidget: !isProgressExpanded && histories.isNotEmpty
              ? _buildProgressSummaryRow(histories.first)
              : null,
          content: histories.isEmpty
              ? _buildProgressEmpty()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...List.generate(
                      histories.length,
                      (i) => _buildTimelineItem(
                        histories[i],
                        isFirst: i == 0,
                        isLast: i == histories.length - 1,
                        revisiNumber: revisiNumberMap[i],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildProgressShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: 14,
              width: 100,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 14),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            height: 10,
                            width: 70,
                            decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 5),
                        Container(
                            height: 12,
                            decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummaryRow(HistoryOrderModel history) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: Constants.primaryColorVendor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              history.deskripsi,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500),
            ),
          ),
          _buildLiveBadge(),
        ],
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
                color: Colors.green, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text('Live',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(HistoryOrderModel history,
      {required bool isFirst, required bool isLast, int? revisiNumber}) {
    // ✅ Warna & label dari _cfg() + OrderStatusFlow.displayLabel
    final cfg = _cfg(history.statusProgressPesanan);
    final dotColor = isFirst ? cfg.color : Colors.grey.shade400;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${Helper.formatTanggal(history.tglProgress)}, ${Helper.toLocalTime(history.tglProgress)}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      if (revisiNumber != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isFirst ? cfg.bgColor : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Revisi ke-$revisiNumber',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color:
                                    isFirst ? cfg.color : Colors.grey.shade500),
                          ),
                        ),
                    ],
                  ),
                  if (revisiNumber == null) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isFirst ? cfg.bgColor : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        cfg.label,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isFirst ? cfg.color : Colors.grey.shade500),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  if (history.statusProgressPesanan == 'revisi' ||
                      (history.statusProgressPesanan == 'proses' &&
                          history.deskripsi.toLowerCase().contains('revisi')))
                    _buildRevisionNote(history.deskripsi, cfg)
                  else
                    Text(
                      history.deskripsi,
                      style: TextStyle(
                        fontSize: 14,
                        color: isFirst
                            ? Constants.primaryColorVendor
                            : Colors.black54,
                        fontWeight:
                            isFirst ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevisionNote(String deskripsi, StatusConfig cfg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cfg.bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: cfg.color, width: 3)),
      ),
      child: Text(deskripsi,
          style: TextStyle(
              fontSize: 13, color: Colors.grey.shade800, height: 1.4)),
    );
  }

  Widget _buildProgressEmpty() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.timeline_rounded, size: 52, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text('Belum ada riwayat progress',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildProgressError(String msg, String noBukti, VoidCallback onRetry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 8),
          Text('Gagal memuat progress',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(msg,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColorVendor,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
