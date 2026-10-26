import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

enum SortOption {
  featured('Featured', 'featured'),
  priceLowHigh('Price: Low to High', 'price_asc'),
  priceHighLow('Price: High to Low', 'price_desc'),
  ratingHigh('Top Customer Rated', 'rating_desc');

  final String label;
  final String code;
  const SortOption(this.label, this.code);
}

class SearchFilterSheet extends StatefulWidget {
  final SortOption initialSort;
  final String initialCategory;
  final String initialAge;
  final RangeValues initialPriceRange;
  final double maxAvailablePrice;
  final Function(SortOption sort, String category, String age, RangeValues price) onApply;

  const SearchFilterSheet({
    super.key,
    required this.initialSort,
    required this.initialCategory,
    required this.initialAge,
    required this.initialPriceRange,
    required this.maxAvailablePrice,
    required this.onApply,
  });

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late SortOption _selectedSort;
  late String _selectedCategory;
  late String _selectedAge;
  late RangeValues _priceRange;

  static const List<Map<String, String>> ageFilters = [
    {'label': 'All Ages', 'val': 'all'},
    {'label': '0-2 Yrs', 'val': '0-2'},
    {'label': '3-5 Yrs', 'val': '3-5'},
    {'label': '6-8 Yrs', 'val': '6-8'},
    {'label': '9-12 Yrs', 'val': '9-12'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.initialSort;
    _selectedCategory = widget.initialCategory;
    _selectedAge = widget.initialAge;
    _priceRange = widget.initialPriceRange;
  }

  void _reset() {
    setState(() {
      _selectedSort = SortOption.featured;
      _selectedCategory = 'all';
      _selectedAge = 'all';
      _priceRange = RangeValues(0, widget.maxAvailablePrice > 0 ? widget.maxAvailablePrice : 3000);
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxPrice = widget.maxAvailablePrice > 0 ? widget.maxAvailablePrice : 3000.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Filter & Sort Products',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Reset All', style: TextStyle(color: AppColors.saleRed, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable filter options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Sort Options
                const Text(
                  'Sort By',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SortOption.values.map((sort) {
                    final isSelected = _selectedSort == sort;
                    return ChoiceChip(
                      label: Text(sort.label),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedSort = sort);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 22),
                const Divider(),
                const SizedBox(height: 12),

                // 2. Price Range Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Price Range',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    Text(
                      '₹${_priceRange.start.round()} - ₹${_priceRange.end.round()}',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 13.5),
                    ),
                  ],
                ),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: maxPrice,
                  divisions: 20,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.borderLight,
                  onChanged: (vals) => setState(() => _priceRange = vals),
                ),

                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 12),

                // 3. Category Filter
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All Categories'),
                      selected: _selectedCategory == 'all',
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedCategory == 'all' ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = 'all'),
                    ),
                    ...AppConstants.featuredCategories.map((cat) {
                      final isSelected = _selectedCategory == cat['handle'];
                      return ChoiceChip(
                        avatar: Text(cat['icon']!, style: const TextStyle(fontSize: 14)),
                        label: Text(cat['title']!),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          setState(() => _selectedCategory = isSelected ? 'all' : cat['handle']!);
                        },
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 22),
                const Divider(),
                const SizedBox(height: 12),

                // 4. Age Group Filter
                const Text(
                  'Target Age Group',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ageFilters.map((age) {
                    final isSelected = _selectedAge == age['val'];
                    return ChoiceChip(
                      label: Text(age['label']!),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _selectedAge = age['val']!),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),

          // Bottom Apply Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_selectedSort, _selectedCategory, _selectedAge, _priceRange);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply Filters & Sort', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
