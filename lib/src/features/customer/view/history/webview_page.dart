import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/view/payment/payment_success_splash_screen.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/order_tab_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebviewPage digunakan untuk dua keperluan:
///   1. Halaman Midtrans Snap ([paymentData] != null) — FCM + polling aktif
///   2. URL umum ([paymentData] == null) — tanpa payment logic
class WebviewPage extends StatefulWidget {
  final String url;

  /// Isi [paymentData] saat membuka halaman Midtrans Snap.
  /// Kosongkan untuk penggunaan webview biasa.
  final PesananModel? paymentData;

  /// Dipanggil saat snap gagal load dan user memilih fallback ke core payment.
  /// Hanya relevan saat [paymentData] != null.
  final VoidCallback? onFallbackToCore;

  const WebviewPage({
    super.key,
    required this.url,
    this.paymentData,
    this.onFallbackToCore,
  });

  @override
  State<WebviewPage> createState() => _WebviewPageState();
}

class _WebviewPageState extends State<WebviewPage>
    with SingleTickerProviderStateMixin {
  late WebViewController _controller;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _isLoading = true;
  String? _errorMessage;
  ErrorType? _errorType;
  Timer? _loadingHideTimer;

  // ── Payment state ─────────────────────────────────────────────────────
  final PesananService _pesananService = PesananService();

  bool _isNavigating = false;
  StreamSubscription<PesananModel>? _fcmSubscription;
  Timer? _pollingTimer;

  late PesananModel _currentData;

  static const int _pollingIntervalSeconds = 10;

  bool get _isPaymentMode => widget.paymentData != null;

  // ── Midtrans Snap URL patterns ────────────────────────────────────────
  static const List<String> _successUrlPatterns = [
    'finish',
    'transaction_status=capture',
    'transaction_status=settlement',
    'order_status=capture',
    'order_status=settlement',
  ];

  static const List<String> _failedUrlPatterns = [
    'unfinish',
    'cancel',
    'error',
    'transaction_status=deny',
    'transaction_status=cancel',
    'transaction_status=expire',
    'order_status=deny',
    'order_status=cancel',
    'order_status=expire',
  ];

  // =========================================
  // INIT & DISPOSE
  // =========================================

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initWebView();

    if (_isPaymentMode) {
      _currentData = widget.paymentData!;
      _startPolling();
      WidgetsBinding.instance.addPostFrameCallback((_) => _listenFCM());
    }
  }

  @override
  void dispose() {
    _loadingHideTimer?.cancel();
    _animController.dispose();
    _fcmSubscription?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  // =========================================
  // FCM LISTENER
  // =========================================

  void _listenFCM() {
    _fcmSubscription = context
        .read<PesananProvider>()
        .paymentUpdateStream
        .where((p) => p.noBukti == widget.paymentData!.noBukti)
        .listen((updated) async {
      debugPrint('[WebviewPage] 🔔 FCM payment update: ${updated.statusBayar}');
      if (!mounted || _isNavigating) return;

      setState(() => _currentData = updated);

      if (PesananProvider.isPaymentSettled(updated.statusBayar)) {
        await _handlePaymentSuccess(updated);
      }
    });

    debugPrint('[WebviewPage] ✅ FCM stream listener attached');
  }

  // =========================================
  // POLLING (fallback jika FCM tidak sampai)
  // =========================================

  void _startPolling() {
    _pollingTimer = Timer.periodic(
      const Duration(seconds: _pollingIntervalSeconds),
      (_) {
        if (!_isNavigating) _pollStatus();
      },
    );
  }

  Future<void> _pollStatus() async {
    try {
      final list = await _pesananService
          .getAll(noBukti: widget.paymentData!.noBukti)
          .timeout(const Duration(seconds: 10), onTimeout: () => []);

      if (!mounted || list.isEmpty) return;

      final fresh = list.first;

      if (fresh.statusBayar != _currentData.statusBayar) {
        debugPrint(
            '[WebviewPage] 📊 Poll: ${_currentData.statusBayar} → ${fresh.statusBayar}');
        setState(() => _currentData = fresh);

        if (PesananProvider.isPaymentSettled(fresh.statusBayar)) {
          await _handlePaymentSuccess(fresh);
        }
      }
    } catch (e) {
      debugPrint('[WebviewPage] ⚠️ Poll error: $e');
    }
  }

  // =========================================
  // HANDLE PAYMENT SUCCESS
  // =========================================

  Future<void> _handlePaymentSuccess(PesananModel updated) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    _fcmSubscription?.cancel();
    _pollingTimer?.cancel();

    if (!mounted) return;

    try {
      await context.read<HistoryOrderProvider>().createPersiapan(
            updated.noBukti,
            updated.idCustomer,
          );

      await context.read<PesananProvider>().loadOrder(context);
      context.read<OrderTabProvider>().setSelectedTabIndex(1);

      if (!mounted) return;

      // Pop webview dulu, lalu push splash screen ke atas MainOrderPage.
      // Dengan begitu stack menjadi: MainOrderPage → SplashScreen
      // (bukan: MainOrderPage → WebviewPage → SplashScreen)
      Navigator.of(context).pop();

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentSuccessSplashScreen(
            orderNumber: updated.noTrackingPesanan ?? '',
            amount: updated.grandTotal,
            noBukti: updated.noBukti,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[WebviewPage] ❌ handlePaymentSuccess error: $e');
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  // =========================================
  // WEBVIEW INIT
  // =========================================

  void _initAnimations() {
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));
  }

  void _initWebView() {
    String url = widget.url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      // Jembatan untuk unduhan "blob:" (lihat _handleBlobDownload) — WebView
      // tidak bisa navigasi langsung ke blob: URL sebagai file (selalu
      // net::ERR_FILE_NOT_FOUND), jadi kontennya di-fetch ulang lewat JS di
      // dalam halaman lalu dikirim ke sini sebagai data URL base64.
      ..addJavaScriptChannel(
        'FlutterDownload',
        onMessageReceived: (message) => _handleDownloadMessage(message.message),
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          _loadingHideTimer?.cancel();
          if (mounted) setState(() => _isLoading = true);
          if (_isPaymentMode) {
            _injectDownloadHelper(); // ✅ pasang override sedini mungkin
          }
        },
        onPageFinished: (url) {
          _loadingHideTimer?.cancel();
          _loadingHideTimer = Timer(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _isLoading = false);
          });
          if (_isPaymentMode) {
            _checkSnapCallbackUrl(url);
            _injectDownloadHelper(); // ✅ jaga-jaga kalau iframe/SPA reload konten
          }
        },
        onHttpError: (err) {
          // Midtrans Snap menampilkan halaman expired-nya sendiri (mis. #/407).
          // Jangan timpa dengan overlay error kita.
          final reqUrl = err.request?.uri.toString() ?? '';
          if (reqUrl.contains('midtrans.com/snap')) return;

          if (mounted) {
            setState(() {
              _errorMessage =
                  'Terjadi kesalahan HTTP: ${err.response?.statusCode}';
              _errorType = ErrorType.http;
              _isLoading = false;
            });
            _animController.forward(from: 0);
          }
        },
        onWebResourceError: (err) {
          if (err.isForMainFrame == false) return;
          if (err.description.contains('ERR_UNKNOWN_URL_SCHEME')) return;
          final ignore = [
            'net::ERR_BLOCKED_BY_CLIENT',
            'net::ERR_FAILED',
            'net::ERR_ABORTED',
          ];
          if (ignore.any((e) => err.description.contains(e))) return;

          if (mounted) {
            setState(() {
              _errorMessage = _mapErrorMessage(err);
              _errorType = _mapErrorType(err);
              _isLoading = false;
            });
            _animController.forward(from: 0);
          }
        },
        onNavigationRequest: (req) {
          if (_isExternalUrl(req.url)) {
            _openExternal(req.url);
            return NavigationDecision.prevent;
          }
          if (req.url.contains('wa.me') ||
              req.url.contains('api.whatsapp.com')) {
            _openExternal(_toWhatsAppUrl(req.url));
            return NavigationDecision.prevent;
          }
          if (req.url == 'about:blank' || req.url.startsWith('javascript:')) {
            return NavigationDecision.prevent;
          }
          // Tombol "Download QRIS" Midtrans Snap men-set location ke blob:
          // URL (hasil generate QR di sisi JS). WebView tidak sanggup
          // menavigasi ke blob: sebagai file — batalkan navigasinya dan
          // ambil isinya lewat JS selagi context halaman masih hidup.
          if (req.url.startsWith('blob:')) {
            _extractBlobViaJs(req.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));

    _loadUrl(url);
  }

  /// Cek apakah URL adalah callback dari Midtrans Snap,
  /// lalu trigger immediate poll tanpa menunggu interval berikutnya.
  void _checkSnapCallbackUrl(String url) {
    if (!_isPaymentMode || _isNavigating) return;

    final lowerUrl = url.toLowerCase();
    debugPrint('[WebviewPage] 🔍 URL check: $url');

    final isSuccess = _successUrlPatterns.any((p) => lowerUrl.contains(p));
    final isFailed = _failedUrlPatterns.any((p) => lowerUrl.contains(p));

    if (isSuccess) {
      debugPrint('[WebviewPage] ✅ Snap success URL — trigger immediate poll');
      _pollStatus();
    } else if (isFailed) {
      debugPrint('[WebviewPage] ❌ Snap failed/cancel URL detected');
    }
  }

  /// Fetch ulang isi blob: URL dari dalam context halaman (masih hidup
  /// karena navigasinya sudah dibatalkan), lalu kirim sebagai data URL
  /// base64 lewat JavaScriptChannel `FlutterDownload`.
  Future<void> _handleBlobDownload(String blobUrl) async {
    final escapedUrl = blobUrl.replaceAll("'", "\\'");
    final script = '''
      (function() {
        fetch('$escapedUrl')
          .then(function(res) { return res.blob(); })
          .then(function(blob) {
            var reader = new FileReader();
            reader.onloadend = function() {
              FlutterDownload.postMessage(reader.result);
            };
            reader.onerror = function() {
              FlutterDownload.postMessage('ERROR:gagal membaca blob');
            };
            reader.readAsDataURL(blob);
          })
          .catch(function(e) {
            FlutterDownload.postMessage('ERROR:' + e.message);
          });
      })();
    ''';
    try {
      await _controller.runJavaScript(script);
    } catch (e) {
      debugPrint('[WebviewPage] ⚠️ Gagal jalankan skrip unduhan blob: $e');
    }
  }

  // ── Blob download helper ─────────────────────────────────────────
