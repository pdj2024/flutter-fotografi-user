import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Constants {
  static const Color primaryColor = Color(0xff3b3add); //Color(0xffEE4D2D);
  static const Color primaryColorVendor = Color(0xff3b3add);

  static const String customer = 'customer';
  static const String vendor = 'vendor';

  static const String baseUrl = 'http://43.228.212.41:15';
      // 'https://fotoapi.pdj.web.id'; // Ganti dengan URL API Anda

  static formatCurrency(num value, {String prefix = "IDR "}) {
    return "$prefix${NumberFormat("#,##0", "id_ID").format(value)}";
  }
}
