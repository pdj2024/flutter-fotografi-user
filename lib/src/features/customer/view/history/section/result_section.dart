import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/view/history/webview_page.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/status_config.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/revisi_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/selesaikan_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:mpjnew/src/features/customer/widget/order_status_flow.dart';
import 'package:provider/provider.dart';

class ResultSection extends StatefulWidget {
  const ResultSection({
    super.key,
    required this.pesanan,
    required this.onShowUlasanDialog,
  });

  final PesananModel pesanan;

  /// Dialog ulasan tetap dikelola parent — dia yang menyimpan state `ulasan`
  /// yang dipakai UlasanSection, jadi tidak boleh diduplikasi di sini.
  final VoidCallback onShowUlasanDialog;

  @override
  State<ResultSection> createState() => _ResultSectionState();
}

class _ResultSectionState extends State<ResultSection> {
  bool _isSubmittingStatus = false;

  StatusConfig _cfg(String status) => getStatus(status);

  Future<void> _selesaikanPesanan() async {
    final pesananProvider = context.read<PesananProvider>();
    final historyProvider = context.read<HistoryOrderProvider>();
    final pesanan =
        pesananProvider.getPesananByNoOrder(widget.pesanan.noBukti);
    if (pesanan == null) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SelesaikanDialog(
        pesanan: pesanan,
        onSuccess: () async {
          if (!mounted) return;
          await pesananProvider.refreshOrder(widget.pesanan.noBukti);
          await historyProvider.fetchHistoryForOrder(widget.pesanan.noBukti);
          if (mounted) {
            await Future.delayed(const Duration(milliseconds: 800));
            if (mounted) widget.onShowUlasanDialog();
          }
        },
      ),
    );
  }

  Future<void> _mintaRevisi() async {
    final pesananProvider = context.read<PesananProvider>();
    final historyProvider = context.read<HistoryOrderProvider>();
    final pesanan =
        pesananProvider.getPesananByNoOrder(widget.pesanan.noBukti);
    if (pesanan == null) return;

    // Guard: kuota revisi habis jika maxRevisi > 0 dan revisiCount >= maxRevisi
    final maxRevisi = pesanan.revisi;
    if (maxRevisi > 0) {
      final revisiCount = historyProvider
          .getHistoryForOrder(pesanan.noBukti)
          .where((h) => h.statusProgressPesanan == 'revisi')
          .length;
      if (revisiCount >= maxRevisi) {
        if (!mounted) return;
        CustomSnackbar.showErrorSnackbar(
          context,
          'Kuota revisi sudah habis ($revisiCount/$maxRevisi). '
          'Silakan selesaikan pesanan.',
        );
        return;
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RevisiDialog(
        pesanan: pesanan,
        onSuccess: () async {
          if (!mounted) return;
          await pesananProvider.refreshOrder(widget.pesanan.noBukti);
          await historyProvider.fetchHistoryForOrder(widget.pesanan.noBukti);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.pesanan.statusProgresPesanan?.toLowerCase() ?? '';
    final cfg = _cfg(status);
    final isRevisi = status == 'revisi';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cfg.color.withOpacity(0.5)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: cfg.bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.photo_library_outlined,
                    color: cfg.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isRevisi
                      ? 'Hasil Kerja Sebelum Revisi'
                      : 'Hasil Pekerjaan Vendor',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              InkWell(
                onTap: () => Helper.copyToClipboard(
                    context, widget.pesanan.linkUrl!, 'Link Hasil'),
                borderRadius: BorderRadius.circular(20),
                child: Tooltip(
                  message: 'Salin link',
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cfg.bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.copy_rounded, size: 16, color: cfg.color),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => context.read<NavigationProvider>().navigateToPage(
                  context,
                  WebviewPage(url: widget.pesanan.linkUrl!),
                  targetTabIndex: 2,
                ),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cfg.bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cfg.color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.link_rounded, size: 16, color: cfg.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.pesanan.linkUrl!,
                      style: TextStyle(
                        fontSize: 13,
                        color: cfg.color,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: cfg.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.open_in_new_rounded, size: 14, color: cfg.color),
                ],
              ),
            ),
          ),
          if (status == 'review') ...[
            const SizedBox(height: 10),
            _buildCustomerActionArea('review', widget.pesanan),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerActionArea(String status, PesananModel pesanan) {
    if (status != 'review') return const SizedBox.shrink();

    return Consumer<HistoryOrderProvider>(
      builder: (context, hp, _) {
        final histories = hp.getHistoryForOrder(pesanan.noBukti);
        final revisiCount =
            histories.where((h) => h.statusProgressPesanan == 'revisi').length;
        final maxRevisi = pesanan.revisi;
        final revisiHabis = maxRevisi >= 0 && revisiCount >= maxRevisi;

        final cfgSelesai = _cfg('selesai');
        final selesaiTransition = OrderStatusFlow.get('review', 'selesai');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (revisiHabis) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.block_rounded,
                        size: 18, color: Colors.orange.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kuota revisi sudah habis',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Kamu telah menggunakan $revisiCount dari $maxRevisi kesempatan revisi. '
                            'Silakan selesaikan pesanan jika sudah puas dengan hasilnya.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _isSubmittingStatus ? null : _selesaikanPesanan,
                icon: _isSubmittingStatus
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(cfgSelesai.icon, size: 18),
                label: Text(
                  selesaiTransition?.actionLabel ?? 'Selesaikan',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cfgSelesai.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmittingStatus ? null : _mintaRevisi,
                      icon: _isSubmittingStatus
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _cfg('revisi').color))
                          : Icon(_cfg('revisi').icon, size: 18),
                      label: Text(
                        OrderStatusFlow.get('review', 'revisi')?.actionLabel ??
                            'Minta Revisi',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _cfg('revisi').color,
                        side:
                            BorderSide(color: _cfg('revisi').color, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _isSubmittingStatus ? null : _selesaikanPesanan,
                      icon: _isSubmittingStatus
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Icon(cfgSelesai.icon, size: 18),
                      label: Text(
                        selesaiTransition?.actionLabel ?? 'Selesaikan',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cfgSelesai.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
