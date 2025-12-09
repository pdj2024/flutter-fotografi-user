import 'package:flutter/material.dart';

class ChipsWidget extends StatelessWidget {
  final String idData;
  final String label;
  final Function(dynamic id) onDelete;
  final Color? backgroundColor;
  final Color? labelColor;
  final Color? deleteIconColor;
  const ChipsWidget(
      {super.key,
      required this.idData,
      required this.label,
      required this.onDelete,
      this.backgroundColor,
      this.labelColor,
      this.deleteIconColor});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: labelColor ?? Colors.white,
          fontSize: 13,
        ),
      ),
      backgroundColor: backgroundColor ?? Colors.blue,
      deleteIconColor: deleteIconColor ?? Colors.white,
      shadowColor: Colors.transparent,
      elevation: 0,
      onDeleted: () => onDelete(idData),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
