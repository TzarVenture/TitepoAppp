import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/coupon_selector_modal.dart';
import '../../widgets/delivery_pincode_calculator.dart';
import '../auth/login_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  void _checkout(CartProvider cart) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (!auth.isLoggedIn) {
      final loggedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (ctx) => LoginScreen(
            isFromCheckout: true,
            onLoginSuccess: () {
              Navigator.pop(ctx, true);
            },
          ),
        ),
      );

      if (loggedIn != true) return;
    }

    if (!mounted) return;
    _processFinalCheckout(cart, auth);
  }

  void _processFinalCheckout(CartProvider cart, AuthProvider auth) async {
    // Build Shopify direct cart permalink: /cart/{variant_id}:{quantity},...
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
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(url, mode: LaunchMode.inAppBrowserView);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Shopping Cart (${cartProvider.totalItemCount})',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (cartProvider.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear Cart',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Shopping Cart?'),
                    content: const Text('Are you sure you want to remove all items from your cart?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          cartProvider.clearCart();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear All', style: TextStyle(color: AppColors.saleRed)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cartProvider.items.isEmpty
          ? EmptyStateWidget(
              icon: Icons.shopping_bag_outlined,
              title: 'Your Cart is Empty',
              description: 'Looks like you haven\'t added any toys or return gifts to your cart yet!',
              buttonText: 'Start Shopping',
              onButtonPressed: () {
                Navigator.pop(context);
              },
            )
          : Column(
              children: [
                // 1. Free Shipping Progress Bar Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.accentYellowLight,
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: cartProvider.isFreeShippingEligible
                            ? const Text(
                                '🎉 You unlocked FREE SHIPPING on this order!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 12.5,
                                ),
                              )
                            : Text(
                                'Add ${Formatters.formatPrice(cartProvider.remainingForFreeShipping)} more to qualify for FREE SHIPPING!',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                // 2. Scrollable Body: Items + Delivery Estimator + Coupon Section
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Cart Items List
                      ...cartProvider.items.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Product Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  color: AppColors.surfaceGrey,
                                  child: CachedNetworkImage(
                                    imageUrl: item.product.mainImage,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Item details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    if (item.selectedVariant != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          'Option: ${item.selectedVariant!.title}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      Formatters.formatPrice(item.unitPrice),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quantity Stepper & Remove Action
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => cartProvider.removeFromCart(item.cartKey),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => cartProvider.updateQuantity(item.cartKey, -1),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                            child: Icon(Icons.remove, size: 14),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            '${item.quantity}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => cartProvider.updateQuantity(item.cartKey, 1),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                            child: Icon(Icons.add, size: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 8),

                      // 3. Interactive Coupon Code Management Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accentYellow.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.confirmation_number_outlined, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cartProvider.appliedCouponCode != null
                                        ? 'Coupon "${cartProvider.appliedCouponCode}" Applied'
                                        : 'Apply Coupon or Promo Code',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: cartProvider.appliedCouponCode != null ? AppColors.success : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    cartProvider.appliedCouponCode != null
                                        ? 'Saving ${Formatters.formatPrice(cartProvider.discountAmount)} on this order'
                                        : 'Tap to view available discount coupons',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (cartProvider.appliedCouponCode != null)
                              TextButton(
                                onPressed: () => cartProvider.removeCoupon(),
                                child: const Text('Remove', style: TextStyle(color: AppColors.saleRed, fontWeight: FontWeight.bold, fontSize: 12)),
                              )
                            else
                              ElevatedButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => CouponSelectorModal(cart: cartProvider),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Offers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 4. Delivery Pincode Estimator
                      DeliveryPincodeCalculator(cart: cartProvider),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // 5. Sticky Bottom Order Summary & Checkout
                Container(
                  padding: const EdgeInsets.all(18),
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
                            const Text('Subtotal', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
                            Text(Formatters.formatPrice(cartProvider.subtotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        if (cartProvider.discountAmount > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Coupon Discount (${cartProvider.appliedCouponCode})', style: const TextStyle(color: AppColors.saleRed, fontSize: 13)),
                              Text('-${Formatters.formatPrice(cartProvider.discountAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.saleRed, fontSize: 13.5)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimated Shipping', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
                            Text(
                              cartProvider.shippingFee == 0 ? 'FREE' : Formatters.formatPrice(cartProvider.shippingFee),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: cartProvider.shippingFee == 0 ? AppColors.success : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              Formatters.formatPrice(cartProvider.grandTotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 21,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => _checkout(cartProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_outline, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Proceed to Checkout',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
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
