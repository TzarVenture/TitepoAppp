import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_theme.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/shopify_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/storefront_service.dart';
import '../../widgets/fullscreen_image_viewer.dart';
import '../../widgets/product_card.dart';
import '../../widgets/ui_kit.dart';
import '../cart/cart_screen.dart';
import '../checkout/checkout_webview_screen.dart';
import '../return_gift/return_gift_solutions_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late ProductModel _product;
  late List<String?> _selected; // selected value per option
  final _pageController = PageController();
  int _imageIndex = 0;
  int _quantity = 1;
  bool _buyingNow = false;
  bool _descExpanded = false;
  List<ProductModel> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _initSelection();
    _refresh();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initSelection() {
    final v = _product.firstAvailableVariant;
    _selected = List.generate(
      _product.options.length,
      (i) => (v != null && i < v.optionValues.length) ? v.optionValues[i] : null,
    );
  }

  Future<void> _refresh() async {
    final shop = context.read<ShopifyProvider>();
    final results = await Future.wait([
      shop.refreshProduct(_product.handle),
      shop.recommendationsFor(_product),
    ]);
    if (!mounted) return;
    setState(() {
      final fresh = results[0] as ProductModel?;
      if (fresh != null) {
        _product = fresh;
        _initSelection();
      }
      _recommendations = results[1] as List<ProductModel>;
    });
  }

  ProductVariant? get _variant {
    if (_product.variants.isEmpty) return null;
    if (_product.options.isEmpty) return _product.variants.first;
    for (final v in _product.variants) {
      var ok = true;
      for (var i = 0; i < _selected.length; i++) {
        if (i >= v.optionValues.length || v.optionValues[i] != _selected[i]) {
          ok = false;
          break;
        }
      }
      if (ok) return v;
    }
    return null;
  }

  bool _isValueAvailable(int optionIndex, String value) {
    return _product.variants.any((v) {
      if (!v.available || optionIndex >= v.optionValues.length || v.optionValues[optionIndex] != value) return false;
      for (var i = 0; i < _selected.length; i++) {
        if (i == optionIndex || _selected[i] == null) continue;
        if (i < v.optionValues.length && v.optionValues[i] != _selected[i]) return false;
      }
      return true;
    });
  }

  void _select(int optionIndex, String value) {
    setState(() => _selected[optionIndex] = value);
    final img = _variant?.image;
    if (img != null) {
      final idx = _product.images.indexOf(img);
      if (idx >= 0 && _pageController.hasClients) {
        _pageController.animateToPage(idx, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    }
  }

  bool get _canBuy => _variant != null && _variant!.available && _variant!.shopifyId != null;

  Future<void> _addToCart() async {
    if (!_canBuy) return;
    await context.read<CartProvider>().addToCart(_product, variant: _variant, quantity: _quantity);
    if (!mounted) return;
    showAppSnack(
      context,
      'Added $_quantity to cart',
      actionLabel: 'VIEW CART',
      onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
    );
  }

  /// Checks out just this item, leaving the saved cart untouched.
  Future<void> _buyNow() async {
    if (!_canBuy) return;
    final user = context.read<AuthProvider>().currentUser;
    final item = CartItem(product: _product, selectedVariant: _variant, quantity: _quantity);
    setState(() => _buyingNow = true);
    try {
      final cart = await StorefrontService().createCart(
        items: [item],
        buyer: BuyerDetails(email: user?.email, phone: user?.phone),
      );
      if (!mounted) return;
      final accepted = cart.quantityFor(item.shopifyVariantId!);
      if (accepted < _quantity) {
        showAppSnack(context, accepted == 0 ? 'Sorry, this item just sold out.' : 'Only $accepted available.');
        if (accepted == 0) return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutWebViewScreen(
            checkoutUrl: cart.checkoutUrl,
            items: [CartItem(product: _product, selectedVariant: _variant, quantity: accepted)],
            expectedTotal: cart.total,
            clearCartOnComplete: false,
          ),
        ),
      );
    } on StorefrontException catch (e) {
      if (mounted) showAppSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _buyingNow = false);
    }
  }

  bool get _isReturnGift =>
      _product.title.toLowerCase().contains('return gift') ||
      _product.tags.any((t) => t.toLowerCase().contains('return'));

  @override
  Widget build(BuildContext context) {
    final saved = context.select<WishlistProvider, bool>((w) => w.isWishlisted(_product.id));
    final variant = _variant;
    final price = variant?.price ?? _product.price;
    final compareAt = variant != null ? variant.compareAtPrice : _product.compareAtPrice;
    final images = _product.images.isEmpty ? [''] : _product.images;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: width.clamp(0, 520),
              backgroundColor: AppColors.surface,
              leading: Padding(
                padding: const EdgeInsets.all(6),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              actions: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 20, color: saved ? AppColors.saleRed : AppColors.ink),
                    onPressed: () => context.read<WishlistProvider>().toggleWishlist(_product),
                  ),
                ),
                const SizedBox(width: 6),
                const CircleAvatar(backgroundColor: Colors.white, child: CartIconButton()),
                const SizedBox(width: 10),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: (i) => setState(() => _imageIndex = i),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullscreenImageViewer(images: _product.images, initialIndex: i),
                          ),
                        ),
                        child: AppNetworkImage(url: images[i], width: 1000, background: AppColors.surfaceGrey),
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (i) {
                            final active = i == _imageIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: active ? 20 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: active ? AppColors.primary : Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_product.vendor.isNotEmpty)
                      Text(_product.vendor.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 11.5, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: AppColors.primaryLight)),
                    const SizedBox(height: 6),
                    Text(_product.displayTitle, style: AppTheme.display(size: 25)),
                    const SizedBox(height: 10),
                    PriceTag(price: price, compareAt: compareAt, size: 24, showPercent: true),
                    const SizedBox(height: 10),
                    _stockChip(),
                    for (var i = 0; i < _product.options.length; i++)
                      if (_product.hasRealVariants) _optionSelector(i),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const Spacer(),
                        QuantityStepper(
                          quantity: _quantity,
                          onDecrement: _quantity > 1 ? () => setState(() => _quantity--) : null,
                          onIncrement: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                    if (_isReturnGift) ...[
                      const SizedBox(height: 22),
                      _returnGiftBanner(),
                    ],
                    const SizedBox(height: 14),
                    _bulkBanner(),
                    const SizedBox(height: 24),
                    _description(),
                    const SizedBox(height: 18),
                    _trustRow(),
                  ],
                ),
              ),
            ),
            if (_recommendations.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SectionHeader(title: 'You may also like', onAction: null)),
              SliverToBoxAdapter(child: ProductRail(products: _recommendations)),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _stockChip() {
    final v = _variant;
    final (label, color, icon) = v == null
        ? ('Select an option', AppColors.textMuted, Icons.tune_rounded)
        : v.available
            ? ('In stock · ready to ship', AppColors.success, Icons.check_circle_rounded)
            : ('Sold out', AppColors.saleRed, Icons.remove_circle_outline_rounded);
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }

  Widget _optionSelector(int i) {
    final option = _product.options[i];
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: '${option.name}: ', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            TextSpan(text: _selected[i] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          ])),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: option.values.map((value) {
              final selected = _selected[i] == value;
              final available = _isValueAvailable(i, value);
              return ChoiceChip(
                label: Text(
                  value,
                  style: TextStyle(
                    decoration: available ? null : TextDecoration.lineThrough,
                    color: selected ? Colors.white : (available ? AppColors.ink : AppColors.textMuted),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                selected: selected,
                onSelected: (_) => _select(i, value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _returnGiftBanner() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReturnGiftSolutionsScreen())),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.accentYellowLight, borderRadius: BorderRadius.circular(18)),
        child: const Row(
          children: [
            Text('🎁', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Make return gift bags', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                  Text('Pick a bag, fill it with gifts, choose how many.', style: TextStyle(fontSize: 12.5)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Widget _bulkBanner() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        final text = 'Hi Titepo team, I\'d like bulk pricing for "${_product.displayTitle}". Quantity: ';
        launchUrl(Uri.parse('${AppConstants.supportWhatsApp}?text=${Uri.encodeComponent(text)}'),
            mode: LaunchMode.externalApplication);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.groups_2_outlined, color: AppColors.primary),
            SizedBox(width: 12),
            Expanded(
              child: Text('Ordering in bulk for a party or school? Ask us for a quote on WhatsApp.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  String _plainDescription() {
    var html = _product.description;
    html = html.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n• ');
    html = html.replaceAll(RegExp(r'<br\s*/?>|</p>|</h\d>|</div>', caseSensitive: false), '\n');
    html = html.replaceAll(RegExp(r'<[^>]*>'), '');
    html = html
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    return html.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).join('\n\n');
  }

  Widget _description() {
    final text = _plainDescription();
    if (text.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About this product', style: AppTheme.display(size: 19)),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: _descExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: Text(text, maxLines: 5, overflow: TextOverflow.ellipsis, style: _descStyle),
          secondChild: Text(text, style: _descStyle),
        ),
        if (text.length > 280)
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => setState(() => _descExpanded = !_descExpanded),
            child: Text(_descExpanded ? 'Show less' : 'Read more'),
          ),
      ],
    );
  }

  TextStyle get _descStyle => const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary);

  Widget _trustRow() {
    Widget item(IconData icon, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(height: 6),
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
    return Row(
      children: [
        item(Icons.child_care_rounded, 'Kid-safe\nmaterials'),
        item(Icons.lock_outline_rounded, 'Secure\ncheckout'),
        item(Icons.support_agent_rounded, 'WhatsApp\nsupport'),
      ],
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: _canBuy
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 54)),
                    onPressed: _addToCart,
                    child: const Text('Add to cart'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _buyingNow ? null : _buyNow,
                    child: _buyingNow
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Buy now'),
                  ),
                ),
              ],
            )
          : FilledButton(
              onPressed: null,
              child: Text(_variant == null ? 'Select an option' : 'Sold out'),
            ),
    );
  }
}
