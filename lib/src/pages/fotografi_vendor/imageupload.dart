// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:photo_manager/photo_manager.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:video_player/video_player.dart';

// import '../providers/constants.dart';
// import 'imageupload_review.dart';
// import 'dart:ui' as ui;
// import 'package:image/image.dart' as img;

// class ImageUploadPage extends StatefulWidget {
//   const ImageUploadPage({Key? key}) : super(key: key);

//   @override
//   State<ImageUploadPage> createState() => _ImageUploadPageState();
// }

// class _ImageUploadPageState extends State<ImageUploadPage> with TickerProviderStateMixin {
//   bool _hasPermission = false;
//   List<AssetEntity> _assets = [];
//   AssetEntity? _selectedAsset;
//   VideoPlayerController? _videoController;

//   final GlobalKey _previewKey = GlobalKey();

//   late ScrollController _scrollController;
//   bool _isPreviewVisible = true;
//   late AnimationController _animController;

//   BoxFit _fitMode = BoxFit.cover;

   

//   // Aspect ratio options
//   final Map<String, double> _aspectRatios = {
//     '1:1': 1.0,
//     // '16:9': 16 / 9,
//     '4:5': 4 / 5,
//   };
//   String _selectedAspectRatioLabel = '4:5'; // default

//   final Map<String, Uint8List?> _thumbCache = {};
//   Uint8List? _previewCache;
//   String? _previewCacheAssetId;

//   @override
//   void initState() {
//     super.initState();
//     _scrollController = ScrollController()..addListener(_scrollListener);

//     _animController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );

//     _requestPermissionAndFetch();
//   }

//   @override
//   void dispose() {
//     _scrollController.removeListener(_scrollListener);
//     _scrollController.dispose();
//     _videoController?.removeListener(_videoListener);
//     _videoController?.dispose();
//     _animController.dispose();
//     super.dispose();
//   }

//   void _scrollListener() {
//     if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
//       if (_isPreviewVisible) {
//         _isPreviewVisible = false;
//         _animController.forward();
//       }
//     } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
//       if (!_isPreviewVisible) {
//         _isPreviewVisible = true;
//         _animController.reverse();
//       }
//     }
//   }

//   Future<void> _requestPermissionAndFetch() async {
//     final PermissionState result = await PhotoManager.requestPermissionExtend();

//     if (result.isAuth) {
//       _hasPermission = true;
//       await _loadAssets();
//     } else {
//       _hasPermission = false;
//     }
//     setState(() {});
//   }

//   Future<void> _loadAssets() async {
//     final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
//       type: RequestType.common,
//       onlyAll: true,
//     );

//     if (albums.isEmpty) return;

//     _assets = await albums.first.getAssetListPaged(page: 0, size: 300);

//     if (_assets.isNotEmpty) {
//       _selectedAsset = _assets.first;
//       await _prepareVideoControllerIfNeeded(_selectedAsset!);
//       await _loadPreviewCache(_selectedAsset!);
//     }
//     setState(() {});
//   }

//   void _videoListener() {
//     if (_videoController == null) return;

//     final pos = _videoController!.value.position;
//     if (pos >= const Duration(seconds: 30)) {
//       _videoController!.seekTo(Duration.zero);
//       _videoController!.play();
//     }
//   }

//   Future<void> _prepareVideoControllerIfNeeded(AssetEntity asset) async {
//     _videoController?.removeListener(_videoListener);
//     await _videoController?.dispose();
//     _videoController = null;

//     if (asset.type == AssetType.video) {
//       final file = await asset.file;
//       if (file != null) {
//         _videoController = VideoPlayerController.file(file);
//         await _videoController!.initialize();
//         _videoController!
//           ..setLooping(false)
//           ..addListener(_videoListener)
//           ..play();
//       }
//     }
//     setState(() {});
//   }

//   Future<void> _loadPreviewCache(AssetEntity asset) async {
//     if (_previewCacheAssetId == asset.id) return;

//     if (asset.type == AssetType.image) {
//       _previewCache = await asset.thumbnailDataWithSize(const ThumbnailSize(1080, 1080));
//     } else {
//       _previewCache = null;
//     }
//     _previewCacheAssetId = asset.id;
//   }

//   void _onFitModeToggle() {
//     setState(() {
//       _fitMode = _fitMode == BoxFit.cover ? BoxFit.contain : BoxFit.cover;
//     });
//   }

//   // Ketika user pilih aspect ratio dari dropdown
//   void _onAspectRatioChanged(String? newValue) {
//     if (newValue == null) return;
//     setState(() {
//       _selectedAspectRatioLabel = newValue;
//     });
//   }

