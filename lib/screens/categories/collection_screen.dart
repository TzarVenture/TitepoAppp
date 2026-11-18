import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/shopify_provider.dart';
import '../../widgets/product_browser.dart';
import '../../widgets/ui_kit.dart';

/// Products of a single Shopify collection (same order as titepo.com).
class CollectionScreen extends StatefulWidget {
  final String handle;
  final String title;
  const CollectionScreen({super.key, required this.handle, required this.title});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  List<ProductModel>? _products;
  ProductSort _sort = ProductSort.featured;
  bool _inStock = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    final list = await context.read<ShopifyProvider>().loadCollection(widget.handle, force: force);
    if (mounted) setState(() => _products = list);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _products == null ? null : sortAndFilter(_products!, _sort, _inStock);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: const [CartIconButton(), SizedBox(width: 6)],
      ),
      body: visible == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(force: true),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: BrowseToolbar(
                      count: visible.length,
                      sort: _sort,
                      inStockOnly: _inStock,
                      onSort: (s) => setState(() => _sort = s),
                      onInStock: (v) => setState(() => _inStock = v),
                    ),
                  ),
                  BrowseGrid(products: visible),
                ],
              ),
            ),
    );
  }
}
