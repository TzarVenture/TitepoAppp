import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/product.dart';
import '../../providers/shopify_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/product_card.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/search_filter_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = [];

  SortOption _selectedSort = SortOption.featured;
  String _selectedCategory = 'all';
  String _selectedAge = 'all';
  RangeValues _priceRange = const RangeValues(0, 3000);

  final List<String> _popularTags = [
    'Return Gifts',
    'Die-Cast Cars',
    'School Bags',
    'Water Bottles',
    'Lunch Box',
    'Cute Mugs',
    'Stationery',
    'Bento Box',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await StorageService.loadSearchHistory();
    if (mounted) setState(() => _recentSearches = list);
  }

  Future<void> _saveQuery(String q) async {
    final clean = q.trim();
    if (clean.isEmpty) return;
    _recentSearches.remove(clean);
    _recentSearches.insert(0, clean);
    if (_recentSearches.length > 8) _recentSearches = _recentSearches.sublist(0, 8);
    await StorageService.saveSearchHistory(_recentSearches);
    if (mounted) setState(() {});
  }

  Future<void> _clearHistory() async {
    _recentSearches.clear();
    await StorageService.saveSearchHistory([]);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    Provider.of<ShopifyProvider>(context, listen: false).search(query);
    if (query.trim().length >= 3) {
      _saveQuery(query);
    }
  }

  List<ProductModel> _applyFiltersAndSort(List<ProductModel> products) {
    var result = List<ProductModel>.from(products);

    // 1. Filter by category
    if (_selectedCategory != 'all') {
      result = result.where((p) {
        return p.tags.contains(_selectedCategory) ||
            p.productType.toLowerCase().contains(_selectedCategory.replaceAll('-', ' '));
      }).toList();
    }

    // 2. Filter by Age
    if (_selectedAge != 'all') {
      result = result.where((p) {
        final combined = '${p.tags.join(' ')} ${p.title} ${p.description}'.toLowerCase();
        if (_selectedAge == '0-2') {
          return combined.contains('toddler') || combined.contains('infant') || combined.contains('baby') || combined.contains('0-2');
        } else if (_selectedAge == '3-5') {
          return combined.contains('preschool') || combined.contains('3-5') || combined.contains('lunch');
        } else if (_selectedAge == '6-8') {
          return combined.contains('school') || combined.contains('backpack') || combined.contains('car') || combined.contains('6-8');
        } else if (_selectedAge == '9-12') {
          return combined.contains('die-cast') || combined.contains('puzzle') || combined.contains('9-12');
        }
        return true;
      }).toList();
    }

    // 3. Filter by Price Range
    result = result.where((p) => p.price >= _priceRange.start && p.price <= _priceRange.end).toList();

    // 4. Sort
    switch (_selectedSort) {
      case SortOption.priceLowHigh:
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighLow:
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.ratingHigh:
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.featured:
        break;
    }

    return result;
  }

  bool get _hasActiveFilters =>
      _selectedSort != SortOption.featured ||
      _selectedCategory != 'all' ||
      _selectedAge != 'all' ||
      _priceRange.start > 0 ||
      _priceRange.end < 3000;

  @override
  Widget build(BuildContext context) {
    final shopifyProvider = Provider.of<ShopifyProvider>(context);
    final rawList = _searchController.text.isEmpty
        ? shopifyProvider.allProducts
        : shopifyProvider.searchResults;
    final displayedProducts = _applyFiltersAndSort(rawList);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearch,
            textInputAction: TextInputAction.search,
            onSubmitted: (q) {
              _onSearch(q);
              _saveQuery(q);
            },
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search toys, return gifts, bags...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
          ),
        ),
        actions: [
          // Filter & Sort Trigger Icon with Active Dot
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: Colors.white),
                tooltip: 'Filter & Sort',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => SearchFilterSheet(
                      initialSort: _selectedSort,
                      initialCategory: _selectedCategory,
                      initialAge: _selectedAge,
                      initialPriceRange: _priceRange,
                      maxAvailablePrice: 3000,
                      onApply: (sort, cat, age, range) {
                        setState(() {
                          _selectedSort = sort;
                          _selectedCategory = cat;
                          _selectedAge = age;
                          _priceRange = range;
                        });
                      },
                    ),
                  );
                },
              ),
              if (_hasActiveFilters)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accentYellow,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recent Searches (if available and no text query)
            if (_searchController.text.isEmpty && _recentSearches.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.history_rounded, size: 18, color: AppColors.textMuted),
                        SizedBox(width: 6),
                        Text(
                          'Recent Searches',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: _clearHistory,
                      child: const Text('Clear', style: TextStyle(color: AppColors.saleRed, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _recentSearches.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final q = _recentSearches[idx];
                    return ActionChip(
                      label: Text(q),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.borderLight),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      labelStyle: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      onPressed: () {
                        _searchController.text = q;
                        _onSearch(q);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Popular Trend Suggestions
            if (_searchController.text.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trending Now 🔥',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _popularTags.map((tag) {
                        return ActionChip(
                          label: Text(tag),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.borderLight),
                          labelStyle: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          onPressed: () {
                            _searchController.text = tag;
                            _onSearch(tag);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
            ],

            // Active Filter Summary Chips
            if (_hasActiveFilters) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text('Active: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (_selectedSort != SortOption.featured)
                              _buildPill(_selectedSort.label, () => setState(() => _selectedSort = SortOption.featured)),
                            if (_selectedCategory != 'all')
                              _buildPill('Category: ${_selectedCategory.toUpperCase()}', () => setState(() => _selectedCategory = 'all')),
                            if (_selectedAge != 'all')
                              _buildPill('Age: $_selectedAge Yrs', () => setState(() => _selectedAge = 'all')),
                            if (_priceRange.start > 0 || _priceRange.end < 3000)
                              _buildPill('₹${_priceRange.start.round()}-₹${_priceRange.end.round()}', () => setState(() => _priceRange = const RangeValues(0, 3000))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Results Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _searchController.text.isEmpty
                        ? 'Catalog (${displayedProducts.length})'
                        : 'Results (${displayedProducts.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  if (_hasActiveFilters)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSort = SortOption.featured;
                          _selectedCategory = 'all';
                          _selectedAge = 'all';
                          _priceRange = const RangeValues(0, 3000);
                        });
                      },
                      child: const Text('Reset All', style: TextStyle(color: AppColors.saleRed, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),

            // Products Grid
            if (shopifyProvider.isSearching)
              const SkeletonLoader()
            else if (displayedProducts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 60, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'No matching toys found',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Try clearing your active filters or searching for "cars", "bags", or "lunch"',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.52,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: displayedProducts.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: displayedProducts[index]);
                },
              ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 13, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
