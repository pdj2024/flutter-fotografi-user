import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/complain_model.dart';

class ComplainService {
  final String entity = 'Complain';
  final String controller = 'complain';
  final ApiClient _client = apiClient;

  /// GET /complain/get-group
  /// `noOrder` saja sudah cukup untuk cek apakah order ini punya Complain.
  /// Catatan: query param backend huruf kecil semua (orderby/orderdir).
  Future<List<ComplainModel>> getGroup({
    String? noOrder,
    String? noComplain,
    String? status,
    String? orderBy,
    String? orderDir,
  }) async {
    try {
      final response = await _client.get(
        '/$controller/get-group',
        queryParameters: {
          if (noOrder != null && noOrder.isNotEmpty) 'no_order': noOrder,
          if (noComplain != null && noComplain.isNotEmpty)
            'no_complain': noComplain,
          if (status != null && status.isNotEmpty) 'status': status,
          if (orderBy != null && orderBy.isNotEmpty) 'orderby': orderBy,
          if (orderDir != null && orderDir.isNotEmpty) 'orderdir': orderDir,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> data = json['Data'] ?? [];
        return data.map((e) => ComplainModel.fromJson(e)).toList();
      } else if (response.statusCode == 204) {
        return [];
      } else {
        throw Exception('Gagal load $entity (${response.statusCode})');
      }
    } catch (e, s) {
      debugPrint('❌ ComplainService.getGroup: $e');
      debugPrint(s.toString());
      throw Exception('Gagal load $entity: $e');
    }
  }

  /// GET /complain/get-header — daftar ringkas Complain milik satu user
  /// (dipakai halaman list, mis. menu "Complain" di Setting). Tanpa
  /// `status`, balikin semua (aktif + selesai).
  ///
  /// `noComplain` opsional — filter ke satu complain spesifik. Dipakai
  /// ComplainProvider.closeComplain() untuk membaca field lengkap
  /// (Prioritas/Assigned_To/Hasil_Akhir/dll, yang tidak ada di ComplainModel
  /// dari get-group) sebelum PUT update-header, karena endpoint itu
  /// full-replace -- field yang tidak dikirim akan ditimpa kosong.
  Future<List<ComplainHeaderModel>> getHeader({
    required String senderId,
    String? noComplain,
    String? status,
    String? orderBy,
    String? orderDir,
  }) async {
    try {
      final response = await _client.get(
        '/$controller/get-header',
        queryParameters: {
          'sender_id': senderId,
          if (noComplain != null && noComplain.isNotEmpty)
            'no_complain': noComplain,
          if (status != null && status.isNotEmpty) 'status': status,
          if (orderBy != null && orderBy.isNotEmpty) 'orderby': orderBy,
          if (orderDir != null && orderDir.isNotEmpty) 'orderdir': orderDir,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> data = json['Data'] ?? [];
        return data.map((e) => ComplainHeaderModel.fromJson(e)).toList();
      } else if (response.statusCode == 204) {
        return [];
      } else {
        throw Exception('Gagal load $entity (${response.statusCode})');
      }
    } catch (e, s) {
      debugPrint('❌ ComplainService.getHeader: $e');
      debugPrint(s.toString());
      throw Exception('Gagal load $entity: $e');
    }
  }

  /// POST /complain/create — dipakai untuk create baru & reply.
  /// `noComplain` kosong ("") = buat complain baru. Terisi = reply ke thread itu.
  Future<void> sendMessage({
    required String noOrder,
    required String senderId,
    required String tipeUser,
    required String message,
    String noComplain = '',
    String judul = '',
    List<String>? idMedia,
  }) async {
    try {
      final body = {
        'no_complain': noComplain,
        'judul': judul,
        'no_order': noOrder,
        'sender_id': senderId,
        'tipe_user': tipeUser,
        'message': message,
        'Jenis_Pesan': (idMedia != null && idMedia.isNotEmpty) ? 'image' : 'text',
        'Send_Status': 'sent',
        'id_media': (idMedia != null && idMedia.isNotEmpty) ? idMedia : null,
      };

      final response = await _client.post(
        '/$controller/create',
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal mengirim $entity (${response.statusCode})');
      }
    } catch (e, s) {
      debugPrint('❌ ComplainService.sendMessage: $e');
      debugPrint(s.toString());
      throw Exception('Gagal mengirim $entity: $e');
    }
  }

  /// PUT /complain/update-header?no_id={noComplain} — full-replace, jadi
  /// [body] harus berisi SELURUH field header (bukan cuma yang berubah),
  /// kalau tidak field yang tidak dikirim akan ditimpa kosong di backend.
  Future<void> updateHeader({
    required String noComplain,
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _client.put(
        '/$controller/update-header',
        queryParameters: {'no_id': noComplain},
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal update $entity (${response.statusCode})');
      }
    } catch (e, s) {
      debugPrint('❌ ComplainService.updateHeader: $e');
      debugPrint(s.toString());
      throw Exception('Gagal update $entity: $e');
    }
  }
}
