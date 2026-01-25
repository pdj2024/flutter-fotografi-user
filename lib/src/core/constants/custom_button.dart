import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/text_style.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:provider/provider.dart';

class CustomButton {
  static Widget loginButton({
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Image.asset(
        'assets/google_icon.png',
        height: 24,
      ),
      label: const Text('Masuk dengan Gmail', style: AppTextStyle.buttonBlack),
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  static Widget textButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: AppTextStyle.primary(AppTextStyle.body1),
      ),
    );
  }
}
