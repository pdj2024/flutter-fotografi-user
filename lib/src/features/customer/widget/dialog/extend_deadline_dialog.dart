import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/features/customer/widget/field/custom_text_field.dart';
import 'package:mpjnew/src/features/customer/widget/field/date_picker_field.dart';
import 'package:mpjnew/src/features/customer/widget/field/time_picker_field.dart';

/// Dialog untuk memilih batas pengerjaan baru. Dua cara mengisi:
///   1. Pilih Tanggal -- tentukan tanggal & jam baru langsung.
///   2. Tambah Durasi -- isi tambahan hari+jam dari batas pengerjaan
///      SEKARANG (pola sama seperti "Estimasi Pengerjaan" di offering form
///      vendor, offering_chat_form.dart).
/// Hanya bertanggung jawab atas pemilihan + validasi minimal -- pop dengan
/// `DateTime` baru kalau disimpan, `null` kalau dibatalkan. Panggilan
/// API/refresh dipegang pemanggil (lihat extend_deadline_flow.dart).
class ExtendDeadlineDialog extends StatefulWidget {
  const ExtendDeadlineDialog({super.key, required this.currentDeadline});

  final DateTime currentDeadline;

  @override
  State<ExtendDeadlineDialog> createState() => _ExtendDeadlineDialogState();
}

class _ExtendDeadlineDialogState extends State<ExtendDeadlineDialog> {
  bool _useDuration = false;

  // ── Mode: Pilih Tanggal ──────────────────────────────────────────
  DateTime? _date;
  TimeOfDay? _time;
  String _zone = 'WIB';

  // ── Mode: Tambah Durasi ──────────────────────────────────────────
  final _hariController = TextEditingController(text: '0');
  final _jamController = TextEditingController(text: '0');

  String? _error;

  @override
  void initState() {
    super.initState();

    // Default field tanggal/waktu = batas pengerjaan SEKARANG, supaya user
    // tinggal geser dari situ, bukan mulai dari kosong.
    final local = widget.currentDeadline.toLocal();
    _date = local;
    _time = TimeOfDay.fromDateTime(local);
    final zone = Helper.getZonaIndonesia(local);
    _zone = zone.isNotEmpty ? zone : 'WIB';

    // Rebuild supaya preview "Batas baru: ..." ikut update saat diketik.
    _hariController.addListener(_onDurasiChanged);
    _jamController.addListener(_onDurasiChanged);
  }

  void _onDurasiChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _hariController.removeListener(_onDurasiChanged);
    _jamController.removeListener(_onDurasiChanged);
    _hariController.dispose();
    _jamController.dispose();
    super.dispose();
  }

  int get _durasiTambahanJam {
    final hari = int.tryParse(_hariController.text) ?? 0;
    final jam = int.tryParse(_jamController.text) ?? 0;
    return hari * 24 + jam;
  }

  DateTime get _previewDeadline =>
      widget.currentDeadline.add(Duration(hours: _durasiTambahanJam));

  void _setMode(bool useDuration) {
    setState(() {
      _useDuration = useDuration;
      _error = null;
    });
  }

  void _submit() {
    if (_useDuration) {
      if (_durasiTambahanJam < 1) {
        setState(() => _error = 'Isi tambahan waktu minimal 1 jam.');
        return;
      }
      Navigator.pop(context, _previewDeadline);
      return;
    }

    if (_date == null || _time == null) {
      setState(() => _error = 'Pilih tanggal dan waktu terlebih dahulu.');
      return;
    }
    final newDeadline = Helper.toUTC(_date!, _time!, _zone);
    if (!newDeadline.isAfter(widget.currentDeadline)) {
      setState(() =>
          _error = 'Tanggal/jam baru harus setelah batas pengerjaan saat ini.');
      return;
    }
    Navigator.pop(context, newDeadline);
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: const Color(0xfff9f9f9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_available_outlined,
                      size: 22, color: Constants.primaryColor),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Perpanjang Batas Pengerjaan',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Batas pengerjaan saat ini: ',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  Text(
                    '${Helper.formatTanggal(widget.currentDeadline)}, '
                    '${Helper.toLocalTime(widget.currentDeadline)}',
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Perpanjang hingga:',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),

              // ── Toggle mode ─────────────────────────────────────
              // Row(
              //   children: [
              //     Expanded(
              //       child: _ModeButton(
              //         label: 'Pilih Tanggal',
              //         selected: !_useDuration,
              //         onTap: () => _setMode(false),
              //       ),
              //     ),
              //     const SizedBox(width: 8),
              //     Expanded(
              //       child: _ModeButton(
              //         label: 'Tambah Durasi',
              //         selected: _useDuration,
              //         onTap: () => _setMode(true),
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 16),

              if (_useDuration) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Hari',
                        controller: _hariController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        placeholder: '0',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomTextField(
                        label: 'Jam',
                        controller: _jamController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        placeholder: '0',
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Batas baru: ${Helper.formatTanggal(_previewDeadline)}, '
                          '${Helper.toLocalTime(_previewDeadline)}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                DatePickerField(
                  label: 'Tanggal',
                  selectedDate: _date,
                  isPenawaran: true,
                  placeholder: "Pilih tanggal realisasi",
                  minDate: widget.currentDeadline,
                  onDateSelected: (v) => setState(() {
                    _date = v;
                    _error = null;
                  }),
                ),
                TimePickerField(
                  label: 'Waktu',
                  selectedTime: _time,
                  selectedZone: _zone,
                  onTimeSelected: (t, z) => setState(() {
                    _time = t;
                    _zone = z;
                    _error = null;
                  }),
                ),
              ],

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Simpan',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Constants.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Constants.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
