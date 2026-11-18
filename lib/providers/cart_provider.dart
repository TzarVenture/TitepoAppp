import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/return_gift_bundle.dart';
import '../services/storage_service.dart';
import '../services/storefront_service.dart';

/// Result of preparing a real Shopify checkout.
class CheckoutPreparation {
  final ShopifyCart cart;

  /// Messages about lines Shopify changed (e.g. limited stock).
  final List<String> adjustments;
  const CheckoutPreparation(this.cart, this.adjustments);
}

class CartProvider with ChangeNotifier {
  final StorefrontService _storefront;
  CartProvider({StorefrontService? storefront}) : _storefront = storefront ?? StorefrontService();

  List<CartItem> _items = [];
  String? _appliedCouponCode;
  String? _orderNote;

  /// Latest pricing from Shopify for the current cart contents.
  ShopifyCart? _quote;
  bool _isQuoting = false;
  String? _quoteError;
  Timer? _quoteDebounce;
  int _quoteGeneration = 0;

  List<CartItem> get items => List.unmodifiable(_items);
  String? get appliedCouponCode => _appliedCouponCode;
  String? get orderNote => _orderNote;
  ShopifyCart? get quote => _quote;
  bool get isQuoting => _isQuoting;
  String? get quoteError => _quoteError;
  bool get isEmpty => _items.isEmpty;

  int get totalItemCount => _items.fold(0, (s, i) => s + i.quantity);

  /// Subtotal computed from catalogue prices (shown until Shopify responds).
  double get subtotal => _items.fold(0.0, (s, i) => s + i.totalPrice);

  /// Discount confirmed by Shopify.
  double get discountAmount => _quote?.discountTotal ?? 0.0;

  /// Total confirmed by Shopify (before shipping, which is chosen at checkout).
  double get grandTotal => _quote?.total ?? subtotal;

  List<CartItem> get unavailableItems => _items.where((i) => !i.isPurchasable).toList();

  int quantityInCart(String productId) =>
      _items.where((i) => i.product.id == productId).fold(0, (s, i) => s + i.quantity);

  Future<void> initCart() async {
    _items = await StorageService.loadCart();
    _appliedCouponCode = await StorageService.loadAppliedCoupon();
    notifyListeners();
    _scheduleQuote(immediate: true);
  }

  // ── Mutations ────────────────────────────────────────────────────────────

  Future<void> addToCart(
    ProductModel product, {
    ProductVariant? variant,
    int quantity = 1,
    Map<String, String>? attributes,
    String? customNotes,
  }) async {
    final chosen = variant ?? product.firstAvailableVariant;
    final candidate = CartItem(
      product: product,
      selectedVariant: chosen,
      quantity: quantity,
      attributes: attributes,
      customNotes: customNotes,
    );
    final idx = _items.indexWhere((i) => i.cartKey == candidate.cartKey);
    if (idx >= 0) {
      _items[idx].quantity += quantity;
    } else {
      _items.add(candidate);
    }
    await _persistAndRequote();
  }

  /// Adds a return-gift bundle: the bag (with its customisation as Shopify
  /// line-item properties) plus every accessory × number of bags.
  Future<void> addReturnGiftBundle(ReturnGiftBundle bundle) async {
    final bag = bundle.selectedBag;
    if (bag == null) return;

    final summaries = <String>[];
    bundle.selectedItems.forEach((pId, qty) {
      final acc = bundle.accessoriesMap[pId];
      if (acc != null) summaries.add('${acc.displayTitle} ×$qty');
    });

    final attributes = <String, String>{
      'Bag type': bundle.isCustomBag ? 'Custom printed bag' : bag.displayTitle,
      if (summaries.isNotEmpty) 'Fill each bag with': summaries.join(', '),
      if (bundle.customDesignNotes.trim().isNotEmpty) 'Design notes': bundle.customDesignNotes.trim(),
      if (bundle.customPartyMessage.trim().isNotEmpty) 'Party message': bundle.customPartyMessage.trim(),
      if (bundle.isCustomBag && bundle.customImageBytes != null)
        'Artwork': 'Customer will share artwork on WhatsApp (${bundle.customImageFileName ?? "image"})',
    };

    final notes = bundle.isCustomBag
        ? 'Custom bag${bundle.customDesignNotes.isNotEmpty ? ": ${bundle.customDesignNotes}" : ""}'
        : 'Theme bag: ${bag.displayTitle}';

    _items.add(CartItem(
      product: bag,
      selectedVariant: bag.firstAvailableVariant,
      quantity: bundle.numberOfBags,
      customNotes: summaries.isEmpty ? notes : '$notes\nInside each bag: ${summaries.join(", ")}',
      bundleItemSummaries: summaries,
      attributes: attributes,
    ));

    bundle.selectedItems.forEach((pId, qtyPerBag) {
      final acc = bundle.accessoriesMap[pId];
      if (acc == null) return;
      _items.add(CartItem(
        product: acc,
        selectedVariant: acc.firstAvailableVariant,
        quantity: qtyPerBag * bundle.numberOfBags,
        customNotes: 'For return gift bags (${bag.displayTitle})',
        attributes: {'Return gift bag': bag.displayTitle},
      ));
    });

    await _persistAndRequote();
  }

  Future<void> updateQuantity(String cartKey, int delta) async {
    final index = _items.indexWhere((item) => item.cartKey == cartKey);
    if (index < 0) return;
    _items[index].quantity += delta;
    if (_items[index].quantity <= 0) _items.removeAt(index);
    await _persistAndRequote();
  }

