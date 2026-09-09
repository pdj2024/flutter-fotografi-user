import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';

/// Riwayat persetujuan dokumen legal — dicatat terpisah dari field
/// Tnc_*/Pp_*/Ven_* di profil user, satu record per dokumen yang disetujui.
class UserAgreementService {
  final String entity = 'UserAgreement';
  final String controller = 'UserAgreement';
  final ApiClient _client = apiClient;

  Future<void> create({
    required String idDokumen,
    required String idUser,
    required String email,
    required String deviceInfo,
    required DateTime acceptedAt,
  }) async {
    final response = await _client.post(
      '/$controller/create',
      body: jsonEncode({
        'Id_Dokumen': idDokumen,
        'Id_User': idUser,
        'Email': email,
        'Device_Info': deviceInfo,
        'Accepted_At':
            DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(acceptedAt.toUtc()),
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Gagal membuat riwayat $entity (${response.statusCode})');
    }
  }
}
