import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class DatePickerField extends StatefulWidget {
  final String label;
  final DateTime? selectedDate;
  final String? errorMessage;
  final String? placeholder;
  final bool isPenawaran;

  /// Override eksplisit untuk minDate picker. Kalau diisi, ini menang atas
  /// default dari [isPenawaran] (dipakai mis. saat tanggal harus setelah
  /// suatu deadline tertentu, bukan sekadar "hari ini").
  final DateTime? minDate;

  final Function(DateTime) onDateSelected;

  const DatePickerField({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.placeholder = "",
    this.isPenawaran = false,
    this.errorMessage,
    this.minDate,
  });

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  late DateTime? chosenDate;

  @override
  void initState() {
    super.initState();
    chosenDate = widget.selectedDate; // simpan ke state lokal
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),

        // FIELD UI
        GestureDetector(
          onTap: () async {
            // registrasiProvider.setShowPopup(true);
            final date = await showModernDatePicker(
              context,
              initialDate: chosenDate,
            );

            if (date != null) {
              setState(() => chosenDate = date);
              widget.onDateSelected(date); // kirim ke parent
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  chosenDate != null
                      ? DateFormat("dd-MM-yyyy").format(chosenDate!)
                      : widget.placeholder ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    color: chosenDate != null ? Colors.black : Colors.grey,
                  ),
                ),
                const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (widget.errorMessage != null)
          Column(
            children: [
              SizedBox(
                height: 4,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Text(
                  widget.errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            ],
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  // ============================================================
  // SHOW DATE PICKER BOTTOM SHEET
  // ============================================================

  Future<DateTime?> showModernDatePicker(BuildContext context,
      {DateTime? initialDate}) async {
    DateTime tempPicked = initialDate ?? DateTime(2000);

    return await showGeneralDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black45, // sedikit gelap
      pageBuilder: (_, __, ___) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, _, child) {
        return Stack(
          children: [
            // ---------- BLUR BACKGROUND ----------
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                ),
              ),
            ),

            // ---------- BOTTOM SHEET ----------
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOut)),
                child: Material(
                  elevation: 8,
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  child: SizedBox(
                    height: 420,
                    child: Column(
                      children: [
                        // HEADER
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  "Batal",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context, tempPicked),
                                child: Text(
                                  "Pilih",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Constants.primaryColorVendor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 0),

                        // SYNCFUSION DATE PICKER
                        Expanded(
                          child: SfDateRangePicker(
                            backgroundColor: Colors.white,
                            selectionMode: DateRangePickerSelectionMode.single,
                            showNavigationArrow: true,
                            initialSelectedDate: initialDate ?? DateTime(2000),
                            minDate: widget.minDate ??
                                (widget.isPenawaran ? DateTime.now() : null),
                            maxDate: widget.isPenawaran ? null : DateTime.now(),
                            onSelectionChanged: (args) {
                              tempPicked = args.value;
                            },
                            selectionColor: Constants.primaryColorVendor,
                            todayHighlightColor: Constants.primaryColorVendor,
                            headerStyle: DateRangePickerHeaderStyle(
                              backgroundColor: Colors.white,
                              textAlign: TextAlign.center,
                              textStyle: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Constants.primaryColorVendor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
