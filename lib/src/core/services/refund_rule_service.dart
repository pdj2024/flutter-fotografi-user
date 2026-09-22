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
}
