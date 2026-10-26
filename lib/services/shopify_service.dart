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

  /// Fallback high-quality curated data for Titepo kids store
  List<ProductModel> _getFallbackProducts() {
    return [
      ProductModel(
        id: '1',
        title: 'Titepo Waterproof EVA Cute Cartoon School Backpack',
        handle: 'titepo-waterproof-eva-cartoon-cute-baby-children-backpack-large-silicone-shoulder-kids-school-bag',
        description: 'Premium lightweight, waterproof EVA silicone backpack designed for school and travel. Features 3D cartoon embossed design, breathable ergonomic shoulder straps, and extra-large compartment space.',
        vendor: 'Titepo',
        productType: 'School Bag',
        price: 1499.0,
        compareAtPrice: 1899.0,
        images: [
          'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800',
          'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=800',
        ],
        variants: [
          ProductVariant(id: 'v1', title: 'Pink Dino', price: 1499.0, compareAtPrice: 1899.0),
          ProductVariant(id: 'v2', title: 'Blue Astronaut', price: 1499.0, compareAtPrice: 1899.0),
          ProductVariant(id: 'v3', title: 'Green Monster', price: 1499.0, compareAtPrice: 1899.0),
        ],
        tags: ['bags', 'school-bag', 'new-arrival', 'return-gift'],
      ),
      ProductModel(
        id: '2',
        title: 'Die-Cast Metal Alloy Supercar Toy with Light & Sound',
        handle: 'die-cast-sport-car-toy-red',
        description: 'Heavyweight die-cast metal car toy with pull-back function, openable doors, LED headlights, and realistic engine sound effects. 100% child safe & durable alloy construction.',
        vendor: 'Titepo',
        productType: 'Toy Car',
        price: 799.0,
        compareAtPrice: 999.0,
        images: [
          'https://images.unsplash.com/photo-1581235720704-06d3acfcb36f?w=800',
          'https://images.unsplash.com/photo-1594787318286-3d835c1d207f?w=800',
        ],
        variants: [
          ProductVariant(id: 'v4', title: 'Red Racing Ferrari', price: 799.0, compareAtPrice: 999.0),
          ProductVariant(id: 'v5', title: 'Yellow Lamborghini', price: 799.0, compareAtPrice: 999.0),
        ],
        tags: ['cars', 'new-arrival', 'return-gift'],
      ),
      ProductModel(
        id: '3',
        title: 'Insulated Stainless Steel Kids Water Bottle with Straw (500ml)',
        handle: 'titepo-stainless-steel-kids-water-bottle',
        description: 'Double-walled vacuum insulated BPA-free stainless steel water bottle. Keeps drinks cold for 12 hours. Spill-proof straw lid and cute silicone protection sleeve.',
        vendor: 'Titepo',
        productType: 'Drinkware',
        price: 649.0,
        compareAtPrice: 799.0,
        images: [
          'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=800',
        ],
        variants: [
          ProductVariant(id: 'v6', title: 'Purple Bunny 500ml', price: 649.0),
          ProductVariant(id: 'v7', title: 'Yellow Bear 500ml', price: 649.0),
        ],
        tags: ['drinkware', 'water-bottle', 'return-gift'],
      ),
      ProductModel(
        id: '4',
        title: 'Leak-Proof 3-Compartment Kids Bento Lunch Box',
        handle: 'titepo-bento-lunch-box',
        description: 'Food-grade BPA free 3 compartment bento lunch box with chopsticks & spoon included. Easy snap-lock clips for little hands, leakproof silicone seal.',
        vendor: 'Titepo',
        productType: 'Lunch Box',
        price: 599.0,
        compareAtPrice: 749.0,
        images: [
          'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=800',
        ],
        variants: [
          ProductVariant(id: 'v8', title: 'Mint Green', price: 599.0),
          ProductVariant(id: 'v9', title: 'Pastel Pink', price: 599.0),
        ],
        tags: ['lunch-box', 'new-arrival'],
      ),
      ProductModel(
        id: '5',
        title: 'Cute 3D Cartoon Ceramic Mug with Lid & Spoon',
        handle: 'titepo-cute-cartoon-mug',
        description: 'Adorable 350ml ceramic coffee and milk mug with silicone coaster, matching lid and stainless steel spoon. Great gift for kids & birthday return gifts.',
        vendor: 'Titepo',
        productType: 'Mug',
        price: 399.0,
        compareAtPrice: 499.0,
        images: [
          'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=800',
        ],
        variants: [
          ProductVariant(id: 'v10', title: 'Cat Design', price: 399.0),
          ProductVariant(id: 'v11', title: 'Unicorn Design', price: 399.0),
        ],
        tags: ['mug', 'return-gift'],
      ),
      ProductModel(
        id: '6',
        title: '3D Pop-Up Decompression Pencil Case Box',
        handle: 'titepo-3d-popup-pencil-case',
        description: 'Multi-functional hard shell 3D pencil box with secret pop-up sharpener, calculator, and ruler slots. High quality EVA material.',
        vendor: 'Titepo',
        productType: 'Stationery',
        price: 499.0,
        compareAtPrice: 699.0,
        images: [
          'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?w=800',
        ],
        variants: [
          ProductVariant(id: 'v12', title: 'Space Galaxy', price: 499.0),
          ProductVariant(id: 'v13', title: 'Unicorn Dream', price: 499.0),
        ],
        tags: ['stationary', 'return-gift', 'new-arrival'],
      ),
      ProductModel(
        id: '7',
        title: 'Custom Birthday Return Gift Hamper Box (Pack of 10)',
        handle: 'titepo-return-gift-hamper-pack',
        description: 'Complete birthday return gift package for kids party. Includes custom themed pouch, activity stationery set, mini car, and cute keychain ready in gift box packaging.',
        vendor: 'Titepo',
        productType: 'Return Gift Package',
        price: 2499.0,
        compareAtPrice: 2999.0,
        images: [
          'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=800',
        ],
        variants: [
          ProductVariant(id: 'v14', title: 'Pack of 10 Hampers', price: 2499.0),
          ProductVariant(id: 'v15', title: 'Pack of 20 Hampers', price: 4799.0),
        ],
        tags: ['return-gift', 'featured'],
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
