import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/default_value_model.dart';

class DefaultValueService {
  final String entity = 'Nilai Default';
  final String controller = 'nilaidefault';
  final ApiClient _client = apiClient;
  final String idCompany = 'comp_1';

  Future<PpnModel> getPpn() async {
    try {
      final response = await _client.get(
        '/$controller/getAll',
        queryParameters: {'no_id': idCompany},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> data = json['Data'] ?? [];

        if (data.isEmpty) {
          throw Exception('Data $entity kosong');
        }

        final raw = data.first as Map<String, dynamic>;
        return PpnModel.fromJson(raw);
      }

      if (response.statusCode == 204) {
        return const PpnModel(ppn: 0, inclPpn: false, platform: 0);
      }

      throw Exception('Gagal load $entity (${response.statusCode})');
    } catch (e, s) {
      Error.throwWithStackTrace(
        Exception('Gagal load PPN: $e'),
        s,
      );
    }
  }

  // ── GET APP CONFIG ───────────────────────────────────────────
  // Chat_Help : pesan default WA customer service
  // Batas_Revisi : default revisi saat vendor buat paket baru

  Future<AppConfigModel> getAppConfig() async {
    try {
      final response = await _client.get(
        '/$controller/getAll',
        queryParameters: {'no_id': idCompany},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> data = json['Data'] ?? [];
        if (data.isEmpty) return AppConfigModel.fallback;
        return AppConfigModel.fromJson(data.first as Map<String, dynamic>);
      }

      if (response.statusCode == 204) return AppConfigModel.fallback;

      throw Exception('Gagal load $entity (${response.statusCode})');
    } catch (e, s) {
      Error.throwWithStackTrace(
        Exception('Gagal load AppConfig: $e'),
        s,
      );
    }
  }

  Future<VersionModel> getVersionApp() async {
    try {
      final response = await _client.get(
        '/$controller/getAll/version',
        queryParameters: {'no_id': idCompany},
        requireAuth: false,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> data = json['Data'] ?? [];

        if (data.isEmpty) {
          throw Exception('Data version $entity kosong');
        }

        final raw = data.first as Map<String, dynamic>;
        final version = VersionModel.fromJson(raw);

        debugPrint(
            '[DefaultValueService] App versi lokal   : ${Constants.versionApp}');
        debugPrint(
            '[DefaultValueService] App customer server: ${version.versionAppCustomer}');
        debugPrint(
            '[DefaultValueService] DB versi server   : ${version.versionDatabase}');
        debugPrint(
            '[DefaultValueService] API versi server  : ${version.versionApi}');
        debugPrint(
            '[DefaultValueService] Playstore customer: ${version.linkPlaystoreCustomer}');

        return version;
      }

      if (response.statusCode == 204) {
        return const VersionModel(
          versionApp: '',
          versionAppCustomer: '',
          versionAppVendor: '',
          versionDatabase: '',
          versionApi: '',
          linkPlaystoreCustomer: '',
          linkPlaystoreVendor: '',
        );
      }

      throw Exception('Gagal load version $entity (${response.statusCode})');
    } catch (e, s) {
      Error.throwWithStackTrace(
        Exception('Gagal load version: $e'),
        s,
      );
    }
  }
}
