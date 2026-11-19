import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/collection.dart';
import '../services/shopify_service.dart';

class ShopifyProvider with ChangeNotifier {
  final ShopifyService _service = ShopifyService();

  List<ProductModel> _allProducts = [];
  List<CollectionModel> _collections = [];
  final Map<String, List<ProductModel>> _collectionCache = {};
  List<ProductModel> _searchResults = [];
  List<ProductModel> _categoryProducts = [];

  bool _isLoading = false;
  bool _isCategoryLoading = false;
  bool _isSearching = false;
  String? _errorMessage;
  String _selectedCollectionHandle = 'all';
  int _searchToken = 0;

  List<ProductModel> get allProducts => _allProducts;
  List<CollectionModel> get collections => _collections;
  List<ProductModel> get searchResults => _searchResults;
  List<ProductModel> get categoryProducts => _categoryProducts;
  bool get isLoading => _isLoading;
  bool get isCategoryLoading => _isCategoryLoading;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;
  String get selectedCollectionHandle => _selectedCollectionHandle;

  /// Homepage rails mirror titepo.com's homepage collections.
  List<ProductModel> get newArrivals {
    final c = _collectionCache['new-arrival-1'] ?? _collectionCache['new-arrival'];
    if (c != null && c.isNotEmpty) return c;
    final sorted = [..._allProducts]
      ..sort((a, b) => (b.publishedAt ?? DateTime(2000)).compareTo(a.publishedAt ?? DateTime(2000)));
    return sorted.take(12).toList();
  }

  List<ProductModel> get featuredProducts {
    final c = _collectionCache['new-arrival'];
    if (c != null && c.isNotEmpty) return c;
    return _allProducts.take(10).toList();
  }

  List<ProductModel> get returnGifts => _collectionCache['return-gift'] ?? const [];

  List<ProductModel> get onSale {
    final list = _allProducts.where((p) => p.isOnSale && p.available).toList()
      ..sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
    return list.take(12).toList();
  }

  List<ProductModel>? productsFor(String handle) =>
      handle == 'all' ? _allProducts : _collectionCache[handle];

  CollectionModel? collectionByHandle(String handle) {
    for (final c in _collections) {
      if (c.handle == handle) return c;
    }
    return null;
  }

  ProductModel? productByHandle(String handle) {
    for (final p in _allProducts) {
      if (p.handle == handle) return p;
    }
    return null;
  }

  Future<void>? _catalogLoad;
  Completer<void> _firstContent = Completer<void>();

  /// Completes as soon as there is something to show on the home screen
  /// (cached catalogue, first page of products, or the load has finished).
  Future<void> get firstContentReady => _firstContent.future;

  void _markFirstContent() {
    if (!_firstContent.isCompleted) _firstContent.complete();
  }

  /// Loads the catalogue progressively: cached copy first, then home-page
  /// collections and the full catalogue page by page, notifying as data arrives.
  Future<void> loadCatalogData() {
    return _catalogLoad ??= _doLoadCatalog().whenComplete(() => _catalogLoad = null);
  }

  Future<void> _doLoadCatalog() async {
    if (_firstContent.isCompleted && _allProducts.isEmpty) _firstContent = Completer<void>();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1) Instant: products saved on the phone from the last successful load.
      if (_allProducts.isEmpty) {
        final cached = await _service.cachedProducts();
        if (cached.isNotEmpty && _allProducts.isEmpty) {
          _allProducts = cached;
          if (_selectedCollectionHandle == 'all') _categoryProducts = _allProducts;
          _markFirstContent();
          notifyListeners();
        }
      }

      // 2) Network: everything in parallel, UI updated as each part arrives.
      await Future.wait([
        _service.fetchCollections().then((c) {
          _collections = c;
          notifyListeners();
        }),
        for (final h in const ['new-arrival-1', 'new-arrival', 'return-gift'])
          _loadCollectionIntoCache(h).then((list) {
            if (list.isNotEmpty) notifyListeners();
          }),
        _service
            .fetchProducts(onProgress: (partial) {
              if (partial.length >= _allProducts.length) {
                _allProducts = partial;
                if (_selectedCollectionHandle == 'all') _categoryProducts = _allProducts;
                _markFirstContent();
                notifyListeners();
              }
            })
            .then((all) {
              if (all.isNotEmpty) {
                _allProducts = all;
                if (_selectedCollectionHandle == 'all') _categoryProducts = _allProducts;
              }
            }),
      ]);

      if (_allProducts.isEmpty) {
        _errorMessage = 'Couldn\'t load products. Check your connection and pull to refresh.';
      }
    } catch (_) {
      if (_allProducts.isEmpty) {
        _errorMessage = 'Couldn\'t load products. Check your connection and pull to refresh.';
      }
    } finally {
      _isLoading = false;
      _markFirstContent();
      notifyListeners();
    }
  }

  Future<List<ProductModel>> _loadCollectionIntoCache(String handle) async {
    final list = await _service.fetchProductsByCollection(handle);
    if (list.isNotEmpty) _collectionCache[handle] = list;
    return list;
  }

  /// Loads (and caches) a collection's products.
  Future<List<ProductModel>> loadCollection(String handle, {bool force = false}) async {
    if (handle == 'all') return _allProducts;
    if (!force && _collectionCache.containsKey(handle)) return _collectionCache[handle]!;
    final list = await _loadCollectionIntoCache(handle);
    notifyListeners();
    return list;
  }

  Future<void> selectCategory(String handle) async {
    _selectedCollectionHandle = handle;
    final cached = productsFor(handle);
    if (cached != null) {
      _categoryProducts = cached;
      notifyListeners();
      return;
    }
    _isCategoryLoading = true;
    notifyListeners();
    try {
      _categoryProducts = await loadCollection(handle);
    } finally {
      _isCategoryLoading = false;
      notifyListeners();
    }
  }

  Future<List<ProductModel>> recommendationsFor(ProductModel product) async {
    final recs = await _service.fetchRecommendations(product.id);
    return recs.where((p) => p.id != product.id).toList();
  }

  /// Live product data (fresh price / stock) for the detail page.
  Future<ProductModel?> refreshProduct(String handle) => _service.fetchProductByHandle(handle);

  Future<void> search(String query) async {
    final token = ++_searchToken;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    // Instant local results from the full catalogue…
    final words = q.split(RegExp(r'\s+'));
    _searchResults = _allProducts.where((p) {
      final hay = '${p.title} ${p.productType} ${p.tags.join(' ')} ${p.vendor}'.toLowerCase();
      return words.every(hay.contains);
    }).toList();
    _isSearching = true;
    notifyListeners();

    // …then Shopify's relevance ranking on top.
    final handles = await _service.searchHandles(query);
    if (token != _searchToken) return;
    final ranked = <ProductModel>[];
    for (final h in handles) {
      final p = productByHandle(h);
      if (p != null) ranked.add(p);
    }
    final rankedIds = ranked.map((p) => p.id).toSet();
    _searchResults = [...ranked, ..._searchResults.where((p) => !rankedIds.contains(p.id))];
    _isSearching = false;
    notifyListeners();
  }
}
