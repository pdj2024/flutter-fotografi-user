import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/status_config.dart';

class EmptyOrder extends StatelessWidget {
  final String? selectedFilter;
  final VoidCallback onTap;
  const EmptyOrder({super.key, this.selectedFilter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 32,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              selectedFilter == null
                  ? 'Belum ada pesanan aktif'
                  : 'Tidak ada pesanan ${getStatus(selectedFilter!).label.toLowerCase()}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            if (selectedFilter != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onTap,
                child: Text(
                  'Lihat semua',
                  style: TextStyle(
                    fontSize: 13,
                    color: Constants.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
