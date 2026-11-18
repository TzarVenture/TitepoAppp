import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../services/storage_service.dart';
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
  OrderModel? _currentOrder;
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _searchedQuery;
  List<OrderModel> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    final initialId = widget.order?.orderId ?? widget.initialOrderId ?? '';
    _lookupController = TextEditingController(text: initialId);
    _currentOrder = widget.order;
    _hasSearched = widget.order != null;
    _loadRecentOrders();
  }

  @override
  void dispose() {
    _lookupController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentOrders() async {
    final list = await StorageService.loadOrders();
    if (mounted) {
      setState(() {
        _recentOrders = list;
      });
      // If an initial order ID was passed without an OrderModel, auto-lookup
      if (widget.order == null && widget.initialOrderId != null && widget.initialOrderId!.trim().isNotEmpty) {
        _performLookup();
      }
    }
  }

  Future<void> _performLookup() async {
    final query = _lookupController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an Order ID or AWB number')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchedQuery = query;
    });

    final cleanQuery = query.replaceAll('#', '').trim().toLowerCase();
    final orders = await StorageService.loadOrders();

    OrderModel? match;
    for (final o in orders) {
      final oId = o.orderId.replaceAll('#', '').trim().toLowerCase();
      final awb = o.awbNumber.trim().toLowerCase();
      if (oId == cleanQuery || (awb.isNotEmpty && awb == cleanQuery)) {
        match = o;
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _currentOrder = match;
    });
  }

  void _launchLiveWebTracking() async {
    final Uri url = Uri.parse(AppConstants.orderTrackingUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.inAppBrowserView,
        browserConfiguration: const BrowserConfiguration(showTitle: true),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open tracking page.')),
      );
    }
  }

  void _launchWhatsAppOrderInquiry(String query) async {
    final text = 'Hi Titepo team, could you please provide a tracking update for my order #$query?';
    final Uri url = Uri.parse('https://wa.me/919876543210?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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

  List<TrackingEvent> _resolveTrackingEvents(OrderModel order) {
    if (order.trackingEvents.isNotEmpty) return order.trackingEvents;
    final s = order.status.toLowerCase();
    final dateStr = Formatters.formatDate(order.orderDate);

    if (s == 'delivered') {
      return [
        const TrackingEvent(
          title: 'Delivered Successfully',
          description: 'Shipment delivered and handed over safely.',
          timestamp: 'Delivered',
          isCompleted: true,
          isCurrent: true,
        ),
        const TrackingEvent(
          title: 'Out for Delivery',
          description: 'Delivery associate is en route to your location.',
          timestamp: 'Out for delivery',
          isCompleted: true,
        ),
        const TrackingEvent(
          title: 'Arrived at Local Delivery Hub',
          description: 'Parcel reached destination sorting center.',
          timestamp: 'In transit',
          isCompleted: true,
        ),
        const TrackingEvent(
          title: 'Dispatched from Warehouse',
          description: 'Packed securely in kid-safe tamper-evident box.',
          timestamp: 'Dispatched',
          isCompleted: true,
        ),
        TrackingEvent(
          title: 'Order Confirmed',
          description: 'Order confirmed and verified.',
          timestamp: dateStr,
          isCompleted: true,
        ),
      ];
    } else if (s.contains('out for delivery')) {
      return [
        const TrackingEvent(
          title: 'Out for Delivery',
          description: 'Courier executive is en route with your package.',
          timestamp: 'Today',
          isCompleted: true,
          isCurrent: true,
        ),
        const TrackingEvent(
          title: 'Arrived at Local Hub',
          description: 'Parcel reached regional distribution hub.',
          timestamp: 'Arrived',
          isCompleted: true,
        ),
        const TrackingEvent(
          title: 'Dispatched from Warehouse',
          description: 'Handed over to courier express partner.',
          timestamp: 'Dispatched',
          isCompleted: true,
        ),
        TrackingEvent(
          title: 'Order Confirmed',
          description: 'Order confirmed and verified.',
          timestamp: dateStr,
          isCompleted: true,
        ),
      ];
    } else if (s.contains('dispatch') || s.contains('shipped') || s.contains('transit')) {
      return [
        const TrackingEvent(
          title: 'In Transit',
          description: 'Package in transit with courier partner.',
          timestamp: 'In transit',
          isCompleted: true,
          isCurrent: true,
        ),
        const TrackingEvent(
          title: 'Dispatched from Warehouse',
          description: 'Packed securely and handed over to courier.',
          timestamp: 'Dispatched',
          isCompleted: true,
        ),
        TrackingEvent(
          title: 'Order Confirmed',
          description: 'Order confirmed and verified.',
          timestamp: dateStr,
          isCompleted: true,
        ),
      ];
    }

    return [
      TrackingEvent(
        title: 'Order Received & Processing',
        description: 'Inventory allocated and preparing for shipment.',
        timestamp: dateStr,
        isCompleted: true,
        isCurrent: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
                builder: (_) => ContactSupportModal(orderId: _currentOrder?.orderId),
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
                          hintText: 'Order ID or AWB (e.g. 1001)',
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

            // Content switch: Found Order vs Search Not Found vs Initial Guidance
            if (_currentOrder != null)
              _buildFoundOrderView(_currentOrder!)
            else if (_hasSearched)
              _buildNotFoundView()
            else
              _buildInitialGuidanceView(),
          ],
        ),
      ),
    );
  }

  Widget _buildFoundOrderView(OrderModel order) {
    final statusColor = _getStatusColor(order.status);
    final events = _resolveTrackingEvents(order);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                        'Order #${order.orderId}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Placed on ${Formatters.formatDate(order.orderDate)}',
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
                      order.status,
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
                          order.courier.isNotEmpty ? order.courier : 'Express Surface Dispatch',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (order.awbNumber.isNotEmpty)
                          Row(
                            children: [
                              Text(
                                'AWB: ${order.awbNumber}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: order.awbNumber));
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
                          )
                        else
                          Text(
                            'AWB tracking number assigned upon dispatch',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              if (order.estimatedDelivery.isNotEmpty) ...[
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
                          'Estimated Delivery: ${order.estimatedDelivery}',
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
                    'Shipment Timeline',
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
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final isLast = index == events.length - 1;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

        if (order.shippingAddress.isNotEmpty) ...[
          const SizedBox(height: 16),
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
                  order.shippingAddress,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],

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
                builder: (_) => ContactSupportModal(orderId: order.orderId),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: Text(
              'Need Help with this Order?',
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
    );
  }

  Widget _buildNotFoundView() {
    final query = _searchedQuery ?? _lookupController.text;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: Color(0xFFD97706),
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Order #$query Not Found Locally',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We could not find order #$query in this device\'s recent local app history.\n\nIf you placed this order on titepo.com or via WhatsApp, you can track it live via our official web portal or message our customer support team directly.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _launchLiveWebTracking,
              icon: const Icon(Icons.open_in_browser_rounded, size: 18),
              label: Text(
                'Track on Titepo.com',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _launchWhatsAppOrderInquiry(query),
              icon: const Icon(Icons.chat_rounded, color: Color(0xFF16A34A), size: 18),
              label: Text(
                'Ask WhatsApp Support for #$query',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF16A34A),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF16A34A)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildInitialGuidanceView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_recentOrders.isNotEmpty) ...[
            Text(
              'Your Recent App Orders',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap any order to view live dispatch & delivery status',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_recentOrders.length, (index) {
              final o = _recentOrders[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                    ),
                    title: Text(
                      'Order #${o.orderId}',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    subtitle: Text(
                      '${Formatters.formatDate(o.orderDate)} • ${o.status}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                    onTap: () {
                      setState(() {
                        _lookupController.text = o.orderId;
                        _currentOrder = o;
                        _hasSearched = true;
                      });
                    },
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Guidance Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_searching_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Track Any Titepo Parcel',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Live courier tracking & dispatch updates',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  '💡 Where can I find my Order ID?',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Check your order confirmation SMS or WhatsApp from Titepo\n'
                  '• Look for the receipt email sent from orders@titepo.com\n'
                  '• Enter either the 4-6 digit Order ID or the Courier AWB number above.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _launchLiveWebTracking,
                    icon: const Icon(Icons.language_rounded, size: 16),
                    label: Text(
                      'Open Official Web Tracking Portal',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}
