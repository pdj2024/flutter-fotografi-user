import 'package:flutter/material.dart';

class CustomIcons {
  static IconData getMetodeIcon(String metode) {
    switch (metode.split(' ').first) {
      case "QRIS":
        return Icons.qr_code_2_rounded;
      case "VA":
        return Icons.account_balance_rounded;
      case "COUNTER":
        return Icons.store_rounded;
      case "CARD":
        return Icons.credit_card_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  static Color getMetodeColor(String metode) {
    switch (metode.split(' ').first) {
      case "QRIS":
        return Colors.purple;
      case "VA":
        return Colors.blue;
      case "COUNTER":
        return Colors.orange;
      case "CARD":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
