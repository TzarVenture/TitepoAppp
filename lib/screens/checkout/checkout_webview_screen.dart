import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../providers/cart_provider.dart';
import '../../services/storage_service.dart';
import '../../services/web_navigation.dart';
import 'order_success_screen.dart';

/// Real Shopify checkout (titepo.com) inside the app.
///
/// Payment, shipping, address and order creation are all handled by Shopify.
/// When Shopify shows its thank-you page, the order is recorded on this device
/// (with its live order-status link) and the cart is cleared.
class CheckoutWebViewScreen extends StatefulWidget {
  final String checkoutUrl;
  final List<CartItem> items;
  final double expectedTotal;
  final String? discountCode;

  /// False for "Buy now", which checks out a single item without the saved cart.
  final bool clearCartOnComplete;

  const CheckoutWebViewScreen({
    super.key,
    required this.checkoutUrl,
    required this.items,
    required this.expectedTotal,
    this.discountCode,
    this.clearCartOnComplete = true,
  });

  @override
  State<CheckoutWebViewScreen> createState() => _CheckoutWebViewScreenState();
}

class _CheckoutWebViewScreenState extends State<CheckoutWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _orderCompleted = false;
  bool _handlingCompletion = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => mounted ? setState(() => _progress = p) : null,
        onNavigationRequest: (request) async {
          if (WebNavigation.isExternal(request.url)) {
            final ok = await WebNavigation.launchExternal(request.url);
            if (!ok && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Payment app not found. Please choose another payment method.'),
              ));
            }
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onUrlChange: (change) {
          final url = change.url;
          if (url != null && WebNavigation.isOrderConfirmation(url)) _onOrderConfirmed(url);
        },
        onPageFinished: (url) {
          if (WebNavigation.isOrderConfirmation(url)) _onOrderConfirmed(url);
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame == true && mounted) {
            setState(() => _loadError = error.description);
          }
        },
      ))
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  Future<void> _onOrderConfirmed(String url) async {
    if (_handlingCompletion) return;
    _handlingCompletion = true;
    setState(() => _orderCompleted = true);

    // The cart has been converted into a real Shopify order — clear it now.
    if (widget.clearCartOnComplete) {
      await context.read<CartProvider>().clearCart();
    }

    // Thank-you page is client-rendered; poll for the order number briefly.
    String orderNumber = '';
    String email = '';
    for (var i = 0; i < 12 && orderNumber.isEmpty; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      try {
        final r = await _controller.runJavaScriptReturningResult(WebNavigation.extractOrderNumberJs);
        orderNumber = _clean(r);
        if (email.isEmpty) {
          email = _clean(await _controller.runJavaScriptReturningResult(WebNavigation.extractEmailJs));
        }
      } catch (_) {}
    }

    double? paidTotal;
    try {
      final raw = _clean(await _controller.runJavaScriptReturningResult(WebNavigation.extractTotalJs));
      paidTotal = double.tryParse(raw.replaceAll(',', ''));
    } catch (_) {}

    final order = OrderModel(
      orderId: orderNumber.isNotEmpty ? '#$orderNumber' : 'Order ${DateTime.now().millisecondsSinceEpoch % 1000000}',
      orderDate: DateTime.now(),
      items: widget.items,
      totalAmount: (paidTotal != null && paidTotal > 0) ? paidTotal : widget.expectedTotal,
      statusUrl: url,
      email: email.isNotEmpty ? email : null,
      discountCode: widget.discountCode,
    );
    await StorageService.addOrder(order);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
    );
  }

  String _clean(Object? raw) {
    var s = raw?.toString() ?? '';
    if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) s = s.substring(1, s.length - 1);
    return s == 'null' ? '' : s.trim();
  }

  Future<bool> _confirmLeave() async {
    if (_orderCompleted) return true;
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    if (!mounted) return false;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave checkout?'),
        content: const Text('Your order has not been placed yet. Your cart will be saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(80, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmLeave()) navigator.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (_orderCompleted) return;
              final shouldLeave = await _confirmLeave();
              if (shouldLeave) navigator.pop();
            },
          ),
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, size: 18, color: AppColors.success),
              SizedBox(width: 6),
              Text('Secure checkout', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
          centerTitle: true,
          bottom: _progress < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    minHeight: 3,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primarySoft,
                  ),
                )
              : null,
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loadError != null) _buildError(),
            if (_orderCompleted) _buildFinalising(),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text('Checkout could not load', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Check your connection and try again. Your cart is saved.', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              setState(() => _loadError = null);
              _controller.loadRequest(Uri.parse(widget.checkoutUrl));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalising() {
    return Container(
      color: Colors.white.withValues(alpha: 0.94),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 44, height: 44, child: CircularProgressIndicator(strokeWidth: 3)),
          SizedBox(height: 18),
          Text('Order placed! Fetching your receipt…', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
