import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

import 'imageupload_review.dart'; // Pastikan ini versi 1 file, bukan list

class UploadPhotoPage extends StatefulWidget {
  const UploadPhotoPage({super.key});

  @override
  State<UploadPhotoPage> createState() => _UploadPhotoPageState();
}

class _UploadPhotoPageState extends State<UploadPhotoPage> {
  final ImagePicker _picker = ImagePicker();
  List<AssetEntity> _galleryAssets = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth) return;

    final recent = (await PhotoManager.getAssetPathList(
      type: RequestType.image,
    ))
        .first;

    final assets = await recent.getAssetListPaged(page: 0, size: 120);
    setState(() => _galleryAssets = assets);
  }

  Future<void> _cropAndNavigate(File file) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      aspectRatio: const CropAspectRatio(ratioX: 5, ratioY: 4),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          hideBottomControls: true,
          lockAspectRatio: true,
          initAspectRatio: CropAspectRatioPreset.ratio4x3,
          cropStyle: CropStyle.rectangle,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          aspectRatioLockEnabled: true,
          aspectRatioPickerButtonHidden: true,
          minimumAspectRatio: 0.8,
        ),
      ],
    );

    if (cropped != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewUploadPage(file: File(cropped.path)),
        ),
      );
    }
  }

  Future<void> _handleTapAsset(AssetEntity asset) async {
    setState(() => _isLoading = true);
    final file = await asset.file;
    if (file != null) {
      await _cropAndNavigate(file);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      await _cropAndNavigate(File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Photo'),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(4),
              itemCount: _galleryAssets.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (context, i) {
                final asset = _galleryAssets[i];
                return FutureBuilder<Uint8List?>(
                  future: asset.thumbnailDataWithSize(
                    const ThumbnailSize(200, 200),
                  ),
                  builder: (c, snap) {
                    final bytes = snap.data;
                    if (bytes == null) {
                      return const ColoredBox(color: Colors.black12);
                    }
                    return GestureDetector(
                      onTap: () => _handleTapAsset(asset),
                      child: Image.memory(bytes, fit: BoxFit.cover),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
