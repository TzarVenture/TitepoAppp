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
import '../return_gift/return_gift_solutions_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late ProductVariant? _selectedVariant;
  // Default to standard 10-piece birthday party pack size
  int _quantity = 10;
  final TextEditingController _pincodeController = TextEditingController();
  String? _deliveryEstimateText;
  bool _isCheckingPincode = false;

  /// Tiered party bulk volume discount rate
  double get _bulkDiscountRate {
    if (_quantity >= 30) return 0.20; // 20% OFF for 30+ pcs (Mega Party)
    if (_quantity >= 20) return 0.15; // 15% OFF for 20+ pcs (Classroom Pack)
    if (_quantity >= 10) return 0.10; // 10% OFF for 10+ pcs (Standard Party)
    return 0.0;
  }

  double get _unitPrice => _selectedVariant?.price ?? widget.product.price;
  double get _discountedUnitPrice => _unitPrice * (1.0 - _bulkDiscountRate);
  double get _totalBulkPrice => _discountedUnitPrice * _quantity;
  double get _totalSavings => (_unitPrice - _discountedUnitPrice) * _quantity;

  void _showCustomQuantityDialog() {
    final controller = TextEditingController(text: '$_quantity');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Party Guest / Gift Count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Number of Kids / Return Gifts',
            hintText: 'e.g. 18, 24, 35',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                setState(() => _quantity = val);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Apply Count'),
          ),
        ],
      ),
    );
  }

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

                  // 4. Scientifically-Brained Bulk Party Pricing & Gifting
                  Container(
                    padding: const EdgeInsets.all(14),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.card_giftcard_rounded, color: AppColors.primary, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Bulk Return Gift Pricing',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accentYellowLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '🎉 PARTY DISCOUNTS',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Tier Cards: 10+, 20+, 30+ pcs
                        Row(
                          children: [
                            Expanded(
                              child: _buildBulkTierCard(
                                title: 'Party Pack',
                                pcs: '10+ Pcs',
                                discount: '10% OFF',
                                unitPrice: _unitPrice * 0.90,
                                isActive: _quantity >= 10 && _quantity < 20,
                                onTap: () => setState(() => _quantity = 10),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildBulkTierCard(
                                title: 'Classroom',
                                pcs: '20+ Pcs',
                                discount: '15% OFF',
                                badge: 'POPULAR',
                                unitPrice: _unitPrice * 0.85,
                                isActive: _quantity >= 20 && _quantity < 30,
                                onTap: () => setState(() => _quantity = 20),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildBulkTierCard(
                                title: 'Mega Hamper',
                                pcs: '30+ Pcs',
                                discount: '20% OFF',
                                badge: 'BEST VALUE',
                                unitPrice: _unitPrice * 0.80,
                                isActive: _quantity >= 30,
                                onTap: () => setState(() => _quantity = 30),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Psychological Savings Alert / Nudge
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: _quantity >= 10
                                ? AppColors.accentYellowLight
                                : AppColors.surfaceGrey,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _quantity >= 10
                                  ? AppColors.accentYellow
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _quantity >= 10 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                size: 16,
                                color: _quantity >= 10 ? AppColors.primary : AppColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _quantity >= 10
                                      ? '🎉 ${(_bulkDiscountRate * 100).toInt()}% Party Bulk Discount Applied! Total Savings: ${Formatters.formatPrice(_totalSavings)}'
                                      : '💡 Add ${10 - _quantity} more piece${10 - _quantity == 1 ? '' : 's'} to unlock 10% Bulk Party Discount!',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: _quantity >= 10 ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Stepper + Quick Bulk Selection Chips
                        Row(
                          children: [
                            const Text(
                              'Quantity:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16),
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      '$_quantity',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    onPressed: isAvailable ? () => setState(() => _quantity++) : null,
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _showCustomQuantityDialog,
                              icon: const Icon(Icons.edit_outlined, size: 14),
                              label: const Text('Custom Count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Quick Bulk Preset Chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final count in [10, 15, 20, 25, 30, 50])
                              ChoiceChip(
                                label: Text('$count pcs'),
                                selected: _quantity == count,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _quantity == count ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: _quantity == count ? AppColors.primary : AppColors.border,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                onSelected: (sel) {
                                  if (sel) setState(() => _quantity = count);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 5. Custom Return Gift Bag Pairing Section (The Core Value Prop)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.accentYellow,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Pair with Custom Return Gift Bags',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'RECOMMENDED',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Packing for a celebration? Add personalized theme bags printed with your child\'s photo & name for all $_quantity gifts!',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReturnGiftSolutionsScreen(
                                    initialAccessory: widget.product,
                                    initialQuantity: _quantity,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: Text('🎒 Build Return Gift Bag with this Toy ($_quantity Bags)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

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
          border: const Border(
            top: BorderSide(color: AppColors.borderLight, width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: isAvailable
              ? Row(
                  children: [
                    // Left: Live Pack Total Price & Unit Breakdown
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                Formatters.formatPrice(_totalBulkPrice),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (_bulkDiscountRate > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.saleRed.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${(_bulkDiscountRate * 100).toInt()}% OFF',
                                    style: const TextStyle(
                                      color: AppColors.saleRed,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_quantity Pcs Pack (${Formatters.formatPrice(_discountedUnitPrice)}/pc)',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Middle: Quick "Pair with Custom Bag" Button
                    Tooltip(
                      message: 'Pair with Custom Gift Bags',
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReturnGiftSolutionsScreen(
                                initialAccessory: widget.product,
                                initialQuantity: _quantity,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary, width: 1.2),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Right: Primary Add to Cart Button
                    ElevatedButton.icon(
                      onPressed: () {
                        cartProvider.addToCart(
                          product,
                          variant: _selectedVariant,
                          quantity: _quantity,
                        );
                        CartDrawerModal.show(context);
                      },
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  Widget _buildBulkTierCard({
    required String title,
    required String pcs,
    required String discount,
    required double unitPrice,
    required bool isActive,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentYellowLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.borderLight,
            width: isActive ? 1.8 : 1.0,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                ),
              )
            else
              const SizedBox(height: 14),
            Text(
              pcs,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: isActive ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppColors.saleRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                discount,
                style: const TextStyle(
                  color: AppColors.saleRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${Formatters.formatPrice(unitPrice)}/pc',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
