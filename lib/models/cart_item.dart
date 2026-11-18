import 'product.dart';

class CartItem {
  final ProductModel product;
  final ProductVariant? selectedVariant;
  int quantity;

  /// Human-readable note shown in the app's cart.
  final String? customNotes;
  final List<String>? bundleItemSummaries;

  /// Line-item properties sent to Shopify. They appear on the order in
  /// Shopify Admin (e.g. bag theme, party message, contents per bag).
  final Map<String, String> attributes;

  CartItem({
    required this.product,
    this.selectedVariant,
    this.quantity = 1,
    this.customNotes,
    this.bundleItemSummaries,
    Map<String, String>? attributes,
  }) : attributes = attributes ?? const {};

  ProductVariant? get _variant =>
      selectedVariant ?? (product.variants.isNotEmpty ? product.firstAvailableVariant : null);

  double get unitPrice => _variant?.price ?? product.price;

  double? get unitCompareAtPrice => _variant?.compareAtPrice ?? product.compareAtPrice;

  double get totalPrice => unitPrice * quantity;

  String get image => _variant?.image ?? product.mainImage;

  String? get variantLabel {
    final t = _variant?.title;
    if (t == null || t == 'Default Title') return null;
    return t;
  }

  /// Real Shopify variant id, or null if this line cannot be checked out.
  /// (Never falls back to a different product.)
  String? get shopifyVariantId => _variant?.shopifyId;

  bool get isPurchasable => shopifyVariantId != null && (_variant?.available ?? product.available);

  /// Unique key distinguishing variant choices and customisations.
  String get cartKey {
    final extra = attributes.isEmpty && customNotes == null
        ? ''
        : '_${Object.hashAll([customNotes, ...attributes.entries.map((e) => '${e.key}=${e.value}')])}';
    return '${product.id}_${_variant?.id ?? "default"}$extra';
  }

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'selectedVariant': selectedVariant?.toJson(),
        'quantity': quantity,
        'customNotes': customNotes,
        'bundleItemSummaries': bundleItemSummaries,
        'attributes': attributes,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: ProductModel.fromJson(Map<String, dynamic>.from(json['product'])),
      selectedVariant: json['selectedVariant'] != null
          ? ProductVariant.fromJson(Map<String, dynamic>.from(json['selectedVariant']))
          : null,
      quantity: json['quantity'] ?? 1,
      customNotes: json['customNotes'] as String?,
      bundleItemSummaries: (json['bundleItemSummaries'] as List?)?.map((e) => e.toString()).toList(),
      attributes: (json['attributes'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }
}
