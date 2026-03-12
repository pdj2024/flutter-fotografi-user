import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:mpjnew/src/core/services/document_service.dart';
import 'package:url_launcher/url_launcher.dart';

enum LegalType { privacy, terms }

class LegalPage extends StatefulWidget {
  final LegalType type;

  const LegalPage({super.key, required this.type});

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  final DocumentService _service = DocumentService();

  DocumentModel? _document;
  bool _isLoading = true;
  String? _error;

  // ── Config per type ───────────────────────────────────────

  String get _title => widget.type == LegalType.privacy
      ? 'Kebijakan Privasi'
      : 'Syarat & Ketentuan';

  String get _subtitle => widget.type == LegalType.privacy
      ? 'Cara kami melindungi data Anda'
      : 'Aturan penggunaan aplikasi';

  IconData get _icon => widget.type == LegalType.privacy
      ? Icons.shield_outlined
      : Icons.description_outlined;

  Color get _color => widget.type == LegalType.privacy
      ? const Color(0xFFE67E22)
      : const Color(0xFF2980B9);

  Color get _bgColor => widget.type == LegalType.privacy
      ? const Color(0xFFFEF3E8)
      : const Color(0xFFE8F4FD);

  // ── Lifecycle ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final doc = widget.type == LegalType.privacy
          ? await _service.getKebijakanPrivasiAplikasi()
          : await _service.getSyaratKetentuanAplikasi();

      if (mounted)
        setState(() {
          _document = doc;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(_icon, color: _color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              _title,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _isLoading
                ? _buildLoading()
                : _error != null
                    ? _buildError()
                    : _buildContent(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STATES
  // ═══════════════════════════════════════════════════════════

  Widget _buildLoading() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(_color),
            ),
            const SizedBox(height: 16),
            Text(
              'Memuat dokumen...',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.wifi_off_rounded,
                  color: Colors.red.shade400, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Dokumen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Periksa koneksi internet Anda\nlalu coba lagi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadDocument,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_document == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Html(
          data: _document!.deskripsi,
          style: {
            'body': Style(
              margin: Margins.symmetric(horizontal: 12),
              padding: HtmlPaddings.zero,
              fontSize: FontSize(14),
              lineHeight: LineHeight(1.6),
              color: Colors.black87,
            ),
            'h1': Style(
              fontSize: FontSize(20),
              fontWeight: FontWeight.bold,
              color: Colors.black,
              margin: Margins.only(top: 16, bottom: 8),
            ),
            'h2': Style(
              fontSize: FontSize(15),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              margin: Margins.only(top: 20, bottom: 6),
              padding: HtmlPaddings.only(left: 12),
              border: Border(
                left: BorderSide(color: _color, width: 3),
              ),
            ),
            'h3': Style(
              fontSize: FontSize(14),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              margin: Margins.only(top: 12, bottom: 4),
            ),
            'p': Style(
              margin: Margins.only(bottom: 8),
              fontSize: FontSize(13.5),
              lineHeight: LineHeight(1.65),
              color: const Color(0xFF444444),
            ),
            'ul': Style(
              margin: Margins.only(left: 4, bottom: 8),
            ),
            'li': Style(
              fontSize: FontSize(13.5),
              lineHeight: LineHeight(1.65),
              color: const Color(0xFF444444),
              margin: Margins.only(bottom: 4),
            ),
            'strong': Style(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            'hr': Style(
              margin: Margins.symmetric(vertical: 12),
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            'a': Style(
              color: _color,
              textDecoration: TextDecoration.none,
              fontWeight: FontWeight.w500,
            ),
          },
          onLinkTap: (url, attributes, element) async {
            if (url == null) return;
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
          },
        ),
      ),
    );
  }
}
