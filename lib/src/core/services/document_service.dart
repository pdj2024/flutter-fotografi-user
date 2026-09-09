import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';

class DocumentModel {
  final String kode;
  final String judul;
  final String deskripsi;
  final String version;
  final DateTime? updatedAt;

  DocumentModel({
    required this.kode,
    required this.judul,
    required this.deskripsi,
    this.version = '',
    this.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      kode: json['Kode'] ?? '',
      judul: json['Judul'] ?? '',
      deskripsi: json['Deskripsi'] ?? '',
      version: json['Version'] ?? '',
      updatedAt: json['Updated_At'] != null
          ? DateTime.tryParse(json['Updated_At'])?.toLocal()
          : null,
    );
  }
}

class DocumentService {
  final String entity = 'Document';
  final String controller = 'document';
  final ApiClient _client = apiClient;

  /// Ambil dokumen berdasarkan kode. Kode-nya berasal dari company profile
  /// (lihat [CompanyService]), bukan hardcode lagi.
  Future<DocumentModel?> getByKode(String kode) async {
    try {
      final response = await _client.get(
        '/$controller/getAll',
        queryParameters: {'kode': kode},
        requireAuth: false,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> data = json['Data'] ?? [];
        if (data.isEmpty) return null;
        return DocumentModel.fromJson(data.first as Map<String, dynamic>);
      } else {
        throw Exception('Gagal load $entity (${response.statusCode})');
      }
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());
      throw Exception('Gagal load $entity');
    }
  }
}
