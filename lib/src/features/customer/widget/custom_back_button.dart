import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:provider/provider.dart';

class CustomBackButton extends StatelessWidget {
  final String? label;
  final Color color;

  const CustomBackButton({
    super.key,
    this.label,
    this.color = Colors.black,
  });

  Future<void> _handleBack(BuildContext context) async {
    final navProvider = context.read<NavigationProvider>();
    final didPop = await navProvider.handleBackButton(context);

    print("bisa back? $didPop");

    if (!didPop) {
      // Fallback jika tidak bisa pop
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back,
        color: color,
      ),
      onPressed: () =>
          _handleBack(context), // ✅ FIX: Panggil function dengan ()
    );
  }
}
