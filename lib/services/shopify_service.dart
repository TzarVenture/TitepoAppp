import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/collection.dart';
import '../core/constants/app_constants.dart';
import 'storage_service.dart';

/// Catalogue reads from the live titepo.com storefront (public JSON endpoints).
class ShopifyService {
  final http.Client _client;

  ShopifyService({http.Client? client}) : _client = client ?? http.Client();

  // Shared across all ShopifyService instances so the whole app is throttled together.
  static final Map<String, Future<dynamic>> _inFlight = {};
  static final Map<String, _CacheEntry> _memCache = {};
  static const int _maxConcurrent = 3;
  static int _active = 0;
  static final List<Completer<void>> _waiters = [];
  static final Random _rng = Random();

  /// Collection lists are cached on disk so the app still shows products when
  /// Shopify rate-limits (HTTP 429) this device.
  static const Duration _diskRefreshAfter = Duration(minutes: 10);
  static const String _diskPrefix = 'shopify_http_cache_v1:';

  static bool _persistable(String path) =>
      path.startsWith('/collections/') && path.contains('/products.json');

  /// Large responses are decoded on a background isolate so the UI keeps animating.
  static Future<dynamic> _decode(String body) async =>
      body.length > 60000 ? compute(_jsonDecodeTop, body) : jsonDecode(body);

  static Future<void> _acquire() async {
    if (_active < _maxConcurrent) {
      _active++;
      return;
    }
    final c = Completer<void>();
    _waiters.add(c);
    await c.future; // slot is handed over directly by _release
  }

