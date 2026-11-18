import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../models/return_gift_bundle.dart';
import '../../providers/cart_provider.dart';
import '../../services/shopify_service.dart';
import '../../widgets/accessory_quick_view_modal.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/custom_bag_preview_card.dart';
import '../../widgets/customize_theme_bag_modal.dart';
import '../../widgets/ui_kit.dart';
import '../cart/cart_screen.dart';

class ReturnGiftSolutionsScreen extends StatefulWidget {
  final ProductModel? initialAccessory;
  final int? initialQuantity;

  const ReturnGiftSolutionsScreen({
    super.key,
    this.initialAccessory,
    this.initialQuantity,
  });

  @override
  State<ReturnGiftSolutionsScreen> createState() => _ReturnGiftSolutionsScreenState();
}

class _ReturnGiftSolutionsScreenState extends State<ReturnGiftSolutionsScreen> {
  final ShopifyService _shopifyService = ShopifyService();
  int _currentStep = 1; // 1: Select Bag, 2: Choose Gifts, 3: Review Bag

  bool _isLoading = true;
  ProductModel? _customBagProduct;
  List<ProductModel> _readyMadeBags = [];
  List<ProductModel> _accessories = [];
  List<ProductModel> _filteredAccessories = [];

  String _selectedCategory = 'All';
  String _searchQuery = '';

  late ReturnGiftBundle _bundle;

