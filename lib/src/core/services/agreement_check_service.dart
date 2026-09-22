import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/company_service.dart';
import 'package:mpjnew/src/core/services/document_service.dart';
import 'package:mpjnew/src/core/services/user_agreement_service.dart';
import 'package:mpjnew/src/core/utils/device_info_helper.dart';
import 'package:mpjnew/src/data/models/customer_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/customer_service.dart';
import 'package:mpjnew/src/features/customer/view/history/webview_page.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

enum AgreementType { terms, privacy }

class PendingAgreement {
  final AgreementType type;
  final String kode;
  final String version;

  const PendingAgreement({
    required this.type,
    required this.kode,
    required this.version,
  });

  String get title =>
      type == AgreementType.terms ? 'Syarat & Ketentuan' : 'Kebijakan Privasi';
}

/// Gate persetujuan dokumen legal.
///
/// Versi terbaru diambil dari company profile, lalu dibandingkan dengan versi
/// yang tercatat di user. Kalau user belum pernah setuju atau versinya sudah
/// tertinggal, user wajib menyetujui ulang sebelum bisa memakai aplikasi.
class AgreementCheckService {
  /// Dipanggil setelah login berhasil dan saat app restart dengan sesi aktif.
  ///
  /// [refreshOnMismatch] paksa ambil ulang data user dari backend saat
  /// terdeteksi selisih versi. Perlu di jalur restart karena `restoreSession`
  /// memakai cache Hive yang hanya di-refresh tiap 24 jam — tanpa ini user
  /// yang sudah setuju di device lain akan ditanya lagi, dan PUT persetujuan
  /// berpotensi menimpa data profil dengan isi cache yang basi.
  /// Di jalur login baru data user selalu fresh, jadi bisa dimatikan.
  static Future<void> ensure(
    BuildContext context, {
    bool refreshOnMismatch = true,
  }) async {
    try {
      final userProv = context.read<UserProvider>();
      var customer = userProv.customer;
      if (customer == null) return;

      final company = await CompanyService().get();

      var pending = _pendingFor(customer, company);
      if (pending.isEmpty) return;

      if (refreshOnMismatch) {
        await userProv.refreshUserData();
        customer = userProv.customer;
        if (customer == null) return;

        pending = _pendingFor(customer, company);
        if (pending.isEmpty) {
          debugPrint('[Agreement] Versi sudah sesuai setelah refresh');
          return;
        }
      }

      if (!context.mounted) return;

      final accepted = await _showAgreementPage(context, pending);
      if (accepted.isEmpty) return;

      await _save(userProv, customer, accepted);
    } catch (e) {
      // Fail open — jangan kunci user di luar aplikasi kalau endpoint company
      // atau dokumen sedang bermasalah.
      debugPrint('[Agreement] Gagal cek persetujuan: $e');
    }
  }

  // ── Perbandingan versi ───────────────────────────────────────

  static List<PendingAgreement> _pendingFor(
    CustomerModel customer,
    CompanyModel company,
  ) {
    final pending = <PendingAgreement>[];

    if (_needsAccept(customer.tncVersion, company.termsConditions)) {
      pending.add(PendingAgreement(
        type: AgreementType.terms,
        kode: company.termsConditions.kode,
        version: company.termsConditions.version,
      ));
    }

    if (_needsAccept(customer.ppVersion, company.privacyPolicy)) {
      pending.add(PendingAgreement(
        type: AgreementType.privacy,
        kode: company.privacyPolicy.kode,
        version: company.privacyPolicy.version,
      ));
    }

    return pending;
  }

  static bool _needsAccept(String userVersion, DocumentRef ref) {
    if (!ref.isValid || ref.version.isEmpty) return false;
    if (userVersion.trim().isEmpty) return true;
    return _isServerNewer(userVersion, ref.version);
  }

  /// True kalau versi server lebih baru dari versi yang tercatat di user.
  /// Format MAJOR.MINOR.PATCH — sama seperti di VersionCheckService.
  static bool _isServerNewer(String local, String server) {
    try {
      final l = _parse(local);
      final s = _parse(server);
      for (int i = 0; i < 3; i++) {
        if (s[i] > l[i]) return true;
        if (s[i] < l[i]) return false;
      }
      return false;
    } catch (e) {
      debugPrint('[Agreement] Gagal parse versi "$local" vs "$server": $e');
      return false;
    }
  }

