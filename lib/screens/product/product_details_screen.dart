import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/shopify_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/enhanced_product_image_gallery.dart';
import '../../widgets/variant_color_selector.dart';
import '../../widgets/stock_availability_badge.dart';
import '../../widgets/cart_drawer_modal.dart';
import '../cart/cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late ProductVariant? _selectedVariant;
  int _quantity = 1;
  final TextEditingController _pincodeController = TextEditingController();
  String? _deliveryEstimateText;
  bool _isCheckingPincode = false;

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.product.variants.isNotEmpty
        ? widget.product.variants.first
        : null;
  }

  @override
  void dispose() {
    _pincodeController.dispose();
    super.dispose();
  }

  void _checkPincode() {
    final pin = _pincodeController.text.trim();
    if (pin.length != 6 || int.tryParse(pin) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit Indian PIN code'),
          backgroundColor: AppColors.saleRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isCheckingPincode = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isCheckingPincode = false;
          final now = DateTime.now();
          final estStart = now.add(const Duration(days: 3));
          final estEnd = now.add(const Duration(days: 5));
          final months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ];
          _deliveryEstimateText =
              'Express delivery to $pin by ${estStart.day} - ${estEnd.day} ${months[estEnd.month - 1]} 🚚';
        });
      }
    });
  }

  List<ProductModel> _getRelatedProducts(ShopifyProvider shopify) {
    final current = widget.product;
    final all = shopify.allProducts;
    if (all.isEmpty) return [];

    // Filter by same productType or matching tags
    final related = all.where((p) {
      if (p.id == current.id) return false;
      final sameType = p.productType.isNotEmpty &&
          p.productType.toLowerCase() == current.productType.toLowerCase();
      final hasCommonTag = p.tags.any((t) => current.tags.contains(t));
      return sameType || hasCommonTag;
    }).toList();

    if (related.length >= 4) return related;

    // Fallback: add top products from catalog to give a rich carousel
    for (final p in all) {
      if (p.id != current.id && !related.any((r) => r.id == p.id)) {
        related.add(p);
      }
      if (related.length >= 10) break;
    }
    return related;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final isSaved = wishlistProvider.isWishlisted(product.id);
    final shopifyProvider = Provider.of<ShopifyProvider>(context);

    final currentPrice = _selectedVariant?.price ?? product.price;
    final comparePrice = _selectedVariant?.compareAtPrice ?? product.compareAtPrice;
    final isOnSale = comparePrice != null && comparePrice > currentPrice;
    final discountPercent = isOnSale ? (((comparePrice - currentPrice) / comparePrice) * 100).round() : 0;
    final isAvailable = _selectedVariant?.available ?? product.available;
    final relatedProducts = _getRelatedProducts(shopifyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          product.vendor.isNotEmpty ? product.vendor : 'TITEPO',
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.favorite : Icons.favorite_border,
              color: isSaved ? AppColors.saleRed : Colors.white,
            ),
            onPressed: () {
              wishlistProvider.toggleWishlist(product);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isSaved ? 'Removed from Wishlist' : 'Saved to Wishlist ❤️'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),
                  if (cart.totalItemCount > 0)
                    Positioned(
                      right: 6,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.saleRed,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${cart.totalItemCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Enhanced Pinch-To-Zoom Image Gallery with Interactive Viewer & Fullscreen Mode
            EnhancedProductImageGallery(
              images: product.images,
              fallbackImage: product.mainImage,
              isOnSale: isOnSale,
              discountPercent: discountPercent,
            ),

            const SizedBox(height: 16),

            // 2. Main Product Details Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tag & Stock availability badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.productType.isNotEmpty ? product.productType.toUpperCase() : 'KIDS PRODUCT',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      StockAvailabilityBadge(
                        isAvailable: isAvailable,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Product Title
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Rating & Reviews Count
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (i) => const Icon(Icons.star, color: AppColors.starYellow, size: 16),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        product.formattedRating,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Flexible(
                        child: Text(
                          ' (${product.reviewsCount} reviews)',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Price Section with Discount Callout
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
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
                        Text(
                          Formatters.formatPrice(currentPrice),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (isOnSale) ...[
                          Text(
                            Formatters.formatPrice(comparePrice),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.saleRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Save ${Formatters.formatPrice(comparePrice - currentPrice)}',
                              style: const TextStyle(
                                color: AppColors.saleRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 3. Variant / Color Selector with Swatches & Stock Status
                  VariantColorSelector(
                    variants: product.variants,
                    selectedVariant: _selectedVariant,
                    onSelectVariant: (v) {
                      setState(() => _selectedVariant = v);
                    },
                  ),

                  if (product.variants.length > 1) const SizedBox(height: 18),

                  // 4. Quantity Selector
                  Row(
                    children: [
                      const Text(
                        'Quantity:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: isAvailable ? () => setState(() => _quantity++) : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 5. Delivery Pincode Estimator
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Delivery & Availability Check',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: TextField(
                                  controller: _pincodeController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    hintText: 'Enter 6-digit PIN code',
                                    hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                                    counterText: '',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 42,
                              child: ElevatedButton(
                                onPressed: _isCheckingPincode ? null : _checkPincode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: _isCheckingPincode
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Check', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                        if (_deliveryEstimateText != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.accentYellowLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _deliveryEstimateText!,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 6. Verified Store Trust Badges
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Row(
                      children: [
                        _TrustFeature(icon: Icons.local_shipping_outlined, title: 'Free Shipping > ₹500'),
                        _TrustFeature(icon: Icons.card_giftcard, title: 'Ready to Gift'),
                        _TrustFeature(icon: Icons.verified_outlined, title: 'Safe & Non-Toxic'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 7. Product Description
                  const Text(
                    'Product Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Formatters.cleanHtml(product.description),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // 8. Related Products Carousel
                  if (relatedProducts.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Text('✨ ', style: TextStyle(fontSize: 16)),
                            Text(
                              'You May Also Like',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${relatedProducts.length} items',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 285,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: relatedProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final rel = relatedProducts[index];
                          return ProductCard(
                            product: rel,
                            width: 160,
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),

      // Sticky Bottom Action Bar with Dynamic Stock State
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: isAvailable
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          cartProvider.addToCart(
                            product,
                            variant: _selectedVariant,
                            quantity: _quantity,
                          );
                          CartDrawerModal.show(context);
                        },
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                        label: const Text('Add to Bag'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primary, width: 1.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await cartProvider.addToCart(
                            product,
                            variant: _selectedVariant,
                            quantity: _quantity,
                          );
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CartScreen()),
                          );
                        },
                        icon: const Icon(Icons.bolt_rounded, size: 18),
                        label: const Text('One-Click Buy'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                )
              : ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.notifications_outlined, size: 18),
                  label: const Text('Notify Me When Available'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
        ),
      ),
    );
  }
}

class _TrustFeature extends StatelessWidget {
  final IconData icon;
  final String title;

  const _TrustFeature({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
