import 'dart:convert';

import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';


class DocumentModel {
  final String kode;
  final String judul;
  final String deskripsi;

  DocumentModel({
    required this.kode,
    required this.judul,
    required this.deskripsi,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      kode: json['Kode'] as String,
      judul: json['Judul'] as String,
      deskripsi: json['Deskripsi'] as String,
    );
  }
}

class DocumentService {
  final String entity = 'Document';
  final String controller = 'document';
  final ApiClient _client = apiClient;

  Future<DocumentModel?> getKebijakanPrivasiAplikasi() async {
    try {
      final response = await _client.get("/$controller/getAll?kode=PRIV-001",
          requireAuth: false);
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> data = json['Data'];
        return DocumentModel.fromJson(data.first as Map<String, dynamic>);
      } else {
        throw Exception('Gagal load $entity (${response.statusCode})');
      }
    } catch (e, s) {
      print(e);
      print(s);
      throw Exception('Gagal load $entity');
    }
  }

  Future<DocumentModel?> getSyaratKetentuanAplikasi() async {
    try {
      final response = await _client.get("/$controller/getAll?kode=TOS-001",
          requireAuth: false);
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> data = json['Data'];
        return DocumentModel.fromJson(data.first as Map<String, dynamic>);
      } else {
        throw Exception('Gagal load $entity (${response.statusCode})');
      }
    } catch (e, s) {
      print(e);
      print(s);
      throw Exception('Gagal load $entity');
    }
  }
}