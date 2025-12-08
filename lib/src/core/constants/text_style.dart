import 'package:flutter/material.dart';
import '../constants/constants.dart';

class AppTextStyle {
  // ================
  // HEADLINES
  // ================
  static const headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const headline2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );

  static const headline3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  // ================
  // SUBTITLE
  // ================
  static const subtitle1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static const subtitle2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  static const subtitle3 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  // ================
  // BODY TEXT
  // ================
  static const body1 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.black,
  );

  static const body2 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.black54,
  );

  // ================
  // CAPTION
  // ================
  static const caption = TextStyle(
    fontSize: 11,
    color: Colors.grey,
  );

  // ================
  // BUTTON TEXT
  // ================
  static const button = TextStyle(
    fontSize: 16,
    color: Colors.white,
  );

  static const buttonBlack = TextStyle(
    fontSize: 16,
    color: Colors.black,
  );

  // ================
  // FORM
  // ================
  static const inputLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static const inputHint = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  static const inputValue = TextStyle(
    fontSize: 14,
    color: Colors.black,
  );

  // ================
  // ERROR
  // ================
  static const error = TextStyle(
    fontSize: 12,
    color: Colors.red,
    fontWeight: FontWeight.w600,
  );

  // ======================================================
  // =============  EXTRA UTILITIES  ======================
  // ======================================================

  /// Membuat teks menjadi primary-colored
  static TextStyle primary(TextStyle base) {
    return base.copyWith(
      color: Constants.primaryColorVendor,
    );
  }

  /// Membuat teks menjadi underline
  static TextStyle underline(TextStyle base) {
    return base.copyWith(
      decoration: TextDecoration.underline,
    );
  }

  /// Membuat teks menjadi primary + underline
  static TextStyle primaryUnderline(TextStyle base) {
    return base.copyWith(
      color: Constants.primaryColorVendor,
      decoration: TextDecoration.underline,
    );
  }
}
