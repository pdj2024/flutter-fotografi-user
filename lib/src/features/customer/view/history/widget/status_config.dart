// ═══════════════════════════════════════════════════════════════
// STATUS CONFIG — menggunakan StatusProgresConstant
// Tambah import: status_progres_constant.dart
// ═══════════════════════════════════════════════════════════════

// Wrapper agar tetap bisa dipakai dgn dot-notation di seluruh file
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/status_progres_constant.dart';
import 'package:mpjnew/src/features/customer/widget/order_status_flow.dart';

class StatusConfig {
  final Color color;
  final Color bgColor; // warna bg = color.withOpacity(0.10)
  final String label;
  final IconData icon;

  const StatusConfig({
    required this.color,
    required this.bgColor,
    required this.label,
    required this.icon,
  });
}

/// Resolve status → _StatusConfig
/// Prioritas: StatusProgresConstant (sumber tunggal kebenaran)
/// Fallback: menunggu bayar (tidak ada di constant)
StatusConfig getStatus(String status) {
  if (status.toLowerCase() == 'menunggu bayar') {
    return StatusConfig(
      color: const Color(0xFF2563EB),
      bgColor: const Color(0xFFEFF6FF),
      // ✅ Pakai displayLabel — konsisten dengan OrderStatusFlow
      label: OrderStatusFlow.displayLabel('menunggu bayar'),
      icon: Icons.payment_outlined,
    );
  }

  final found = StatusProgresConstant.statusOptions.firstWhere(
    (s) => s['value'] == status.toLowerCase(),
    orElse: () => <String, dynamic>{},
  );

  if (found.isEmpty) {
    return StatusConfig(
      color: const Color(0xFF64748B),
      bgColor: const Color(0xFFF1F5F9),
      label: OrderStatusFlow.displayLabel(
          status), // ✅ fallback juga pakai displayLabel
      icon: Icons.hourglass_empty_outlined,
    );
  }

  final Color c = found['color'] as Color;
  return StatusConfig(
    color: c,
    bgColor: Color.fromRGBO(
      c.red.clamp(0, 255),
      c.green.clamp(0, 255),
      c.blue.clamp(0, 255),
      0.10,
    ),
    // ✅ Kunci perubahan: label dari OrderStatusFlow, bukan dari StatusProgresConstant
    label: OrderStatusFlow.displayLabel(found['value'] as String),
    icon: found['icon'] as IconData,
  );
}
