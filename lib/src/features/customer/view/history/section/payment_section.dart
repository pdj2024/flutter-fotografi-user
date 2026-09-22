import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/metode_pembayaran_model.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/expandable_card.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/info_row.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/price_row.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/status_config.dart';
import 'package:mpjnew/src/features/customer/view/payment/detail_pembayaran_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:provider/provider.dart';

class PaymentSection extends StatefulWidget {
  const PaymentSection(
      {super.key, required this.pesanan, this.metodePembayaran});

  final PesananModel pesanan;
  final MetodePembayaranModel? metodePembayaran;

  @override
  State<PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends State<PaymentSection> {
  StatusConfig _cfg(String status) => getStatus(status);

  bool isPaymentExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isPaid = widget.pesanan.statusBayar == 'settlement' ||
        widget.pesanan.statusBayar == 'capture';
    // ✅ Warna dari getStatus — bukan hardcode Colors.green / Colors.orange
    final payColor =
        isPaid ? _cfg('selesai').color : _cfg('menunggu bayar').color;
    final payBg =
        isPaid ? _cfg('selesai').bgColor : _cfg('menunggu bayar').bgColor;

    return ExpandableCard(
      title: 'Pembayaran',
      isExpanded: isPaymentExpanded,
      onToggle: () => setState(() => isPaymentExpanded = !isPaymentExpanded),
      summaryWidget: !isPaymentExpanded
          ? Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: payBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: payColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      isPaid ? 'Sudah Bayar' : 'Belum Bayar',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: payColor),
                    ),
                  ),
                  Text(
                    Helper.formatCurrency(widget.pesanan.grandTotal),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Constants.primaryColorVendor),
                  ),
                ],
              ),
            )
          : null,
      content: _buildPaymentContent(
          widget.pesanan, widget.metodePembayaran?.fee ?? 0),
    );
  }

  Widget _buildPaymentContent(PesananModel pesanan, int adminFee) {
    final isPaid = PesananProvider.isPaymentSettled(pesanan.statusBayar);
    final payColor =
        isPaid ? _cfg('selesai').color : _cfg('menunggu bayar').color;

    final bool isInclPpn = pesanan.inclPpn == true;
    final bool isExclPpn = pesanan.inclPpn == false;
    final int ppnAmount = pesanan.totPpn ?? 0;
    final int ppnPercent = pesanan.ppn ?? 0;

    // Snap expired
    bool isPaymentExpired = pesanan.status?.toLowerCase() == 'expired';
    if (!isPaid && !isPaymentExpired) {
      if (pesanan.statusBayar == 'expire') {
        isPaymentExpired = true;
      } else if (pesanan.linkSnap != null && pesanan.linkSnap!.isNotEmpty) {
        if (pesanan.expiryTime != null) {
          isPaymentExpired = pesanan.expiryTime!.isBefore(DateTime.now());
        } else {
          final ref = pesanan.createdAt ?? pesanan.updatedAt;
          if (ref != null) {
            isPaymentExpired = DateTime.now().difference(ref).inDays >= 30;
          }
        }
      } else {
        // Core expired
        final hasMethods =
            pesanan.metodeBayar != null && pesanan.metodeBayar!.isNotEmpty;
        if (hasMethods) {
          final noNum = (pesanan.paymentNumber1 == null ||
                  pesanan.paymentNumber1!.isEmpty) &&
              (pesanan.paymentNumber2 == null ||
                  pesanan.paymentNumber2!.isEmpty);
          if (noNum && pesanan.expiryTime == null) {
            final ref = pesanan.createdAt ?? pesanan.updatedAt;
            isPaymentExpired =
                ref == null || DateTime.now().difference(ref).inDays >= 1;
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isPaymentExpired) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.link_off_rounded,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pembayaran sudah expired. Hubungi vendor atau buat pesanan baru jika diperlukan.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        InfoRow(
          label: 'Nomor Bukti',
          value: pesanan.noTrackingPesanan ?? '-',
          icon: Icons.receipt_long_outlined,
          copyable: true,
        ),
        const SizedBox(height: 8),
        InfoRow(
          label: 'Metode Pembayaran',
          value: pesanan.metodeBayar != null
              ? pesanan.metodeBayar!.replaceAll('_', ' ').toUpperCase()
              : '-',
          icon: Icons.account_balance_wallet_outlined,
        ),
        const SizedBox(height: 8),
        InfoRow(
          label: 'Status Pembayaran',
          icon: Icons.schedule_outlined,
          value: isPaid ? 'Sudah Bayar' : 'Belum Bayar',
          valueColor: payColor,
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),

        // ── Header Ringkasan ─────────────────────────────
        const Text(
          'Ringkasan Pembayaran',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // ── Subtotal ─────────────────────────────────────
        PriceRow(
          label: 'Subtotal',
          value: Helper.formatCurrency(pesanan.subtotal - adminFee),
        ),

        if (!isInclPpn) const SizedBox(height: 6),

        // ── Keterangan PPN (include) ─────────────────────
        if (isInclPpn)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 6),
            child: Text(
              ppnPercent > 0
                  ? 'Harga sudah termasuk PPN $ppnPercent%'
                  : 'Harga sudah termasuk PPN',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // ── Biaya Admin ──────────────────────────────────
        PriceRow(
          label: 'Biaya admin',
          value: Helper.formatCurrency(adminFee),
        ),

        if (!isInclPpn) const SizedBox(height: 6),

        // ── Baris PPN (exclude) ──────────────────────────
        if (isExclPpn && ppnAmount > 0) ...[
          PriceRow(
            label: ppnPercent > 0 ? 'PPN $ppnPercent%' : 'PPN',
            value: Helper.formatCurrency(ppnAmount),
          ),
          const SizedBox(height: 6),
        ],

        const Divider(height: 20),

        // ── Total ────────────────────────────────────────
        PriceRow(
          label: 'Total Pembayaran',
          value: Helper.formatCurrency(pesanan.grandTotal),
          isBold: true,
          valueColor: Constants.primaryColorVendor,
        ),

        // ── Tombol Ganti Metode ──────────────────────────
        if (!isPaid &&
            !isPaymentExpired &&
            (pesanan.paymentNumber1 != null || pesanan.expiryTime != null)) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<NavigationProvider>().navigateToPage(
                      context,
                      targetTabIndex: 2,
                      DetailPembayaranPage(existingNoBukti: pesanan.noBukti),
                    );
              },
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('Ganti Metode Bayar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
