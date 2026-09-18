import 'dart:convert';

import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/refund_rule_model.dart';

class RefundRuleService {
  final String entity = 'Master Refund';
  final String controller = 'MasRefund';
  final ApiClient _client = apiClient;

  Future<List<RefundRuleModel>> getAll() async {
    try {
      final response = await _client.get(
        '/$controller/getAll',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> data = json['Data'];
        return data.map((e) => RefundRuleModel.fromJson(e)).toList();
      } else if (response.statusCode == 204) {
        return [];
      } else {
        throw Exception('Gagal load $entity (${response.statusCode})');
      }
    } catch (e, s) {
      Error.throwWithStackTrace(
        Exception('Gagal load Refund Rule: $e'),
        s,
      );
    }
  }

  /// Pilih tier refund yang berlaku berdasarkan sisa jam sebelum tglRealisasi.
  /// Jam_Limit adalah BATAS ATAS tiap bracket (bukan ambang minimal) — data
  /// contoh: Jam_Limit 24→0%, 48→25%, 72→50% berarti:
  ///   sisa jam ≤ 24        → tier Jam_Limit=24 (0%)
  ///   24 < sisa jam ≤ 48   → tier Jam_Limit=48 (25%)
  ///   48 < sisa jam ≤ 72   → tier Jam_Limit=72 (50%)
  /// Ambil bracket TERKECIL yang batas atasnya >= sisaJam.
  RefundRuleModel? resolveTier(List<RefundRuleModel> rules, double sisaJam) {
    final eligible = rules.where((r) => sisaJam <= r.jamLimit).toList()
      ..sort((a, b) => a.jamLimit.compareTo(b.jamLimit));
    return eligible.isNotEmpty ? eligible.first : null;
  }
}
