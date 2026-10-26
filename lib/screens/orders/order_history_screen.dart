import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../widgets/contact_support_modal.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final List<OrderModel> _orders = [
    OrderModel(
      orderId: 'TP-98231',
      orderDate: DateTime.now().subtract(const Duration(days: 2)),
      items: [],
      totalAmount: 1998.0,
      status: 'Out for Delivery',
      courier: 'Blue Dart Express',
      awbNumber: 'BLUEDART-8829104',
      estimatedDelivery: 'Today by 7:00 PM',
      shippingAddress: 'Flat 402, Sunshine Heights, 12th Main, Indiranagar, Bengaluru 560038',
      paymentMethod: 'Prepaid (Google Pay)',
      trackingEvents: [
        const TrackingEvent(
          title: 'Out for Delivery',
          description: 'Courier executive Rajesh is en route with your package.',
          timestamp: 'Today • 08:30 AM',
          isCompleted: true,
          isCurrent: true,
        ),
        const TrackingEvent(
          title: 'Reached Nearest Hub (Indiranagar)',
          description: 'Package arrived at regional distribution facility.',
          timestamp: 'Yesterday • 09:40 PM',
          isCompleted: true,
        ),
        const TrackingEvent(
          title: 'In Transit',
          description: 'Package in transit from Mumbai Central Fulfillment Center.',
          timestamp: '2 days ago • 04:15 PM',
          isCompleted: true,
        ),
        const TrackingEvent(
          title: 'Dispatched & Handed to Blue Dart',
          description: 'Packed securely in protective bubble wrap and dispatched.',
          timestamp: '2 days ago • 11:00 AM',
          isCompleted: true,
        ),
        const TrackingEvent(
          title: 'Order Confirmed',
          description: 'Order received and inventory assigned.',
          timestamp: '2 days ago • 09:15 AM',
          isCompleted: true,
        ),
      ],
    ),
    OrderModel(
      orderId: 'TP-98104',
      orderDate: DateTime.now().subtract(const Duration(days: 12)),
      items: [],
      totalAmount: 799.0,
      status: 'Delivered',
      courier: 'Delhivery Surface',
      awbNumber: 'DLHV-992384711',
      estimatedDelivery: 'Delivered on Sep 25, 2026',
      shippingAddress: 'Flat 301, Lakeview Residency, Outer Ring Road, Bengaluru 560103',
      paymentMethod: 'UPI / PhonePe',
      trackingEvents: [
        const TrackingEvent(
          title: 'Delivered Successfully',
          description: 'Package handed over to resident. Verified by OTP.',
          timestamp: 'Sep 25, 2026 • 02:45 PM',
          isCompleted: true,
          isCurrent: true,
        ),
        const TrackingEvent(
          title: 'Out for Delivery',
          description: 'Delivery associate Manoj Kumar has picked up the shipment.',
          timestamp: 'Sep 25, 2026 • 09:30 AM',
          isCompleted: true,
        ),
        const TrackingEvent(
          title: 'Arrived at Local Delivery Hub',
          description: 'Shipment received at Bellandur Sorting Facility.',
          timestamp: 'Sep 24, 2026 • 07:15 PM',
          isCompleted: true,
        ),
        const TrackingEvent(
          title: 'Dispatched from Central Warehouse',
          description: 'Manifest created and transferred to Delhivery Air Express.',
          timestamp: 'Sep 23, 2026 • 11:20 AM',
          isCompleted: true,
        ),
        const TrackingEvent(
          title: 'Order Placed & Confirmed',
          description: 'Payment verified. Items packed in kid-safe tamper-evident box.',
          timestamp: 'Sep 22, 2026 • 04:10 PM',
          isCompleted: true,
        ),
      ],
    ),
  ];

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.success;
      case 'out for delivery':
        return const Color(0xFFF59E0B);
      case 'dispatched':
      case 'shipped':
        return AppColors.primary;
      default:
        return AppColors.secondary;
    }
  }

  void _launchShopifyOrders() async {
    final Uri url = Uri.parse(AppConstants.orderTrackingUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'My Orders & Shipments',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Order Support',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ContactSupportModal(),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.borderLight)),
          ),
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
              );
            },
            icon: const Icon(Icons.search_rounded, size: 18),
            label: Text(
              'Track Any Order by Order ID / Mobile',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
      body: _orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No orders placed yet',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your past and active deliveries will appear here.',
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                if (index == _orders.length) {
                  // Shopify Web Account banner
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_clock_outlined, color: AppColors.textMuted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Looking for older web orders?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sign in to view your complete web order history',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _launchShopifyOrders,
                          child: Text(
                            'Open Web',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final order = _orders[index];
                final statusColor = _getStatusColor(order.status);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.025),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Order #${order.orderId}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.status,
                              style: GoogleFonts.plusJakartaSans(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Placed on ${Formatters.formatDate(order.orderDate)} • ${order.paymentMethod}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Shipped via ${order.courier} (${order.awbNumber})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Divider(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Amount',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                              ),
                              Text(
                                Formatters.formatPrice(order.totalAmount),
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OrderTrackingScreen(order: order),
                                ),
                              );
                            },
                            icon: const Icon(Icons.local_shipping_rounded, size: 16),
                            label: Text(
                              'Track Shipment',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
