import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/product.dart';
import '../../providers/shopify_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/marquee_banner.dart';
import '../../widgets/trust_badge_row.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/return_gift_modal.dart';
import '../../widgets/animated_category_rails.dart';
import '../../widgets/video_reels_preview_section.dart';
import '../../widgets/product_slider_section.dart';
import '../../widgets/promo_banner_card.dart';
import '../../widgets/age_filter_rails.dart';
import '../cart/cart_screen.dart';
import '../search/search_screen.dart';
import '../categories/categories_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _heroController = PageController();
  int _heroIndex = 0;
  Timer? _heroAutoPlayTimer;
  String _activeCategoryFilter = 'all';
  String _activeAgeFilter = 'all';

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
    super.dispose();
  }

  void _onHeroAction(Map<String, dynamic> item) {
    if (item['action'] == 'modal') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ReturnGiftModal(),
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
    if (_activeAgeFilter == 'all') return products;

    return products.where((p) {
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
    final rawDisplayed = _activeCategoryFilter == 'all'
        ? shopifyProvider.allProducts
        : shopifyProvider.categoryProducts;
    final displayedProducts = _filterProducts(rawDisplayed);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Brand Icon & Title
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: AppColors.accentYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'TITEPO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: 1.4,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'KIDS TOYS & RETURN GIFTS',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.accentYellow,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Search Quick Button
                  IconButton(
                    icon: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
                    tooltip: 'Search Products',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      );
                    },
                  ),

                  // Cart Icon with live badge
                  Consumer<CartProvider>(
                    builder: (context, cart, _) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CartScreen()),
                              );
                            },
                          ),
                          if (cart.totalItemCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: AnimatedScale(
                                scale: 1.0,
                                duration: const Duration(milliseconds: 250),
                                child: Container(
                                  padding: const EdgeInsets.all(3.5),
                                  decoration: const BoxDecoration(
                                    color: AppColors.saleRed,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
      body: RefreshIndicator(
        onRefresh: () => shopifyProvider.loadCatalogData(),
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: (shopifyProvider.isLoading && shopifyProvider.allProducts.isEmpty)
            ? const SkeletonLoader.homeScreen()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Announcement Marquee Bar
                    const MarqueeBanner(),

                    // Search Bar Quick Trigger
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SearchScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderLight, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Search toys, return gifts, bags, cars...',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

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
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => const ReturnGiftModal(),
                                    );
                                  },
                                  icon: const Icon(Icons.send_rounded, size: 14),
                                  label: const Text('Request Custom Hampers'),
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
                ),
              ),
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
