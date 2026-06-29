import 'package:flutter/material.dart';
import 'package:mpjnew/src/features/customer/widget/order_status_flow.dart';

// ═══════════════════════════════════════════════════════════════
// StatusConfig
// ═══════════════════════════════════════════════════════════════

class StatusConfig {
  final Color color;
  final Color bgColor;
  final String label;
  final IconData icon;

  const StatusConfig({
    required this.color,
    required this.bgColor,
    required this.label,
    required this.icon,
  });
}

// ── Tabel warna & icon per status ────────────────────────────────

const _colorTable = <String, (Color, IconData)>{
  'menunggu bayar': (
    Color(0xFFD97706),
    Icons.credit_card_outlined
  ), // ✅ Kuning amber
  'persiapan': (Color(0xFF2563EB), Icons.calendar_today_rounded), // Biru
  'proses': (Color(0xFF0284C7), Icons.upload_file_rounded), // ✅ Biru sky
  'review': (Color(0xFF7C3AED), Icons.rate_review_outlined), // Ungu
  'revisi': (Color(0xFF0D9488), Icons.edit_note_rounded), // Teal
  'selesai': (Color(0xFF16A34A), Icons.check_circle_outline_rounded), // Hijau
  'dibatalkan': (Color(0xFFDC2626), Icons.cancel_outlined), // Merah
  'batal': (Color(0xFFDC2626), Icons.cancel_rounded), // Merah
  'expired': (Color(0xFFD97706), Icons.timer_off_rounded), // Oranye
};

const _fallbackColor = Color(0xFF64748B);
const _fallbackBg = Color(0xFFF1F5F9);
const _fallbackIcon = Icons.hourglass_empty_outlined;
const _fallbackLabel = 'Tidak Diketahui';

// ── Factory function ──────────────────────────────────────────────

StatusConfig getStatus(String status) {
  final key = status.toLowerCase().trim();
  final label = OrderStatusFlow.displayLabel(key);
  final entry = _colorTable[key];

  if (entry == null) {
    return StatusConfig(
      color: _fallbackColor,
      bgColor: _fallbackBg,
      label: label.isNotEmpty ? label : _fallbackLabel,
      icon: _fallbackIcon,
    );
  }

  final (color, icon) = entry;
  return StatusConfig(
    color: color,
    bgColor: color.withOpacity(0.10),
    label: label,
    icon: icon,
  );
}
