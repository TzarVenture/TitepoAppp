import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/product.dart';
import 'product_card.dart';

enum ProductSort { featured, newest, priceLow, priceHigh, discount }

extension ProductSortLabel on ProductSort {
  String get label => switch (this) {
        ProductSort.featured => 'Featured',
        ProductSort.newest => 'Newest',
        ProductSort.priceLow => 'Price: low to high',
        ProductSort.priceHigh => 'Price: high to low',
        ProductSort.discount => 'Biggest discount',
      };
}

List<ProductModel> sortAndFilter(List<ProductModel> input, ProductSort sort, bool inStockOnly) {
  final list = inStockOnly ? input.where((p) => p.available).toList() : [...input];
  switch (sort) {
    case ProductSort.featured:
      break;
    case ProductSort.newest:
      list.sort((a, b) => (b.publishedAt ?? DateTime(2000)).compareTo(a.publishedAt ?? DateTime(2000)));
    case ProductSort.priceLow:
      list.sort((a, b) => a.price.compareTo(b.price));
    case ProductSort.priceHigh:
      list.sort((a, b) => b.price.compareTo(a.price));
    case ProductSort.discount:
      list.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
  }
  return list;
}

/// Sort + "in stock" toolbar shown above product grids.
class BrowseToolbar extends StatelessWidget {
  final int count;
  final ProductSort sort;
  final bool inStockOnly;
  final ValueChanged<ProductSort> onSort;
  final ValueChanged<bool> onInStock;

  const BrowseToolbar({
    super.key,
    required this.count,
    required this.sort,
    required this.inStockOnly,
    required this.onSort,
    required this.onInStock,
  });

  void _pickSort(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Sort by', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ),
            ...ProductSort.values.map((s) => ListTile(
                  title: Text(s.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: s == sort ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    onSort(s);
                  },
                )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Text('$count items', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const Spacer(),
          FilterChip(
            label: const Text('In stock'),
            selected: inStockOnly,
            onSelected: onInStock,
            labelStyle: TextStyle(
              color: inStockOnly ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.swap_vert_rounded, size: 18),
            label: Text(sort == ProductSort.featured ? 'Sort' : sort.label.split(':').first),
            onPressed: () => _pickSort(context),
          ),
        ],
      ),
    );
  }
}

class EmptyProducts extends StatelessWidget {
  final String message;
  const EmptyProducts({super.key, this.message = 'No products here yet.'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.toys_outlined, size: 52, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Sliver grid wrapper used by browse screens.
class BrowseGrid extends StatelessWidget {
  final List<ProductModel> products;
  const BrowseGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SliverToBoxAdapter(child: EmptyProducts());
    }
    return ProductSliverGrid(products: products);
  }
}
