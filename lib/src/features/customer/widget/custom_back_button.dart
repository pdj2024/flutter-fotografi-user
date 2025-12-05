import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routing/navigation_provider.dart';

class CustomBackButton extends StatelessWidget {
  final String? label;
  final Color color;

  const CustomBackButton({super.key, 
    this.label,
    this.color = Colors.black, // Default warna hitam
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back,
        color: color,
      ),
      onPressed: () async {
        final provider = Provider.of<NavigationProvider>(context, listen: false);
        bool allowPop = await provider.onWillPop();
        if (allowPop) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
