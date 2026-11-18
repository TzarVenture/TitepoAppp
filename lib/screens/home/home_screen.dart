import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_theme.dart';
import '../../models/product.dart';
import '../../providers/shopify_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/titepo_brand_logo.dart';
import '../../widgets/ui_kit.dart';
import '../../widgets/video_reels_preview_section.dart';
import '../categories/collection_screen.dart';
import '../main_navigation.dart';
import '../search/search_screen.dart';
import '../wishlist/wishlist_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openCollection(BuildContext context, String handle, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CollectionScreen(handle: handle, title: title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopifyProvider>();
    final nav = MainNavigationScope.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: shop.loadCatalogData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              titleSpacing: 16,
              toolbarHeight: 64,
              title: const TitepoBrandLogo(height: 34),
              actions: [
                IconButton(
                  tooltip: 'Wishlist',
                  icon: const Icon(Icons.favorite_border_rounded),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen())),
                ),
                const CartIconButton(),
                const SizedBox(width: 6),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _SearchBar(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _AnnouncementStrip()),
            SliverToBoxAdapter(
              child: _HeroCarousel(
                onGiftBags: () => nav?.switchTab(MainNavigation.gifts),
                onCollection: (h, t) => _openCollection(context, h, t),
              ),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Shop by category',
                actionLabel: 'All',
                onAction: () => nav?.switchTab(MainNavigation.shop),
              ),
            ),
            SliverToBoxAdapter(child: _CategoryStrip(onTap: (h, t) => _openCollection(context, h, t))),
            if (shop.isLoading && shop.allProducts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
              )
            else if (shop.allProducts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(message: shop.errorMessage, onRetry: shop.loadCatalogData),
              )
            else ...[
              ..._rail(
                context,
                title: 'New arrivals',
                subtitle: 'Fresh picks just landed',
                products: shop.newArrivals,
                handle: 'new-arrival-1',
              ),
              SliverToBoxAdapter(child: _GiftBuilderCard(onTap: () => nav?.switchTab(MainNavigation.gifts))),
              ..._rail(
                context,
                title: 'Return gifts',
                subtitle: 'Party favours kids actually love',
                products: shop.returnGifts,
                handle: 'return-gift',
              ),
              const SliverToBoxAdapter(
                child: Padding(padding: EdgeInsets.only(top: 28), child: VideoReelsPreviewSection()),
              ),
              if (shop.onSale.isNotEmpty)
                ..._rail(
                  context,
                  title: 'Deals of the day',
                  subtitle: 'Biggest savings in store',
                  products: shop.onSale,
                  handle: 'all',
                ),
              ..._rail(
                context,
                title: 'Featured collection',
                products: shop.featuredProducts,
                handle: 'new-arrival',
              ),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Explore everything',
                  subtitle: '${shop.allProducts.length} products',
                  onAction: () => nav?.switchTab(MainNavigation.shop),
                ),
              ),
              ProductSliverGrid(products: shop.allProducts.where((p) => p.available).take(20).toList()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton(
                    onPressed: () => nav?.switchTab(MainNavigation.shop),
                    child: Text('View all ${shop.allProducts.length} products'),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: _PromiseSection()),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _rail(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<ProductModel> products,
    required String handle,
  }) {
    if (products.isEmpty) return const [];
    return [
      SliverToBoxAdapter(
        child: SectionHeader(
          title: title,
          subtitle: subtitle,
          onAction: handle == 'all'
              ? () => MainNavigationScope.of(context)?.switchTab(MainNavigation.shop)
              : () => _openCollection(context, handle, title),
        ),
      ),
      SliverToBoxAdapter(child: ProductRail(products: products.take(12).toList())),
    ];
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.textMuted),
              SizedBox(width: 10),
              Expanded(
                child: Text('Search toys, bags, bottles, gifts…',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementStrip extends StatefulWidget {
  const _AnnouncementStrip();

  @override
  State<_AnnouncementStrip> createState() => _AnnouncementStripState();
}

class _AnnouncementStripState extends State<_AnnouncementStrip> {
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _i = (_i + 1) % AppConstants.marqueeMessages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
            child: child,
          ),
        ),
        child: Text(
          AppConstants.marqueeMessages[_i],
          key: ValueKey(_i),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _HeroCarousel extends StatefulWidget {
  final VoidCallback onGiftBags;
  final void Function(String handle, String title) onCollection;
  const _HeroCarousel({required this.onGiftBags, required this.onCollection});

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;
  Timer? _timer;

  static const _slides = [
    _Slide('RETURN GIFTS', 'Party bags,\nsorted in minutes', 'Build gift bags', 'gifts', null, '🎁',
        [AppColors.primary, AppColors.primaryLight], 'return-gift'),
    _Slide('BACK TO SCHOOL', 'Backpacks kids\nwant to carry', 'Shop bags', 'collection', 'bags', '🎒',
        [Color(0xFFE76F51), Color(0xFFF4A261)], 'bags'),
    _Slide('ZOOM ZOOM', 'Die-cast cars\n& racers', 'Shop cars', 'collection', 'cars', '🏎️',
        [Color(0xFF264653), Color(0xFF2A9D8F)], 'cars'),
    _Slide('LUNCH TIME', 'Bottles, bento\nboxes & mugs', 'Shop drinkware', 'collection', 'drinkware', '🥤',
        [Color(0xFF6D597A), Color(0xFFB56576)], 'drinkware'),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage((_page + 1) % _slides.length,
          duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopifyProvider>();
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 188,
          child: PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final s = _slides[i];
              final image = shop.collectionByHandle(s.imageCollection)?.image ??
                  (shop.productsFor(s.imageCollection)?.isNotEmpty == true
                      ? shop.productsFor(s.imageCollection)!.first.mainImage
                      : null);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => s.action == 'gifts'
                      ? widget.onGiftBags()
                      : widget.onCollection(
                          s.collection!,
                          shop.collectionByHandle(s.collection!)?.title ?? s.cta.replaceFirst('Shop ', ''),
                        ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: s.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          bottom: -10,
                          top: 18,
                          width: 170,
                          child: image != null
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(90)),
                                  child: AppNetworkImage(url: image, width: 400, background: Colors.white24),
                                )
                              : Center(child: Text(s.emoji, style: const TextStyle(fontSize: 80))),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 160, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.eyebrow,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                              const SizedBox(height: 6),
                              Text(s.title, style: AppTheme.display(size: 23, color: Colors.white, weight: FontWeight.w800)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                                child: Text(s.cta,
                                    style: TextStyle(color: s.colors.first, fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _Slide {
  final String eyebrow, title, cta, action;
  final String? collection;
  final String emoji;
  final List<Color> colors;
  final String imageCollection;
  const _Slide(this.eyebrow, this.title, this.cta, this.action, this.collection, this.emoji, this.colors,
      this.imageCollection);
}

class _CategoryStrip extends StatelessWidget {
  final void Function(String handle, String title) onTap;
  const _CategoryStrip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopifyProvider>();
    const cats = AppConstants.featuredCategories;
    return SizedBox(
      height: 112,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final c = cats[i];
          final image = shop.collectionByHandle(c['handle']!)?.image;
          return GestureDetector(
            onTap: () => onTap(c['handle']!, c['title']!),
            child: SizedBox(
              width: 74,
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.pastels[i % AppColors.pastels.length],
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: image != null
                        ? AppNetworkImage(url: image, width: 200, background: Colors.transparent)
                        : Center(child: Text(c['icon']!, style: const TextStyle(fontSize: 30))),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c['title']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GiftBuilderCard extends StatelessWidget {
  final VoidCallback onTap;
  const _GiftBuilderCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget step(String n, String label) => Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.accentYellow,
                child: Text(n, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 13)),
              ),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Return gift bag builder',
                              style: AppTheme.display(size: 22, color: Colors.white, weight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          const Text('Custom or themed bags, filled and ready for the party.',
                              style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Text('🎁', style: TextStyle(fontSize: 44)),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    step('1', 'Choose a bag'),
                    step('2', 'Add gifts'),
                    step('3', 'Pick quantity'),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.accentYellow, borderRadius: BorderRadius.circular(14)),
                  child: const Text('Start building',
                      style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink, fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromiseSection extends StatelessWidget {
  const _PromiseSection();

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String title, String body) => Expanded(
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 2),
              Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 32, 16, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.creamLight, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Text('Our promise to you & your kids', textAlign: TextAlign.center, style: AppTheme.display(size: 19)),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tile(Icons.child_care_rounded, 'Kid-safe', 'Non-toxic, child-friendly'),
              tile(Icons.lock_outline_rounded, 'Secure', 'Shopify-powered checkout'),
              tile(Icons.support_agent_rounded, 'Real help', 'Chat with our team'),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(AppConstants.supportWhatsApp), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('WhatsApp'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(AppConstants.instagramUrl), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Instagram'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String? message;
  final Future<void> Function() onRetry;
  const _ErrorState({this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(message ?? 'Something went wrong', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
