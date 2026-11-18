import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/product/product_details_screen.dart';
import 'ui_kit.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final double? width;

  const ProductCard({super.key, required this.product, this.width});

  void _open(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)));
  }

  void _quickAdd(BuildContext context) {
    if (product.hasRealVariants) {
      _open(context); // choose an option first
      return;
    }
    context.read<CartProvider>().addToCart(product);
    showAppSnack(
      context,
      'Added to cart',
      actionLabel: 'VIEW',
      onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.select<WishlistProvider, bool>((w) => w.isWishlisted(product.id));

    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () => _open(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AppNetworkImage(url: product.mainImage, width: 480),
                    ),
                  ),
                  if (!product.available)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(20)),
                          child: const Text('Sold out',
                              style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    )
                  else if (product.isOnSale)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.saleRed, borderRadius: BorderRadius.circular(20)),
                        child: Text('${product.discountPercentage}% OFF',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10.5)),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _CircleButton(
                      icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: saved ? AppColors.saleRed : AppColors.ink,
                      tooltip: saved ? 'Remove from wishlist' : 'Save to wishlist',
                      onTap: () => context.read<WishlistProvider>().toggleWishlist(product),
                    ),
                  ),
                  if (product.available)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: _CircleButton(
                        icon: Icons.add_rounded,
                        color: Colors.white,
                        background: AppColors.primary,
                        tooltip: 'Add to cart',
                        onTap: () => _quickAdd(context),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                product.displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.3, color: AppColors.ink),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: PriceTag(price: product.price, compareAt: product.compareAtPrice, size: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.background = const Color(0xF2FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(7), child: Icon(icon, size: 19, color: color)),
        ),
      ),
    );
  }
}

/// Responsive 2/3-column product grid as a sliver.
class ProductSliverGrid extends StatelessWidget {
  final List<ProductModel> products;
  final EdgeInsetsGeometry padding;

  const ProductSliverGrid({
    super.key,
    required this.products,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 24),
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 230,
          mainAxisSpacing: 20,
          crossAxisSpacing: 14,
          childAspectRatio: 0.62,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) => ProductCard(product: products[i]),
          childCount: products.length,
        ),
      ),
    );
  }
}

/// Horizontally scrolling product rail.
class ProductRail extends StatelessWidget {
  final List<ProductModel> products;
  final double itemWidth;

  const ProductRail({super.key, required this.products, this.itemWidth = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemWidth + 92,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => ProductCard(product: products[i], width: itemWidth),
      ),
    );
  }
}
