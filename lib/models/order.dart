import 'cart_item.dart';

class TrackingEvent {
  final String title;
  final String description;
  final String timestamp;
  final bool isCompleted;
  final bool isCurrent;

  const TrackingEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    this.isCompleted = false,
    this.isCurrent = false,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'timestamp': timestamp,
        'isCompleted': isCompleted,
        'isCurrent': isCurrent,
      };

  factory TrackingEvent.fromJson(Map<String, dynamic> json) => TrackingEvent(
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        timestamp: json['timestamp'] ?? '',
        isCompleted: json['isCompleted'] ?? false,
        isCurrent: json['isCurrent'] ?? false,
      );
}

class OrderModel {
  final String orderId;
  final DateTime orderDate;
  final List<CartItem> items;
  final double totalAmount;
  final String status; // 'Processing', 'Confirmed', 'Dispatched', 'Out for Delivery', 'Delivered'
  final String shippingAddress;
  final String paymentMethod;
  final String courier;
  final String awbNumber;
  final String estimatedDelivery;
  final List<TrackingEvent> trackingEvents;

  OrderModel({
    required this.orderId,
    required this.orderDate,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.shippingAddress,
    required this.paymentMethod,
    this.courier = 'Blue Dart Express',
    this.awbNumber = '',
    this.estimatedDelivery = '',
    this.trackingEvents = const [],
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'orderDate': orderDate.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'totalAmount': totalAmount,
        'status': status,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'courier': courier,
        'awbNumber': awbNumber,
        'estimatedDelivery': estimatedDelivery,
        'trackingEvents': trackingEvents.map((e) => e.toJson()).toList(),
      };

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['orderId'] ?? '',
      orderDate: DateTime.tryParse(json['orderDate'] ?? '') ?? DateTime.now(),
      items: (json['items'] as List? ?? [])
          .map((item) => CartItem.fromJson(item))
          .toList(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Processing',
      shippingAddress: json['shippingAddress'] ?? 'Home Address',
      paymentMethod: json['paymentMethod'] ?? 'Online Payment',
      courier: json['courier'] ?? 'Blue Dart Express',
      awbNumber: json['awbNumber'] ?? '',
      estimatedDelivery: json['estimatedDelivery'] ?? '',
      trackingEvents: (json['trackingEvents'] as List? ?? [])
          .map((e) => TrackingEvent.fromJson(e))
          .toList(),
    );
  }
}