//   Future<Uint8List?> _capturePreview() async {
//     try {
//       RenderRepaintBoundary boundary = _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
//       final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
//       final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//       return byteData?.buffer.asUint8List();
//     } catch (e) {
//       print("Capture failed: $e");
//       return null;
//     }
//   }
// //   Future<Uint8List?> _capturePreview() async {
// //   try {
// //     RenderRepaintBoundary boundary = _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
// //     final ui.Image fullImage = await boundary.toImage(pixelRatio: 2.0);
// //     final byteData = await fullImage.toByteData(format: ui.ImageByteFormat.png);
// //     if (byteData == null) return null;

// //     Uint8List pngBytes = byteData.buffer.asUint8List();

// //     // Decode image pakai package 'image'
// //     final img.Image? decodedImage = img.decodeImage(pngBytes);
// //     if (decodedImage == null) return null;

// //     // Hitung aspect ratio preview konten (misal video size atau image size)
// //     // Kalau video:
// //     double contentWidth = 1;
// //     double contentHeight = 1;

// //     if (_selectedAsset?.type == AssetType.video && _videoController != null && _videoController!.value.isInitialized) {
// //       contentWidth = _videoController!.value.size.width.toDouble();
// //       contentHeight = _videoController!.value.size.height.toDouble();
// //     } else if (_previewCache != null) {
// //       // Kalau image cache, kamu bisa tentukan fixed ukuran sesuai image asli
// //       // Contoh (sesuaikan dengan ukuran image asli):
// //       contentWidth = 400;
// //       contentHeight = 300;
// //     }

// //     double contentAspectRatio = contentWidth / contentHeight;
// //     double widgetAspectRatio = decodedImage.width / decodedImage.height;

// //     int cropX = 0;
// //     int cropY = 0;
// //     int cropWidth;
// //     int cropHeight;

// //     if (widgetAspectRatio > contentAspectRatio) {
// //       // Widget lebih lebar, crop horizontal hitam (samping)
// //       cropHeight = decodedImage.height;
// //       cropWidth = (cropHeight * contentAspectRatio).toInt();
// //       cropX = ((decodedImage.width - cropWidth) / 2).toInt();
// //       cropY = 0;
// //     } else {
// //       // Widget lebih tinggi, crop vertical hitam (atas/bawah)
// //       cropWidth = decodedImage.width;
// //       cropHeight = (cropWidth / contentAspectRatio).toInt();
// //       cropX = 0;
// //       cropY = ((decodedImage.height - cropHeight) / 2).toInt();
// //     }

// //     img.Image croppedImage = img.copyCrop(decodedImage, cropX, cropY, cropWidth, cropHeight);
// //     Uint8List croppedBytes = Uint8List.fromList(img.encodePng(croppedImage));

// //     return croppedBytes;
// //   } catch (e) {
// //     print("Capture failed: $e");
// //     return null;
// //   }
// // }

  

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.clear),
//           onPressed: () => Navigator.of(context).maybePop(),
//         ),
//         title: const Text('Gallery'),
//         actions: [
//         TextButton(
//   onPressed: _selectedAsset == null
//       ? null
//       : () async {
//           if (_selectedAsset!.type == AssetType.video) {
//             // Langsung teruskan file video-nya ke halaman review tanpa capture preview
//             final file = await _selectedAsset!.file;
//             if (file != null) {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ReviewUploadPage(
//                     videoFile: file,   // misal kamu tambah parameter videoFile di ReviewUploadPage
//                     fit: _fitMode,
//                   ),
//                 ),
//               );
//             }
//           } else {
//             // Kalau image, seperti biasa capture preview dan teruskan
//             Uint8List? cropped = await _capturePreview();
//             if (cropped != null) {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ReviewUploadPage(
//                     imageBytes: cropped,
//                     fit: _fitMode,
//                   ),
//                 ),
//               );
//             }
//           }
//         },
//   child: const Text('Next', style: TextStyle(color: Colors.blue)),
// ),

//         ],
//       ),
//       body: _hasPermission ? _buildBody() : _buildNoPermission(),
//     );
//   }

//   Widget _buildBody() {
//     if (_assets.isEmpty) {
//       return const Center(
//         child: Text('Tidak ada foto / video', style: TextStyle(color: Colors.white)),
//       );
//     }

//     double aspectRatio = 1 /  (4 / 5);
    
//     if (_aspectRatios[_selectedAspectRatioLabel] != null) {
//       aspectRatio = 1 / _aspectRatios[_selectedAspectRatioLabel]!;
//     }

//     return Column(
//       children: [
//         // Dropdown aspect ratio
//         Container(
//           color: Colors.black,
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//           child: Row(
//             children: [
//               const Text(
//                 'Aspect Ratio: ',
//                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//               ),
//               DropdownButton<String>(
//                 value: _selectedAspectRatioLabel,
//                 dropdownColor: Colors.grey[900],
//                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//                 items: _aspectRatios.keys
//                     .map((label) => DropdownMenuItem(
//                           value: label,
//                           child: Text(label),
//                         ))
//                     .toList(),
//                 onChanged: _onAspectRatioChanged,
//               ),
//               const Spacer(),
//               _fitToggleButton(),
//             ],
//           ),
//         ),

