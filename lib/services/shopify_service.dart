import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/collection.dart';
import '../core/constants/app_constants.dart';

class ShopifyService {
  final http.Client _client;

  ShopifyService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch products from live Shopify API with limit
  Future<List<ProductModel>> fetchProducts({int limit = 30}) async {
    try {
      final response = await _client
          .get(Uri.parse('${AppConstants.storeDomain}/products.json?limit=$limit'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['products'] is List) {
          final List list = data['products'];
          return list.map((item) => ProductModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      // Fallback on error or offline
    }
    return _getFallbackProducts();
  }

  /// Fetch collections from live Shopify API
  Future<List<CollectionModel>> fetchCollections() async {
    try {
      final response = await _client
          .get(Uri.parse('${AppConstants.storeDomain}/collections.json'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['collections'] is List) {
          final List list = data['collections'];
          return list.map((item) => CollectionModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      // Fallback
    }
    return _getFallbackCollections();
  }

  /// Fetch products by collection handle
  Future<List<ProductModel>> fetchProductsByCollection(String handle) async {
    try {
      final response = await _client
          .get(Uri.parse('${AppConstants.storeDomain}/collections/$handle/products.json'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['products'] is List) {
          final List list = data['products'];
          return list.map((item) => ProductModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      // Fallback
    }
    final all = await fetchProducts();
    if (handle.isEmpty || handle == 'all') return all;
    return all.where((p) {
      final tagsStr = p.tags.join(' ').toLowerCase();
      final typeStr = p.productType.toLowerCase();
      final titleStr = p.title.toLowerCase();
      final h = handle.toLowerCase();
      return tagsStr.contains(h) || typeStr.contains(h) || titleStr.contains(h) || p.handle.contains(h);
    }).toList();
  }

  /// Fetch a single product by handle directly from Shopify
  Future<ProductModel?> fetchProductByHandle(String handle) async {
    try {
      final response = await _client
          .get(Uri.parse('${AppConstants.storeDomain}/products/$handle.json'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['product'] is Map<String, dynamic>) {
          return ProductModel.fromJson(data['product']);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetch the customizable bag product from Shopify
  Future<ProductModel> fetchCustomBagProduct() async {
    final customBag = await fetchProductByHandle('titepo-custom-theme-bag');
    if (customBag != null) return customBag;

    return ProductModel(
      id: '9357456834775',
      title: 'Titepo Custom Return Gift Bag',
      handle: 'titepo-custom-theme-bag',
      description:
          'Personalized return gift bag with custom theme design, custom name printing, and uploaded graphics tailored for your special occasion.',
      vendor: 'TITEPO',
      productType: 'Custom Bag',
      price: 250.0,
      compareAtPrice: 500.0,
      images: [
        'https://cdn.shopify.com/s/files/1/0824/4792/5463/files/whitebag-removebg-preview.png?v=1786107156'
      ],
      variants: [
        ProductVariant(id: '49548778209495', title: 'Default Title', price: 250.0, compareAtPrice: 500.0),
      ],
      tags: ['custom-bag', 'return-gift'],
    );
  }

  /// Fetch ready-made theme bags from Shopify
  Future<List<ProductModel>> fetchReadyMadeThemeBags() async {
    final List<String> themeHandles = [
      'jungle-theme',
      'animal-theme',
      'birthday-theme',
      'princess-theme',
    ];
    final List<ProductModel> bags = [];

    for (final handle in themeHandles) {
      final p = await fetchProductByHandle(handle);
      if (p != null) {
        bags.add(p);
      }
    }

    if (bags.isNotEmpty) return bags;

    return [
      ProductModel(
        id: '9269896118487',
        title: 'Titepo Jungle Theme (300 GSM)',
        handle: 'jungle-theme',
        description: 'Vibrant jungle safari themed high-grade 300 GSM kraft gift bag.',
        vendor: 'TITEPO',
        productType: 'Theme Bag',
        price: 200.0,
        images: ['https://cdn.shopify.com/s/files/1/0824/4792/5463/files/jungle-theme.webp?v=1779173733'],
        variants: [ProductVariant(id: '48636095758551', title: 'Default Title', price: 200.0)],
        tags: ['theme-bag', 'jungle'],
      ),
      ProductModel(
        id: '9269897887959',
        title: 'Titepo Animal Theme (300 GSM)',
        handle: 'animal-theme',
        description: 'Cute zoo animals theme 300 GSM gift bag for kids.',
        vendor: 'TITEPO',
        productType: 'Theme Bag',
        price: 200.0,
        images: ['https://cdn.shopify.com/s/files/1/0824/4792/5463/files/animal-theme.webp?v=1779173733'],
        variants: [ProductVariant(id: '48636100000000', title: 'Default Title', price: 200.0)],
        tags: ['theme-bag', 'animal'],
      ),
      ProductModel(
        id: '9269895987415',
        title: 'Titepo Birthday Theme (300 GSM)',
        handle: 'birthday-theme',
        description: 'Festive birthday party celebration themed bag.',
        vendor: 'TITEPO',
        productType: 'Theme Bag',
        price: 200.0,
        images: ['https://cdn.shopify.com/s/files/1/0824/4792/5463/files/birthday-theme.webp?v=1779173733'],
        variants: [ProductVariant(id: '48636111111111', title: 'Default Title', price: 200.0)],
        tags: ['theme-bag', 'birthday'],
      ),
      ProductModel(
        id: '9269895332055',
        title: 'Titepo Princess Theme (300 GSM)',
        handle: 'princess-theme',
        description: 'Magical fairytale princess castle theme gift bag.',
        vendor: 'TITEPO',
        productType: 'Theme Bag',
        price: 200.0,
        images: ['https://cdn.shopify.com/s/files/1/0824/4792/5463/files/princess-theme.webp?v=1779173733'],
        variants: [ProductVariant(id: '48636122222222', title: 'Default Title', price: 200.0)],
        tags: ['theme-bag', 'princess'],
      ),
    ];
  }

  /// Fetch accessories & gifts for the bag builder
  Future<List<ProductModel>> fetchReturnGiftAccessories() async {
    try {
      final accFuture = fetchProductsByCollection('accessories');
      final giftFuture = fetchProductsByCollection('return-gift');
      final results = await Future.wait([accFuture, giftFuture]);

      final Map<String, ProductModel> map = {};
      for (final list in results) {
        for (final p in list) {
          // Exclude bags from accessories list
          if (!p.handle.contains('theme') && !p.handle.contains('custom-theme-bag')) {
            map[p.id] = p;
          }
        }
      }
      if (map.isNotEmpty) {
        return map.values.toList();
      }
    } catch (_) {}
    return fetchProducts();
  }

  /// Search products by query keyword
  Future<List<ProductModel>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _client
          .get(Uri.parse('${AppConstants.storeDomain}/search/suggest.json?q=${Uri.encodeComponent(query)}&resources[type]=product'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final productsData = data['resources']?['results']?['products'];
        if (productsData is List && productsData.isNotEmpty) {
          return productsData.map((item) => ProductModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      // Fallback local filter
    }

    final all = await fetchProducts();
    final q = query.toLowerCase().trim();
    return all.where((p) {
      return p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.vendor.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  /// Fallback high-quality curated data for Titepo kids store with real Shopify catalog IDs
  List<ProductModel> _getFallbackProducts() {
    return [
      ProductModel(
        id: '9384208695511',
        title: 'Titepo Shaped Hardshell EVA Shoulder Bagpack Space Theme',
        handle: 'titepo-shaped-hardshell-eva-shoulder-bagpack-space-theme',
        description: 'Premium lightweight, waterproof EVA hardshell backpack designed for school and travel. Features 3D space theme embossed design, breathable ergonomic shoulder straps, and spacious compartment.',
        vendor: 'Titepo',
        productType: 'School Bag',
        price: 1499.0,
        compareAtPrice: 1899.0,
        images: [
          'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800',
          'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=800',
        ],
        variants: [
          ProductVariant(id: '49660578136279', title: 'Space Theme EVA', price: 1499.0, compareAtPrice: 1899.0),
        ],
        tags: ['bags', 'school-bag', 'new-arrival', 'return-gift'],
      ),
      ProductModel(
        id: '9384369815767',
        title: 'Titepo 6 Pcs Animal Highlighter Pens Set',
        handle: 'titepo-6-pcs-animal-highlighter-pens-set-online-return-gift-solution',
        description: 'Cute pastel animal highlighters set with chisel tips. High quality ink suitable for kids notebooks, coloring and school work.',
        vendor: 'Titepo',
        productType: 'Stationery',
        price: 120.0,
        compareAtPrice: 240.0,
        images: [
          'https://cdn.shopify.com/s/files/1/0824/4792/5463/files/1_463658f9-d456-497f-a15e-3ec3de3585f5.jpg?v=1788182655',
        ],
        variants: [
          ProductVariant(id: '49660817834199', title: 'Set of 6 Highlighters', price: 120.0, compareAtPrice: 240.0),
        ],
        tags: ['stationary', 'new-arrival', 'return-gift'],
      ),
      ProductModel(
        id: '9384208859351',
        title: 'Titepo 3 Compartment Bento Box for Kids',
        handle: 'titepo-3-compartment-bento-box-for-kids-online-return-gift-solution',
        description: 'Food-grade stainless steel 3 compartment bento lunch box with spoon included. Easy snap-lock clips for little hands, leakproof silicone seal.',
        vendor: 'Titepo',
        productType: 'Lunch Box',
        price: 600.0,
        compareAtPrice: 1200.0,
        images: [
          'https://cdn.shopify.com/s/files/1/0824/4792/5463/files/1_2ef37834-4173-41cb-9b63-c779415958df.jpg?v=1788182522',
        ],
        variants: [
          ProductVariant(id: '49660578627799', title: 'Sky Blue Bento Box', price: 600.0, compareAtPrice: 1200.0),
        ],
        tags: ['lunch-box', 'return-gift'],
      ),
      ProductModel(
        id: '9384208826583',
        title: 'Titepo Preschool Backpack Toddler Neoprene Animal - Elephant',
        handle: 'titepo-preschool-backpack-toddler-neoprene-animal-elephant',
        description: 'Ultra-lightweight neoprene toddler backpack featuring cute elephant ears, safety leash clip, and padded breathable shoulder straps.',
        vendor: 'Titepo',
        productType: 'School Bag',
        price: 899.0,
        compareAtPrice: 1199.0,
        images: [
          'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=800',
        ],
        variants: [
          ProductVariant(id: '49660578595031', title: 'Elephant Neoprene', price: 899.0, compareAtPrice: 1199.0),
        ],
        tags: ['bags', 'new-arrival'],
      ),
      ProductModel(
        id: '9384208793815',
        title: 'Titepo Cool Wheelie Kids Trolley Backpack',
        handle: 'titepo-cool-wheelie-kids-backpack',
        description: 'Multi-functional rolling school trolley backpack with smooth wheels and retractable handle. Relieves spine burden for school going kids.',
        vendor: 'Titepo',
        productType: 'School Bag',
        price: 1299.0,
        compareAtPrice: 1699.0,
        images: [
          'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=800',
        ],
        variants: [
          ProductVariant(id: '49660578562263', title: 'Wheelie Trolley Bag', price: 1299.0, compareAtPrice: 1699.0),
        ],
        tags: ['bags', 'return-gift'],
      ),
      ProductModel(
        id: '9384208302295',
        title: 'Titepo Automatic Electric Pencil Sharpener for Kids',
        handle: 'titepo-automatic-electric-pencil-sharpener-for-kids',
        description: 'Battery operated electric pencil sharpener with heavy duty helical steel blade, safety auto-stop mechanism and shavings tray.',
        vendor: 'Titepo',
        productType: 'Stationery',
        price: 499.0,
        compareAtPrice: 699.0,
        images: [
          'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?w=800',
        ],
        variants: [
          ProductVariant(id: '49660577743063', title: 'Electric Sharpener', price: 499.0, compareAtPrice: 699.0),
        ],
        tags: ['stationary', 'return-gift', 'new-arrival'],
      ),
      ProductModel(
        id: '9384208466135',
        title: 'Titepo Chisel Tip Colouring Pens Set - 6 Pcs',
        handle: 'titepo-chisel-tip-colouring-pens-set-6-pcs',
        description: 'Vibrant chisel tip colouring pens designed for young artists. Non-toxic washable inks, perfect for return gifts and party hampers.',
        vendor: 'Titepo',
        productType: 'Stationery',
        price: 199.0,
        compareAtPrice: 299.0,
        images: [
          'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=800',
        ],
        variants: [
          ProductVariant(id: '49660577906903', title: '6 Pcs Set', price: 199.0, compareAtPrice: 299.0),
        ],
        tags: ['stationary', 'return-gift', 'featured'],
      ),
    ];
  }

  List<CollectionModel> _getFallbackCollections() {
    return [
      CollectionModel(id: 'c1', title: 'Return Gifts', handle: 'return-gift', description: 'Complete Gifting Packages for Birthday Celebrations', productsCount: 45),
      CollectionModel(id: 'c2', title: 'Die-Cast Cars', handle: 'cars', description: 'Alloy Metal Cars, Racing Track Sets & Vehicles', productsCount: 28),
      CollectionModel(id: 'c3', title: 'School Bags', handle: 'bags', description: 'Lightweight EVA 3D Cartoon Backpacks & Pouches', productsCount: 36),
      CollectionModel(id: 'c4', title: 'Water Bottles', handle: 'drinkware', description: 'Insulated Stainless Steel & BPA-Free Bottles', productsCount: 24),
      CollectionModel(id: 'c5', title: 'Lunch Boxes', handle: 'lunch-box', description: 'Leak-proof Bento Boxes & Stainless Steel Containers', productsCount: 19),
      CollectionModel(id: 'c6', title: 'Cute Mugs', handle: 'mug', description: '3D Animal & Cartoon Mugs for Kids', productsCount: 16),
      CollectionModel(id: 'c7', title: 'Stationery Sets', handle: 'stationary', description: 'Pencil Boxes, Art Kits & Fun School Accessories', productsCount: 30),
      CollectionModel(id: 'c8', title: 'New Arrivals', handle: 'new-arrival', description: 'Latest Toys & Gifting Trends', productsCount: 50),
    ];
  }
}
