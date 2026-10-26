import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class TrustBadgeRow extends StatelessWidget {
  const TrustBadgeRow({super.key});

  @override
  Widget build(BuildContext context) {
    final badges = [
      {'icon': Icons.local_shipping_outlined, 'title': 'Free Shipping', 'sub': 'Over ₹500'},
      {'icon': Icons.card_giftcard, 'title': 'Ready to Gift', 'sub': 'Premium Packaging'},
      {'icon': Icons.verified_user_outlined, 'title': '100% Quality', 'sub': 'Safe & Non-Toxic'},
      {'icon': Icons.published_with_changes, 'title': 'Easy Return', 'sub': 'Instant Support'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: badges.map((b) {
          return Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  b['icon'] as IconData,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  b['title'] as String,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
                const SizedBox(height: 1),
                Text(
                  b['sub'] as String,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
