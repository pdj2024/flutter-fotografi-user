import 'dart:convert';

import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/default_value_model.dart';


// ═══════════════════════════════════════════════════════════════
// DEFAULT VALUE SERVICE
//
// getPpn()        → PpnModel  (Ppn, Incl_Ppn, Platform)
// getVersionApp() → VersionModel (Version_App, Version_Database, Version_Api)
// ═══════════════════════════════════════════════════════════════

class DefaultValueService {
  final String entity = 'Nilai Default';
  final String controller = 'nilaidefault';
  final ApiClient _client = apiClient;
  final String idCompany = 'comp_1';

  // ── GET PPN ───────────────────────────────────────────────────
  // Mengambil Ppn, Incl_Ppn, dan Platform dari endpoint getAll.
  // Endpoint ini mengembalikan seluruh config perusahaan;
  // kita hanya mengambil field yang diperlukan untuk kalkulasi biaya.

  Future<PpnModel> getPpn() async {
    try {
      final response = await _client.get(
        '/$controller/getAll',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> data = json['Data'] ?? [];

        if (data.isEmpty) {
          throw Exception('Data $entity kosong');
        }

        // Ambil hanya field yang diperlukan
        final raw = data.first as Map<String, dynamic>;
        return PpnModel.fromJson(raw);
      }

      if (response.statusCode == 204) {
        // Tidak ada data → kembalikan default (no PPN, no platform fee)
        return const PpnModel(ppn: 0, inclPpn: false, platform: 0);
      }

      throw Exception('Gagal load $entity (${response.statusCode})');
    } catch (e, s) {
      // Re-throw agar caller bisa handle (misal tampilkan error di UI)
      Error.throwWithStackTrace(
        Exception('Gagal load PPN: $e'),
        s,
      );
    }
  }

  // ── GET VERSION APP ───────────────────────────────────────────
  // Endpoint khusus version — mengembalikan Version_App,
  // Version_Database, dan Version_Api.
  // Juga membandingkan dengan Constants.versionApp untuk
  // cek apakah app perlu diupdate.

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

        // Log perbandingan versi (untuk debug)
        // ignore: avoid_print
        print(
            '[DefaultValueService] App versi lokal   : ${Constants.versionApp}');
        // ignore: avoid_print
        print(
            '[DefaultValueService] App versi server  : ${version.versionApp}');
        // ignore: avoid_print
        print(
            '[DefaultValueService] DB versi server   : ${version.versionDatabase}');
        // ignore: avoid_print
        print(
            '[DefaultValueService] API versi server  : ${version.versionApi}');

        return version;
      }

      if (response.statusCode == 204) {
        return const VersionModel(
          versionApp: '',
          versionDatabase: '',
          versionApi: '',
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
