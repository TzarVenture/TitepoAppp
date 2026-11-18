import 'product.dart';

class CartItem {
  final ProductModel product;
  final ProductVariant? selectedVariant;
  int quantity;
  final String? customNotes;
  final List<String>? bundleItemSummaries;

  CartItem({
    required this.product,
    this.selectedVariant,
    this.quantity = 1,
    this.customNotes,
    this.bundleItemSummaries,
  });

  /// Price per item taking selected variant into account
  double get unitPrice => selectedVariant?.price ?? product.price;

  /// Total price for this line item
  double get totalPrice => unitPrice * quantity;

  /// Real Shopify Variant ID for live checkout permalinks
  String get shopifyVariantId {
    if (selectedVariant != null && RegExp(r'^\d+$').hasMatch(selectedVariant!.id)) {
      return selectedVariant!.id;
    }
    for (var v in product.variants) {
      if (RegExp(r'^\d+$').hasMatch(v.id)) {
        return v.id;
      }
    }
    if (RegExp(r'^\d+$').hasMatch(product.id)) {
      return product.id;
    }
    return '49660817834199';
  }

  /// Unique key for cart item distinguishing variant choices
  String get cartKey {
    final notePart = customNotes != null ? '_${customNotes.hashCode}' : '';
    return '${product.id}_${selectedVariant?.id ?? "default"}$notePart';
  }

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'selectedVariant': selectedVariant?.toJson(),
        'quantity': quantity,
        'customNotes': customNotes,
        'bundleItemSummaries': bundleItemSummaries,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: ProductModel.fromJson(json['product']),
      selectedVariant: json['selectedVariant'] != null
          ? ProductVariant.fromJson(json['selectedVariant'])
          : null,
      quantity: json['quantity'] ?? 1,
      customNotes: json['customNotes'] as String?,
      bundleItemSummaries: (json['bundleItemSummaries'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}
