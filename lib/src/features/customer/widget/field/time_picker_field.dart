import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';

class TimePickerField extends StatefulWidget {
  final String label;
  final TimeOfDay? selectedTime;
  final String? errorMessage;
  final String selectedZone;

  final Function(TimeOfDay, String) onTimeSelected;

  const TimePickerField({
    super.key,
    required this.label,
    required this.selectedTime,
    required this.onTimeSelected,
    this.selectedZone = "WIB",
    this.errorMessage,
  });

  @override
  State<TimePickerField> createState() => _TimePickerFieldState();
}

class _TimePickerFieldState extends State<TimePickerField> {
  late TimeOfDay? chosenTime;
  late String chosenZone;

  @override
  void initState() {
    super.initState();
    chosenTime = widget.selectedTime;
    chosenZone = widget.selectedZone;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),

        /// FIELD
        GestureDetector(
          onTap: () async {
            final result = await showModernTimePicker(context,
                initialTime: chosenTime, initialZone: chosenZone);

            if (result != null) {
              setState(() {
                chosenTime = result["time"];
                chosenZone = result["zone"];
              });
              widget.onTimeSelected(result["time"], result["zone"]);
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
            child: Text(
              chosenTime != null
                  ? "${_formatTime(chosenTime!)}  •  $chosenZone"
                  : "Pilih waktu & zona",
              style: TextStyle(
                fontSize: 15,
                color: chosenTime != null ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),

        if (widget.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 5),
            child: Text(widget.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14)),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  // =====================================================================
  // TIME PICKER + PILIH ZONA (WIB / WITA / WIT)
  // =====================================================================

  Future<Map<String, dynamic>?> showModernTimePicker(
    BuildContext context, {
    TimeOfDay? initialTime,
    required String initialZone,
  }) async {
    TimeOfDay tempTime = initialTime ?? TimeOfDay.now();
    String tempZone = initialZone;

    return showGeneralDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black45,
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, __, ___) {
        return Stack(
          alignment: Alignment.center,
          children: [
            /// LAYER BLUR
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.black.withOpacity(0.2)),
              ),
            ),

            /// POPUP UTAMA
            SlideTransition(
              position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: Material(
                color: Colors.white,
                elevation: 10,
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  width: 330,
                  height: 320,
                  child: Column(children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text("Batal",
                                  style: TextStyle(color: Colors.grey))),
                          GestureDetector(
                            onTap: () => Navigator.pop(
                                context, {"time": tempTime, "zone": tempZone}),
                            child: Text("Pilih",
                                style: TextStyle(
                                    color: Constants.primaryColor,
                                    fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),

                    const Divider(height: 0),

                    const SizedBox(height: 8),

                    /// TIME PICKER
                    Expanded(
                      child: TimePickerSpinner(
                        time: DateTime(
                            2024, 1, 1, tempTime.hour, tempTime.minute),
                        is24HourMode: true,
                        spacing: 50,
                        itemHeight: 50,
                        normalTextStyle:
                            const TextStyle(fontSize: 18, color: Colors.grey),
                        highlightedTextStyle: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Constants.primaryColor),
                        onTimeChange: (time) {
                          setState(() {
                            tempTime =
                                TimeOfDay(hour: time.hour, minute: time.minute);
                          });
                        },
                      ),
                    ),

                    /// === ZONA WAKTU SELECTOR ===
                    const SizedBox(height: 10),

                    StatefulBuilder(
                      builder: (context, setInnerState) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: ["WIB", "WITA", "WIT"].map((zone) {
                            final active = tempZone == zone;

                            return GestureDetector(
                              onTap: () {
                                setInnerState(
                                    () => tempZone = zone); // UPDATE REALTIME
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: active
                                      ? Constants.primaryColor
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(zone,
                                    style: TextStyle(
                                        color: active
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.w600)),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 18),
                  ]),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  String _formatTime(TimeOfDay t) =>
      DateFormat("HH:mm").format(DateTime(2024, 1, 1, t.hour, t.minute));
}
