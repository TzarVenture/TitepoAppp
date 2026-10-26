import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/cart_provider.dart';

class CouponSelectorModal extends StatefulWidget {
  final CartProvider cart;

  const CouponSelectorModal({super.key, required this.cart});

  @override
  State<CouponSelectorModal> createState() => _CouponSelectorModalState();
}

class _CouponSelectorModalState extends State<CouponSelectorModal> {
  final TextEditingController _customController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _apply(String code) {
    final err = widget.cart.applyCoupon(code);
    if (err == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coupon "$code" applied successfully! 🎉'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() => _errorText = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.confirmation_number_outlined, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Available Offers & Coupons',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Custom Input Box
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter coupon code',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _apply(_customController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              style: const TextStyle(color: AppColors.saleRed, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],

          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 8),

          const Text(
            'Recommended Coupons for You:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),

          // List of verified coupons
          ...CartProvider.availableCoupons.map((coupon) {
            final isApplied = widget.cart.appliedCouponCode == coupon.code;
            final isEligible = coupon.minOrderValue == null || widget.cart.subtotal >= coupon.minOrderValue!;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isApplied ? AppColors.accentYellowLight : AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isApplied ? AppColors.accentYellow : AppColors.borderLight,
                  width: isApplied ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary, width: 1.2),
                    ),
                    child: Text(
                      coupon.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        fontSize: 12.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coupon.description,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (coupon.minOrderValue != null && coupon.minOrderValue! > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Min order ${Formatters.formatPrice(coupon.minOrderValue!)}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isEligible ? AppColors.textMuted : AppColors.saleRed,
                              fontWeight: isEligible ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isApplied)
                    TextButton(
                      onPressed: () {
                        widget.cart.removeCoupon();
                        Navigator.pop(context);
                      },
                      child: const Text('Remove', style: TextStyle(color: AppColors.saleRed, fontWeight: FontWeight.bold)),
                    )
                  else
                    ElevatedButton(
                      onPressed: isEligible ? () => _apply(coupon.code) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentYellow,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
