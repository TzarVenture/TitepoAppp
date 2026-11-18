import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/customer_address.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/coupon_selector_modal.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<CustomerAddress> _savedAddresses = [];
  CustomerAddress? _selectedAddress;
  bool _isLoadingAddresses = true;

  // Inline address controllers if no saved address exists
  final _inlineFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _flatController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  final TextEditingController _partyNotesController = TextEditingController();

  // Payment method: 'upi' or 'cod'
  String _selectedPaymentMethod = 'upi';
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pincodeController.dispose();
    _flatController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _partyNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    final rawList = await StorageService.loadAddresses();
    final addresses = rawList
        .map((str) {
          try {
            return CustomerAddress.fromJson(jsonDecode(str));
          } catch (_) {
            return null;
          }
        })
        .whereType<CustomerAddress>()
        .where((a) => a.id != 'addr_default_1' && a.name != 'Pooja Sharma')
        .toList();

    CustomerAddress? defaultAddr;
    if (addresses.isNotEmpty) {
      defaultAddr = addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addresses.first,
      );
    } else {
      // Pre-fill user profile if logged in
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUser != null) {
        _nameController.text = auth.currentUser!.name;
        _phoneController.text = auth.currentUser!.phone;
      }
    }

    if (mounted) {
      setState(() {
        _savedAddresses = addresses;
        _selectedAddress = defaultAddr;
        _isLoadingAddresses = false;
      });
    }
  }

  void _showAddressPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Delivery Address',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: _savedAddresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final addr = _savedAddresses[index];
                  final isSelected = _selectedAddress?.id == addr.id;

                  return InkWell(
                    onTap: () {
                      setState(() => _selectedAddress = addr);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentYellowLight : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.borderLight,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? AppColors.primary : AppColors.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      addr.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        addr.type.toUpperCase(),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  addr.fullAddress,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '📞 +91 ${addr.phone}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  CustomerAddress? _resolveCurrentAddress() {
    if (_selectedAddress != null) {
      return _selectedAddress;
    }

    if (_inlineFormKey.currentState != null && _inlineFormKey.currentState!.validate()) {
      return CustomerAddress(
        id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        pincode: _pincodeController.text.trim(),
        flatHouse: _flatController.text.trim(),
        areaStreet: _streetController.text.trim(),
        landmark: '',
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        type: 'Home',
        isDefault: true,
      );
    }

    return null;
  }

  Future<void> _handlePlaceOrder(CartProvider cart) async {
    final address = _resolveCurrentAddress();

    if (address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please fill or select your complete delivery address.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    // Save newly entered inline address to local storage
    if (_selectedAddress == null) {
      final updatedList = List<CustomerAddress>.from(_savedAddresses)..add(address);
      final rawList = updatedList.map((a) => jsonEncode(a.toJson())).toList();
      await StorageService.saveAddresses(rawList);
    }

    if (!mounted) return;

    // Build real live Shopify cart permalink
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final segments = cart.items.map((item) => '${item.shopifyVariantId}:${item.quantity}').join(',');

    final queryParams = <String, String>{};
    if (cart.appliedCouponCode != null && cart.appliedCouponCode!.trim().isNotEmpty) {
      queryParams['discount'] = cart.appliedCouponCode!.trim();
    }
    final notes = _partyNotesController.text.trim();
    if (notes.isNotEmpty) {
      queryParams['note'] = notes;
    }

    // Prefill customer shipping information on Shopify
    queryParams['checkout[shipping_address][first_name]'] = address.name;
    queryParams['checkout[shipping_address][phone]'] = address.phone;
    queryParams['checkout[shipping_address][address1]'] = address.flatHouse;
    if (address.areaStreet.isNotEmpty) {
      queryParams['checkout[shipping_address][address2]'] = address.areaStreet;
    }
    if (address.city.isNotEmpty) {
      queryParams['checkout[shipping_address][city]'] = address.city;
    }
    if (address.state.isNotEmpty) {
      queryParams['checkout[shipping_address][province]'] = address.state;
    }
    if (address.pincode.isNotEmpty) {
      queryParams['checkout[shipping_address][zip]'] = address.pincode;
    }
    queryParams['checkout[shipping_address][country]'] = 'India';
    if (auth.currentUser?.email != null && auth.currentUser!.email.isNotEmpty) {
      queryParams['checkout[email]'] = auth.currentUser!.email;
    }

    final checkoutUri = Uri.parse('${AppConstants.storeDomain}/cart/$segments')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final launched = await launchUrl(
        checkoutUri,
        mode: LaunchMode.inAppBrowserView,
        browserConfiguration: const BrowserConfiguration(showTitle: true),
      );

      if (!launched) {
        await launchUrl(checkoutUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open checkout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        _showPostCheckoutPrompt(cart, address);
      }
    }
  }

  void _showPostCheckoutPrompt(CartProvider cart, CustomerAddress address) {
    final orderNumController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Status Verification',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Did you complete payment or place your order?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentYellowLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentYellow.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'If you completed checkout on Shopify, enter your Order # from the confirmation screen, SMS or email.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: orderNumController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Shopify Order Number (e.g. #1024)',
                  hintText: 'Enter order number if received',
                  prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final rawNum = orderNumController.text.trim();
                  final orderNum = rawNum.isNotEmpty
                      ? rawNum.replaceAll('#', '')
                      : DateTime.now().millisecondsSinceEpoch.toString().substring(7);
                  final orderId = '#$orderNum';
                  final awbNumber = 'BD-${orderNum.length > 5 ? orderNum : DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

                  final paymentLabel = _selectedPaymentMethod == 'upi'
                      ? 'UPI / Online Payment'
                      : 'Cash on Delivery (COD)';

                  final notes = _partyNotesController.text.trim();
                  final addressText = notes.isNotEmpty
                      ? '${address.name}\n${address.fullAddress}\nPhone: +91 ${address.phone}\nNote: $notes'
                      : '${address.name}\n${address.fullAddress}\nPhone: +91 ${address.phone}';

                  final verifiedOrder = OrderModel(
                    orderId: orderId,
                    orderDate: DateTime.now(),
                    items: List.from(cart.items),
                    totalAmount: cart.grandTotal,
                    status: 'Confirmed',
                    shippingAddress: addressText,
                    paymentMethod: paymentLabel,
                    courier: 'Blue Dart Express',
                    awbNumber: awbNumber,
                    estimatedDelivery: '3 to 5 Business Days',
                    trackingEvents: [
                      TrackingEvent(
                        title: 'Shopify Order Confirmed',
                        description: 'Payment preference verified ($paymentLabel). Order received by Titepo store.',
                        timestamp: 'Just now',
                        isCompleted: true,
                        isCurrent: true,
                      ),
                      const TrackingEvent(
                        title: 'Protective Packaging',
                        description: 'Items sanitized and packed in tamper-evident safety packaging.',
                        timestamp: 'Upcoming',
                        isCompleted: false,
                      ),
                      const TrackingEvent(
                        title: 'Dispatched via Blue Dart Air Express',
                        description: 'Shipping manifest created with live AWB tracking.',
                        timestamp: 'Upcoming',
                        isCompleted: false,
                      ),
                      const TrackingEvent(
                        title: 'Out for Delivery',
                        description: 'Delivery associate will deliver package to your doorstep.',
                        timestamp: 'Upcoming',
                        isCompleted: false,
                      ),
                    ],
                  );

                  await StorageService.addOrder(verifiedOrder);
                  await cart.clearCart();

                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderSuccessScreen(order: verifiedOrder),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(
                  'Yes, Order Completed — Save & View',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Your cart items are saved. You can proceed with payment anytime!'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                },
                child: Text(
                  'Not Yet / Still Browsing (Keep Cart)',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    if (cart.items.isEmpty && !_isPlacingOrder) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(
                'Your Cart is Empty',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Browse Products', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F0),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.lock_outline_rounded, size: 19, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Secure In-App Checkout',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.borderLight)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL PAYABLE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    Formatters.formatPrice(cart.grandTotal),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isPlacingOrder ? null : () => _handlePlaceOrder(cart),
                  icon: _isPlacingOrder
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.lock_rounded, size: 18),
                  label: Text(
                    _isPlacingOrder ? 'Processing...' : 'Proceed to Pay',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Delivery Address Card
            Container(
              padding: const EdgeInsets.all(16),
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
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Delivery Address',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (_savedAddresses.isNotEmpty)
                        TextButton(
                          onPressed: _showAddressPicker,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Change Address',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 20),
                  if (_isLoadingAddresses)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ))
                  else if (_selectedAddress != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _selectedAddress!.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _selectedAddress!.type.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedAddress!.fullAddress,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contact: +91 ${_selectedAddress!.phone}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    )
                  else
                    // Inline address entry form
                    Form(
                      key: _inlineFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter your shipping details below for 1-tap delivery:',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name *',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Mobile Number *',
                                    prefixText: '+91 ',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) => v == null || v.trim().length != 10 ? '10 digits' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _flatController,
                            decoration: const InputDecoration(
                              labelText: 'Flat / House No. / Building Name *',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _streetController,
                            decoration: const InputDecoration(
                              labelText: 'Street / Area / Colony *',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _pincodeController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Pincode *',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) => v == null || v.trim().length != 6 ? '6 digits' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _cityController,
                                  decoration: const InputDecoration(
                                    labelText: 'City *',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. Order Items Preview
            Container(
              padding: const EdgeInsets.all(16),
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
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Order Items (${cart.totalItemCount} pcs)',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        Formatters.formatPrice(cart.subtotal),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ...cart.items.map((item) {
                    final imgUrl = item.product.images.isNotEmpty ? item.product.images.first : '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: imgUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                width: 48,
                                height: 48,
                                color: const Color(0xFFF3F4F6),
                                child: const Icon(Icons.image_outlined, size: 20, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.selectedVariant != null)
                                  Text(
                                    item.selectedVariant!.title,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                Text(
                                  'Qty: ${item.quantity} × ${Formatters.formatPrice(item.unitPrice)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            Formatters.formatPrice(item.totalPrice),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. Payment Method Selection
            Container(
              padding: const EdgeInsets.all(16),
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
                      const Icon(Icons.payment_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Select Payment Option',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // UPI / Online Option
                  InkWell(
                    onTap: () => setState(() => _selectedPaymentMethod = 'upi'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedPaymentMethod == 'upi'
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedPaymentMethod == 'upi' ? AppColors.primary : AppColors.borderLight,
                          width: _selectedPaymentMethod == 'upi' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedPaymentMethod == 'upi'
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: _selectedPaymentMethod == 'upi' ? AppColors.primary : AppColors.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'UPI / Online Payment',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16A34A),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '⚡ FASTEST',
                                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Google Pay, PhonePe, Paytm, BHIM, Cards & NetBanking',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Cash on Delivery Option
                  InkWell(
                    onTap: () => setState(() => _selectedPaymentMethod = 'cod'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedPaymentMethod == 'cod'
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedPaymentMethod == 'cod' ? AppColors.primary : AppColors.borderLight,
                          width: _selectedPaymentMethod == 'cod' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedPaymentMethod == 'cod'
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: _selectedPaymentMethod == 'cod' ? AppColors.primary : AppColors.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cash on Delivery (COD)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pay cash or UPI to courier upon parcel arrival',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 4. Party Gifting Instructions (Optional)
            Container(
              padding: const EdgeInsets.all(16),
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
                      const Icon(Icons.card_giftcard_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Party Gifting Note (Optional)',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _partyNotesController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Birthday kid\'s name: Aarav, 5th Birthday theme, or gift wrap notes...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 5. Coupon / Promo Code Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cart.appliedCouponCode != null
                          ? 'Coupon "${cart.appliedCouponCode}" Applied (-${Formatters.formatPrice(cart.discountAmount)})'
                          : 'Have a coupon code? View offers',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: cart.appliedCouponCode != null ? const Color(0xFF16A34A) : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (cart.appliedCouponCode != null)
                    TextButton(
                      onPressed: () => cart.removeCoupon(),
                      child: const Text('Remove', style: TextStyle(color: AppColors.saleRed, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  else
                    TextButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => CouponSelectorModal(cart: cart),
                        );
                      },
                      child: const Text('Apply', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 6. Bill Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bill Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items Subtotal',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        Formatters.formatPrice(cart.subtotal),
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  if (cart.discountAmount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Promo Discount (${cart.appliedCouponCode})',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF16A34A)),
                        ),
                        Text(
                          '-${Formatters.formatPrice(cart.discountAmount)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shipping & Handling',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        cart.shippingFee == 0 ? 'FREE' : Formatters.formatPrice(cart.shippingFee),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: cart.shippingFee == 0 ? const Color(0xFF16A34A) : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Grand Total',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        Formatters.formatPrice(cart.grandTotal),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w900,
                          fontSize: 19,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 6. Security Assurance
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Text(
                    '100% Safe & Kid-Friendly Certified • Secure Checkout',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