  static void _release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _active--;
    }
  }

  static Future<_CacheEntry?> _readDisk(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_diskPrefix$path');
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return _CacheEntry(m['data'], DateTime.fromMillisecondsSinceEpoch(m['at'] as int));
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeDisk(String path, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_diskPrefix$path',
        jsonEncode({'at': DateTime.now().millisecondsSinceEpoch, 'data': data}),
      );
    } catch (_) {}
  }

  /// Identical requests share one network call; results are cached in memory (2 min)
  /// and, for collection lists, on disk (served instantly, refreshed in the background).
  /// At most [_maxConcurrent] requests run at once; 429/5xx are retried with backoff.
  Future<dynamic> _getJson(String path, {Duration timeout = const Duration(seconds: 15)}) async {
    final mem = _memCache[path];
    if (mem != null && DateTime.now().difference(mem.at) < const Duration(minutes: 2)) {
      return mem.data;
    }
    if (_persistable(path)) {
      final disk = await _readDisk(path);
      if (disk != null) {
        _memCache[path] = _CacheEntry(disk.data);
        if (DateTime.now().difference(disk.at) > _diskRefreshAfter) {
          _refresh(path, timeout).catchError((_) => null); // background refresh
        }
        return disk.data;
      }
    }
    return _refresh(path, timeout);
  }

  Future<dynamic> _refresh(String path, Duration timeout) {
    return _inFlight.putIfAbsent(path, () async {
      try {
        final data = await _fetchWithRetry(path, timeout);
        _memCache[path] = _CacheEntry(data);
        if (_persistable(path)) await _writeDisk(path, data);
        return data;
      } finally {
        _inFlight.remove(path);
      }
    });
  }

  Future<dynamic> _fetchWithRetry(String path, Duration timeout) async {
    const maxAttempts = 4;
    for (var attempt = 1; ; attempt++) {
      await _acquire();
      http.Response res;
      try {
        res = await _client.get(Uri.parse('${AppConstants.storeDomain}$path'), headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36',
        }).timeout(timeout);
      } finally {
        _release();
      }
      debugPrint('[Shopify] GET $path -> ${res.statusCode} (${res.body.length} bytes) attempt $attempt');
      if (res.statusCode == 200) return _decode(res.body);
      final retryable = res.statusCode == 429 || res.statusCode >= 500;
      if (!retryable || attempt >= maxAttempts) {
        throw Exception('HTTP ${res.statusCode} for $path');
      }
      final retryAfter = int.tryParse(res.headers['retry-after'] ?? '');
      final baseMs = retryAfter != null
          ? retryAfter.clamp(1, 8) * 1000
          : 1000 * attempt * (attempt + 1) ~/ 2; // 1s, 3s, 6s
      await Future.delayed(Duration(milliseconds: baseMs + _rng.nextInt(600)));
    }
  }

  // ---------------------------------------------------------------------------
  // Storefront GraphQL (primary). Shopify throttles the public /products.json
  // endpoints per IP (HTTP 429, especially on mobile networks); the GraphQL API
  // is meant for apps and is also what the cart/checkout already uses.
  // ---------------------------------------------------------------------------
  static const int _gqlPageSize = 25; // keeps query cost under the tokenless limit
  static const int _gqlMaxPages = 20;

  static const String _productFields = r"""
    id title handle descriptionHtml vendor productType tags publishedAt availableForSale
    options { name values }
    images(first: 8) { nodes { id url } }
    variants(first: 25) {
      nodes {
        id title availableForSale
        price { amount }
        compareAtPrice { amount }
        selectedOptions { name value }
        image { url }
      }
    }
  """;

  static final Uri _gqlEndpoint =
      Uri.parse('${AppConstants.storeDomain}/api/${AppConstants.storefrontApiVersion}/graphql.json');

  static String _numericId(dynamic gid) {
    final s = gid?.toString() ?? '';
    final i = s.lastIndexOf('/');
    final tail = i >= 0 ? s.substring(i + 1) : s;
    final q = tail.indexOf('?');
    return q >= 0 ? tail.substring(0, q) : tail;
  }

  /// Converts a Storefront GraphQL product node into the REST-style JSON
  /// that [ProductModel.fromJson] already understands.
  static Map<String, dynamic> _gqlProductToRest(Map<String, dynamic> n) {
    final images = <Map<String, dynamic>>[];
    for (final i in (n['images']?['nodes'] as List? ?? [])) {
      images.add({'id': _numericId(i['id']), 'src': i['url']});
    }
    final variants = <Map<String, dynamic>>[];
    for (final v in (n['variants']?['nodes'] as List? ?? [])) {
      final sel = (v['selectedOptions'] as List? ?? []);
      final m = <String, dynamic>{
        'id': _numericId(v['id']),
        'title': v['title'],
        'price': v['price']?['amount'],
        'compare_at_price': v['compareAtPrice']?['amount'],
        'available': v['availableForSale'] == true,
        if (v['image']?['url'] != null) 'featured_image': {'src': v['image']['url']},
      };
      for (var k = 0; k < sel.length && k < 3; k++) {
        m['option${k + 1}'] = sel[k]['value'];
      }
      variants.add(m);
    }
    return {
      'id': _numericId(n['id']),
      'title': n['title'],
      'handle': n['handle'],
      'body_html': n['descriptionHtml'],
      'vendor': n['vendor'],
      'product_type': n['productType'],
      'tags': n['tags'] ?? [],
      'published_at': n['publishedAt'],
      'available': n['availableForSale'] == true,
      'options': n['options'] ?? [],
      'images': images,
      'variants': variants,
    };
  }

  Future<Map<String, dynamic>> _gqlPost(String query, Map<String, dynamic> variables) async {
    final headers = <String, String>{'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (AppConstants.storefrontAccessToken.isNotEmpty) {
      headers['X-Shopify-Storefront-Access-Token'] = AppConstants.storefrontAccessToken;
    }
    for (var attempt = 1; ; attempt++) {
      await _acquire();
      http.Response res;
      try {
        res = await _client
            .post(_gqlEndpoint, headers: headers, body: jsonEncode({'query': query, 'variables': variables}))
            .timeout(const Duration(seconds: 20));
      } finally {
        _release();
      }
      debugPrint('[Shopify][GQL] -> ${res.statusCode} (${res.body.length} bytes) attempt $attempt');
      if (res.statusCode == 200) {
        final body = await _decode(res.body) as Map<String, dynamic>;
        final errors = body['errors'];
        if (errors is List && errors.isNotEmpty) {
          throw Exception('GraphQL: ${errors.map((e) => e['message']).join('; ')}');
        }
        return body['data'] as Map<String, dynamic>;
      }
      if ((res.statusCode == 429 || res.statusCode >= 500) && attempt < 3) {
        await Future.delayed(Duration(milliseconds: 1000 * attempt + _rng.nextInt(500)));
        continue;
      }
      throw Exception('GraphQL HTTP ${res.statusCode}');
    }
  }

  /// All products (or one collection's products, in the merchant's order) via GraphQL.
  Future<List<ProductModel>> _gqlProducts({String? collectionHandle, void Function(List<ProductModel>)? onPage}) async {
    final out = <ProductModel>[];
    String? cursor;
    for (var page = 0; page < _gqlMaxPages; page++) {
      final String query;
      if (collectionHandle == null) {
        query = 'query(\$first:Int!,\$after:String){products(first:\$first,after:\$after){'
            'pageInfo{hasNextPage endCursor} nodes{$_productFields}}}';
      } else {
        query = 'query(\$handle:String!,\$first:Int!,\$after:String){collection(handle:\$handle){'
            'products(first:\$first,after:\$after){pageInfo{hasNextPage endCursor} nodes{$_productFields}}}}';
      }
      final data = await _gqlPost(query, {
        if (collectionHandle != null) 'handle': collectionHandle,
        'first': _gqlPageSize,
        'after': cursor,
      });
      final conn = collectionHandle == null ? data['products'] : data['collection']?['products'];
      if (conn == null) break; // collection does not exist
      for (final n in (conn['nodes'] as List? ?? [])) {
        out.add(ProductModel.fromJson(_gqlProductToRest(n as Map<String, dynamic>)));
      }
      if (onPage != null && (page == 0 || page % 4 == 3)) onPage(List.unmodifiable(out));
      if (conn['pageInfo']?['hasNextPage'] != true) break;
      cursor = conn['pageInfo']['endCursor'] as String?;
    }
    return out;
  }

  List<ProductModel> _parseProducts(dynamic data) {
    final list = data is Map ? data['products'] : null;
    if (list is! List) return [];
    return list.whereType<Map<String, dynamic>>().map(ProductModel.fromJson).toList();
  }

  /// Entire catalogue (paginated, 250 per page). Falls back to the offline cache.
  /// Products saved on the phone from the last successful load.
  Future<List<ProductModel>> cachedProducts() => StorageService.getCachedProducts();

  Future<List<ProductModel>> fetchProducts({int maxPages = 6, void Function(List<ProductModel>)? onProgress}) async {
    // 1) Storefront GraphQL (not throttled like /products.json)
    try {
      final all = await _gqlProducts(onPage: onProgress);
      if (all.isNotEmpty) {
        await StorageService.cacheProducts(all);
        return all;
      }
    } catch (e) {
      debugPrint('[Shopify] GraphQL fetchProducts failed: $e');
    }
    // 2) Public JSON endpoint
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
    } catch (e) {
      debugPrint('[Shopify] fetchProducts FAILED: $e');
    }
    // 3) Offline cache
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
      final list = await _gqlProducts(collectionHandle: handle);
      if (list.isNotEmpty) return list;
    } catch (e) {
      debugPrint('[Shopify] GraphQL collection $handle failed: $e');
    }
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
  /// The recommendations endpoint uses Shopify's "AJAX" product format:
  /// prices are integers in paise (67500 = Rs 675) and image URLs start with
  /// "//" (no https:). Convert it to the REST format ProductModel expects.
  static Map<String, dynamic> _normalizeAjaxProduct(Map<String, dynamic> p) {
    String fixUrl(dynamic u) {
      final s = u?.toString() ?? '';
      return s.startsWith('//') ? 'https:$s' : s;
    }

    dynamic money(dynamic v) => v is num ? (v / 100).toStringAsFixed(2) : v;

    final out = Map<String, dynamic>.from(p);
    if (p['images'] is List) {
      out['images'] = (p['images'] as List)
          .map((i) => i is Map ? {...i, 'src': fixUrl(i['src'])} : fixUrl(i))
          .toList();
    }
    if (p['featured_image'] is String) out['featured_image'] = fixUrl(p['featured_image']);
    for (final k in ['price', 'price_min', 'price_max', 'compare_at_price', 'compare_at_price_min', 'compare_at_price_max']) {
      if (p.containsKey(k)) out[k] = money(p[k]);
    }
    if (p['variants'] is List) {
      out['variants'] = (p['variants'] as List).whereType<Map>().map((v) {
        final m = Map<String, dynamic>.from(v);
        m['price'] = money(v['price']);
        m['compare_at_price'] = money(v['compare_at_price']);
        final fi = v['featured_image'];
        if (fi is Map && fi['src'] != null) m['featured_image'] = {...fi, 'src': fixUrl(fi['src'])};
        return m;
      }).toList();
    }
    return out;
  }

  Future<List<ProductModel>> fetchRecommendations(String productId) async {
    try {
      final data = await _getJson('/recommendations/products.json?product_id=$productId&limit=10');
      final list = data is Map ? data['products'] : null;
      if (list is! List) return [];
      return list
          .whereType<Map<String, dynamic>>()
          .map((p) => ProductModel.fromJson(_normalizeAjaxProduct(p)))
          .toList();
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

class _CacheEntry {
  final dynamic data;
  final DateTime at;
  _CacheEntry(this.data, [DateTime? at]) : at = at ?? DateTime.now();
}

dynamic _jsonDecodeTop(String s) => jsonDecode(s);
