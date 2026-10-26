import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/empty_state.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Wishlist (${wishlistProvider.wishlistProducts.length})'),
        actions: [
          if (wishlistProvider.wishlistProducts.isNotEmpty)
            TextButton(
              onPressed: () {
                for (var p in wishlistProvider.wishlistProducts) {
                  cartProvider.addToCart(p);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Added all Wishlist products to Cart! 🛍️'),
                  ),
                );
              },
              child: const Text(
                'Add All to Cart',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: wishlistProvider.wishlistProducts.isEmpty
          ? EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Your Wishlist is Empty',
              description: 'Save your favorite toys and return gifts to view them anytime!',
              buttonText: 'Discover Products',
              onButtonPressed: () {
                Navigator.pop(context);
              },
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.52,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: wishlistProvider.wishlistProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(product: wishlistProvider.wishlistProducts[index]);
              },
            ),
    );
  }
}
