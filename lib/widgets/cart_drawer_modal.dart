import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/cart/cart_screen.dart';
import 'coupon_selector_modal.dart';

class CartDrawerModal extends StatelessWidget {
  const CartDrawerModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CartDrawerModal(),
    );
  }

  void _checkout(BuildContext context, CartProvider cart) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (!auth.isLoggedIn) {
      final loggedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (ctx) => LoginScreen(
            isFromCheckout: true,
            onLoginSuccess: () => Navigator.pop(ctx, true),
          ),
        ),
      );
      if (loggedIn != true) return;
    }

    // Direct cart permalink to Shopify
    final List<String> cartSegments = [];
    for (final item in cart.items) {
      final variantId = item.selectedVariant?.id ??
          (item.product.variants.isNotEmpty ? item.product.variants.first.id : null);
      if (variantId != null && int.tryParse(variantId) != null) {
        cartSegments.add('$variantId:${item.quantity}');
      }
    }

    String checkoutUrl;
    if (cartSegments.isNotEmpty) {
      checkoutUrl = '${AppConstants.storeDomain}/cart/${cartSegments.join(',')}';
      if (cart.appliedCouponCode != null && cart.appliedCouponCode!.isNotEmpty) {
        checkoutUrl += '?discount=${Uri.encodeComponent(cart.appliedCouponCode!)}';
      }
    } else {
      checkoutUrl = '${AppConstants.storeDomain}/cart';
    }

    final Uri url = Uri.parse(checkoutUrl);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Your Bag (${cart.totalItemCount})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Free shipping indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.accentYellowLight,
            child: Row(
              children: [
                const Icon(Icons.local_shipping, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: cart.isFreeShippingEligible
                      ? const Text(
                          '🎉 Free Delivery Unlocked!',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                        )
                      : Text(
                          'Add ${Formatters.formatPrice(cart.remainingForFreeShipping)} more for Free Shipping',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 11.5),
                        ),
                ),
              ],
            ),
          ),

          // Cart Items List
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 54, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'Your bag is currently empty',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Start Exploring Toys'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: item.product.mainImage,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  if (item.selectedVariant != null)
                                    Text(
                                      item.selectedVariant!.title,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatPrice(item.unitPrice),
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => cart.updateQuantity(item.cartKey, -1),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.remove, size: 14),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                InkWell(
                                  onTap: () => cart.updateQuantity(item.cartKey, 1),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.add, size: 14),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Coupon Strip
          if (cart.items.isNotEmpty)
            InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CouponSelectorModal(cart: cart),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cart.appliedCouponCode != null
                            ? 'Coupon "${cart.appliedCouponCode}" Applied (-${Formatters.formatPrice(cart.discountAmount)})'
                            : 'Have a coupon code? View offers',
                        style: TextStyle(
                          color: cart.appliedCouponCode != null ? AppColors.success : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 12),
                  ],
                ),
              ),
            ),

          // Bottom Checkout Summary
          if (cart.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          Formatters.formatPrice(cart.grandTotal),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CartScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.primary),
                            ),
                            child: const Text('View Full Cart'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () => _checkout(context, cart),
                            icon: const Icon(Icons.bolt_rounded, size: 18),
                            label: const Text('Instant Checkout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