  static List<int> _parse(String version) {
    final parts = version.trim().split('.');
    return List.generate(
        3, (i) => i < parts.length ? int.tryParse(parts[i]) ?? 0 : 0);
  }

  // ── Halaman persetujuan ──────────────────────────────────────

  /// Satu halaman penuh memuat semua dokumen yang pending sekaligus.
  static Future<List<PendingAgreement>> _showAgreementPage(
    BuildContext context,
    List<PendingAgreement> pending,
  ) async {
    final accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AgreementPage(pending: pending),
        fullscreenDialog: true,
      ),
    );

    return accepted == true ? pending : [];
  }

  // ── Simpan ───────────────────────────────────────────────────

  /// Satu PUT untuk semua dokumen yang disetujui — `toJsonUpdate()` mengirim
  /// seluruh profil, jadi PUT terpisah per dokumen memperlebar risiko menimpa
  /// data lain dan bisa menyisakan state setengah jadi kalau gagal di tengah.
  static Future<void> _save(
    UserProvider userProv,
    CustomerModel customer,
    List<PendingAgreement> accepted,
  ) async {
    final loc = await DeviceInfoHelper.describe();
    final now = DateTime.now();

    var updated = customer;
    for (final item in accepted) {
      if (item.type == AgreementType.terms) {
        updated = updated.copyWith(
          tncLoc: loc,
          tncVersion: item.version,
          tncTime: now,
        );
      } else {
        updated = updated.copyWith(
          ppLoc: loc,
          ppVersion: item.version,
          ppTime: now,
        );
      }
    }

    await CustomerService().update(updated);

    // Riwayat persetujuan (satu record per dokumen) — terpisah dari field
    // Tnc_*/Pp_* di profil, jadi kegagalannya tidak boleh menahan update
    // lokal: profil server sudah benar, ini cuma audit trail tambahan.
    try {
      final agreementService = UserAgreementService();
      await Future.wait(accepted.map((item) => agreementService.create(
            idDokumen: item.kode,
            idUser: updated.noId,
            email: updated.email,
            deviceInfo: loc,
            acceptedAt: now,
          )));
    } catch (e) {
      debugPrint(
          '[Agreement] Gagal membuat riwayat persetujuan (non-fatal): $e');
    }

    userProv.updateCustomerLocally(updated);
    debugPrint(
        '[Agreement] ✅ Persetujuan tersimpan (${accepted.length} dokumen)');
  }
}

// ═══════════════════════════════════════════════════════════════
// HALAMAN PERSETUJUAN — sticky header per dokumen, dibaca berurutan
// ═══════════════════════════════════════════════════════════════

class AgreementPage extends StatefulWidget {
  final List<PendingAgreement> pending;

  const AgreementPage({super.key, required this.pending});

  @override
  State<AgreementPage> createState() => _AgreementPageState();
}

class _AgreementPageState extends State<AgreementPage> {
  final DocumentService _service = DocumentService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();

  /// Tinggi header tiap dokumen. Dipakai sebagai minExtent/maxExtent
  /// SliverPersistentHeader (pinned) sekaligus ambang batas untuk
  /// mendeteksi kapan sebuah dokumen dianggap "sudah lewat" saat di-scroll.
  static const double _headerHeight = 66.0;

  late final List<DocumentModel?> _documents;
  late final List<bool> _isLoading;
  late final List<String?> _errors;
  late final List<GlobalKey> _bodyKeys;

  /// Indeks dokumen yang sedang dibaca (dokumen pertama yang belum
  /// sepenuhnya ter-scroll lewat). Dipakai untuk menandai header dokumen
  /// sebelumnya dengan centang hijau.
  int _activeIndex = 0;
  bool _agreed = false;

  /// Sekali true, tetap true — supaya kalau user scroll balik ke atas
  /// untuk membaca ulang, checkbox tidak ke-lock lagi.
  bool _unlocked = false;

  bool get _allLoaded => _documents.every((d) => d != null);

  @override
  void initState() {
    super.initState();
    final n = widget.pending.length;
    _documents = List<DocumentModel?>.filled(n, null);
    _isLoading = List<bool>.filled(n, true);
    _errors = List<String?>.filled(n, null);
    _bodyKeys = List.generate(n, (_) => GlobalKey());
    _loadAll();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait(List.generate(widget.pending.length, _loadOne));
  }

