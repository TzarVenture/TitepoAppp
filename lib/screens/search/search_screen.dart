import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/shopify_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/product_browser.dart';
import '../../widgets/product_card.dart';
import '../categories/collection_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<String> _history = [];
  String _query = '';
  ProductSort _sort = ProductSort.featured;
  bool _inStock = false;

  static const _suggestions = ['Water bottle', 'Backpack', 'Lunch box', 'Highlighter', 'Car', 'Mug', 'Pencil'];

  @override
  void initState() {
    super.initState();
    StorageService.loadSearchHistory().then((h) {
      if (mounted) setState(() => _history = h);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _query = value.trim());
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<ShopifyProvider>().search(value);
    });
  }

  Future<void> _submit(String value) async {
    final q = value.trim();
    if (q.isEmpty) return;
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    _onChanged(q);
    final updated = [q, ..._history.where((h) => h.toLowerCase() != q.toLowerCase())].take(8).toList();
    setState(() => _history = updated);
    await StorageService.saveSearchHistory(updated);
  }

  Future<void> _clearHistory() async {
    setState(() => _history = []);
    await StorageService.saveSearchHistory([]);
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopifyProvider>();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: _submit,
            decoration: InputDecoration(
              hintText: 'Search the Titepo store',
              isDense: true,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                      },
                    ),
            ),
          ),
        ),
      ),
      body: _query.isEmpty ? _buildIdle() : _buildResults(shop),
    );
  }

  Widget _buildIdle() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_history.isNotEmpty) ...[
          Row(
            children: [
              Text('Recent', style: AppTheme.display(size: 18)),
              const Spacer(),
              TextButton(onPressed: _clearHistory, child: const Text('Clear')),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _history
                .map((h) => ActionChip(
                      avatar: const Icon(Icons.history_rounded, size: 16),
                      label: Text(h),
                      onPressed: () => _submit(h),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
        Text('Popular searches', style: AppTheme.display(size: 18)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions
              .map((s) => ActionChip(
                    avatar: const Icon(Icons.trending_up_rounded, size: 16, color: AppColors.primary),
                    label: Text(s),
                    onPressed: () => _submit(s),
                  ))
              .toList(),
        ),
        const SizedBox(height: 28),
        Text('Browse categories', style: AppTheme.display(size: 18)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 3,
          children: [
            for (var i = 0; i < AppConstants.featuredCategories.length; i++)
              Material(
                color: AppColors.pastels[i % AppColors.pastels.length],
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CollectionScreen(
                        handle: AppConstants.featuredCategories[i]['handle']!,
                        title: AppConstants.featuredCategories[i]['title']!,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Text(AppConstants.featuredCategories[i]['icon']!, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(AppConstants.featuredCategories[i]['title']!,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildResults(ShopifyProvider shop) {
    final results = sortAndFilter(shop.searchResults, _sort, _inStock);
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        if (shop.isSearching)
          const SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2)),
        SliverToBoxAdapter(
          child: BrowseToolbar(
            count: results.length,
            sort: _sort,
            inStockOnly: _inStock,
            onSort: (s) => setState(() => _sort = s),
            onInStock: (v) => setState(() => _inStock = v),
          ),
        ),
        if (results.isEmpty && !shop.isSearching)
          SliverToBoxAdapter(child: EmptyProducts(message: 'No results for "$_query".\nTry a different word.'))
        else
          ProductSliverGrid(products: results),
      ],
    );
  }
}
