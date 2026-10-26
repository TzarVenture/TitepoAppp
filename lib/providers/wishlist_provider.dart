import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/storage_service.dart';

class WishlistProvider with ChangeNotifier {
  List<ProductModel> _wishlistProducts = [];

  List<ProductModel> get wishlistProducts => _wishlistProducts;

  Future<void> initWishlist() async {
    _wishlistProducts = await StorageService.loadWishlist();
    notifyListeners();
  }

  bool isWishlisted(String productId) {
    return _wishlistProducts.any((p) => p.id == productId);
  }

  Future<void> toggleWishlist(ProductModel product) async {
    final exists = isWishlisted(product.id);
    if (exists) {
      _wishlistProducts.removeWhere((p) => p.id == product.id);
    } else {
      _wishlistProducts.add(product);
    }
    await StorageService.saveWishlist(_wishlistProducts);
    notifyListeners();
  }

  Future<void> clearWishlist() async {
    _wishlistProducts.clear();
    await StorageService.saveWishlist(_wishlistProducts);
    notifyListeners();
  }
}
