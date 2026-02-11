import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/services/media_preload_service.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/hive_entity/media_url_model.dart';

/// Widget untuk menampilkan gambar post dengan swipe horizontal.
///
/// ✅ UPDATED: Menggunakan MediaPreloadService untuk background preloading
/// ✅ Semua gambar di-preload saat widget dibuat
/// ✅ User tidak perlu menunggu saat swipe
///
/// TIDAK menggunakan PageView untuk menghindari unbounded height error.
/// Menggunakan AnimatedSwitcher + GestureDetector untuk navigasi.
/// Tinggi gambar mengikuti aspect ratio asli setelah load.
class ImagePost extends StatefulWidget {
  final List<MediaUrlModel> mediaUrl;
  final BoxFit fit;
  
  // ✅ NEW: Control preloading behavior
  final bool enablePreload;

  const ImagePost({
    super.key,
    required this.mediaUrl,
    this.fit = BoxFit.cover,
    this.enablePreload = true, // ✅ Default: enabled
  });

  @override
  State<ImagePost> createState() => _ImagePostState();
}

class _ImagePostState extends State<ImagePost> {
  int _currentIndex = 0;
  bool _isImageLoaded = false;
  double? _imageHeight;
  
  // ✅ NEW: Preload service instance
  final MediaPreloadService _preloadService = MediaPreloadService();
  
  // ✅ NEW: Track preload status
  bool _isPreloading = false;
  final Set<int> _preloadedIndices = {};

  @override
  void initState() {
    super.initState();
    
    // ✅ Preload all images in background
    if (widget.enablePreload) {
      _preloadAllImages();
    }
  }

  @override
  void didUpdateWidget(ImagePost oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // ✅ If media URLs changed, preload new images
    if (widget.mediaUrl != oldWidget.mediaUrl && widget.enablePreload) {
      _preloadAllImages();
    }
  }

