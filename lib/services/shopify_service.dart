import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/collection.dart';
import '../core/constants/app_constants.dart';
import 'storage_service.dart';

/// Catalogue reads from the live titepo.com storefront (public JSON endpoints).
class ShopifyService {
  final http.Client _client;

  ShopifyService({http.Client? client}) : _client = client ?? http.Client();

  Future<dynamic> _getJson(String path, {Duration timeout = const Duration(seconds: 15)}) async {
    final res = await _client
        .get(Uri.parse('${AppConstants.storeDomain}$path'), headers: {'Accept': 'application/json'})
        .timeout(timeout);
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return jsonDecode(res.body);
  }

  List<ProductModel> _parseProducts(dynamic data) {
    final list = data is Map ? data['products'] : null;
    if (list is! List) return [];
    return list.whereType<Map<String, dynamic>>().map(ProductModel.fromJson).toList();
  }

  /// Entire catalogue (paginated, 250 per page). Falls back to the offline cache.
  Future<List<ProductModel>> fetchProducts({int maxPages = 6}) async {
    try {
      final all = <ProductModel>[];
      for (var page = 1; page <= maxPages; page++) {
        final batch = _parseProducts(await _getJson('/products.json?limit=250&page=$page'));
        all.addAll(batch);
        if (batch.length < 250) break;
      }
      if (all.isNotEmpty) {
        await StorageService.cacheProducts(all);
        return all;
      }
    } catch (_) {}
    return StorageService.getCachedProducts();
  }

  Future<List<CollectionModel>> fetchCollections() async {
    try {
      final data = await _getJson('/collections.json?limit=250');
      if (data['collections'] is List) {
        return (data['collections'] as List)
            .whereType<Map<String, dynamic>>()
            .map(CollectionModel.fromJson)
            .where((c) => !AppConstants.hiddenCollections.contains(c.handle))
            .toList();
      }
    } catch (_) {}

    return AppConstants.featuredCategories
        .map((c) => CollectionModel(id: c['handle']!, title: c['title']!, handle: c['handle']!))
        .toList();
  }

  /// Products in a collection, in the merchant's collection order.
  Future<List<ProductModel>> fetchProductsByCollection(String handle) async {
    if (handle.isEmpty || handle == 'all') return fetchProducts();
    try {
      return _parseProducts(await _getJson('/collections/$handle/products.json?limit=250'));
    } catch (_) {}
    return [];
  }

  Future<ProductModel?> fetchProductByHandle(String handle) async {
    try {
      final data = await _getJson('/products/$handle.json', timeout: const Duration(seconds: 10));
      if (data['product'] is Map<String, dynamic>) return ProductModel.fromJson(data['product']);
    } catch (_) {}
    return null;
  }

  /// "You may also like" — Shopify's own recommendation engine.
  Future<List<ProductModel>> fetchRecommendations(String productId) async {
    try {
      return _parseProducts(await _getJson('/recommendations/products.json?product_id=$productId&limit=10'));
    } catch (_) {
      return [];
    }
  }

  /// Customisable return-gift bag.
  Future<ProductModel> fetchCustomBagProduct() async {
    final customBag = await fetchProductByHandle('titepo-custom-theme-bag');
    if (customBag != null) return customBag;

    return ProductModel(
      id: '9357456834775',
      title: 'Titepo Custom Return Gift Bag',
      handle: 'titepo-custom-theme-bag',
      description: 'Personalised return gift bag printed with your own theme, name or artwork.',
      vendor: 'TITEPO',
      productType: 'Custom Bag',
      price: 250.0,
      images: const [
        'https://cdn.shopify.com/s/files/1/0824/4792/5463/files/whitebag-removebg-preview.png?v=1786107156'
      ],
      variants: [ProductVariant(id: '49548778209495', title: 'Default Title', price: 250.0)],
      tags: const ['custom-bag', 'return-gift'],
    );
  }

  static const Map<String, List<String>> _themeBags = {
    // handle: [product id, variant id, title, image]
    'jungle-theme': ['9269896118487', '48636095758551', 'Titepo Jungle Theme (300 GSM)', 'jungle-theme.webp'],
    'animal-theme': ['9269897887959', '48636097528023', 'Titepo Animal Theme (300 GSM)', 'animal-theme.webp'],
    'birthday-theme': ['9269895987415', '48636095561943', 'Titepo Birthday Theme (300 GSM)', 'birthday-theme.webp'],
    'princess-theme': ['9269895332055', '48636094873815', 'Titepo Princess Theme (300 GSM)', 'princess-theme.webp'],
  };

  /// Ready-made theme bags (fetched live in parallel; offline fallback uses real ids).
  Future<List<ProductModel>> fetchReadyMadeThemeBags() async {
    final live = await Future.wait(_themeBags.keys.map(fetchProductByHandle));
    final bags = live.whereType<ProductModel>().toList();
    if (bags.isNotEmpty) return bags;

    return _themeBags.entries.map((e) {
      final v = e.value;
      return ProductModel(
        id: v[0],
        title: v[2],
        handle: e.key,
        description: 'Sturdy 300 GSM printed return gift bag.',
        vendor: 'TITEPO',
        productType: 'Theme Bag',
        price: 200.0,
        images: ['https://cdn.shopify.com/s/files/1/0824/4792/5463/files/${v[3]}'],
        variants: [ProductVariant(id: v[1], title: 'Default Title', price: 200.0)],
        tags: const ['theme-bag'],
      );
    }).toList();
  }

  /// Items to fill return-gift bags (accessories + return-gift collection).
  Future<List<ProductModel>> fetchReturnGiftAccessories() async {
    final results = await Future.wait([
      fetchProductsByCollection('accessories'),
      fetchProductsByCollection('return-gift'),
    ]);
    final map = <String, ProductModel>{};
    for (final list in results) {
      for (final p in list) {
        if (!p.handle.contains('theme') && !p.handle.contains('custom-theme-bag') && p.available) {
          map[p.id] = p;
        }
      }
    }
    return map.values.toList();
  }

  /// Shopify predictive search; returns product handles in relevance order.
  Future<List<String>> searchHandles(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final data = await _getJson(
        '/search/suggest.json?q=${Uri.encodeComponent(query)}&resources[type]=product&resources[limit]=10',
        timeout: const Duration(seconds: 8),
      );
      final products = data['resources']?['results']?['products'];
      if (products is List) return products.map((p) => p['handle'].toString()).toList();
    } catch (_) {}
    return [];
  }
}
