import 'cart_item.dart';

/// An order placed through Shopify checkout from this device.
///
/// Live status (payment, fulfilment, courier tracking) is always read from
/// Shopify via [statusUrl] — the app never invents tracking data.
class OrderModel {
  /// Shopify order name, e.g. "#1042" (or a confirmation code if the
  /// order name was not visible on the thank-you page).
  final String orderId;
  final DateTime orderDate;
  final List<CartItem> items;
  final double totalAmount;

  /// Shopify order-status page captured from checkout (live tracking).
  final String? statusUrl;
  final String? email;
  final String? discountCode;

  OrderModel({
    required this.orderId,
    required this.orderDate,
    required this.items,
    required this.totalAmount,
    this.statusUrl,
    this.email,
    this.discountCode,
  });

  int get itemCount => items.fold(0, (s, i) => s + i.quantity);

  bool get hasCustomBag => items.any((i) => i.attributes.containsKey('Artwork'));

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'orderDate': orderDate.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'totalAmount': totalAmount,
        'statusUrl': statusUrl,
        'email': email,
        'discountCode': discountCode,
      };

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['orderId'] ?? '',
      orderDate: DateTime.tryParse(json['orderDate'] ?? '') ?? DateTime.now(),
      items: (json['items'] as List? ?? [])
          .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      statusUrl: json['statusUrl'] as String?,
      email: json['email'] as String?,
      discountCode: json['discountCode'] as String?,
    );
  }
}