//
// Alur "Download QRIS" Midtrans Snap: buat Blob → createObjectURL →
// klik anchor → SEGERA revokeObjectURL (sinkron, di call stack yang
// sama). Round-trip Dart↔JS kita (dicegat navigasi → panggil balik
// runJavaScript) bersifat async, jadi selalu kalah cepat — begitu
// script kita jalan, URL sudah revoked → fetch() gagal
// ("Failed to fetch").
//
// Fix: override URL.createObjectURL supaya begitu Blob dibuat, kita
// simpan REFERENSI OBJEK BLOB-nya sendiri (bukan cuma string URL) di
// cache. Objek Blob tetap hidup di memory selama masih direferensikan,
// walaupun URL-nya sudah di-revoke — jadi kita ambil dari cache
// duluan, fetch() hanya jadi fallback kalau entah kenapa cache kosong.
  Future<void> _injectDownloadHelper() async {
    const script = '''
    (function() {
      if (window.__ftDownloadHelperInstalled) return;
      window.__ftDownloadHelperInstalled = true;

      window.__ftBlobCache = {};
      var origCreateObjectURL = URL.createObjectURL.bind(URL);
      URL.createObjectURL = function(blob) {
        var url = origCreateObjectURL(blob);
        window.__ftBlobCache[url] = blob;
        return url;
      };

      window.__ftExtractBlob = function(url) {
        var cached = window.__ftBlobCache[url];
        var blobPromise = cached
          ? Promise.resolve(cached)
          : fetch(url).then(function(r) { return r.blob(); });

        blobPromise.then(function(blob) {
          var reader = new FileReader();
          reader.onloadend = function() {
            FlutterDownload.postMessage(reader.result);
          };
          reader.onerror = function() {
            FlutterDownload.postMessage('ERROR:gagal membaca blob');
          };
          reader.readAsDataURL(blob);
        }).catch(function(err) {
          FlutterDownload.postMessage('ERROR:' + err.message);
        });
      };

      // Cegat klik tombol download SEBELUM handler asli Snap sempat
      // jalan (capture phase) — mencegah navigasi default sekaligus
      // memastikan kita ambil blob lewat cache, bukan fetch ke URL
      // yang berpotensi sudah revoked.
      document.addEventListener('click', function(e) {
        var el = e.target;
        while (el && el.tagName !== 'A') { el = el.parentElement; }
        if (!el) return;
        var href = el.getAttribute('href') || '';
        if (!href.startsWith('blob:') || !el.hasAttribute('download')) return;

        e.preventDefault();
        e.stopPropagation();
        if (typeof e.stopImmediatePropagation === 'function') {
          e.stopImmediatePropagation();
        }
        window.__ftExtractBlob(href);
      }, true);
    })();
  ''';

    try {
      await _controller.runJavaScript(script);
    } catch (e) {
      debugPrint('[WebviewPage] ⚠️ Gagal pasang download helper: $e');
    }
  }

  /// Fallback untuk kasus blob: lolos dari click-interceptor (mis. dipicu
  /// via `window.location = blob:...` alih-alih anchor `download`).
  /// Tetap lewat window.__ftExtractBlob supaya cache Blob (jika ada)
  /// tetap diprioritaskan sebelum fetch().
  Future<void> _extractBlobViaJs(String blobUrl) async {
    final escapedUrl = blobUrl.replaceAll("'", "\\'");
    try {
      await _controller.runJavaScript(
        "window.__ftExtractBlob && window.__ftExtractBlob('$escapedUrl');",
      );
    } catch (e) {
      debugPrint('[WebviewPage] ⚠️ Gagal jalankan extractBlob: $e');
    }
  }

  Future<void> _handleDownloadMessage(String message) async {
  if (message.startsWith('ERROR:')) {
    debugPrint('[WebviewPage] ⚠️ Blob download error: $message');
    if (mounted) {
      CustomSnackbar.showErrorSnackbar(context, 'Gagal mengunduh QR Code');
    }
    return;
  }

  try {
    final base64Str = message.contains(',') ? message.split(',').last : message;
    final bytes = base64Decode(base64Str);

    // ✅ Pakai permission API bawaan `gal`, bukan permission_handler.
    // Gal tahu persis permission apa yang dibutuhkan per versi Android/iOS
    // untuk MENULIS ke galeri, tanpa perlu deklarasi manual tambahan di
    // AndroidManifest.xml (Android 10+ scoped storage tidak butuh runtime
    // permission untuk menyimpan file baru lewat MediaStore).
    final hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      final granted = await Gal.requestAccess();
      if (!granted) {
        if (mounted) {
          CustomSnackbar.showErrorSnackbar(
              context, 'Izin penyimpanan diperlukan untuk mengunduh QR Code');
        }
        return;
      }
    }

    await Gal.putImageBytes(
      bytes,
      album: 'QRIS Payment',
      name: 'QRIS_Payment_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (mounted) {
      CustomSnackbar.showSuccessSnackbar(context, 'QR Code berhasil disimpan');
    }
  } catch (e) {
    debugPrint('[WebviewPage] ⚠️ Gagal simpan QR dari blob: $e');
    if (mounted) {
      CustomSnackbar.showErrorSnackbar(
          context, 'Gagal mengunduh QR Code: ${e.toString()}');
    }
  }
}

  Future<void> _loadUrl(String url) async {
    try {
      await _controller.loadRequest(Uri.parse(url));
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat URL: $url';
          _errorType = ErrorType.unknown;
          _isLoading = false;
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorType = null;
    });
    String url = widget.url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    _loadUrl(url);
  }

  /// Fallback ke core payment — pop webview lalu panggil callback
  void _fallbackToCore() {
    _pollingTimer?.cancel();
    _fcmSubscription?.cancel();
    Navigator.of(context).pop();
    widget.onFallbackToCore?.call();
  }

  // =========================================
  // BUILD
  // =========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: _isNavigating ? null : const CustomBackButton(),
        title: _isPaymentMode
            ? const Text(
                'Pembayaran',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              )
            : null,
        actions: [
          if (_isNavigating)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.green.shade600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Memproses...',
                    style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: WebViewWidget(controller: _controller)),
            if (_isLoading) _buildLoading(),
            if (_errorMessage != null && !_isLoading) _buildError(),
            if (_isNavigating && _isPaymentMode) _buildSuccessOverlay(),
          ],
        ),
      ),
    );
  }

  // ── Success overlay ─────────────────────────────────────────────────────
  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 72, color: Colors.green.shade400),
            const SizedBox(height: 20),
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Sedang memproses pesanan Anda...',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Colors.green.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loading ─────────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Colors.deepPurple.shade400),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Memuat halaman...',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                widget.url,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error ───────────────────────────────────────────────────────────────
  Widget _buildError() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          color: Colors.white,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _errorIcon(),
                  const SizedBox(height: 32),
                  Text(
                    _errorTitle(),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorDesc(),
                    style: TextStyle(
                        fontSize: 15, color: Colors.grey.shade600, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  _retryButton(),
                  // Tombol fallback ke core — hanya muncul di payment mode
                  if (_isPaymentMode && widget.onFallbackToCore != null) ...[
                    const SizedBox(height: 16),
                    _fallbackButton(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorIcon() {
    final (icon, color, bg) = switch (_errorType) {
      ErrorType.noInternet => (
          Icons.wifi_off_rounded,
          const Color(0xFFEF4444),
          const Color(0xFFFEE2E2)
        ),
      ErrorType.timeout => (
          Icons.access_time_rounded,
          const Color(0xFFF59E0B),
          const Color(0xFFFEF3C7)
        ),
      ErrorType.serverError => (
          Icons.dns_rounded,
          const Color(0xFF8B5CF6),
          const Color(0xFFEDE9FE)
        ),
      ErrorType.http => (
          Icons.error_outline_rounded,
          const Color(0xFFEC4899),
          const Color(0xFFFCE7F3)
        ),
      ErrorType.sslError => (
          Icons.lock_outline_rounded,
          const Color(0xFFEF4444),
          const Color(0xFFFEE2E2)
        ),
      _ => (
          Icons.sentiment_dissatisfied_rounded,
          const Color(0xFF6B7280),
          const Color(0xFFF3F4F6)
        ),
    };
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, size: 60, color: color),
    );
  }

  String _errorTitle() => switch (_errorType) {
        ErrorType.noInternet => 'Tidak Ada Koneksi',
        ErrorType.timeout => 'Koneksi Timeout',
        ErrorType.serverError => 'Server Bermasalah',
        ErrorType.http => 'Terjadi Kesalahan',
        ErrorType.sslError => 'Masalah Keamanan',
        _ => 'Oops! Ada Masalah',
      };

  String _errorDesc() => switch (_errorType) {
        ErrorType.noInternet =>
          'Sepertinya kamu sedang offline.\nPastikan koneksi internet aktif.',
        ErrorType.timeout => 'Halaman membutuhkan waktu terlalu lama.',
        ErrorType.serverError =>
          'Tidak dapat terhubung ke server.\nCoba beberapa saat lagi.',
        ErrorType.sslError => 'Ada masalah dengan sertifikat keamanan.',
        _ => _errorMessage ?? 'Terjadi kesalahan yang tidak terduga.',
      };

  Widget _retryButton() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 300),
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.deepPurple.shade400,
          Colors.deepPurple.shade600,
        ]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _retry,
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'Coba Lagi',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tombol fallback ke metode pembayaran core (tanpa Snap)
  Widget _fallbackButton() {
    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: TextButton(
          onPressed: _fallbackToCore,
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment_outlined,
                  size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'Gunakan Metode Pembayaran Lain',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================
  // HELPERS
  // =========================================

  bool _isExternalUrl(String url) {
    try {
      final scheme = Uri.parse(url).scheme.toLowerCase();
      return [
        'whatsapp',
        'wa',
        'tel',
        'mailto',
        'sms',
        'intent',
        'market',
        'fb',
        'facebook',
        'instagram',
        'twitter',
        'tg',
        'viber',
        'line',
        'maps',
        'geo',
      ].contains(scheme);
    } catch (_) {
      return false;
    }
  }

  Future<void> _openExternal(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[WebviewPage] ⚠️ openExternal error: $e');
    }
  }

  String _toWhatsAppUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final phone = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : '';
      final text = uri.queryParameters['text'] ?? '';
      if (phone.isNotEmpty) {
        return text.isNotEmpty
            ? 'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(text)}'
            : 'whatsapp://send?phone=$phone';
      }
    } catch (_) {}
    return url;
  }

  String _mapErrorMessage(WebResourceError error) {
    final d = error.description.toLowerCase();
    if (d.contains('internet') || d.contains('network')) {
      return 'Tidak ada koneksi internet';
    }
    if (d.contains('timeout')) return 'Koneksi timeout';
    if (d.contains('host') || d.contains('resolve')) {
      return 'Server tidak dapat dihubungi';
    }
    if (d.contains('ssl') || d.contains('certificate')) {
      return 'Masalah sertifikat keamanan';
    }
    return 'Terjadi kesalahan: ${error.description}';
  }

  ErrorType _mapErrorType(WebResourceError error) {
    final d = error.description.toLowerCase();
    if (d.contains('internet') || d.contains('network')) {
      return ErrorType.noInternet;
    }
    if (d.contains('timeout')) return ErrorType.timeout;
    if (d.contains('host') || d.contains('resolve')) {
      return ErrorType.serverError;
    }
    if (d.contains('ssl') || d.contains('certificate')) {
      return ErrorType.sslError;
    }
    return ErrorType.unknown;
  }
}

enum ErrorType { noInternet, timeout, serverError, http, sslError, unknown }
