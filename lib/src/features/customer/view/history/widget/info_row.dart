import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = Colors.black,
    this.copyable = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final bool copyable;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.black45),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black54)),
                  if (copyable)
                    InkWell(
                      onTap: () =>
                          Helper.copyToClipboard(context, value, label),
                      child: Icon(Icons.copy_rounded,
                          size: 16, color: Constants.primaryColorVendor),
                    ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      color: valueColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
