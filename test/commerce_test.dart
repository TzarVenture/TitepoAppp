import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titepo_app/models/cart_item.dart';
import 'package:titepo_app/models/order.dart';
import 'package:titepo_app/models/product.dart';
import 'package:titepo_app/providers/cart_provider.dart';
import 'package:titepo_app/services/shopify_service.dart';
import 'package:titepo_app/services/storefront_service.dart';
import 'package:titepo_app/services/web_navigation.dart';

class _RealHttp extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => HttpOverrides.global = _RealHttp());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Models', () {
    test('parses Shopify REST product with variants, options and availability', () {
      final p = ProductModel.fromJson({
        'id': 1,
        'title': 'Bottle | Online Return Gift Solution',
        'handle': 'bottle',
        'body_html': '<p>Hi</p>',
        'vendor': 'TITEPO TOYS',
        'product_type': '',
        'tags': 'a, b',
        'options': [
          {'name': 'Color', 'values': ['Red', 'Blue']}
        ],
        'images': [
          {'id': 10, 'src': 'https://cdn.shopify.com/a.jpg'},
          {'id': 11, 'src': 'https://cdn.shopify.com/b.jpg'},
        ],
        'variants': [
          {'id': 100, 'title': 'Red', 'option1': 'Red', 'price': '199.00', 'compare_at_price': '299.00', 'available': false},
          {'id': 101, 'title': 'Blue', 'option1': 'Blue', 'price': '219.00', 'compare_at_price': null, 'available': true, 'image_id': 11},
        ],
      });
      expect(p.displayTitle, 'Bottle');
      expect(p.available, isTrue);
      expect(p.hasRealVariants, isTrue);
      expect(p.firstAvailableVariant!.id, '101');
      expect(p.price, 219.0); // price of first *available* variant
      expect(p.variants[1].image, 'https://cdn.shopify.com/b.jpg');
      expect(p.tags, ['a', 'b']);

      // Round-trips through the offline cache format.
      final cached = ProductModel.fromJson(p.toJson());
      expect(cached.variants.length, 2);
      expect(cached.options.first.values, ['Red', 'Blue']);
      expect(cached.firstAvailableVariant!.id, '101');
    });

    test('cart item never falls back to a different product', () {
      final p = ProductModel(
        id: 'x', title: 't', handle: 'h', description: '', vendor: '', productType: '',
        price: 1, images: const [], variants: const [], tags: const [],
      );
      final item = CartItem(product: p);
      expect(item.shopifyVariantId, isNull);
      expect(item.isPurchasable, isFalse);
    });

    test('order JSON round-trip keeps live status link', () {
      final o = OrderModel(
        orderId: '#1042', orderDate: DateTime(2026, 11, 18), items: const [], totalAmount: 499,
        statusUrl: 'https://titepo.com/checkouts/cn/abc/thank-you',
      );
      final r = OrderModel.fromJson(o.toJson());
      expect(r.statusUrl, o.statusUrl);
      expect(r.orderId, '#1042');
    });
  });

  group('Web navigation', () {
    test('detects Shopify order confirmation URLs', () {
      expect(WebNavigation.isOrderConfirmation('https://titepo.com/checkouts/cn/hWN123/en-in/thank-you'), isTrue);
      expect(WebNavigation.isOrderConfirmation('https://titepo.com/checkouts/c/abc/thank_you'), isTrue);
      expect(WebNavigation.isOrderConfirmation('https://titepo.com/82447925463/orders/9f8e7d'), isTrue);
      expect(WebNavigation.isOrderConfirmation('https://titepo.com/checkouts/cn/hWN123/en-in'), isFalse);
      expect(WebNavigation.isOrderConfirmation('https://titepo.com/cart/c/abc?key=1'), isFalse);
    });

    test('routes payment-app links outside the web view', () {
      expect(WebNavigation.isExternal('upi://pay?pa=x@ybl'), isTrue);
      expect(WebNavigation.isExternal('intent://pay?pa=x#Intent;scheme=upi;end'), isTrue);
      expect(WebNavigation.isExternal('phonepe://pay'), isTrue);
      expect(WebNavigation.isExternal('https://wa.me/917304056607'), isTrue);
      expect(WebNavigation.isExternal('https://titepo.com/checkouts/cn/abc'), isFalse);
    });
  });

  group('Live titepo.com store', () {
    late List<ProductModel> catalog;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      catalog = await ShopifyService().fetchProducts();
    });

    test('loads the full catalogue (not just the first page)', () {
      expect(catalog.length, greaterThan(50));
      expect(catalog.every((p) => p.handle.isNotEmpty), isTrue);
    });

    test('creates a real Shopify cart with line properties and a checkout URL', () async {
      final product = catalog.firstWhere((p) => p.available && p.firstAvailableVariant?.shopifyId != null);
      final item = CartItem(
        product: product,
        quantity: 1,
        attributes: const {'Party message': 'Thanks for coming!'},
      );
      final cart = await StorefrontService().createCart(items: [item], note: 'Automated test — not an order');

      expect(cart.checkoutUrl, startsWith('https://titepo.com/'));
      expect(cart.currencyCode, 'INR');
      expect(cart.subtotal, closeTo(item.unitPrice, 0.01));
      expect(cart.quantityFor(item.shopifyVariantId!), 1);
    });

    test('Shopify rejects an invalid discount code instead of the app inventing one', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = CartProvider();
      final product = catalog.firstWhere((p) => p.available && !p.hasRealVariants);
      await provider.addToCart(product);
      final error = await provider.applyCoupon('NOT-A-REAL-CODE-123');
      expect(error, isNotNull);
      expect(provider.appliedCouponCode, isNull);
      expect(provider.discountAmount, 0);
      provider.dispose();
    });

    test('prepareCheckout returns a checkout URL for the cart', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = CartProvider();
      final product = catalog.firstWhere((p) => p.available && !p.hasRealVariants);
      await provider.addToCart(product, quantity: 2);
      final prep = await provider.prepareCheckout();
      expect(prep.cart.checkoutUrl, contains('/cart/c/'));
      expect(prep.cart.total, greaterThan(0));
      provider.dispose();
    });
  });
}
