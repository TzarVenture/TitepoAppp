import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/storage_service.dart';
import '../core/constants/app_constants.dart';

class CouponModel {
  final String code;
  final String description;
  final double discountPercent; // e.g. 10.0 for 10%
  final double? minOrderValue;

  const CouponModel({
    required this.code,
    required this.description,
    required this.discountPercent,
    this.minOrderValue,
  });
}

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  String? _appliedCouponCode;
  double _discountAmount = 0.0;
  String? _deliveryPincode;
  String? _deliveryEstimateText;

  // Available real promo coupons
  static const List<CouponModel> availableCoupons = [
    CouponModel(
      code: 'TITEPO10',
      description: 'Flat 10% OFF on all toys & return gifts',
      discountPercent: 10.0,
      minOrderValue: 0.0,
    ),
    CouponModel(
      code: 'BIRTHDAY15',
      description: 'Flat 15% OFF on orders over ₹1,500',
      discountPercent: 15.0,
      minOrderValue: 1500.0,
    ),
    CouponModel(
      code: 'BULK20',
      description: 'Flat 20% OFF on bulk return gift orders over ₹3,000',
      discountPercent: 20.0,
      minOrderValue: 3000.0,
    ),
  ];

  List<CartItem> get items => _items;
  String? get appliedCouponCode => _appliedCouponCode;
  double get discountAmount => _discountAmount;
  String? get deliveryPincode => _deliveryPincode;
  String? get deliveryEstimateText => _deliveryEstimateText;

  int get totalItemCount {
    int count = 0;
    for (var item in _items) {
      count += item.quantity;
    }
    return count;
  }

  double get subtotal {
    double sum = 0.0;
    for (var item in _items) {
      sum += item.totalPrice;
    }
    return sum;
  }

  bool get isFreeShippingEligible => subtotal >= AppConstants.freeShippingThreshold;

  double get remainingForFreeShipping {
    if (isFreeShippingEligible) return 0.0;
    return AppConstants.freeShippingThreshold - subtotal;
  }

  double get shippingFee {
    if (_items.isEmpty || isFreeShippingEligible) return 0.0;
    return AppConstants.defaultShippingFee;
  }

  double get grandTotal {
    double total = subtotal - _discountAmount + shippingFee;
    return total > 0 ? total : 0.0;
  }

  Future<void> initCart() async {
    _items = await StorageService.loadCart();
    notifyListeners();
  }

  /// Add product with variant to cart
  Future<void> addToCart(ProductModel product, {ProductVariant? variant, int quantity = 1}) async {
    final key = '${product.id}_${variant?.id ?? "default"}';
    final existingIndex = _items.indexWhere((item) => item.cartKey == key);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        product: product,
        selectedVariant: variant ?? (product.variants.isNotEmpty ? product.variants.first : null),
        quantity: quantity,
      ));
    }
    _recalculateDiscount();
    await StorageService.saveCart(_items);
    notifyListeners();
  }

  /// Update item quantity
  Future<void> updateQuantity(String cartKey, int delta) async {
    final index = _items.indexWhere((item) => item.cartKey == cartKey);
    if (index >= 0) {
      _items[index].quantity += delta;
      if (_items[index].quantity <= 0) {
        _items.removeAt(index);
      }
      _recalculateDiscount();
      await StorageService.saveCart(_items);
      notifyListeners();
    }
  }

  /// Remove item completely
  Future<void> removeFromCart(String cartKey) async {
    _items.removeWhere((item) => item.cartKey == cartKey);
    _recalculateDiscount();
    await StorageService.saveCart(_items);
    notifyListeners();
  }

  /// Apply coupon code with error reason
  String? applyCoupon(String code) {
    final formatted = code.trim().toUpperCase();
    final coupon = availableCoupons.cast<CouponModel?>().firstWhere(
          (c) => c?.code == formatted,
          orElse: () => null,
        );

    if (coupon == null) {
      return 'Invalid coupon code. Try TITEPO10';
    }

    if (coupon.minOrderValue != null && subtotal < coupon.minOrderValue!) {
      return 'Requires minimum order of ₹${coupon.minOrderValue!.toStringAsFixed(0)}';
    }

    _appliedCouponCode = coupon.code;
    _discountAmount = subtotal * (coupon.discountPercent / 100.0);
    notifyListeners();
    return null; // Success (no error)
  }

  void removeCoupon() {
    _appliedCouponCode = null;
    _discountAmount = 0.0;
    notifyListeners();
  }

  void _recalculateDiscount() {
    if (_appliedCouponCode == null) {
      _discountAmount = 0.0;
      return;
    }
    final coupon = availableCoupons.cast<CouponModel?>().firstWhere(
          (c) => c?.code == _appliedCouponCode,
          orElse: () => null,
        );
    if (coupon != null && (coupon.minOrderValue == null || subtotal >= coupon.minOrderValue!)) {
      _discountAmount = subtotal * (coupon.discountPercent / 100.0);
    } else {
      _appliedCouponCode = null;
      _discountAmount = 0.0;
    }
  }

  /// Delivery Pincode Estimator
  void setDeliveryPincode(String pin) {
    _deliveryPincode = pin;
    final now = DateTime.now();
    final estStart = now.add(const Duration(days: 3));
    final estEnd = now.add(const Duration(days: 5));
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    _deliveryEstimateText = 'Delivering to $pin by ${estStart.day} - ${estEnd.day} ${months[estEnd.month - 1]} 🚚';
    notifyListeners();
  }

  void clearDeliveryPincode() {
    _deliveryPincode = null;
    _deliveryEstimateText = null;
    notifyListeners();
  }

  Future<void> clearCart() async {
    _items.clear();
    _appliedCouponCode = null;
    _discountAmount = 0.0;
    await StorageService.saveCart(_items);
    notifyListeners();
  }
}
