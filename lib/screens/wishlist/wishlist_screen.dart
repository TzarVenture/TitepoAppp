import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/ui_kit.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final products = wishlist.wishlistProducts;

    return Scaffold(
      appBar: AppBar(
        title: Text(products.isEmpty ? 'Wishlist' : 'Wishlist (${products.length})'),
        actions: const [CartIconButton(), SizedBox(width: 6)],
      ),
      body: products.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: const BoxDecoration(color: Color(0xFFFFE4EC), shape: BoxShape.circle),
                      child: const Icon(Icons.favorite_border_rounded, size: 50, color: AppColors.saleRed),
                    ),
                    const SizedBox(height: 20),
                    Text('Nothing saved yet', style: AppTheme.display(size: 22)),
                    const SizedBox(height: 6),
                    Text('Tap the heart on any product to save it here.',
                        textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 20),
                    FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Browse products')),
                  ],
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ProductSliverGrid(products: products.reversed.toList()),
              ],
            ),
    );
  }
}
