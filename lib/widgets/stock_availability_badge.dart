import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StockAvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  final int? quantityLeft;

  const StockAvailabilityBadge({
    super.key,
    required this.isAvailable,
    this.quantityLeft,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.saleRed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.saleRed.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.saleRed, size: 14),
            SizedBox(width: 6),
            Text(
              'Currently Out of Stock',
              style: TextStyle(
                color: AppColors.saleRed,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final isLowStock = quantityLeft != null && quantityLeft! > 0 && quantityLeft! <= 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isLowStock
            ? AppColors.starYellow.withValues(alpha: 0.15)
            : AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLowStock
              ? AppColors.starYellow.withValues(alpha: 0.5)
              : AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isLowStock ? const Color(0xFFD97706) : AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isLowStock
                ? 'Hurry! Only $quantityLeft units left in stock'
                : 'In Stock & Ready to Dispatch',
            style: TextStyle(
              color: isLowStock ? const Color(0xFFB45309) : AppColors.success,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