//         // Preview area with fixed aspect ratio
//         AspectRatio(
//           aspectRatio: aspectRatio,
//           child: _selectedAsset != null ? _previewWidget(_selectedAsset!) : const SizedBox.shrink(),
//         ),

//         Expanded(
//           child: GridView.builder(
//             controller: _scrollController,
//             padding: const EdgeInsets.all(2),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               mainAxisSpacing: 2,
//               crossAxisSpacing: 2,
//             ),
//             itemCount: _assets.length,
//             itemBuilder: (context, index) {
//               final asset = _assets[index];
//               return _GridThumbnail(
//                 asset: asset,
//                 isSelected: asset == _selectedAsset,
//                 thumbCache: _thumbCache,
//                 onTap: () async {
//                   if (_selectedAsset == asset) return;
//                   _selectedAsset = asset;
//                   _fitMode = BoxFit.cover;
//                   _previewCache = null;
//                   _previewCacheAssetId = null;
//                   await _prepareVideoControllerIfNeeded(asset);
//                   await _loadPreviewCache(asset);
//                   setState(() {});
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _previewWidget(AssetEntity asset) {
//     if (asset.type == AssetType.video && _videoController?.value.isInitialized == true) {
//       return RepaintBoundary(
//         key: _previewKey,
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             InteractiveViewer(
//               boundaryMargin: const EdgeInsets.all(80),
//               maxScale: 5,
//               minScale: 1,
//               child: FittedBox(
//                 fit: _fitMode,
//                 alignment: Alignment.center,
//                 child: SizedBox(
//                   width: _videoController!.value.size.width,
//                   height: _videoController!.value.size.height,
//                   child: VideoPlayer(_videoController!),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     if (_previewCache != null) {
//       return RepaintBoundary(
//         key: _previewKey,
//         child: InteractiveViewer(
//           boundaryMargin: const EdgeInsets.all(80),
//           maxScale: 5,
//           minScale: 1,
//           child: Image.memory(_previewCache!, fit: _fitMode, alignment: Alignment.center),
//         ),
//       );
//     }

//     return const Center(child: CircularProgressIndicator());
//   }

//   Widget _fitToggleButton() {
//     return InkWell(
//       onTap: _onFitModeToggle,
//       borderRadius: BorderRadius.circular(24),
//       child: Container(
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: Colors.black54,
//           shape: BoxShape.circle,
//           border: Border.all(color: Colors.white70, width: 1.5),
//         ),
//         child: Icon(
//           Icons.fit_screen,
//           color: Colors.white,
//           size: 28,
//         ),
//       ),
//     );
//   }

//   Widget _buildNoPermission() {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text('Izinkan akses galeri untuk memilih foto / video',
//               textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
//           const SizedBox(height: 16),
//           ElevatedButton(onPressed: _requestPermissionAndFetch, child: const Text('Izinkan')),
//           TextButton(onPressed: openAppSettings, child: const Text('Buka Pengaturan Aplikasi')),
//         ],
//       ),
//     );
//   }
// }

// class _GridThumbnail extends StatefulWidget {
//   const _GridThumbnail({
//     Key? key,
//     required this.asset,
//     required this.isSelected,
//     required this.onTap,
//     required this.thumbCache,
//   }) : super(key: key);

//   final AssetEntity asset;
//   final bool isSelected;
//   final VoidCallback onTap;

//   final Map<String, Uint8List?> thumbCache;

//   @override
//   State<_GridThumbnail> createState() => _GridThumbnailState();
// }

// class _GridThumbnailState extends State<_GridThumbnail> {
//   Uint8List? _thumbBytes;

//   @override
//   void initState() {
//     super.initState();
//     _loadThumb();
//   }

//   Future<void> _loadThumb() async {
//     if (widget.thumbCache.containsKey(widget.asset.id)) {
//       _thumbBytes = widget.thumbCache[widget.asset.id];
//       setState(() {});
//       return;
//     }
//     final data = await widget.asset.thumbnailDataWithSize(const ThumbnailSize(200, 200));
//     widget.thumbCache[widget.asset.id] = data;
//     _thumbBytes = data;
//     setState(() {});
//   }

//   @override
//   void didUpdateWidget(covariant _GridThumbnail oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.asset.id != widget.asset.id) {
//       _loadThumb();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: widget.onTap,
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           if (_thumbBytes != null)
//             Image.memory(
//               _thumbBytes!,
//               fit: BoxFit.cover,
//             )
//           else
//             Container(color: Colors.grey.shade900),
//           if (widget.isSelected)
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(
//                   color: Constants.primaryColorVendor,
//                   width: 3,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
