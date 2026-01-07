// lib/src/core/widgets/custom_modal.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class CustomModal {
  /// Show modal dengan blur background
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget body,
    String? title,
    double? height,
    bool isDismissible = true,
    Widget? bottomButton,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isDismissible ? () => Navigator.pop(context) : null,
          child: Stack(
            children: [
              /// Blur Background
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.black.withOpacity(0.2)),
              ),

              /// Modal Content
              GestureDetector(
                onTap: () {}, // Prevent modal close when tapping content
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      height: height ?? MediaQuery.of(context).size.height * 0.6,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                      ),
                      child: Column(
                        children: [
                          /// Handle bar
                          Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          
                          /// Title
                          if (title != null) ...[
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          
                          /// Body
                          Expanded(child: body),
                          
                          /// Bottom Button (optional)
                          if (bottomButton != null) ...[
                            const SizedBox(height: 12),
                            bottomButton,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom Search Bar Widget
class CustomSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const CustomSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey.shade100,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: onChanged,
    );
  }
}