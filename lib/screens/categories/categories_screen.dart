import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/shopify_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/skeleton_loader.dart';

class CategoriesScreen extends StatefulWidget {
  final String? initialCategoryHandle;

  const CategoriesScreen({super.key, this.initialCategoryHandle});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _sortOption = 'featured'; // 'featured', 'price_low', 'price_high', 'rating'
  final ScrollController _tabsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryHandle != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final shopify = Provider.of<ShopifyProvider>(context, listen: false);
        shopify.selectCategory(widget.initialCategoryHandle!);

        // Auto-scroll to selected category tab
        final idx = AppConstants.featuredCategories
            .indexWhere((c) => c['handle'] == widget.initialCategoryHandle);
        if (idx > 0 && _tabsScrollController.hasClients) {
          _tabsScrollController.animateTo(
            idx * 110.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _tabsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopifyProvider = Provider.of<ShopifyProvider>(context);
    var products = List.from(shopifyProvider.categoryProducts);

    // Apply sorting
    if (_sortOption == 'price_low') {
      products.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortOption == 'price_high') {
      products.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortOption == 'rating') {
      products.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories & Collections'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort Products',
            onSelected: (val) {
              setState(() => _sortOption = val);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'featured', child: Text('Featured')),
              const PopupMenuItem(value: 'price_low', child: Text('Price: Low to High')),
              const PopupMenuItem(value: 'price_high', child: Text('Price: High to Low')),
              const PopupMenuItem(value: 'rating', child: Text('Highest Rated')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Category Tabs Bar
          Container(
            height: 54,
            color: Colors.white,
            child: ListView.builder(
              controller: _tabsScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: AppConstants.featuredCategories.length,
              itemBuilder: (context, index) {
                final cat = AppConstants.featuredCategories[index];
                final isSelected = shopifyProvider.selectedCollectionHandle == cat['handle'];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: Text(
                      cat['icon']!,
                      style: const TextStyle(fontSize: 14),
                    ),
                    label: Text(cat['title']!),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.background,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                    onSelected: (_) {
                      shopifyProvider.selectCategory(cat['handle']!);
                    },
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Count & Active Filter Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${products.length} Products',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Sort: ${_sortOption.replaceAll('_', ' ').toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Product Grid
          Expanded(
            child: shopifyProvider.isCategoryLoading
                ? const SkeletonLoader.grid(itemCount: 6)
                : products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.category_outlined, size: 60, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No products found in this category.',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => shopifyProvider.selectCategory('all'),
                              child: const Text('Browse All Products'),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.52,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          return ProductCard(product: products[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
