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
    // onWillPop ikut konvensi WillPopScope: false = sudah ditangani sendiri
    // (berhasil pop navigator tab, pindah tab, atau blok untuk konfirmasi
    // keluar) -- JANGAN pop lagi. true = belum ditangani, baru di situ kita
    // lakukan pop biasa.
    final shouldPop = await navProvider.onWillPop(context);

    if (shouldPop) {
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
