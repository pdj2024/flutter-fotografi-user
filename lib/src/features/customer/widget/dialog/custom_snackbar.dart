import 'package:flutter/material.dart';

class CustomSnackbar {
  static void showErrorSnackbar(BuildContext context, String e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  static void showSuccessSnackbar(BuildContext context, String e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.green,
      ),
    );
  }

  static void showActionSnackbar(
      BuildContext context, String e, SnackBarAction action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.blueGrey.shade400,
        action: action,
      ),
    );
  }

  static void showExitAppSnackbar(
    BuildContext context,
    String e,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }
}
