import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/data/models/refund_rule_model.dart';

/// Daftar seluruh ketentuan pengembalian dana (master refund), supaya customer
/// bisa melihat "kalau dibatalkan H-sekian dapat berapa" sebelum memutuskan.
///
/// [tierAktifId] diisi `RefundInfoModel.idRefund` kalau sedang membuka dari
/// konteks satu pesanan — baris yang sedang berlaku akan ditandai.
Future<void> showRefundRulesSheet(
  BuildContext context,
  List<RefundRuleModel> rules, {
  int? tierAktifId,
}) {
  final sorted = [...rules]..sort((a, b) => a.jamLimit.compareTo(b.jamLimit));

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.gavel_rounded,
                        color: Colors.black54, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ketentuan Pengembalian Dana',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text(
                          'Besaran refund mengikuti sisa waktu menuju jadwal pemotretan',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _RuleTile(
                  rule: sorted[i],
                  aktif: tierAktifId != null &&
                      tierAktifId.toString() == sorted[i].noId,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({required this.rule, required this.aktif});

  final RefundRuleModel rule;
  final bool aktif;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: aktif
            ? Constants.primaryColor.withOpacity(0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: aktif ? Constants.primaryColor : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Dibatalkan ≤ ${rule.jamLimit} jam sebelum pemotretan',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: aktif ? Constants.primaryColor : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${rule.persen.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: aktif ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            rule.keterangan,
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade700, height: 1.4),
          ),
          if (aktif) ...[
            const SizedBox(height: 6),
            Text(
              'Berlaku untuk pesanan ini',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Constants.primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
