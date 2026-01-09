import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpjnew/src/core/constants/constants.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? placeholder;
  final String? errorMessage;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool readOnly;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.keyboardType = TextInputType.text,
    this.errorMessage,
    this.maxLines = 1,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.prefixIcon,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Label
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),

        /// Text Field
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          focusNode: focusNode,
          style: TextStyle(
            fontSize: 14,
            color: readOnly ? Colors.grey.shade600 : Colors.black,
          ),
          inputFormatters: inputFormatters,
          cursorColor: Constants.primaryColorVendor,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),

            filled: true,
            fillColor: readOnly // ✅ UBAH BACKGROUND JIKA READONLY
                ? Colors.grey.shade100
                : Colors.white,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 18),

            /// Border Style
            enabledBorder: _border(Colors.grey.shade300),
            border: _border(Colors.grey.shade300),
            focusedBorder: _border(
              readOnly
                  ? Colors.grey.shade400
                  : Constants.primaryColorVendor, // ✅ UPDATE
              2,
            ),
            errorBorder: _border(Colors.red, 1.6),
            focusedErrorBorder: _border(Colors.red, 2),
          ),
        ),

        /// Error Text
        if (errorMessage != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  /// Border builder
  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
