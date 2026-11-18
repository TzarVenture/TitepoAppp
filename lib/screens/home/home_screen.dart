import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/product.dart';
import '../../providers/shopify_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/marquee_banner.dart';
import '../../widgets/trust_badge_row.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/animated_category_rails.dart';
import '../../widgets/video_reels_preview_section.dart';
import '../../widgets/product_slider_section.dart';
import '../../widgets/promo_banner_card.dart';
import '../../widgets/age_filter_rails.dart';
import '../../widgets/titepo_brand_logo.dart';
import '../../widgets/animated_search_hint.dart';
import '../cart/cart_screen.dart';
import '../categories/categories_screen.dart';
import '../return_gift/return_gift_solutions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _heroController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  int _heroIndex = 0;
  Timer? _heroAutoPlayTimer;
  String _activeCategoryFilter = 'all';
  String _activeAgeFilter = 'all';
  String _searchQuery = '';
  String _searchSort = 'featured';
  bool _isSearchFocused = false;

  final List<Map<String, dynamic>> _heroBanners = [
    {
      'title': 'BIRTHDAY RETURN GIFTS',
      'subtitle': "Curated Birthday Hampers & Gifting Solutions",
      'badge': '🎁 BIRTHDAY SPECIAL',
      'button': 'Explore Return Gifts',
      'action': 'modal',
      'gradient': const [Color(0xFF053827), Color(0xFF0F5A41)],
      'icon': '🎁',
    },
    {
      'title': 'BACK TO SCHOOL SALE!',
      'subtitle': 'Flat 20% OFF on 3D Backpacks & Water Bottles',
      'badge': '🔥 SUMMER SALE 20% OFF',
      'button': 'Shop School Bags',
      'action': 'category',
      'category': 'bags',
      'gradient': const [Color(0xFF0A5C41), Color(0xFF137A57)],
      'icon': '🎒',
    },
    {
      'title': 'DIE-CAST SUPER CARS',
      'subtitle': 'Alloy Metal Cars with Light & Sound Effects',
      'badge': '🏎️ NEW ARRIVALS',
      'button': 'Browse Car Toys',
      'action': 'category',
      'category': 'cars',
      'gradient': const [Color(0xFF03251A), Color(0xFF0A4F38)],
      'icon': '🏎️',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startHeroAutoPlay();
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  void _onSearchFocusChanged() {
    if (mounted) {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    }
  }

  void _startHeroAutoPlay() {
    _heroAutoPlayTimer?.cancel();
    _heroAutoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _heroController.hasClients) {
        final next = (_heroIndex + 1) % _heroBanners.length;
        _heroController.animateToPage(
          next,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _heroAutoPlayTimer?.cancel();
    _heroController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onHeroAction(Map<String, dynamic> item) {
    if (item['action'] == 'modal' || item['category'] == 'return-gift') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReturnGiftSolutionsScreen()),
      );
    } else if (item['action'] == 'category' && item['category'] != null) {
      final shopify = Provider.of<ShopifyProvider>(context, listen: false);
      setState(() => _activeCategoryFilter = item['category']);
      shopify.selectCategory(item['category']);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoriesScreen(
            initialCategoryHandle: item['category'],
          ),
        ),
      );
    }
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    var result = products;

    // 1. Search Query Filter (Real-time live filtering on Home Screen)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) {
        final title = p.title.toLowerCase();
        final desc = p.description.toLowerCase();
        final type = p.productType.toLowerCase();
        final vendor = p.vendor.toLowerCase();
        final tags = p.tags.join(' ').toLowerCase();
        return title.contains(q) || desc.contains(q) || type.contains(q) || vendor.contains(q) || tags.contains(q);
      }).toList();

      if (_searchSort == 'price_low') {
        result.sort((a, b) => a.price.compareTo(b.price));
      } else if (_searchSort == 'price_high') {
        result.sort((a, b) => b.price.compareTo(a.price));
      }
      return result;
    }

    if (_activeAgeFilter == 'all') return result;

    return result.where((p) {
      final combined = '${p.tags.join(' ')} ${p.title} ${p.description}'.toLowerCase();
      if (_activeAgeFilter == '0-2') {
        return combined.contains('toddler') ||
            combined.contains('infant') ||
            combined.contains('baby') ||
            combined.contains('0-2') ||
            combined.contains('soft toy');
      } else if (_activeAgeFilter == '3-5') {
        return combined.contains('preschool') ||
            combined.contains('3-5') ||
            combined.contains('kindergarten') ||
            combined.contains('lunch');
      } else if (_activeAgeFilter == '6-8') {
        return combined.contains('school') ||
            combined.contains('backpack') ||
            combined.contains('bottle') ||
            combined.contains('car') ||
            combined.contains('stationary') ||
            combined.contains('6-8');
      } else if (_activeAgeFilter == '9-12') {
        return combined.contains('die-cast') ||
            combined.contains('puzzle') ||
            combined.contains('9-12') ||
            combined.contains('action');
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final shopifyProvider = Provider.of<ShopifyProvider>(context);
    final rawDisplayed = _searchQuery.isNotEmpty
        ? shopifyProvider.allProducts
        : (_activeCategoryFilter == 'all'
            ? shopifyProvider.allProducts
            : shopifyProvider.categoryProducts);
    final displayedProducts = _filterProducts(rawDisplayed);

    return PopScope(
      canPop: _searchQuery.isEmpty && !_searchFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
        if (_searchQuery.isNotEmpty) {
          setState(() {
            _searchController.clear();
            _searchQuery = '';
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(66),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.borderLight,
                    width: 1.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Official Brand Logo matching the website (replaces the basket icon & text)
                      const TitepoBrandLogo(
                        height: 34,
                      ),
                      const Spacer(),

                      // Search Quick Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderLight, width: 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            _searchQuery.isNotEmpty ? Icons.close_rounded : Icons.search_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          tooltip: _searchQuery.isNotEmpty ? 'Clear Search' : 'Search on Home Screen',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            if (_searchQuery.isNotEmpty) {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                              _searchFocusNode.unfocus();
                            } else {
                              if (_scrollController.hasClients) {
                                _scrollController.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                              _searchFocusNode.requestFocus();
                            }
                          },
                        ),
                      ),
                    const SizedBox(width: 8),

                    // Cart Icon with live badge
                    Consumer<CartProvider>(
                      builder: (context, cart, _) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.borderLight, width: 1.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 22),
                                tooltip: 'Cart',
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CartScreen()),
                                  );
                                },
                              ),
                            ),
                            if (cart.totalItemCount > 0)
                              Positioned(
                                right: -3,
                                top: -3,
                                child: AnimatedScale(
                                  scale: 1.0,
                                  duration: const Duration(milliseconds: 250),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.saleRed,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                    child: Text(
                                      '${cart.totalItemCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => shopifyProvider.loadCatalogData(),
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: (shopifyProvider.isLoading && shopifyProvider.allProducts.isEmpty)
            ? const SkeletonLoader.homeScreen()
            : SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Announcement Marquee Bar
                    const MarqueeBanner(),

                    // Interactive In-Place Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _isSearchFocused ? AppColors.primary : AppColors.borderLight,
                            width: _isSearchFocused ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _isSearchFocused
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            Icon(
                              Icons.search_rounded,
                              color: _isSearchFocused ? AppColors.primary : AppColors.textMuted,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  // Animated rotating placeholder text that changes automatically
                                  if (_searchQuery.isEmpty)
                                    const IgnorePointer(
                                      child: AnimatedSearchHint(
                                        prefix: 'Search ',
                                        hints: [
                                          '"Birthday Return Gifts"... 🎁',
                                          '"Custom Name & Photo Bags"... 🎒',
                                          '"Die-Cast Alloy Super Cars"... 🏎️',
                                          '"School Water Bottles"... 💧',
                                          '"Insulated Bento Lunch Boxes"... 🍱',
                                          '"Kids Puzzles & Activity Sets"... 🧩',
                                        ],
                                        style: TextStyle(
                                          color: Color(0xFF8C939D),
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),

                                  // Active input field with all internal borders stripped
                                  TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    textInputAction: TextInputAction.search,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      filled: false,
                                      fillColor: Colors.transparent,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _searchQuery = val.trim();
                                      });
                                    },
                                    onSubmitted: (_) => _searchFocusNode.unfocus(),
                                  ),
                                ],
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.cancel_rounded, color: AppColors.textMuted, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                tooltip: 'Clear Search',
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.tune_rounded, color: AppColors.textMuted, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                tooltip: 'All Categories',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                                  );
                                },
                              ),
                            const SizedBox(width: 6),
                          ],
                        ),
                      ),
                    ),

                    // Quick Search Suggestion Chips when search bar is focused and empty
                    if (_isSearchFocused && _searchQuery.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              const Text(
                                'Popular: ',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                              ),
                              for (final term in ['Return Gifts', 'Bags', 'Cars', 'Water Bottles', 'Lunch Box', 'Puzzles'])
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ActionChip(
                                    label: Text(term),
                                    labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: AppColors.borderLight),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                    onPressed: () {
                                      _searchController.text = term;
                                      setState(() => _searchQuery = term);
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                    if (_searchQuery.isNotEmpty) ...[
                      // In-Place Search Results View directly on Home Screen
                      _buildHomeScreenSearchResults(shopifyProvider, displayedProducts),
                    ] else ...[
                      const SizedBox(height: 10),

                      // 1. Hero Banner Carousel with smooth animations
                      SizedBox(
                        height: 195,
                        child: PageView.builder(
                        controller: _heroController,
                        onPageChanged: (idx) => setState(() => _heroIndex = idx),
                        itemCount: _heroBanners.length,
                        itemBuilder: (context, index) {
                          final item = _heroBanners[index];
                          final gradients = item['gradient'] as List<Color>;

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradients,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: gradients.first.withValues(alpha: 0.28),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentYellow,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item['badge'] as String,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10.5,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item['title'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 19,
                                          height: 1.15,
                                          letterSpacing: 0.4,
                                        ),
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['subtitle'] as String,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.90),
                                          fontSize: 12.5,
                                          height: 1.25,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () => _onHeroAction(item),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.accentYellow,
                                          foregroundColor: AppColors.textPrimary,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: Text(
                                          item['button'] as String,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      item['icon'] as String,
                                      style: const TextStyle(fontSize: 34),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Indicator Dots
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _heroBanners.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _heroIndex == index ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _heroIndex == index ? AppColors.primary : AppColors.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Trust Badges Strip
                    const TrustBadgeRow(),

                    const SizedBox(height: 20),

                    // 2. Animated Category Rails (Spring-like tap feedback)
                    AnimatedCategoryRails(
                      activeCategory: _activeCategoryFilter,
                      onSelectCategory: (handle) {
                        if (handle == 'return-gift') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ReturnGiftSolutionsScreen()),
                          );
                          return;
                        }
                        setState(() => _activeCategoryFilter = handle);
                        shopifyProvider.selectCategory(handle);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoriesScreen(initialCategoryHandle: handle),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 22),

                    // 3. Video Reels Preview Section (Interactive previews)
                    const VideoReelsPreviewSection(),

                    const SizedBox(height: 24),

                    // 4. Return Gift Party Solutions Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF053827), Color(0xFF0F5A41)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentYellow,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '🎁 RETURN GIFT PACKAGES',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Planning a Birthday Party?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Get custom hampers, ready-to-gift packing & up to 30% bulk discounts!',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontSize: 11.5,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ReturnGiftSolutionsScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                  label: const Text('Design Return Gift Bags'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentYellow,
                                    foregroundColor: AppColors.textPrimary,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('🎂', style: TextStyle(fontSize: 36)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 5. Best Sellers & Trending Horizontal Slider
                    if (shopifyProvider.featuredProducts.isNotEmpty)
                      ProductSliderSection(
                        title: 'Trending & Best Sellers',
                        emoji: '🔥',
                        subtitle: 'Most loved by parents this week',
                        badgeText: 'HOT',
                        products: shopifyProvider.featuredProducts,
                        onSeeAll: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CategoriesScreen(initialCategoryHandle: 'new-arrival'),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 22),

                    // 6. Promotional Discount Card
                    PromoBannerCard(
                      title: 'Save Flat 10% On All Toys',
                      subtitle: 'Use coupon at checkout on any order value',
                      code: 'TITEPO10',
                      badge: 'SPECIAL OFFER',
                      buttonText: 'Shop & Save',
                      gradientColors: const [Color(0xFF03251A), Color(0xFF0A5C41)],
                      emoji: '🎉',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Coupon TITEPO10 copied to clipboard! Applied at checkout.'),
                            backgroundColor: AppColors.primary,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // 7. New Arrivals Horizontal Slider
                    if (shopifyProvider.newArrivals.isNotEmpty) ...[
                      ProductSliderSection(
                        title: 'Fresh New Arrivals',
                        emoji: '✨',
                        subtitle: 'Just added to the Titepo collection',
                        badgeText: 'NEW',
                        products: shopifyProvider.newArrivals,
                        onSeeAll: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CategoriesScreen(initialCategoryHandle: 'new-arrival'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                    ],

                    // 8. Interactive Filter by Age Rail
                    AgeFilterRails(
                      selectedAge: _activeAgeFilter,
                      onSelectAge: (age) {
                        setState(() => _activeAgeFilter = age);
                      },
                    ),

                    const SizedBox(height: 22),

                    // 9. All Products Grid with Category & Age Filters
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _activeCategoryFilter == 'all'
                                      ? 'Explore All Toys'
                                      : 'Category: ${_activeCategoryFilter.replaceAll('-', ' ').toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_activeAgeFilter != 'all')
                                  Text(
                                    'Filtered for: $_activeAgeFilter Years',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_activeCategoryFilter != 'all' || _activeAgeFilter != 'all')
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _activeCategoryFilter = 'all';
                                  _activeAgeFilter = 'all';
                                });
                                shopifyProvider.selectCategory('all');
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Reset All',
                                  style: TextStyle(color: AppColors.saleRed, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Products Grid
                    if (shopifyProvider.isLoading || shopifyProvider.isCategoryLoading)
                      const SkeletonLoader()
                    else if (displayedProducts.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.toys_outlined, size: 54, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              const Text(
                                'No products found for this filter.',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _activeCategoryFilter = 'all';
                                    _activeAgeFilter = 'all';
                                  });
                                  shopifyProvider.selectCategory('all');
                                },
                                child: const Text('Show All Products'),
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
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: displayedProducts.length,
                        itemBuilder: (context, index) {
                          final product = displayedProducts[index];
                          return ProductCard(product: product);
                        },
                      ),

                    const SizedBox(height: 28),

                    // Verified Customer Testimonials
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('⭐ ', style: TextStyle(fontSize: 16)),
                              Text(
                                'What Parents Say About Us',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Real reviews from families trusting Titepo for quality, safety & fun gifts.',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTestimonialCard(
                                  name: 'Riya Sharma',
                                  city: 'Delhi',
                                  comment:
                                      'The return gift hampers were sturdy and beautifully packed. All kids loved them!',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTestimonialCard(
                                  name: 'Amit Patel',
                                  city: 'Mumbai',
                                  comment:
                                      'Awesome 3D school backpack! Non-toxic silicone and fast delivery before school opened.',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
  }

  /// In-Place Search Results View rendered directly on the Home Screen
  Widget _buildHomeScreenSearchResults(ShopifyProvider shopifyProvider, List<ProductModel> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),

          // Search Header Summary & Sort Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.search_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Results for "$_searchQuery"',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${products.length} product${products.length == 1 ? '' : 's'} matching',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sort Dropdown
                PopupMenuButton<String>(
                  initialValue: _searchSort,
                  tooltip: 'Sort Results',
                  onSelected: (val) {
                    setState(() => _searchSort = val);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLight, width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swap_vert_rounded, size: 15, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          _searchSort == 'price_low'
                              ? 'Price: Low'
                              : _searchSort == 'price_high'
                                  ? 'Price: High'
                                  : 'Featured',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'featured', child: Text('Featured / Relevant')),
                    PopupMenuItem(value: 'price_low', child: Text('Price: Low to High')),
                    PopupMenuItem(value: 'price_high', child: Text('Price: High to Low')),
                  ],
                ),

                const SizedBox(width: 8),

                // Clear Search Chip Button
                InkWell(
                  onTap: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                    _searchFocusNode.unfocus();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.saleRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.saleRed,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Search Results Product Grid or Empty State
          if (shopifyProvider.isLoading)
            const SkeletonLoader()
          else if (products.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: AppColors.accentYellowLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search_off_rounded, size: 34, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No toys found for "$_searchQuery"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Try another search term or browse popular categories below:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final tag in ['Bags', 'Cars', 'Bottles', 'Return Gift', 'Puzzles', 'Lunch Box'])
                          ActionChip(
                            label: Text(tag),
                            labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.borderLight),
                            onPressed: () {
                              _searchController.text = tag;
                              setState(() => _searchQuery = tag);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                        _searchFocusNode.unfocus();
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Back to Full Home Screen'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.52,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(product: product);
              },
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard({
    required String name,
    required String city,
    required String comment,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (_) => const Icon(Icons.star, color: AppColors.starYellow, size: 12),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '"$comment"',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                ' • $city',
                style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
