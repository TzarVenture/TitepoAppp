import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../models/product.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/formatters.dart';
import '../providers/wishlist_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/product/product_details_screen.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final double width;

  const ProductCard({
    super.key,
    required this.product,
    this.width = 170,
  });

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final isSaved = wishlistProvider.isWishlisted(product.id);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(product: product),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Container with Badges
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      color: AppColors.surfaceGrey,
                      child: CachedNetworkImage(
                        imageUrl: product.mainImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: AppColors.shimmerBase,
                          highlightColor: AppColors.shimmerHighlight,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.toys, color: AppColors.textMuted, size: 36),
                        ),
                      ),
                    ),
                  ),

                  // Sale Discount Badge
                  if (product.isOnSale)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.accentYellow,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 3,
                            )
                          ],
                        ),
                        child: Text(
                          '-${product.discountPercentage}% OFF',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ),

                  // Wishlist Heart Button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        wishlistProvider.toggleWishlist(product);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isSaved ? 'Removed from Wishlist' : 'Saved to Wishlist ❤️',
                            ),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Color(0xE6FFFFFF),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 3,
                            )
                          ],
                        ),
                        child: Icon(
                          isSaved ? Icons.favorite : Icons.favorite_border,
                          color: isSaved ? AppColors.saleRed : AppColors.textMuted,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Product Info & Price Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isCompact = constraints.maxHeight < 95;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Category / Vendor tag
                                Text(
                                  product.productType.isNotEmpty
                                      ? product.productType.toUpperCase()
                                      : 'KIDS FAVORITE',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.primaryLight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                // Title
                                Text(
                                  product.title,
                                  maxLines: isCompact ? 1 : 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Rating & Price row
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: AppColors.starYellow, size: 13),
                                    const SizedBox(width: 2),
                                    Text(
                                      product.formattedRating,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      ' (${product.reviewsCount})',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            Formatters.formatPrice(product.price),
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14.5,
                                            ),
                                          ),
                                        ),
                                        if (product.isOnSale)
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              Formatters.formatPrice(product.compareAtPrice),
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 10.5,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 4),

                                  // Quick Add to Cart button
                                  InkWell(
                                    onTap: () {
                                      cartProvider.addToCart(product);
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.shopping_bag, color: Colors.white, size: 18),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text('Added "${product.title}" to Cart! 🛍️'),
                                              ),
                                            ],
                                          ),
                                          action: SnackBarAction(
                                            label: 'VIEW CART',
                                            textColor: AppColors.accentYellow,
                                            onPressed: () {},
                                          ),
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: AppColors.primary,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.add_shopping_cart_rounded,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
