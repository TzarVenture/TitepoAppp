import 'product.dart';

class CartItem {
  final ProductModel product;
  final ProductVariant? selectedVariant;
  int quantity;

  CartItem({
    required this.product,
    this.selectedVariant,
    this.quantity = 1,
  });

  /// Price per item taking selected variant into account
  double get unitPrice => selectedVariant?.price ?? product.price;

  /// Total price for this line item
  double get totalPrice => unitPrice * quantity;

  /// Unique key for cart item distinguishing variant choices
  String get cartKey => '${product.id}_${selectedVariant?.id ?? "default"}';

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'selectedVariant': selectedVariant?.toJson(),
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: ProductModel.fromJson(json['product']),
      selectedVariant: json['selectedVariant'] != null
          ? ProductVariant.fromJson(json['selectedVariant'])
          : null,
      quantity: json['quantity'] ?? 1,
    );
  }
}
