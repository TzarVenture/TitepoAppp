import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../core/constants/app_colors.dart';

class VariantColorSelector extends StatelessWidget {
  final List<ProductVariant> variants;
  final ProductVariant? selectedVariant;
  final ValueChanged<ProductVariant> onSelectVariant;

  const VariantColorSelector({
    super.key,
    required this.variants,
    required this.selectedVariant,
    required this.onSelectVariant,
  });

  // Helper mapping common color names to Color objects
  Color _getSwatchColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('red')) return const Color(0xFFE53935);
    if (lower.contains('blue') || lower.contains('sky')) return const Color(0xFF1E88E5);
    if (lower.contains('yellow') || lower.contains('gold')) return const Color(0xFFFFB300);
    if (lower.contains('green')) return const Color(0xFF43A047);
    if (lower.contains('pink') || lower.contains('magenda')) return const Color(0xFFE91E63);
    if (lower.contains('black')) return const Color(0xFF212121);
    if (lower.contains('white')) return const Color(0xFFF5F5F5);
    if (lower.contains('purple') || lower.contains('violet')) return const Color(0xFF8E24AA);
    if (lower.contains('orange')) return const Color(0xFFFB8C00);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty || variants.length == 1 && variants.first.title.toLowerCase() == 'default title') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Option / Color:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            if (selectedVariant != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selectedVariant!.available
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.saleRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  selectedVariant!.available ? 'In Stock' : 'Out of Stock',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: selectedVariant!.available ? AppColors.success : AppColors.saleRed,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: variants.map((variant) {
            final isSelected = selectedVariant?.id == variant.id;
            final isAvailable = variant.available;
            final swatchColor = _getSwatchColor(variant.title);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: isAvailable ? () => onSelectVariant(variant) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isAvailable
                            ? Colors.white
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : isAvailable
                              ? AppColors.border
                              : Colors.grey[300]!,
                      width: isSelected ? 2 : 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Color swatch circle
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: swatchColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        variant.title,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isAvailable
                                  ? AppColors.textPrimary
                                  : Colors.grey[500],
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12.5,
                          decoration: isAvailable ? null : TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
