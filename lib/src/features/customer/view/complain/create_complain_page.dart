import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/utils/attachment_compressor.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/view/complain/complain_thread_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/complain_provider.dart';
import 'package:mpjnew/src/features/customer/widget/attachment_preview_strip.dart';
import 'package:mpjnew/src/features/customer/widget/complain_attachment_picker.dart';

/// Form pengajuan Complain baru untuk satu order — dibuka dari tombol
/// "Ajukan Complain" di halaman detail order.
class CreateComplainPage extends StatefulWidget {
  final PesananModel pesanan;

  const CreateComplainPage({super.key, required this.pesanan});

  @override
  State<CreateComplainPage> createState() => _CreateComplainPageState();
}

class _CreateComplainPageState extends State<CreateComplainPage> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _messageController = TextEditingController();
  final List<PreparedAttachment> _pendingAttachments = [];
  bool _isPreparingAttachments = false;

  @override
  void dispose() {
    _judulController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachments() async {
    if (_isPreparingAttachments) return;
    setState(() => _isPreparingAttachments = true);
    final result = await pickComplainAttachments(
      currentCount: _pendingAttachments.length,
    );
    if (!mounted) return;
    setState(() {
      _isPreparingAttachments = false;
      _pendingAttachments.addAll(result.accepted);
    });

    final message = attachmentPickMessage(result);
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _removeAttachment(int index) {
    setState(() => _pendingAttachments.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userProv = context.read<UserProvider>();
    final senderId = userProv.customer?.noId ?? '';
    final provider = context.read<ComplainProvider>();

    List<String>? mediaIds;
    if (_pendingAttachments.isNotEmpty) {
      final result =
          await provider.uploadAttachments(_pendingAttachments, senderId);
      if (result.failed.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mengunggah lampiran: ${result.failed.join(", ")}',
            ),
          ),
        );
      }
      mediaIds = result.mediaIds.isEmpty ? null : result.mediaIds;
    }

    final ok = await provider.createComplain(
      noOrder: widget.pesanan.noBukti,
      senderId: senderId,
      tipeUser: Constants.customer,
      judul: _judulController.text.trim(),
      message: _messageController.text.trim(),
      idMedia: mediaIds,
    );

    if (!mounted) return;

    if (ok && provider.active != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ComplainThreadPage(
            initial: provider.active,
            showOrderAction: false,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.activeError ?? 'Gagal mengirim complain')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Ajukan Complain',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Consumer<ComplainProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No. Order: ${widget.pesanan.noTrackingPesanan ?? widget.pesanan.noBukti}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        const Text('Judul',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _judulController,
                          decoration:
                              _fieldDecoration('Ringkasan singkat masalahnya'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Judul wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        const Text('Pesan',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 6,
                          decoration:
                              _fieldDecoration('Jelaskan detail masalahnya'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Pesan wajib diisi'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Lampiran',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        if (_pendingAttachments.isEmpty)
                          GestureDetector(
                            onTap:
                                (provider.isSending || _isPreparingAttachments)
                                    ? null
                                    : _pickAttachments,
                            child: Container(
                                padding: EdgeInsets.symmetric(vertical: 50),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.camera_alt_outlined,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Klik untuk mengambil gambar',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600),
                                      ),
                                      Text(
                                        'Opsional — maksimal $kMaxComplainAttachments gambar, 2MB per gambar.',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                )),
                          ),
                        // if (_pendingAttachments.isNotEmpty)

                        if (_pendingAttachments.isNotEmpty) ...[
                          AttachmentPreviewStrip(
                            items: _pendingAttachments,
                            onRemove: _removeAttachment,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (provider.isSending ||
                                      _isPreparingAttachments)
                                  ? null
                                  : _pickAttachments,
                              style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  backgroundColor: Colors.white,
                                  foregroundColor: Constants.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                      color: Constants.primaryColor,
                                      width: 1.5),
                                  shadowColor: Colors.transparent),
                              child: Text('Tambah gambar'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: (provider.isSending || _isPreparingAttachments)
                          ? null
                          : _submit,
                      child: provider.isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Kirim Complain',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F5F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
