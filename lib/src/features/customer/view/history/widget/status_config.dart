
// ═══════════════════════════════════════════════════════════════
// STATUS CONFIG — menggunakan StatusProgresConstant
// Tambah import: status_progres_constant.dart
// ═══════════════════════════════════════════════════════════════

// Wrapper agar tetap bisa dipakai dgn dot-notation di seluruh file
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/status_progres_constant.dart';

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
  // ── menunggu bayar — tidak ada di StatusProgresConstant ──
  if (status.toLowerCase() == 'menunggu bayar') {
    return const StatusConfig(
      color: Color(0xFF2563EB), // Blue-600
      bgColor: Color(0xFFEFF6FF), // Blue-50
      label: 'Belum Bayar',
      icon: Icons.payment_outlined,
    );
  }

  // ── Cari di StatusProgresConstant ──
  final found = StatusProgresConstant.statusOptions.firstWhere(
    (s) => s['value'] == status.toLowerCase(),
    orElse: () => <String, dynamic>{},
  );

  if (found.isEmpty) {
    return const StatusConfig(
      color: Color(0xFF64748B),
      bgColor: Color(0xFFF1F5F9),
      label: 'Proses',
      icon: Icons.hourglass_empty_outlined,
    );
  }

  final Color c = found['color'] as Color;
  return StatusConfig(
    color: c,
    bgColor: Color.fromRGBO(
      (c.red).clamp(0, 255),
      (c.green).clamp(0, 255),
      (c.blue).clamp(0, 255),
      0.10,
    ),
    label: found['label'] as String,
    icon: found['icon'] as IconData,
  );
}