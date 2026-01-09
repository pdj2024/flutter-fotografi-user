import 'package:flutter/material.dart';

class StatusProgresConstant {
  static List<Map<String, dynamic>> statusOptions = [
    {
      'value': 'persiapan',
      'label': 'Persiapan',
      'icon': Icons.inventory_2_rounded,
      'color': Color(0xFF14B8A6), // ✅ Teal - fresh, berbeda dari review
      'showLinkUrl': false,
    },
    {
      'value': 'proses',
      'label': 'Proses',
      'icon': Icons.construction_rounded,
      'color': Color(0xFFF59E0B), // Orange/Amber - tetap
      'showLinkUrl': true,
    },
    {
      'value': 'review',
      'label': 'Review',
      'icon': Icons.rate_review_rounded,
      'color': Color(0xFF8B5CF6), // Purple - tetap
      'showLinkUrl': true,
    },
    {
      'value': 'revisi',
      'label': 'Revisi',
      'icon': Icons.edit_note_rounded,
      'color': Color(0xFF3B82F6),
      'showLinkUrl': true,
    },
    {
      'value': 'selesai',
      'label': 'Selesai',
      'icon': Icons.check_circle_rounded,
      'color': Color(0xFF10B981), // Green - tetap
      'showLinkUrl': true,
    },
  ];
}
