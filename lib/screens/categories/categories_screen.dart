import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/collection.dart';
import '../../providers/shopify_provider.dart';
import '../../widgets/product_browser.dart';
import '../../widgets/ui_kit.dart';
import '../search/search_screen.dart';

/// "Shop" tab: every collection from the store + the full catalogue.
class CategoriesScreen extends StatefulWidget {
  final String? initialCategoryHandle;
  const CategoriesScreen({super.key, this.initialCategoryHandle});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late String _handle = widget.initialCategoryHandle ?? 'all';
  ProductSort _sort = ProductSort.featured;
  bool _inStock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ShopifyProvider>().selectCategory(_handle);
    });
  }

  void _select(String handle) {
    setState(() => _handle = handle);
    context.read<ShopifyProvider>().selectCategory(handle);
  }

  List<CollectionModel> _orderedCollections(List<CollectionModel> all) {
    final featured = AppConstants.featuredCategories.map((c) => c['handle']).toList();
    final list = all.where((c) => c.productsCount > 0 || featured.contains(c.handle)).toList();
    list.sort((a, b) {
      final ia = featured.indexOf(a.handle), ib = featured.indexOf(b.handle);
      if (ia == -1 && ib == -1) return a.title.compareTo(b.title);
      if (ia == -1) return 1;
      if (ib == -1) return -1;
      return ia.compareTo(ib);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopifyProvider>();
    final collections = _orderedCollections(shop.collections);
    final products = sortAndFilter(
      shop.selectedCollectionHandle == _handle ? shop.categoryProducts : const [],
      _sort,
      _inStock,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          const CartIconButton(),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await shop.loadCatalogData();
          if (_handle != 'all') await shop.loadCollection(_handle, force: true);
          await shop.selectCategory(_handle);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _chip('all', 'All'),
                    ...collections.map((c) => _chip(c.handle, _pretty(c))),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: BrowseToolbar(
                count: products.length,
                sort: _sort,
                inStockOnly: _inStock,
                onSort: (s) => setState(() => _sort = s),
                onInStock: (v) => setState(() => _inStock = v),
              ),
            ),
            if (shop.isCategoryLoading || (shop.isLoading && shop.allProducts.isEmpty))
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              BrowseGrid(products: products),
          ],
        ),
      ),
    );
  }

  String _pretty(CollectionModel c) {
    for (final f in AppConstants.featuredCategories) {
      if (f['handle'] == c.handle) return f['title']!;
    }
    return c.title;
  }

  Widget _chip(String handle, String label) {
    final selected = _handle == handle;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w700)),
        selected: selected,
        onSelected: (_) => _select(handle),
      ),
    );
  }
}