  Future<void> _loadOne(int index) async {
    try {
      final doc = await _service.getByKode(widget.pending[index].kode);
      if (!mounted) return;
      setState(() {
        _documents[index] = doc;
        _isLoading[index] = false;
      });
      // Dokumen pendek yang muat penuh di layar (atau ini dokumen terakhir
      // yang baru saja selesai load) tidak akan pernah memicu event scroll
      // sendiri — cek juga langsung setelah render.
      WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errors[index] = 'Gagal memuat dokumen. Periksa koneksi internet Anda.';
        _isLoading[index] = false;
      });
    }
  }

  void _retry(int index) {
    setState(() {
      _isLoading[index] = true;
      _errors[index] = null;
    });
    _loadOne(index);
  }

  /// Hitung berapa dokumen yang isinya sudah lewat (ter-scroll ke belakang
  /// header sticky), lalu tentukan:
  /// - `_activeIndex`: dokumen yang sedang dibaca (untuk centang hijau di
  ///   header dokumen-dokumen sebelumnya).
  /// - `_unlocked`: true kalau semua dokumen sudah lewat / user sudah
  ///   mentok scroll ke bawah / dokumen memang tidak butuh scroll sama
  ///   sekali (muat penuh di layar) — checkbox baru bisa dinyalakan.
  void _onScroll() {
    if (!_allLoaded) return;

    final viewportBox =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null || !viewportBox.attached) return;

    int passed = 0;
    for (int i = 0; i < widget.pending.length; i++) {
      final box = _bodyKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) break;

      final bottom = box.localToGlobal(Offset.zero, ancestor: viewportBox).dy +
          box.size.height;

      // Bottom konten <= tinggi header sticky berarti konten itu sudah
      // sepenuhnya bersembunyi di balik header yang sedang pinned.
      if (bottom <= _headerHeight) {
        passed++;
      } else {
        break;
      }
    }

    final hasScroll = _scrollController.hasClients;
    final atBottom = hasScroll &&
        _scrollController.position.maxScrollExtent > 0 &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 4;
    final noScrollNeeded =
        hasScroll && _scrollController.position.maxScrollExtent <= 0;

    final reachedEnd =
        passed >= widget.pending.length || atBottom || noScrollNeeded;

    // Monoton naik saja — sekali dokumen ditandai selesai (centang), scroll
    // balik ke atas untuk membaca ulang tidak boleh mencabut centangnya.
    final passedActive = passed.clamp(0, widget.pending.length - 1);
    final newActive = passedActive > _activeIndex ? passedActive : _activeIndex;
    final newUnlocked = _unlocked || reachedEnd;

    if (newActive != _activeIndex || newUnlocked != _unlocked) {
      setState(() {
        _activeIndex = newActive;
        _unlocked = newUnlocked;
      });
    }
  }

  void _handleLinkTap(String? url) {
    if (url == null || url.trim().isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final scheme = uri.scheme.toLowerCase();

    if (scheme == 'http' || scheme == 'https') {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WebviewPage(url: url),
        ),
      );
      return;
    }

    _openExternalScheme(uri);
  }

  Future<void> _openExternalScheme(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[Agreement] ⚠️ Gagal membuka link "$uri": $e');
    }
  }

  void _closeApp() {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }

  void _submit() => Navigator.of(context).pop(true);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Persetujuan wajib — tidak bisa ditutup dengan tombol back.
      canPop: false,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F5F7),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 1,
            title: const Text(
              'Persetujuan Diperlukan',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  key: _viewportKey,
                  controller: _scrollController,
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    for (int i = 0; i < widget.pending.length; i++)
                      ..._buildSectionSlivers(i),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// Satu dokumen = 1 sliver header (pinned/sticky) + 1 sliver body.
  /// Karena semua header di-pin berurutan, Flutter otomatis membuat efek
  /// "header dokumen berikutnya mendorong header dokumen sebelumnya keluar
  /// layar lalu menempel di posisi yang sama" saat discroll.
  List<Widget> _buildSectionSlivers(int index) {
    final agreement = widget.pending[index];
    final isLast = index == widget.pending.length - 1;
    // Dokumen terakhir tidak pernah "didorong keluar" oleh header berikutnya
    // (tidak ada dokumen sesudahnya) — jadi ikonnya ditandai selesai begitu
    // scroll mentok di bawah (_unlocked), bukan dari perbandingan index.
    final isDone = index < _activeIndex || (isLast && _unlocked);

    return [
      SliverPersistentHeader(
        pinned: true,
        delegate: _StickyHeaderDelegate(
          height: _headerHeight,
          child: _buildSectionHeader(agreement, isDone: isDone),
        ),
      ),
      SliverToBoxAdapter(
        child: Container(
          key: _bodyKeys[index],
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(14)),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: _buildSectionBody(index),
        ),
      ),
    ];
  }

  Widget _buildSectionHeader(PendingAgreement agreement,
      {required bool isDone}) {
    return Container(
      height: _headerHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDone
                  ? Colors.green.shade50
                  : Constants.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone ? Icons.check_rounded : Icons.description_outlined,
              size: 18,
              color: isDone ? Colors.green.shade600 : Constants.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agreement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDone ? Colors.grey.shade500 : Colors.black87,
                  ),
                ),
                if (agreement.version.isNotEmpty)
                  Text(
                    'Versi ${agreement.version}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBody(int index) {
    if (_isLoading[index]) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (_errors[index] != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Column(
          children: [
            Text(
              _errors[index]!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _retry(index),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    final doc = _documents[index]!;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Html(
        data: doc.deskripsi,
        onLinkTap: (url, attributes, element) => _handleLinkTap(url),
        style: {
          'body': Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontSize: FontSize(13.5),
            lineHeight: LineHeight(1.6),
            color: Colors.black87,
          ),
          'h1': Style(
            fontSize: FontSize(18),
            fontWeight: FontWeight.bold,
            margin: Margins.only(top: 12, bottom: 8),
          ),
          'h2': Style(
            fontSize: FontSize(15),
            fontWeight: FontWeight.w700,
            margin: Margins.only(top: 16, bottom: 6),
          ),
          'h3': Style(
            fontSize: FontSize(14),
            fontWeight: FontWeight.w700,
            margin: Margins.only(top: 12, bottom: 4),
          ),
          'p': Style(
            margin: Margins.only(bottom: 8),
            fontSize: FontSize(13),
            lineHeight: LineHeight(1.65),
            color: const Color(0xFF444444),
          ),
          'li': Style(
            fontSize: FontSize(13),
            lineHeight: LineHeight(1.65),
            color: const Color(0xFF444444),
            margin: Margins.only(bottom: 4),
          ),
          'strong': Style(fontWeight: FontWeight.w700, color: Colors.black87),
          'a': Style(
            color: Constants.primaryColor,
            textDecoration: TextDecoration.underline,
            fontWeight: FontWeight.w500,
          ),
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    final canCheck = _unlocked && _allLoaded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap:
                    canCheck ? () => setState(() => _agreed = !_agreed) : null,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Checkbox(
                      value: _agreed,
                      activeColor: Constants.primaryColor,
                      onChanged: canCheck
                          ? (v) => setState(() => _agreed = v ?? false)
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        'Saya telah membaca dan menyetujui seluruh dokumen di atas',
                        style: TextStyle(
                          fontSize: 12.5,
                          color:
                              canCheck ? Colors.black87 : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!canCheck)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Text(
                          'Gulir hingga dokumen terakhir untuk mengaktifkan',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_agreed && canCheck) ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Saya Setuju',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _closeApp,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    "Tidak, Saya Tidak Setuju (Keluar Aplikasi)",
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Delegate untuk header sticky per dokumen. `pinned: true` di
/// `SliverPersistentHeader` yang membuat header ini menempel di atas
/// viewport sampai header dokumen berikutnya datang dan menggantikannya.
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const _StickyHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Header pinned dipaint DI ATAS body yang scroll di baliknya. Card di
    // dalam `child` punya borderRadius, jadi sudut lengkungnya sendiri
    // transparan (tidak dipaint) — tanpa backdrop opaque ini, body yang
    // sedang scroll tembus terlihat lewat celah sudut tersebut. Warnanya
    // disamakan dengan background Scaffold halaman ini.
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFF5F5F7)),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