  @override
  void initState() {
    super.initState();
    _bundle = ReturnGiftBundle(numberOfBags: widget.initialQuantity ?? 10);
    if (widget.initialAccessory != null) {
      _bundle.selectedItems[widget.initialAccessory!.id] = 1;
      _bundle.accessoriesMap[widget.initialAccessory!.id] = widget.initialAccessory!;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final customBag = await _shopifyService.fetchCustomBagProduct();
      final themeBags = await _shopifyService.fetchReadyMadeThemeBags();
      final accessories = await _shopifyService.fetchReturnGiftAccessories();

      if (mounted) {
        setState(() {
          _customBagProduct = customBag;
          _readyMadeBags = themeBags;
          _accessories = accessories;
          _filteredAccessories = accessories;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterAccessories() {
    setState(() {
      _filteredAccessories = _accessories.where((item) {
        final matchesQuery = _searchQuery.isEmpty ||
            item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.description.toLowerCase().contains(_searchQuery.toLowerCase());

        if (!matchesQuery) return false;

        if (_selectedCategory == 'All') return true;
        if (_selectedCategory == 'Pouches & Bags') {
          return item.title.toLowerCase().contains('pouch') ||
              item.title.toLowerCase().contains('bag') ||
              item.productType.toLowerCase().contains('bag');
        }
        if (_selectedCategory == 'Cups & Plates') {
          return item.title.toLowerCase().contains('cup') ||
              item.title.toLowerCase().contains('plate') ||
              item.title.toLowerCase().contains('party');
        }
        if (_selectedCategory == 'Hats & Caps') {
          return item.title.toLowerCase().contains('hat') || item.title.toLowerCase().contains('cap');
        }
        if (_selectedCategory == 'Mugs & Bottles') {
          return item.title.toLowerCase().contains('mug') ||
              item.title.toLowerCase().contains('bottle') ||
              item.productType.toLowerCase().contains('drinkware');
        }
        return true;
      }).toList();
    });
  }

  void _openCustomBagModal() {
    if (_customBagProduct == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomizeThemeBagModal(
        customBagProduct: _customBagProduct!,
        initialImageBytes: _bundle.customImageBytes,
        initialImageFileName: _bundle.customImageFileName,
        initialNotes: _bundle.customDesignNotes,
        onSave: (bytes, fileName, notes) {
          setState(() {
            _bundle.selectedBag = _customBagProduct;
            _bundle.isCustomBag = true;
            _bundle.customImageBytes = bytes;
            _bundle.customImageFileName = fileName;
            _bundle.customDesignNotes = notes;
            _currentStep = 2; // Advance to Choose Gifts
          });
        },
      ),
    );
  }

  void _selectReadyMadeBag(ProductModel bag) {
    setState(() {
      _bundle.selectedBag = bag;
      _bundle.isCustomBag = false;
      _bundle.customImageBytes = null;
      _bundle.customImageFileName = null;
      _bundle.customDesignNotes = '';
      _currentStep = 2; // Advance to Choose Gifts
    });
  }

  void _openQuickView(ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AccessoryQuickViewModal(
        product: product,
        isAdded: _bundle.isItemSelected(product.id),
        onToggle: () {
          setState(() {
            _bundle.toggleItem(product);
          });
        },
      ),
    );
  }

  void _proceedToCheckout() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    await cart.addReturnGiftBundle(_bundle);

    if (!mounted) return;
    showAppSnack(context, '🎉 Added ${_bundle.numberOfBags} return gift bags to your cart');

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        title: Text(
          'Return Gift Solutions',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        actions: const [CartIconButton(), SizedBox(width: 6)],
      ),
      bottomNavigationBar: _currentStep == 2
          ? _buildStep2StickyBottomBar()
          : _currentStep == 3
              ? _buildStep3StickyBottomBar()
              : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Hero Brand Banner (from Screenshot 2)
                  _buildHeroBanner(),

                  // 2. 4-Step Process Bar (from Screenshot 2)
                  _buildStepProgressIndicator(),

                  const SizedBox(height: 12),

                  // 3. Step Content
                  if (_currentStep == 1)
                    _buildStep1SelectBag()
                  else if (_currentStep == 2)
                    _buildStep2ChooseGifts()
                  else
                    _buildStep3ReviewBag(),

                  const SizedBox(height: 36),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Hero Banner (from Screenshot 2)
  // ---------------------------------------------------------------------------
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            'PLAY. LEARN. GROW.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFC2410C),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Premium Toys for Happy Kids & a Brighter Tomorrow',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          // Benefit Icons (Wrap ensures zero overflow on any screen width)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _buildPillBenefit('🛡️', '100% Kid-Safe'),
              _buildPillBenefit('🎨', 'Full-Bleed Custom Printing'),
              _buildPillBenefit('🎁', 'Ready-to-Gift'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillBenefit(String icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9A3412),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4-Step Progress Indicator (from Screenshot 2)
  // ---------------------------------------------------------------------------
  Widget _buildStepProgressIndicator() {
    final steps = [
      {'num': 1, 'title': 'Select Bag', 'icon': Icons.shopping_bag_outlined},
      {'num': 2, 'title': 'Choose Gifts', 'icon': Icons.card_giftcard_rounded},
      {'num': 3, 'title': 'Review Bag', 'icon': Icons.shopping_cart_outlined},
      {'num': 4, 'title': 'Checkout', 'icon': Icons.credit_card_rounded},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final prevStep = (index ~/ 2) + 1;
            final isPassed = _currentStep > prevStep;
            return Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: isPassed ? AppColors.primary : const Color(0xFFD1D5DB),
            );
          }

          final stepIdx = index ~/ 2;
          final step = steps[stepIdx];
          final stepNum = step['num'] as int;
          final isActive = _currentStep == stepNum;
          final isDone = _currentStep > stepNum;

          return InkWell(
            onTap: () {
              if (stepNum < _currentStep || (_bundle.selectedBag != null && stepNum <= 3)) {
                setState(() => _currentStep = stepNum);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : isDone
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive
                            ? AppColors.primary
                            : isDone
                                ? AppColors.success
                                : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check_rounded, color: AppColors.success, size: 20)
                          : Icon(
                              step['icon'] as IconData,
                              size: 18,
                              color: isActive ? Colors.white : AppColors.textMuted,
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step['title'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                  Text(
                    'Step $stepNum',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      color: isActive ? AppColors.primary : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    ),
  ),
);
  }

  // ---------------------------------------------------------------------------
  // STEP 1: SELECT BAG (Matching Screenshot 2)
  // ---------------------------------------------------------------------------
  Widget _buildStep1SelectBag() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),

          // 1. Featured Custom Bag Banner (from Screenshot 2)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFDF5), Color(0xFFFEF7EC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _bundle.isCustomBag ? AppColors.primary : const Color(0xFFA67D44),
                width: _bundle.isCustomBag ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA67D44).withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bag Thumbnail
                    Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5D7C5)),
                      ),
                      child: _bundle.isCustomBag && _bundle.customImageBytes != null
                          ? Image.memory(_bundle.customImageBytes!, fit: BoxFit.contain)
                          : CachedNetworkImage(
                              imageUrl: _customBagProduct?.mainImage ??
                                  'https://cdn.shopify.com/s/files/1/0824/4792/5463/files/whitebag-removebg-preview.png?v=1786107156',
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) => const Icon(Icons.shopping_bag, color: Color(0xFFA67D44)),
                            ),
                    ),
                    const SizedBox(width: 14),

                    // Title & Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'CUSTOM DESIGN',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accentYellow,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Design Your Own Custom Theme Bag',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Upload your logo, theme graphic & custom text notes for personalized return gifts!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Price & Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Starting Price',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                        ),
                        Text(
                          Formatters.formatPrice(_customBagProduct?.price ?? 250.0),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _openCustomBagModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.accentYellow,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text(
                        _bundle.isCustomBag ? 'Edit Custom Bag' : 'Customize Bag Now',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Section Heading: Or Choose a Ready-Made Theme Bag (from Screenshot 2)
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Or Choose a Ready-Made Theme Bag',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: 16),

          // Ready-Made Bags Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _readyMadeBags.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final bag = _readyMadeBags[index];
              final isSelected = !_bundle.isCustomBag && _bundle.selectedBag?.id == bag.id;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: Container(
                          color: const Color(0xFFF9F6F0),
                          child: CachedNetworkImage(
                            imageUrl: bag.mainImage,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.shopping_bag, size: 40, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bag.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.formatPrice(bag.price),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _selectReadyMadeBag(bag),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? AppColors.primary : const Color(0xFFFAF7F2),
                                foregroundColor: isSelected ? Colors.white : AppColors.primary,
                                side: BorderSide(
                                  color: isSelected ? AppColors.primary : AppColors.borderLight,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                isSelected ? '✓ Selected' : 'Select Bag',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: CHOOSE GIFTS & ACCESSORIES (Matching Screenshot 1)
  // ---------------------------------------------------------------------------
  Widget _buildStep2ChooseGifts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selected Bag Info Strip
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accentYellowLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('🛍️', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _bundle.isCustomBag
                          ? 'Custom Printed Theme Bag'
                          : (_bundle.selectedBag?.title ?? 'Selected Theme Bag'),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Base Price: ${Formatters.formatPrice(_bundle.bagPrice)}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _currentStep = 1),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'Change Bag',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Section Heading (from Screenshot 1)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Your Accessories',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${_filteredAccessories.length} options',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: TextField(
              onChanged: (val) {
                _searchQuery = val;
                _filterAccessories();
              },
              decoration: InputDecoration(
                hintText: 'Search accessories & return gifts...',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              'All',
              'Pouches & Bags',
              'Cups & Plates',
              'Hats & Caps',
              'Mugs & Bottles',
            ].map((cat) {
              final isSel = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    color: isSel ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = cat;
                      _filterAccessories();
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // Product Grid (Matching Screenshot 1)
        Padding(
          padding: const EdgeInsets.all(16),
          child: _filteredAccessories.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No accessories found in this category',
                      style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted),
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredAccessories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder: (context, index) {
                    final item = _filteredAccessories[index];
                    final isAdded = _bundle.isItemSelected(item.id);

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isAdded ? AppColors.primary : AppColors.borderLight,
                          width: isAdded ? 1.8 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Item Image
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: Container(
                                color: const Color(0xFFFAF7F2),
                                child: CachedNetworkImage(
                                  imageUrl: item.mainImage,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const Center(
                                    child: Icon(Icons.card_giftcard, color: AppColors.textMuted),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Item Content
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Formatters.formatPrice(item.price),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Action Buttons: [View] [Add] (from Screenshot 1)
                                Row(
                                  children: [
                                    // View Button
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _openQuickView(item),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          side: const BorderSide(color: AppColors.primary),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'View',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),

                                    // Add Button
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _bundle.toggleItem(item);
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              isAdded ? const Color(0xFF16A34A) : AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          isAdded ? '✓ Added' : 'Add',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Sticky Bottom Bar for Step 2 (matching Screenshot 1)
  Widget _buildStep2StickyBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_bundle.totalAccessoriesCount + 1} Items | ${Formatters.formatPrice(_bundle.pricePerBag)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'per gift bag bundle',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () => setState(() => _currentStep = 3),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Bag',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: REVIEW BAG
  // ---------------------------------------------------------------------------
  Widget _buildStep3ReviewBag() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            'Review Your Gift Bags',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          if (_bundle.isCustomBag) ...[
            CustomBagPreviewCard(
              customImageBytes: _bundle.customImageBytes,
              customText: _bundle.customDesignNotes,
              height: 190,
            ),
            const SizedBox(height: 14),
          ],

          // 1. Selected Bag Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F6F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _bundle.isCustomBag && _bundle.customImageBytes != null
                          ? Image.memory(_bundle.customImageBytes!, fit: BoxFit.contain)
                          : CachedNetworkImage(
                              imageUrl: _bundle.selectedBag?.mainImage ?? '',
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) => const Icon(Icons.shopping_bag),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _bundle.isCustomBag
                                ? 'Custom Printed Theme Bag'
                                : (_bundle.selectedBag?.title ?? 'Theme Bag'),
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          Text(
                            Formatters.formatPrice(_bundle.bagPrice),
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (_bundle.customDesignNotes.isNotEmpty)
                            Text(
                              'Notes: ${_bundle.customDesignNotes}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _currentStep = 1),
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Chosen Accessories Inside Bag
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Items Inside Each Bag (${_bundle.totalAccessoriesCount})',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _currentStep = 2),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      child: const Text('+ Add More'),
                    ),
                  ],
                ),
                const Divider(),
                if (_bundle.selectedItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'No accessories added yet. Tap "+ Add More" to choose gifts!',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _bundle.selectedItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final pId = _bundle.selectedItems.keys.elementAt(index);
                      final product = _bundle.accessoriesMap[pId];
                      final qty = _bundle.selectedItems[pId] ?? 1;

                      if (product == null) return const SizedBox.shrink();

                      return Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: product.mainImage,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  Formatters.formatPrice(product.price),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Quantity Inside Bag Controls
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _bundle.updateItemQuantity(pId, qty - 1);
                                  });
                                },
                              ),
                              Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _bundle.updateItemQuantity(pId, qty + 1);
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Number of Bags Multiplier & Bulk Discounts
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Number of Bags Needed',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        Text(
                          'Ideal for birthday parties & classes',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: _bundle.numberOfBags > 5
                                ? () => setState(() => _bundle.numberOfBags--)
                                : null,
                          ),
                          Text(
                            '${_bundle.numberOfBags}',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () => setState(() => _bundle.numberOfBags++),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bulk quotes are handled by the team (no automatic discounts on the store).
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    final text = 'Hi Titepo team, I need ${_bundle.numberOfBags}+ return gift bags. '
                        'Could you share bulk pricing?';
                    launchUrl(
                      Uri.parse('${AppConstants.supportWhatsApp}?text=${Uri.encodeComponent(text)}'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  child: _buildDiscountBadge('Large order? Ask for a bulk quote on WhatsApp', true),
                ),
                if (_bundle.isCustomBag && _bundle.customImageBytes != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'After placing your order you\'ll be asked to send your artwork on WhatsApp for printing.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. Pricing Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                _buildPriceRow('Cost per Bag Bundle', Formatters.formatPrice(_bundle.pricePerBag)),
                const SizedBox(height: 6),
                _buildPriceRow('Total for ${_bundle.numberOfBags} Bags', Formatters.formatPrice(_bundle.rawSubtotal)),
                const Divider(height: 20),
                _buildPriceRow(
                  'Final Order Total',
                  Formatters.formatPrice(_bundle.finalTotal),
                  isBold: true,
                  color: AppColors.primary,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountBadge(String label, bool isUnlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isUnlocked ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnlocked ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUnlocked ? Icons.check_circle : Icons.lock_outline,
            size: 13,
            color: isUnlocked ? const Color(0xFF16A34A) : AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: isUnlocked ? const Color(0xFF15803D) : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isBold = false, Color? color, double size = 13}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: size,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: size,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStep3StickyBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.formatPrice(_bundle.finalTotal),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '${_bundle.numberOfBags} bags (${_bundle.totalAccessoriesCount} items/bag)',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _proceedToCheckout,
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: Text(
                'Proceed to Checkout',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
