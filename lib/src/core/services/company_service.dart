import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';

/// Referensi dokumen legal dari company profile.
/// Backend mengirim gabungan `kodeDokumen|versi`, mis. `TC-001|1.0.0`.
class DocumentRef {
  final String kode;
  final String version;

  const DocumentRef({required this.kode, required this.version});

  factory DocumentRef.parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const DocumentRef(kode: '', version: '');
    }
    final parts = raw.split('|');
    return DocumentRef(
      kode: parts[0].trim(),
      version: parts.length > 1 ? parts[1].trim() : '',
    );
  }

  bool get isValid => kode.isNotEmpty;
}

class CompanyModel {
  final String noId;
  final DocumentRef termsConditions;
  final DocumentRef privacyPolicy;
  final DocumentRef userAgreement;

  const CompanyModel({
    required this.noId,
    required this.termsConditions,
    required this.privacyPolicy,
    required this.userAgreement,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      noId: json['No_Id'] ?? '',
      termsConditions: DocumentRef.parse(json['Terms_Conditions']),
      privacyPolicy: DocumentRef.parse(json['Privacy_Policy']),
      userAgreement: DocumentRef.parse(json['User_Agreement']),
    );
  }
}

class CompanyService {
  final String entity = 'Company';
  final String controller = 'company';
  final String idCompany = 'comp_1';

  final ApiClient _client = apiClient;

  /// Cache satu kali per sesi app — dipakai bersama oleh gate persetujuan
  /// dan halaman legal di Setting supaya tidak fetch berulang.
  static CompanyModel? _cache;

  static void clearCache() => _cache = null;

  Future<CompanyModel> get({bool force = false}) async {
    if (!force && _cache != null) return _cache!;

    final response = await _client.get(
      '/$controller/getAll',
      queryParameters: {'no_id': idCompany},
      requireAuth: false,
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal load $entity (${response.statusCode})');
    }

    final Map<String, dynamic> json = jsonDecode(response.body);
    final List<dynamic> data = json['Data'] ?? [];
    if (data.isEmpty) {
      throw Exception('Data $entity kosong');
    }

    final company = CompanyModel.fromJson(data.first as Map<String, dynamic>);
    _cache = company;
    debugPrint(
        '[Company] TC=${company.termsConditions.kode}|${company.termsConditions.version} '
        'PP=${company.privacyPolicy.kode}|${company.privacyPolicy.version}');
    return company;
  }
}