  Future<void> setQuantity(String cartKey, int quantity) async {
    final index = _items.indexWhere((item) => item.cartKey == cartKey);
    if (index < 0) return;
    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = quantity;
    }
    await _persistAndRequote();
  }

  Future<void> removeFromCart(String cartKey) async {
    _items.removeWhere((item) => item.cartKey == cartKey);
    await _persistAndRequote();
  }

  void setOrderNote(String? note) {
    _orderNote = (note == null || note.trim().isEmpty) ? null : note.trim();
  }

  Future<void> clearCart() async {
    _items.clear();
    _appliedCouponCode = null;
    _orderNote = null;
    _quote = null;
    _quoteError = null;
    await StorageService.saveCart(_items);
    await StorageService.saveAppliedCoupon(null);
    notifyListeners();
  }

  // ── Discount codes (validated by Shopify) ────────────────────────────────

  /// Returns null on success, or a message explaining why the code was rejected.
  Future<String?> applyCoupon(String code) async {
    final formatted = code.trim().toUpperCase();
    if (formatted.isEmpty) return 'Enter a discount code.';
    if (_items.isEmpty) return 'Add items to your cart first.';

    try {
      final cart = await _storefront.createCart(items: _items, discountCodes: [formatted]);
      final match = cart.discountCodes.where((d) => d.code.toUpperCase() == formatted);
      if (match.isEmpty || !match.first.applicable) {
        return '"$formatted" isn\'t valid for the items in your cart.';
      }
      _appliedCouponCode = formatted;
      _quote = cart;
      _quoteError = null;
      await StorageService.saveAppliedCoupon(formatted);
      notifyListeners();
      return null;
    } on StorefrontException catch (e) {
      return e.message;
    }
  }

  Future<void> removeCoupon() async {
    _appliedCouponCode = null;
    await StorageService.saveAppliedCoupon(null);
    _quote = null;
    notifyListeners();
    _scheduleQuote(immediate: true);
  }

  // ── Shopify pricing & checkout ───────────────────────────────────────────

  Future<void> refreshQuote() => _runQuote();

  /// Builds a fresh Shopify cart for checkout and reconciles quantities
  /// that Shopify adjusted (e.g. not enough stock).
  Future<CheckoutPreparation> prepareCheckout({BuyerDetails? buyer}) async {
    final purchasable = _items.where((i) => i.isPurchasable).toList();
    if (purchasable.isEmpty) {
      throw StorefrontException('Your cart has no items that can be ordered right now.');
    }

    final cart = await _storefront.createCart(
      items: purchasable,
      discountCodes: _appliedCouponCode != null ? [_appliedCouponCode!] : const [],
      note: _orderNote,
      buyer: buyer,
    );

    final adjustments = <String>[];
    // Compare requested vs. accepted quantity per variant.
    final requested = <String, int>{};
    for (final i in purchasable) {
      requested.update(i.shopifyVariantId!, (q) => q + i.quantity, ifAbsent: () => i.quantity);
    }
    requested.forEach((vid, want) {
      final got = cart.quantityFor(vid);
      if (got < want) {
        final item = purchasable.firstWhere((i) => i.shopifyVariantId == vid);
        adjustments.add(got == 0
            ? '${item.product.displayTitle} is out of stock and was removed.'
            : 'Only $got of ${item.product.displayTitle} available — quantity updated.');
        _reduceVariantTo(vid, got);
      }
    });

    if (adjustments.isNotEmpty) {
      await StorageService.saveCart(_items);
    }
    _quote = cart;
    _quoteError = null;
    notifyListeners();
    return CheckoutPreparation(cart, adjustments);
  }

  void _reduceVariantTo(String variantId, int allowed) {
    var remaining = allowed;
    for (final item in _items.where((i) => i.shopifyVariantId == variantId).toList()) {
      if (remaining <= 0) {
        _items.remove(item);
      } else if (item.quantity > remaining) {
        item.quantity = remaining;
        remaining = 0;
      } else {
        remaining -= item.quantity;
      }
    }
  }

  Future<void> _persistAndRequote() async {
    _quote = null;
    notifyListeners();
    await StorageService.saveCart(_items);
    _scheduleQuote();
  }

  void _scheduleQuote({bool immediate = false}) {
    _quoteDebounce?.cancel();
    if (_items.isEmpty) {
      _quote = null;
      _quoteError = null;
      _isQuoting = false;
      notifyListeners();
      return;
    }
    _quoteDebounce = Timer(Duration(milliseconds: immediate ? 0 : 700), _runQuote);
  }

  Future<void> _runQuote() async {
    if (_items.where((i) => i.isPurchasable).isEmpty) return;
    final generation = ++_quoteGeneration;
    _isQuoting = true;
    notifyListeners();
    try {
      final cart = await _storefront.createCart(
        items: _items.where((i) => i.isPurchasable).toList(),
        discountCodes: _appliedCouponCode != null ? [_appliedCouponCode!] : const [],
      );
      if (generation != _quoteGeneration) return;
      _quote = cart;
      _quoteError = null;

      // Drop a saved code that is no longer applicable (e.g. cart changed).
      if (_appliedCouponCode != null &&
          !cart.discountCodes.any((d) => d.code.toUpperCase() == _appliedCouponCode && d.applicable)) {
        _quoteError = 'Code $_appliedCouponCode no longer applies to this cart and was removed.';
        _appliedCouponCode = null;
        await StorageService.saveAppliedCoupon(null);
      }
    } on StorefrontException catch (e) {
      if (generation != _quoteGeneration) return;
      _quoteError = e.message;
    } finally {
      if (generation == _quoteGeneration) {
        _isQuoting = false;
        notifyListeners();
      }
    }
  }

  bool _disposed = false;

  /// In-flight Shopify requests may complete after disposal — ignore them.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _quoteGeneration++; // invalidate any in-flight quote
    _quoteDebounce?.cancel();
    super.dispose();
  }
}
