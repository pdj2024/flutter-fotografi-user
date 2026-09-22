import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/hive_entity/media_url_model.dart';
import 'package:mpjnew/src/data/models/media_upload_model.dart';
import 'package:mpjnew/src/data/models/upload_response_model.dart';
import 'package:http/http.dart' as http;

class MediaService {
  final String entity = 'mediacloud';
  final String controller = 'mediacloud';
  final ApiClient _client = apiClient;

  /// Req Media URl
  Future<List<UploadResponseModel>> reqMediaURL(
    List<String> extensions,
    String userId,
  ) async {
    try {
      final body = {
        'uploader_id': userId,
        'extensions': extensions, // List<String> of extension
      };

      final response = await _client.post(
        '/$controller/req-upload-url-batch',
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal request upload URL ($entity), status: ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception("Format response tidak valid, harus berupa List");
      }

      return decoded
          .map<UploadResponseModel>(
              (e) => UploadResponseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      debugPrint("❌ ERROR reqMediaURL: $e");
      debugPrint(stackTrace.toString());
      throw Exception("Gagal memproses request upload URL: $e");
    }
  }

  Future<bool> uploadMediaCloud({
    required File file,
    required String uploadUrl, // Signed URL
  }) async =>
      uploadMediaCloudBytes(
        bytes: await file.readAsBytes(),
        uploadUrl: uploadUrl,
      );

  /// Upload dari bytes di memory — dipakai jalur yang sudah mengompres
  /// gambar tanpa menulis file baru ke storage (lihat AttachmentCompressor).
  Future<bool> uploadMediaCloudBytes({
    required Uint8List bytes,
    required String uploadUrl, // Signed URL
  }) async {
    try {
      final response = await http.put(
        Uri.parse(uploadUrl),
        body: bytes,
        headers: {
          "Content-Type": "application/octet-stream", // wajib
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("UPLOAD GAGAL ❌ STATUS : ${response.statusCode}");
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint("UPLOAD ERROR ❗ $e");
      debugPrint(stackTrace.toString());
      return false;
    }
  }

  /// Konfirmasi metadata upload — server balikin mediaIds permanen
  Future<dynamic> confirmationUploadMedia(
    List<MediaUploadModel> files,
    String userId,
  ) async {
    try {
      final body = {"files": files.map((e) => e.toJson()).toList()};
      final jsonBody = jsonEncode(body);

      final response = await _client.post(
        '/$controller/confirm-upload-batch',
        body: jsonBody,
        headers: {'Content-Type': 'application/json'},
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": result["Message"],
          "mediaIds": result["MediaIds"] ?? [],
        };
      }

      return {
        "success": false,
        "error": result["Error"] ?? "Unknown error",
      };
    } catch (e, stackTrace) {
      debugPrint("ERROR KONFIRMASI UPLOAD ❗ $e");
      debugPrint(stackTrace.toString());
      return {
        "success": false,
        "error": e.toString(),
      };
    }
  }

  /// Resolve batch Id_Media -> URL signed buat ditampilkan.
  /// GET /mediacloud/read-url-batch, body {"ids": [...]}.
  /// Catatan: ini GET dengan body — pakai ApiClient.getWithBody(), bukan get().
  Future<Map<String, MediaUrlModel>> resolveUrls(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final response = await _client.getWithBody(
        '/$controller/read-url-batch',
        body: {'ids': ids},
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal resolve media (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      final success = decoded['success'] as Map<String, dynamic>? ?? {};

      return success.map((id, raw) {
        final data = raw as Map<String, dynamic>;
        return MapEntry(
          id,
          MediaUrlModel(
            idMedia: id,
            url: data['Url'],
            expiredAt: data['Expired_At'] != null
                ? DateTime.tryParse(data['Expired_At'])
                : null,
            contentType: data['Content_Type'],
            isCompressed: data['IsCompressed'],
            thumbUrl: data['ThumbUrl'],
            size: data['Size'],
          ),
        );
      });
    } catch (e, stackTrace) {
      debugPrint("❌ ERROR resolveUrls: $e");
      debugPrint(stackTrace.toString());
      return {};
    }
  }
}
