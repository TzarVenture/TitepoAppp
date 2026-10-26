import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants/app_colors.dart';

/// Base Shimmer Wrapper with Titepo App Color Palette
class AppShimmer extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? AppColors.shimmerBase,
      highlightColor: highlightColor ?? AppColors.shimmerHighlight,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// Generic Shimmer Box / Rectangle with rounded corners
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer Circle for Avatars, Category Icons, and Floating Buttons
class ShimmerCircle extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry? margin;

  const ShimmerCircle({
    super.key,
    required this.size,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Product Card Skeleton matching the exact layout of [ProductCard]
class ProductCardSkeleton extends StatelessWidget {
  final double width;

  const ProductCardSkeleton({
    super.key,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1:1 Image Placeholder
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
            ),
          ),

          // Details Section
          const Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category tag
                ShimmerBox(width: 48, height: 8, borderRadius: 4),
                SizedBox(height: 6),

                // Title Line 1 & Line 2
                ShimmerBox(width: double.infinity, height: 11, borderRadius: 4),
                SizedBox(height: 4),
                ShimmerBox(width: 80, height: 11, borderRadius: 4),
                SizedBox(height: 8),

                // Rating stars placeholder
                ShimmerBox(width: 55, height: 10, borderRadius: 4),
                SizedBox(height: 10),

                // Price and Add button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 52, height: 14, borderRadius: 4),
                    ShimmerBox(width: 24, height: 24, borderRadius: 7),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Comprehensive, Reusable Skeleton Loader System for Titepo
class SkeletonLoader extends StatelessWidget {
  final Widget? customContent;

  const SkeletonLoader({super.key, this.customContent});

  /// Factory: 2-Column Product Grid Skeleton
  const factory SkeletonLoader.grid({Key? key, int itemCount, double childAspectRatio}) =
      _ProductGridSkeleton;

  /// Factory: Horizontal Shelf Product Skeleton
  const factory SkeletonLoader.horizontalList({Key? key, int itemCount, double height}) =
      _ProductHorizontalSkeleton;

  /// Factory: Circular Category Story Bubbles Skeleton
  const factory SkeletonLoader.categories({Key? key, int itemCount}) =
      _CategoryListSkeleton;

  /// Factory: Hero Banner Skeleton
  const factory SkeletonLoader.banner({Key? key, double height}) =
      _BannerSkeleton;

  /// Factory: Full Home Screen Initial Load Skeleton
  const factory SkeletonLoader.homeScreen({Key? key}) =
      _HomeScreenSkeleton;

  /// Factory: Generic List Items Skeleton (Cart, Orders, Search)
  const factory SkeletonLoader.list({Key? key, int itemCount}) =
      _ListItemsSkeleton;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: customContent ?? const _ProductGridSkeleton(),
    );
  }
}

/// Grid Implementation
class _ProductGridSkeleton extends SkeletonLoader {
  final int itemCount;
  final double childAspectRatio;

  const _ProductGridSkeleton({
    super.key,
    this.itemCount = 4,
    this.childAspectRatio = 0.52,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
        ),
        itemCount: itemCount,
        itemBuilder: (_, __) => const ProductCardSkeleton(),
      ),
    );
  }
}

/// Horizontal Shelf Implementation
class _ProductHorizontalSkeleton extends SkeletonLoader {
  final int itemCount;
  final double height;

  const _ProductHorizontalSkeleton({
    super.key,
    this.itemCount = 4,
    this.height = 285,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SizedBox(
        height: height,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => const ProductCardSkeleton(width: 160),
        ),
      ),
    );
  }
}

/// Category Circles Implementation
class _CategoryListSkeleton extends SkeletonLoader {
  final int itemCount;

  const _CategoryListSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SizedBox(
        height: 94,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, __) => const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShimmerCircle(size: 58),
              SizedBox(height: 6),
              ShimmerBox(width: 48, height: 10, borderRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero Banner Skeleton
class _BannerSkeleton extends SkeletonLoader {
  final double height;

  const _BannerSkeleton({
    super.key,
    this.height = 195,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: const ShimmerBox(
          width: double.infinity,
          height: double.infinity,
          borderRadius: 20,
        ),
      ),
    );
  }
}

/// List Items Skeleton
class _ListItemsSkeleton extends SkeletonLoader {
  final int itemCount;

  const _ListItemsSkeleton({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: const Row(
            children: [
              ShimmerBox(width: 70, height: 70, borderRadius: 12),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: double.infinity, height: 13, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 100, height: 11, borderRadius: 4),
                    SizedBox(height: 10),
                    ShimmerBox(width: 60, height: 14, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Complete Home Screen Initial Load Skeleton
class _HomeScreenSkeleton extends SkeletonLoader {
  const _HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top search bar placeholder
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: ShimmerBox(width: double.infinity, height: 44, borderRadius: 14),
          ),
          SizedBox(height: 6),

          // Banner
          SkeletonLoader.banner(),
          SizedBox(height: 18),

          // Category Bubbles
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerBox(width: 130, height: 16, borderRadius: 4),
          ),
          SizedBox(height: 12),
          SkeletonLoader.categories(),
          SizedBox(height: 22),

          // Trending Shelf
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerBox(width: 170, height: 16, borderRadius: 4),
          ),
          SizedBox(height: 12),
          SkeletonLoader.horizontalList(),
          SizedBox(height: 24),

          // Grid Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerBox(width: 140, height: 16, borderRadius: 4),
          ),
          SizedBox(height: 12),
          SkeletonLoader.grid(itemCount: 4),
        ],
      ),
    );
  }
}
