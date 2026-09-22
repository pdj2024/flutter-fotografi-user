import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/refund_info_model.dart';
import 'package:mpjnew/src/data/models/refund_rule_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/customer_service.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/sticky_button_bar.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/batal_pesanan_flow.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/confirm_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/refund_rules_sheet.dart';
import 'package:mpjnew/src/features/customer/widget/field/custom_text_field.dart';
import 'package:mpjnew/src/features/customer/widget/refund_summary_card.dart';

/// Langkah terakhir pembatalan pesanan berbayar: customer menegaskan nominal
/// yang akan diterima lalu mengisi rekening tujuan.
///
/// Data rekening disimpan ke master customer, tapi SENGAJA hanya bisa diisi
/// dari sini — halaman Edit Profile tidak menampilkan field ini.
class RefundFormPage extends StatefulWidget {
  const RefundFormPage({
    super.key,
    required this.pesanan,
    this.refundInfo,
    this.rules = const [],
    this.roomId,
    this.onSuccess,
  });

  final PesananModel pesanan;
  final RefundInfoModel? refundInfo;
  final List<RefundRuleModel> rules;
  final String? roomId;
  final VoidCallback? onSuccess;

  @override
  State<RefundFormPage> createState() => _RefundFormPageState();
}

class _RefundFormPageState extends State<RefundFormPage> {
  final _bankController = TextEditingController();
  final _rekeningController = TextEditingController();

  String? _bankError;
  String? _rekeningError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Prefill kalau customer pernah membatalkan pesanan sebelumnya.
    final customer = context.read<UserProvider>().customer;
    _bankController.text = customer?.namaBank ?? '';
    _rekeningController.text = customer?.nomorRekening ?? '';
  }

  @override
  void dispose() {
    _bankController.dispose();
    _rekeningController.dispose();
    super.dispose();
  }

  bool _validasi() {
    final bank = _bankController.text.trim();
    final rekening = _rekeningController.text.trim();

    setState(() {
      _bankError = bank.isEmpty ? 'Nama bank wajib diisi' : null;
      _rekeningError = rekening.isEmpty
          ? 'Nomor rekening wajib diisi'
          : rekening.length < 6
              ? 'Nomor rekening tidak valid'
              : null;
    });

    return _bankError == null && _rekeningError == null;
  }

  void _submit() {
    if (!_validasi()) return;

    ConfirmDialog.showKonfirmasiRefundDialog(
      context: context,
      namaBank: _bankController.text.trim(),
      nomorRekening: _rekeningController.text.trim(),
      refundInfo: widget.refundInfo,
      onConfirm: _prosesPembatalan,
    );
  }

  Future<void> _prosesPembatalan() async {
    final userProvider = context.read<UserProvider>();
    final customer = userProvider.customer;
    if (customer == null) {
      CustomSnackbar.showErrorSnackbar(
          context, 'Sesi tidak ditemukan, coba login ulang');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Rekening disimpan DULU: kalau langkah ini gagal, pesanan belum
      // terlanjur dibatalkan tanpa tujuan pengembalian dana.
      final updated = customer.copyWith(
        namaBank: _bankController.text.trim(),
        nomorRekening: _rekeningController.text.trim(),
      );
      await CustomerService().update(updated);
      if (!mounted) return;
      userProvider.updateCustomerLocally(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      CustomSnackbar.showErrorSnackbar(
          context, 'Gagal menyimpan data rekening. Coba lagi.');
      return;
    }

    final berhasil = await eksekusiBatalPesanan(
      context,
      widget.pesanan,
      denganRefund: true,
      roomId: widget.roomId,
      onSuccess: widget.onSuccess,
    );

    if (!mounted) return;
    if (berhasil) {
      Navigator.of(context).pop();
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 1,
          title: const Text(
            'Pengembalian Dana',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          actions: [
            if (widget.rules.isNotEmpty)
              IconButton(
                onPressed: () => showRefundRulesSheet(
                  context,
                  widget.rules,
                  tierAktifId: widget.refundInfo?.idRefund,
                ),
                icon: const Icon(Icons.info_outline_rounded,
                    color: Colors.black54),
                tooltip: 'Lihat ketentuan refund',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    RefundSummaryCard(info: widget.refundInfo),
                    const SizedBox(height: 24),
                    const Text(
                      'Rekening Tujuan',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pastikan rekening atas nama Anda sendiri.',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Nama Bank',
                      controller: _bankController,
                      placeholder: 'Contoh: BCA',
                      errorMessage: _bankError,
                    ),
                    CustomTextField(
                      label: 'Nomor Rekening',
                      controller: _rekeningController,
                      placeholder: 'Contoh: 1234567890',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      errorMessage: _rekeningError,
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: StickyButtonBar(
          btnLabel: 'Ajukan Pembatalan',
          icon: Icons.assignment_return_outlined,
          keterangan: 'Dana diproses maksimal 2x24 jam setelah pengajuan.',
          dotColor: const Color(0xFFDC2626),
          onTap: _isLoading ? null : _submit,
        ),
      ),
    );
  }
}
