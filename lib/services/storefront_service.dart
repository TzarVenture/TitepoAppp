import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/cart_item.dart';

/// Thrown when Shopify rejects a request or is unreachable.
class StorefrontException implements Exception {
  final String message;
  StorefrontException(this.message);
  @override
  String toString() => message;
}

class ShopifyDiscountCode {
  final String code;
  final bool applicable;
  const ShopifyDiscountCode(this.code, this.applicable);
}

class ShopifyCartLine {
  final String variantId; // numeric id
  final int quantity;
  final double subtotal;
  final double total;
  const ShopifyCartLine({
    required this.variantId,
    required this.quantity,
    required this.subtotal,
    required this.total,
  });
}

/// A cart that lives on Shopify. All money values come from Shopify, so what
/// the app shows is exactly what the customer is charged at checkout.
class ShopifyCart {
  final String id;
  final String checkoutUrl;
  final double subtotal;
  final double total;
  final String currencyCode;
  final List<ShopifyDiscountCode> discountCodes;
  final List<ShopifyCartLine> lines;
  final List<String> warnings;

  const ShopifyCart({
    required this.id,
    required this.checkoutUrl,
    required this.subtotal,
    required this.total,
    required this.currencyCode,
    required this.discountCodes,
    required this.lines,
    required this.warnings,
  });

  double get discountTotal => (subtotal - total).clamp(0, double.infinity).toDouble();

  int quantityFor(String variantId) =>
      lines.where((l) => l.variantId == variantId).fold(0, (s, l) => s + l.quantity);
}

class BuyerDetails {
  final String? email;
  final String? phone;
  const BuyerDetails({this.email, this.phone});
}

/// Shopify Storefront GraphQL API — cart & checkout.
///
/// Works with tokenless access (cart, products, collections). If
/// [AppConstants.storefrontAccessToken] is set it is sent as well.
class StorefrontService {
  final http.Client _client;
  StorefrontService({http.Client? client}) : _client = client ?? http.Client();

  static Uri get _endpoint =>
      Uri.parse('${AppConstants.storeDomain}/api/${AppConstants.storefrontApiVersion}/graphql.json');

  static const String _cartFields = r'''
    id
    checkoutUrl
    cost {
      subtotalAmount { amount currencyCode }
      totalAmount { amount currencyCode }
    }
    discountCodes { code applicable }
    lines(first: 100) {
      nodes {
        quantity
        merchandise { ... on ProductVariant { id } }
        cost { subtotalAmount { amount } totalAmount { amount } }
      }
    }
  ''';

  Future<Map<String, dynamic>> _query(String query, Map<String, dynamic> variables) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (AppConstants.storefrontAccessToken.isNotEmpty) {
      headers['X-Shopify-Storefront-Access-Token'] = AppConstants.storefrontAccessToken;
    }

    http.Response res;
    try {
      res = await _client
          .post(_endpoint, headers: headers, body: jsonEncode({'query': query, 'variables': variables}))
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw StorefrontException('Could not reach the Titepo store. Please check your internet connection.');
    }

    if (res.statusCode != 200) {
      throw StorefrontException('Store is temporarily unavailable (${res.statusCode}). Please try again.');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      throw StorefrontException(errors.map((e) => e['message']).join('. '));
    }
    return body['data'] as Map<String, dynamic>;
  }

  /// Create a Shopify cart from the app's cart items.
  Future<ShopifyCart> createCart({
    required List<CartItem> items,
    List<String> discountCodes = const [],
    String? note,
    BuyerDetails? buyer,
  }) async {
    final lines = <Map<String, dynamic>>[];
    for (final item in items) {
      final vid = item.shopifyVariantId;
      if (vid == null) continue;
      lines.add({
        'merchandiseId': 'gid://shopify/ProductVariant/$vid',
        'quantity': item.quantity,
        if (item.attributes.isNotEmpty)
          'attributes': item.attributes.entries
              .where((e) => e.value.trim().isNotEmpty)
              .map((e) => {'key': e.key, 'value': e.value})
              .toList(),
      });
    }
    if (lines.isEmpty) {
      throw StorefrontException('None of the items in your cart can be purchased right now.');
    }

    final buyerIdentity = <String, dynamic>{'countryCode': 'IN'};
    if (buyer?.email != null && buyer!.email!.contains('@')) buyerIdentity['email'] = buyer.email;
    final phone = _normalisePhone(buyer?.phone);
    if (phone != null) buyerIdentity['phone'] = phone;

    const mutation = '''
      mutation CartCreate(\$input: CartInput!) {
        cartCreate(input: \$input) {
          cart { $_cartFields }
          userErrors { field message }
          warnings { code message }
        }
      }
    ''';

    Map<String, dynamic> data;
    try {
      data = await _query(mutation, {
        'input': {
          'lines': lines,
          'buyerIdentity': buyerIdentity,
          if (discountCodes.isNotEmpty) 'discountCodes': discountCodes,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        }
      });
    } on StorefrontException {
      if (buyerIdentity.length > 1) {
        // Retry without optional buyer details if Shopify rejected them.
        return createCart(items: items, discountCodes: discountCodes, note: note);
      }
      rethrow;
    }

    final result = data['cartCreate'] as Map<String, dynamic>?;
    final userErrors = (result?['userErrors'] as List?) ?? [];
    if (userErrors.isNotEmpty) {
      final msg = userErrors.map((e) => e['message']).join('. ');
      if (buyerIdentity.length > 1 && msg.toLowerCase().contains(RegExp('phone|email|buyer'))) {
        return createCart(items: items, discountCodes: discountCodes, note: note);
      }
      throw StorefrontException(msg);
    }

    final cart = result?['cart'];
    if (cart == null) throw StorefrontException('Shopify could not create your cart. Please try again.');

    final warnings = ((result?['warnings'] as List?) ?? []).map((w) => w['message'].toString()).toList();
    return _parseCart(cart as Map<String, dynamic>, warnings);
  }

  ShopifyCart _parseCart(Map<String, dynamic> cart, List<String> warnings) {
    double amt(dynamic m) => double.tryParse(m?['amount']?.toString() ?? '') ?? 0;
    final lines = <ShopifyCartLine>[];
    for (final n in (cart['lines']?['nodes'] as List? ?? [])) {
      final gid = n['merchandise']?['id']?.toString() ?? '';
      lines.add(ShopifyCartLine(
        variantId: gid.split('/').last,
        quantity: (n['quantity'] as num?)?.toInt() ?? 0,
        subtotal: amt(n['cost']?['subtotalAmount']),
        total: amt(n['cost']?['totalAmount']),
      ));
    }
    return ShopifyCart(
      id: cart['id'].toString(),
      checkoutUrl: cart['checkoutUrl'].toString(),
      subtotal: amt(cart['cost']?['subtotalAmount']),
      total: amt(cart['cost']?['totalAmount']),
      currencyCode: cart['cost']?['totalAmount']?['currencyCode']?.toString() ?? 'INR',
      discountCodes: (cart['discountCodes'] as List? ?? [])
          .map((d) => ShopifyDiscountCode(d['code'].toString(), d['applicable'] == true))
          .toList(),
      lines: lines,
      warnings: warnings,
    );
  }

  /// Shopify expects E.164 (+91XXXXXXXXXX).
  static String? _normalisePhone(String? raw) {
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) return '+91$digits';
    if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
    return null;
  }
}
