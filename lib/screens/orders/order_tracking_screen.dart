import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../widgets/contact_support_modal.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel? order;
  final String? initialOrderId;

  const OrderTrackingScreen({
    super.key,
    this.order,
    this.initialOrderId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late final TextEditingController _lookupController;
  late OrderModel _currentOrder;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _lookupController = TextEditingController(
      text: widget.order?.orderId ?? widget.initialOrderId ?? 'TP-98231',
    );
    _currentOrder = widget.order ?? _getMockOrder(_lookupController.text);
  }

  @override
  void dispose() {
    _lookupController.dispose();
    super.dispose();
  }

  OrderModel _getMockOrder(String id) {
    final cleanId = id.trim().toUpperCase();
    if (cleanId.contains('98104')) {
      return OrderModel(
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
      );
    }

    // Default active shipment order
    return OrderModel(
      orderId: cleanId.isEmpty ? 'TP-98231' : cleanId,
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
    );
  }

  void _performLookup() {
    final query = _lookupController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an Order ID or AWB number')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _currentOrder = _getMockOrder(query);
      });
    });
  }

  void _launchLiveWebTracking() async {
    final Uri url = Uri.parse(AppConstants.orderTrackingUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open tracking page.')),
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_currentOrder.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Track Shipment',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Support',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ContactSupportModal(orderId: _currentOrder.orderId),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order Lookup Search Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _lookupController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Search Order ID (e.g. TP-98231)',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _performLookup(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSearching ? null : _performLookup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Track',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Order Status Overview Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order ${_currentOrder.orderId}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Placed on ${Formatters.formatDate(_currentOrder.orderDate)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _currentOrder.status,
                          style: GoogleFonts.plusJakartaSans(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Courier & AWB Info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentYellowLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentOrder.courier,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  'AWB: ${_currentOrder.awbNumber}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: _currentOrder.awbNumber));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('AWB copied to clipboard! 📋'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (_currentOrder.estimatedDelivery.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF16A34A)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Estimated Delivery: ${_currentOrder.estimatedDelivery}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Live Timeline Tracking Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Shipment Progress',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _launchLiveWebTracking,
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: Text(
                          'Web Tracker',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tracking Steps List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _currentOrder.trackingEvents.length,
                    itemBuilder: (context, index) {
                      final event = _currentOrder.trackingEvents[index];
                      final isLast = index == _currentOrder.trackingEvents.length - 1;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline indicator line and dot
                          Column(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: event.isCurrent
                                      ? AppColors.primary
                                      : (event.isCompleted ? AppColors.success : const Color(0xFFE5E7EB)),
                                  shape: BoxShape.circle,
                                  boxShadow: event.isCurrent
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.35),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Icon(
                                    event.isCompleted ? Icons.check_rounded : Icons.radio_button_unchecked,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 48,
                                  color: event.isCompleted ? AppColors.success : const Color(0xFFE5E7EB),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          // Step Details
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: event.isCurrent ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 13.5,
                                      color: event.isCurrent ? AppColors.primary : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    event.description,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    event.timestamp,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Shipping Address Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Delivery Address',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentOrder.shippingAddress,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Help & Support Shortcut
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ContactSupportModal(orderId: _currentOrder.orderId),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text(
                  'Need Help with this Delivery?',
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

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
