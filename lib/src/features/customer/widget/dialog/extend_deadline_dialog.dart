import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/features/customer/widget/field/date_picker_field.dart';
import 'package:mpjnew/src/features/customer/widget/field/time_picker_field.dart';

/// Dialog untuk memilih batas pengerjaan baru. Hanya bertanggung jawab atas
/// pemilihan tanggal/waktu + validasi minimal (harus setelah deadline lama)
/// -- pop dengan `DateTime` baru kalau disimpan, `null` kalau dibatalkan.
/// Panggilan API/refresh dipegang pemanggil (DetailOrderPageV2).
class ExtendDeadlineDialog extends StatefulWidget {
  const ExtendDeadlineDialog({super.key, required this.currentDeadline});

  final DateTime currentDeadline;

  @override
  State<ExtendDeadlineDialog> createState() => _ExtendDeadlineDialogState();
}

class _ExtendDeadlineDialogState extends State<ExtendDeadlineDialog> {
  DateTime? _date;
  TimeOfDay? _time;
  String _zone = 'WIB';
  String? _error;

  void _submit() {
    if (_date == null || _time == null) {
      setState(() => _error = 'Pilih tanggal dan waktu terlebih dahulu.');
      return;
    }
    final newDeadline = Helper.toUTC(_date!, _time!, _zone);
    if (!newDeadline.isAfter(widget.currentDeadline)) {
      setState(() => _error =
          'Tanggal/jam baru harus setelah batas pengerjaan saat ini.');
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
              Text(
                'Batas pengerjaan saat ini: '
                '${Helper.formatTanggal(widget.currentDeadline)}, '
                '${Helper.toLocalTime(widget.currentDeadline)}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              DatePickerField(
                label: 'Tanggal Baru',
                selectedDate: _date,
                isPenawaran: true,
                minDate: widget.currentDeadline,
                onDateSelected: (v) => setState(() {
                  _date = v;
                  _error = null;
                }),
              ),
              TimePickerField(
                label: 'Waktu Baru',
                selectedTime: _time,
                selectedZone: _zone,
                onTimeSelected: (t, z) => setState(() {
                  _time = t;
                  _zone = z;
                  _error = null;
                }),
              ),
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