  // ✅ NEW: Preload all images in this post
  Future<void> _preloadAllImages() async {
    if (_isPreloading) return;
    
    final validMedia = widget.mediaUrl
        .where((media) => media.idMedia != null && media.idMedia!.isNotEmpty)
        .toList();

    if (validMedia.isEmpty) return;

    setState(() {
      _isPreloading = true;
    });

    try {
      debugPrint('[ImagePost] 🚀 Preloading ${validMedia.length} images...');

      // Extract URLs from media
      final urls = validMedia
          .map((media) => media.displayUrl)
          .where((url) => url != null && url.isNotEmpty)
          .cast<String>()
          .toList();

      // Preload with high priority (this is the current post user is viewing)
      await _preloadService.preloadUrls(
        urls,
        priority: 10, // High priority
      );

      // Mark all as preloaded
      if (mounted) {
        setState(() {
          for (int i = 0; i < validMedia.length; i++) {
            _preloadedIndices.add(i);
          }
        });
      }

      debugPrint('[ImagePost] ✅ All images preloaded');
    } catch (e) {
      debugPrint('[ImagePost] ⚠️ Preload error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPreloading = false;
        });
      }
    }
  }

  // ✅ IMPROVED: Preload adjacent images when index changes
  void _preloadAdjacentImages(int currentIndex) {
    final validMedia = widget.mediaUrl
        .where((media) => media.idMedia != null && media.idMedia!.isNotEmpty)
        .toList();

    // Preload next image
    if (currentIndex + 1 < validMedia.length && 
        !_preloadedIndices.contains(currentIndex + 1)) {
      final nextMedia = validMedia[currentIndex + 1];
      if (nextMedia.displayUrl != null) {
        _preloadService.preloadUrls(
          [nextMedia.displayUrl!],
          priority: 9,
        );
        _preloadedIndices.add(currentIndex + 1);
      }
    }

    // Preload previous image
    if (currentIndex - 1 >= 0 && 
        !_preloadedIndices.contains(currentIndex - 1)) {
      final prevMedia = validMedia[currentIndex - 1];
      if (prevMedia.displayUrl != null) {
        _preloadService.preloadUrls(
          [prevMedia.displayUrl!],
          priority: 9,
        );
        _preloadedIndices.add(currentIndex - 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final validMedia = widget.mediaUrl
        .where((media) => media.idMedia != null && media.idMedia!.isNotEmpty)
        .toList();

    if (validMedia.isEmpty) {
      return _buildEmptyPlaceholder();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Container gambar dengan gesture detector
        GestureDetector(
          onHorizontalDragEnd: (details) {
            if (validMedia.length <= 1) return;

            // Swipe ke kiri (next)
            if (details.primaryVelocity! < -300) {
              if (_currentIndex < validMedia.length - 1) {
                setState(() {
                  _currentIndex++;
                  _isImageLoaded = false;
                });
                
                // ✅ Preload adjacent when changing index
                _preloadAdjacentImages(_currentIndex);
              }
            }
            // Swipe ke kanan (previous)
            else if (details.primaryVelocity! > 300) {
              if (_currentIndex > 0) {
                setState(() {
                  _currentIndex--;
                  _isImageLoaded = false;
                });
                
                // ✅ Preload adjacent when changing index
                _preloadAdjacentImages(_currentIndex);
              }
            }
          },
          child: Container(
            width: double.infinity,
            color: Colors.grey.shade50,
            // Gunakan intrinsic height jika sudah ada, atau constraint default
            constraints: BoxConstraints(
              minHeight: _imageHeight ?? 200,
              maxHeight: _imageHeight ?? double.infinity,
            ),
            child: Stack(
              children: [
                // Gambar dengan AnimatedSwitcher untuk transisi smooth
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: _buildImageItem(
                    validMedia[_currentIndex],
                    key: ValueKey(_currentIndex),
                    isPreloaded: _preloadedIndices.contains(_currentIndex),
                  ),
                ),

                // Counter di pojok kanan atas
                if (validMedia.length > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildCounter(validMedia.length),
                  ),
                
                // ✅ NEW: Preload indicator (optional, for debugging)
                if (widget.enablePreload && _isPreloading)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: _buildPreloadIndicator(),
                  ),
              ],
            ),
          ),
        ),

        // Indicator dots
        if (validMedia.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _buildIndicator(validMedia.length),
          ),
      ],
    );
  }

  Widget _buildImageItem(
    MediaUrlModel media, {
    Key? key,
    bool isPreloaded = false,
  }) {
    return CachedNetworkImage(
      key: key,
      imageUrl: media.idMedia!,
      fit: widget.fit,
      width: double.infinity,
      placeholder: (context, url) {
        // ✅ IMPROVED: Jika sudah preloaded, tampilkan loading yang lebih subtle
        if (isPreloaded) {
          return _buildSubtleLoadingPlaceholder();
        }
        
        // Tampilkan thumbnail sambil loading gambar utama
        if (media.thumbUrl != null && media.thumbUrl!.isNotEmpty) {
          return Stack(
            children: [
              // Thumbnail sebagai preview
              CachedNetworkImage(
                imageUrl: media.thumbUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: _imageHeight,
                placeholder: (context, url) => _buildLoadingPlaceholder(),
                errorWidget: (context, url, error) =>
                    _buildLoadingPlaceholder(),
              ),
              // Loading indicator overlay
              _buildLoadingOverlay(),
            ],
          );
        }
        return _buildLoadingPlaceholder();
      },
      errorWidget: (context, url, error) => _buildErrorWidget(),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 150),
      // Optimasi memory
      memCacheWidth: 1080,
      maxWidthDiskCache: 1080,
      // Custom image builder untuk mendapatkan ukuran asli
      imageBuilder: (context, imageProvider) {
        // Dapatkan ukuran gambar untuk constraint yang tepat
        if (!_isImageLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadImageDimensions(imageProvider);
          });
        }

        return Image(
          image: imageProvider,
          fit: widget.fit,
          width: double.infinity,
          // Biarkan height mengikuti aspect ratio asli gambar
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
        );
      },
    );
  }

  /// Load dimensi gambar untuk mendapatkan tinggi yang tepat
  Future<void> _loadImageDimensions(ImageProvider imageProvider) async {
    if (!mounted) return;

    final ImageStream stream =
        imageProvider.resolve(const ImageConfiguration());
    final Completer<void> completer = Completer<void>();
    late ImageStreamListener listener;

    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        if (!mounted) return;

        // Dapatkan ukuran layar
        final screenWidth = MediaQuery.of(context).size.width;

        // Hitung tinggi berdasarkan aspect ratio asli
        final imageWidth = info.image.width.toDouble();
        final imageHeight = info.image.height.toDouble();
        final aspectRatio = imageWidth / imageHeight;
        final calculatedHeight = screenWidth / aspectRatio;

        setState(() {
          _imageHeight = calculatedHeight;
          _isImageLoaded = true;
        });

        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (exception, stackTrace) {
        if (!mounted) return;

        setState(() {
          _imageHeight = 300; // Default height on error
          _isImageLoaded = true;
        });

        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    stream.addListener(listener);

    // Timeout protection
    Future.delayed(const Duration(seconds: 5), () {
      if (!completer.isCompleted && mounted) {
        setState(() {
          _imageHeight = 300; // Default height on timeout
          _isImageLoaded = true;
        });
        stream.removeListener(listener);
        completer.complete();
      }
    });
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: double.infinity,
      height: _imageHeight ?? 300,
      color: Colors.grey.shade50,
      child: Stack(
        children: [
          // Shimmer background
          const ShimmerPlaceholder(
            width: double.infinity,
            height: double.infinity,
          ),
          // Loading overlay
          _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ✅ NEW: Subtle loading untuk gambar yang sudah preloaded
  Widget _buildSubtleLoadingPlaceholder() {
    return Container(
      width: double.infinity,
      height: _imageHeight ?? 300,
      color: Colors.grey.shade50,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Memuat gambar...',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Preload indicator
  Widget _buildPreloadIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Memuat...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) {
          // ✅ IMPROVED: Different color for preloaded images
          final isPreloaded = _preloadedIndices.contains(index);
          final isActive = _currentIndex == index;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 6,
            width: isActive ? 20 : 6,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.black87
                  : (isPreloaded ? Colors.grey.shade300 : Colors.grey.shade400),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCounter(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${_currentIndex + 1}/$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      height: _imageHeight ?? 300,
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Gagal memuat gambar',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _isImageLoaded = false;
                });
              },
              child: Text(
                'Coba lagi',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      width: double.infinity,
      height: 300,
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada gambar',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}