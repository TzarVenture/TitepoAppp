import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/collection.dart';
import '../services/shopify_service.dart';

class ShopifyProvider with ChangeNotifier {
  final ShopifyService _shopifyService = ShopifyService();

  List<ProductModel> _allProducts = [];
  List<ProductModel> _featuredProducts = [];
  List<ProductModel> _newArrivals = [];
  List<ProductModel> _returnGifts = [];
  List<CollectionModel> _collections = [];
  List<ProductModel> _searchResults = [];
  List<ProductModel> _categoryProducts = [];

  bool _isLoading = false;
  bool _isCategoryLoading = false;
  bool _isSearching = false;
  String? _errorMessage;
  String _selectedCollectionHandle = 'all';

  // Getters
  List<ProductModel> get allProducts => _allProducts;
  List<ProductModel> get featuredProducts => _featuredProducts;
  List<ProductModel> get newArrivals => _newArrivals;
  List<ProductModel> get returnGifts => _returnGifts;
  List<CollectionModel> get collections => _collections;
  List<ProductModel> get searchResults => _searchResults;
  List<ProductModel> get categoryProducts => _categoryProducts;

  bool get isLoading => _isLoading;
  bool get isCategoryLoading => _isCategoryLoading;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;
  String get selectedCollectionHandle => _selectedCollectionHandle;

  /// Load initial catalog data (Products & Collections)
  Future<void> loadCatalogData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final productsFuture = _shopifyService.fetchProducts(limit: 50);
      final collectionsFuture = _shopifyService.fetchCollections();

      final results = await Future.wait([productsFuture, collectionsFuture]);

      _allProducts = results[0] as List<ProductModel>;
      _collections = results[1] as List<CollectionModel>;

      // Categorize products for homepage sections
      _featuredProducts = _allProducts.take(8).toList();
      _newArrivals = _allProducts.where((p) => p.tags.contains('new-arrival') || p.isOnSale).toList();
      if (_newArrivals.isEmpty) _newArrivals = _allProducts.take(6).toList();

      _returnGifts = _allProducts.where((p) => p.tags.contains('return-gift') || p.handle.contains('return')).toList();
      if (_returnGifts.isEmpty) _returnGifts = _allProducts.reversed.take(6).toList();

      _categoryProducts = List.from(_allProducts);
    } catch (e) {
      _errorMessage = 'Failed to load Titepo products. Please check your connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select category and fetch products for it
  Future<void> selectCategory(String handle) async {
    _selectedCollectionHandle = handle;
    _isCategoryLoading = true;
    notifyListeners();

    try {
      if (handle == 'all' || handle.isEmpty) {
        _categoryProducts = List.from(_allProducts);
      } else {
        _categoryProducts = await _shopifyService.fetchProductsByCollection(handle);
      }
    } catch (e) {
      _categoryProducts = _allProducts.where((p) {
        return p.tags.contains(handle) || p.productType.toLowerCase().contains(handle.toLowerCase());
      }).toList();
    } finally {
      _isCategoryLoading = false;
      notifyListeners();
    }
  }

  /// Search catalog
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _shopifyService.searchProducts(query);
    } catch (e) {
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }
}
