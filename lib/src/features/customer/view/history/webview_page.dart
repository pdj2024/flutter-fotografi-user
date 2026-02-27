import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/view/payment/payment_success_splash_screen.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/order_tab_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebviewPage digunakan untuk dua keperluan:
///   1. Halaman Midtrans Snap ([paymentData] != null) — FCM listener aktif
///   2. URL umum ([paymentData] == null) — FCM listener tidak dipasang
class WebviewPage extends StatefulWidget {
  final String url;

  /// Isi [paymentData] saat membuka halaman Midtrans Snap.
  /// Kosongkan untuk penggunaan webview biasa.
  final PesananModel? paymentData;

  const WebviewPage({
    super.key,
    required this.url,
    this.paymentData,
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

  // Payment state
  bool _isNavigating = false;
  StreamSubscription<PesananModel>? _fcmSubscription;

  bool get _isPaymentMode => widget.paymentData != null;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initWebView();
    // Pasang FCM listener hanya untuk mode pembayaran
    if (_isPaymentMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _listenFCM());
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _fcmSubscription?.cancel();
    super.dispose();
  }

  // =========================================
  // FCM LISTENER
  // Aktif hanya saat membuka Midtrans Snap
  // =========================================
  void _listenFCM() {
    _fcmSubscription = context
        .read<PesananProvider>()
        .paymentUpdateStream
        .where((p) => p.noBukti == widget.paymentData!.noBukti)
        .listen((updated) async {
      debugPrint('[WebviewPage] 🔔 FCM payment update: ${updated.statusBayar}');
      if (!mounted || _isNavigating) return;

      if (PesananProvider.isPaymentSettled(updated.statusBayar)) {
        await _handlePaymentSuccess(updated);
      }
    });

    debugPrint('[WebviewPage] ✅ FCM stream listener attached');
  }

  // =========================================
  // HANDLE PAYMENT SUCCESS
  // =========================================
  Future<void> _handlePaymentSuccess(PesananModel updated) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    _fcmSubscription?.cancel();

    if (!mounted) return;

    try {
      await context.read<HistoryOrderProvider>().createPersiapan(
            updated.noBukti,
            updated.idCustomer,
          );

      await context.read<PesananProvider>().loadOrder(context);
      context.read<OrderTabProvider>().setSelectedTabIndex(1);

      if (!mounted) return;

      // Ganti seluruh stack dengan success page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentSuccessSplashScreen(
            orderNumber: updated.noTrackingPesanan ?? '',
            amount: updated.grandTotal,
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
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (_) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _isLoading = false);
          });
        },
        onHttpError: (err) {
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
          return NavigationDecision.navigate;
        },
      ));

    _loadUrl(url);
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

  // =========================================
  // BUILD
  // =========================================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_isNavigating) return; // sedang proses sukses, jangan pop
        if (await _controller.canGoBack()) {
          _controller.goBack();
        } else {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 0,
          leading: _isNavigating ? null : const CustomBackButton(),
          title: _isPaymentMode
              ? const Text('Pembayaran',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold))
              : null,
          actions: [
            // ── Indikator sukses (saat FCM diterima) ──────────────────────
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
                        valueColor:
                            AlwaysStoppedAnimation(Colors.green.shade600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Memproses...',
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            // ── Tombol buka langsung (hanya mode non-payment) ─────────────
            // if (!_isPaymentMode && !_isNavigating) ...[
            //   ElevatedButton(
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: const Color(0xFFF9F9F9),
            //       foregroundColor: Constants.primaryColor,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(20),
            //         side: BorderSide(
            //             color: Colors.deepPurple.shade400, width: 1),
            //       ),
            //     ),
            //     onPressed: () => _openExternal(widget.url),
            //     child: const Text('Buka Langsung'),
            //   ),
            //   const SizedBox(width: 20),
            // ],
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: WebViewWidget(controller: _controller)),
              if (_isLoading) _buildLoading(),
              if (_errorMessage != null && !_isLoading) _buildError(),
              // ── Payment success overlay ───────────────────────────────
              if (_isNavigating && _isPaymentMode) _buildSuccessOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Overlay saat pembayaran berhasil terdeteksi via FCM ────────────────
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
            Text('Memuat halaman...',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(widget.url,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

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
                  Text(_errorTitle(),
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748)),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(_errorDesc(),
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          height: 1.5),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 40),
                  _retryButton(),
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
                Text('Coba Lagi',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ],
            ),
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
    if (d.contains('internet') || d.contains('network'))
      return 'Tidak ada koneksi internet';
    if (d.contains('timeout')) return 'Koneksi timeout';
    if (d.contains('host') || d.contains('resolve'))
      return 'Server tidak dapat dihubungi';
    if (d.contains('ssl') || d.contains('certificate'))
      return 'Masalah sertifikat keamanan';
    return 'Terjadi kesalahan: ${error.description}';
  }

  ErrorType _mapErrorType(WebResourceError error) {
    final d = error.description.toLowerCase();
    if (d.contains('internet') || d.contains('network'))
      return ErrorType.noInternet;
    if (d.contains('timeout')) return ErrorType.timeout;
    if (d.contains('host') || d.contains('resolve'))
      return ErrorType.serverError;
    if (d.contains('ssl') || d.contains('certificate'))
      return ErrorType.sslError;
    return ErrorType.unknown;
  }
}

enum ErrorType { noInternet, timeout, serverError, http, sslError, unknown }
