import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewPage extends StatefulWidget {
  final String url;
  const WebviewPage({super.key, required this.url});

  @override
  State<WebviewPage> createState() => _WebviewPageState();
}

class _WebviewPageState extends State<WebviewPage>
    with SingleTickerProviderStateMixin {
  late WebViewController controller;
  bool isLoading = true;
  String? errorMessage;
  ErrorType? errorType;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeWebView();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _handleExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          _showErrorSnackbar('Tidak dapat membuka $url');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool _isExternalUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final scheme = uri.scheme.toLowerCase();
      final externalSchemes = [
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
      ];
      return externalSchemes.contains(scheme);
    } catch (e) {
      return false;
    }
  }

  void _initializeWebView() {
    // ✅ FIX 1: Validasi URL sebelum load
    String urlToLoad = widget.url;
    if (!urlToLoad.startsWith('http://') && !urlToLoad.startsWith('https://')) {
      urlToLoad = 'https://$urlToLoad';
    }

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true)
      // ✅ FIX 2: Tambahkan User Agent untuk kompatibilitas
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('Loading progress: $progress%');
            // ✅ FIX 3: Jangan langsung set isLoading = false di progress 100
            // Biarkan onPageFinished yang handle
          },
          onPageStarted: (String url) {
            debugPrint('Page started: $url');
            if (mounted) {
              setState(() {
                isLoading = true;
                errorMessage = null;
                errorType = null;
              });
            }
          },
          onPageFinished: (String url) {
            debugPrint('Page finished: $url');
            if (mounted) {
              // ✅ FIX 4: Delay sedikit untuk memastikan konten ter-render
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  setState(() => isLoading = false);
                }
              });
            }
          },
          onHttpError: (HttpResponseError error) {
            debugPrint('HTTP Error: ${error.response?.statusCode}');
            if (mounted) {
              setState(() {
                errorMessage =
                    'Terjadi kesalahan HTTP: ${error.response?.statusCode ?? "Unknown"}';
                errorType = ErrorType.http;
                isLoading = false;
              });
              _animationController.forward(from: 0);
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
                'WebResource Error: ${error.description}, type: ${error.errorType}');

            // ✅ FIX 5: Ignore error untuk sub-resources, fokus pada main frame
            if (error.isForMainFrame == false) {
              return;
            }

            // Handle ERR_UNKNOWN_URL_SCHEME
            if (error.description.contains('ERR_UNKNOWN_URL_SCHEME')) {
              return;
            }

            // ✅ FIX 6: Ignore beberapa error yang tidak critical
            final ignorableErrors = [
              'net::ERR_BLOCKED_BY_CLIENT',
              'net::ERR_FAILED',
              'net::ERR_ABORTED',
            ];

            for (final ignorable in ignorableErrors) {
              if (error.description.contains(ignorable)) {
                return;
              }
            }

            if (mounted) {
              setState(() {
                errorMessage = _getErrorMessage(error);
                errorType = _getErrorType(error);
                isLoading = false;
              });
              _animationController.forward(from: 0);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Navigation request: ${request.url}');
            final url = request.url;

            if (_isExternalUrl(url)) {
              _handleExternalUrl(url);
              return NavigationDecision.prevent;
            }

            if (url.contains('wa.me') || url.contains('api.whatsapp.com')) {
              final waUrl = _convertToWhatsAppUrl(url);
              _handleExternalUrl(waUrl);
              return NavigationDecision.prevent;
            }

            // ✅ FIX 7: Handle about:blank dan javascript: scheme
            if (url == 'about:blank' || url.startsWith('javascript:')) {
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          // ✅ FIX 8: Tambahkan handler untuk URL loading
          onUrlChange: (UrlChange change) {
            debugPrint('URL changed to: ${change.url}');
          },
        ),
      );

    // ✅ FIX 9: Load URL dengan try-catch
    _loadUrl(urlToLoad);
  }

  // ✅ FIX 10: Separate method untuk load URL dengan error handling
  Future<void> _loadUrl(String url) async {
    try {
      debugPrint('Loading URL: $url');
      await controller.loadRequest(Uri.parse(url));
    } catch (e) {
      debugPrint('Error loading URL: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Gagal memuat URL: $url';
          errorType = ErrorType.unknown;
          isLoading = false;
        });
        _animationController.forward(from: 0);
      }
    }
  }

  String _convertToWhatsAppUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('wa.me')) {
        final segments = uri.pathSegments;
        if (segments.isNotEmpty) {
          final phone = segments[0];
          final text = uri.queryParameters['text'] ?? '';
          if (text.isNotEmpty) {
            return 'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(text)}';
          }
          return 'whatsapp://send?phone=$phone';
        }
      }
      if (uri.host.contains('api.whatsapp.com')) {
        final phone = uri.queryParameters['phone'] ?? '';
        final text = uri.queryParameters['text'] ?? '';
        if (phone.isNotEmpty) {
          if (text.isNotEmpty) {
            return 'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(text)}';
          }
          return 'whatsapp://send?phone=$phone';
        }
      }
      return url;
    } catch (e) {
      return url;
    }
  }

  String _getErrorMessage(WebResourceError error) {
    if (error.description.toLowerCase().contains('internet') ||
        error.description.toLowerCase().contains('network')) {
      return 'Tidak ada koneksi internet';
    } else if (error.description.toLowerCase().contains('timeout')) {
      return 'Koneksi timeout';
    } else if (error.description.toLowerCase().contains('host') ||
        error.description.toLowerCase().contains('resolve')) {
      return 'Server tidak dapat dihubungi';
    } else if (error.description.toLowerCase().contains('ssl') ||
        error.description.toLowerCase().contains('certificate')) {
      return 'Masalah sertifikat keamanan';
    }
    return 'Terjadi kesalahan: ${error.description}';
  }

  ErrorType _getErrorType(WebResourceError error) {
    final desc = error.description.toLowerCase();
    if (desc.contains('internet') || desc.contains('network')) {
      return ErrorType.noInternet;
    } else if (desc.contains('timeout')) {
      return ErrorType.timeout;
    } else if (desc.contains('host') || desc.contains('resolve')) {
      return ErrorType.serverError;
    } else if (desc.contains('ssl') || desc.contains('certificate')) {
      return ErrorType.sslError;
    }
    return ErrorType.unknown;
  }

  Future<bool> _onWillPop() async {
    if (await controller.canGoBack()) {
      controller.goBack();
      return false;
    }
    return true;
  }

  void _retry() {
    String urlToLoad = widget.url;
    if (!urlToLoad.startsWith('http://') && !urlToLoad.startsWith('https://')) {
      urlToLoad = 'https://$urlToLoad';
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      errorType = null;
    });
    _loadUrl(urlToLoad);
  }

  // ✅ FIX 11: Method untuk debug - cek current URL
  Future<void> _debugCurrentUrl() async {
    final currentUrl = await controller.currentUrl();
    debugPrint('Current URL in WebView: $currentUrl');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 0,
          leading: const CustomBackButton(),
          // ✅ FIX 12: Tambah refresh button untuk debug
          actions: [
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF9F9F9),
                  foregroundColor: Constants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: Colors.deepPurple.shade400,
                      width: 1,
                    ),
                  ),),
              onPressed: () async {
                await _handleExternalUrl(widget.url);
              },
              child: Text("Buka Langsung"),
            ),
            SizedBox(width: 20,)
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // ✅ FIX 13: Pastikan WebViewWidget memiliki ukuran
              Positioned.fill(
                child: WebViewWidget(controller: controller),
              ),
              if (isLoading) _buildLoadingIndicator(),
              if (errorMessage != null && !isLoading) _buildErrorPage(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
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
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.deepPurple.shade400,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Memuat halaman...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            // ✅ FIX 14: Tampilkan URL yang sedang dimuat
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                widget.url,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
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

  Widget _buildErrorPage(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          color: Colors.white,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: _buildErrorIcon(),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _getErrorTitle(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getErrorDescription(),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  _buildRetryButton(),
                  const SizedBox(height: 16),
                  Text(
                    _getHelpText(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorIcon() {
    IconData iconData;
    Color iconColor;
    Color backgroundColor;

    switch (errorType) {
      case ErrorType.noInternet:
        iconData = Icons.wifi_off_rounded;
        iconColor = const Color(0xFFEF4444);
        backgroundColor = const Color(0xFFFEE2E2);
        break;
      case ErrorType.timeout:
        iconData = Icons.access_time_rounded;
        iconColor = const Color(0xFFF59E0B);
        backgroundColor = const Color(0xFFFEF3C7);
        break;
      case ErrorType.serverError:
        iconData = Icons.dns_rounded;
        iconColor = const Color(0xFF8B5CF6);
        backgroundColor = const Color(0xFFEDE9FE);
        break;
      case ErrorType.http:
        iconData = Icons.error_outline_rounded;
        iconColor = const Color(0xFFEC4899);
        backgroundColor = const Color(0xFFFCE7F3);
        break;
      case ErrorType.sslError:
        iconData = Icons.lock_outline_rounded;
        iconColor = const Color(0xFFEF4444);
        backgroundColor = const Color(0xFFFEE2E2);
        break;
      default:
        iconData = Icons.sentiment_dissatisfied_rounded;
        iconColor = const Color(0xFF6B7280);
        backgroundColor = const Color(0xFFF3F4F6);
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: 60,
        color: iconColor,
      ),
    );
  }

  String _getErrorTitle() {
    switch (errorType) {
      case ErrorType.noInternet:
        return 'Tidak Ada Koneksi';
      case ErrorType.timeout:
        return 'Koneksi Timeout';
      case ErrorType.serverError:
        return 'Server Bermasalah';
      case ErrorType.http:
        return 'Terjadi Kesalahan';
      case ErrorType.sslError:
        return 'Masalah Keamanan';
      default:
        return 'Oops! Ada Masalah';
    }
  }

  String _getErrorDescription() {
    switch (errorType) {
      case ErrorType.noInternet:
        return 'Sepertinya kamu sedang offline.\nPastikan koneksi internet aktif dan coba lagi.';
      case ErrorType.timeout:
        return 'Halaman membutuhkan waktu terlalu lama.\nCoba lagi dalam beberapa saat.';
      case ErrorType.serverError:
        return 'Tidak dapat terhubung ke server.\nSilakan coba beberapa saat lagi.';
      case ErrorType.http:
        return 'Terjadi kesalahan saat memuat halaman.\nSilakan coba lagi.';
      case ErrorType.sslError:
        return 'Ada masalah dengan sertifikat keamanan.\nSitus mungkin tidak aman.';
      default:
        return errorMessage ??
            'Terjadi kesalahan yang tidak terduga.\nSilakan coba lagi.';
    }
  }

  String _getHelpText() {
    switch (errorType) {
      case ErrorType.noInternet:
        return 'Periksa WiFi atau data seluler Anda';
      case ErrorType.timeout:
        return 'Koneksi internet mungkin lambat';
      case ErrorType.serverError:
        return 'Masalah mungkin dari sisi server';
      case ErrorType.sslError:
        return 'Periksa tanggal/waktu perangkat Anda';
      default:
        return 'Jika masalah berlanjut, hubungi kami';
    }
  }

  Widget _buildRetryButton() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 300),
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade400,
            Colors.deepPurple.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
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
                Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Coba Lagi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum ErrorType {
  noInternet,
  timeout,
  serverError,
  http,
  sslError,
  unknown,
}
