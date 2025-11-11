import 'package:intl/intl.dart';

class Helper {
    static formatCurrency(num value, {String prefix = "IDR "}) {
    return "$prefix${NumberFormat("#,##0", "id_ID").format(value)}";
  }
}