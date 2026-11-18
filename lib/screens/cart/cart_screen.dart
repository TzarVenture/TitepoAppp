import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/cart_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/storefront_service.dart';
import '../../widgets/ui_kit.dart';
import '../checkout/checkout_webview_screen.dart';
import '../main_navigation.dart';
import '../product/product_details_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _codeController = TextEditingController();
  final _noteController = TextEditingController();
  bool _applyingCode = false;
  String? _codeError;
  bool _startingCheckout = false;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartProvider>();
    _noteController.text = cart.orderNote ?? '';
    if (cart.quote == null && !cart.isEmpty) cart.refreshQuote();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _applyCode(CartProvider cart) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _applyingCode = true;
      _codeError = null;
    });
    final error = await cart.applyCoupon(_codeController.text);
    if (!mounted) return;
    setState(() {
      _applyingCode = false;
      _codeError = error;
    });
    if (error == null) {
      _codeController.clear();
      showAppSnack(context, 'Discount applied 🎉');
    }
  }

  Future<void> _checkout(CartProvider cart) async {
    FocusScope.of(context).unfocus();
    cart.setOrderNote(_noteController.text);
    final user = context.read<AuthProvider>().currentUser;

    setState(() => _startingCheckout = true);
    try {
      final itemsSnapshot = cart.items.where((i) => i.isPurchasable).toList();
      final prep = await cart.prepareCheckout(
        buyer: BuyerDetails(email: user?.email, phone: user?.phone),
      );
      if (!mounted) return;

      if (prep.adjustments.isNotEmpty) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cart updated'),
            content: Text(prep.adjustments.join('\n\n')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Review cart')),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(80, 44)),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
        if (proceed != true || !mounted || cart.isEmpty) return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutWebViewScreen(
            checkoutUrl: prep.cart.checkoutUrl,
            items: prep.adjustments.isEmpty ? itemsSnapshot : cart.items.where((i) => i.isPurchasable).toList(),
            expectedTotal: prep.cart.total,
            discountCode: cart.appliedCouponCode,
          ),
        ),
      );
    } on StorefrontException catch (e) {
      if (mounted) showAppSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _startingCheckout = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(cart.isEmpty ? 'Your cart' : 'Your cart (${cart.totalItemCount})'),
      ),
      body: cart.isEmpty ? _buildEmpty() : _buildContent(cart),
      bottomNavigationBar: cart.isEmpty ? null : _buildCheckoutBar(cart),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
              child: const Icon(Icons.shopping_bag_outlined, size: 54, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text('Your cart is empty', style: AppTheme.display(size: 24)),
            const SizedBox(height: 6),
            Text(
              'Toys, school essentials and return gifts are waiting for you.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final scope = MainNavigationScope.of(context);
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                } else {
                  scope?.switchTab(MainNavigation.home);
                }
              },
              child: const Text('Start shopping'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(CartProvider cart) {
    final unavailable = cart.unavailableItems;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (unavailable.isNotEmpty)
          _notice(
            icon: Icons.info_outline_rounded,
            color: AppColors.warning,
            text: '${unavailable.length} item(s) are sold out and won\'t be included in your order.',
          ),
        if (cart.quoteError != null)
          _notice(icon: Icons.error_outline_rounded, color: AppColors.saleRed, text: cart.quoteError!),
        ...cart.items.map((item) => _CartLine(item: item)),
        const SizedBox(height: 8),
        _buildDiscountCard(cart),
        const SizedBox(height: 12),
        _buildNoteCard(),
        const SizedBox(height: 12),
        _buildSummary(cart),
        const SizedBox(height: 16),
        const _TrustRow(),
      ],
    );
  }

  Widget _notice({required IconData icon, required Color color, required String text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildDiscountCard(CartProvider cart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_offer_outlined, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Discount code', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            if (cart.appliedCouponCode != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${cart.appliedCouponCode} applied'
                        '${cart.discountAmount > 0 ? " · you save ${Formatters.formatPrice(cart.discountAmount)}" : ""}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(onPressed: cart.removeCoupon, child: const Text('Remove')),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Enter code',
                        isDense: true,
                        errorText: _codeError,
                        errorMaxLines: 2,
                      ),
                      onSubmitted: (_) => _applyCode(cart),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(84, 48)),
                      onPressed: _applyingCode ? null : () => _applyCode(cart),
                      child: _applyingCode
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Apply'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.edit_note_rounded, size: 22, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Order note (optional)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: 'Party date, gift message, delivery instructions…',
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(CartProvider cart) {
    final quote = cart.quote;
    final subtotal = quote?.subtotal ?? cart.subtotal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Subtotal', Formatters.formatPrice(subtotal)),
            if (cart.discountAmount > 0)
              _row('Discount', '− ${Formatters.formatPrice(cart.discountAmount)}', color: AppColors.success),
            _row('Shipping', 'Calculated at checkout', muted: true),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
            Row(
              children: [
                const Text('Estimated total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const Spacer(),
                if (cart.isQuoting)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                Text(Formatters.formatPrice(cart.grandTotal),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                quote != null ? 'Prices confirmed by titepo.com' : 'Confirming prices with titepo.com…',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? color, bool muted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: muted ? 13 : 14,
              fontWeight: muted ? FontWeight.w500 : FontWeight.w700,
              color: color ?? (muted ? AppColors.textMuted : AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar(CartProvider cart) {
    final canCheckout = cart.items.any((i) => i.isPurchasable);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Formatters.formatPrice(cart.grandTotal),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const Text('+ shipping', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: (!canCheckout || _startingCheckout) ? null : () => _checkout(cart),
              icon: _startingCheckout
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lock_rounded, size: 18),
              label: Text(_startingCheckout ? 'Preparing…' : 'Checkout'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  final CartItem item;
  const _CartLine({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final purchasable = item.isPurchasable;
    return Dismissible(
      key: ValueKey(item.cartKey),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: AppColors.saleRed, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => cart.removeFromCart(item.cartKey),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: item.product)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: Opacity(
                    opacity: purchasable ? 1 : 0.45,
                    child: AppNetworkImage(url: item.image, width: 240),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.25),
                  ),
                  if (item.variantLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(item.variantLabel!, style: Theme.of(context).textTheme.bodySmall),
                    ),
                  if (item.customNotes != null)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentYellowLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.customNotes!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.3),
                      ),
                    ),
                  if (!purchasable)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('Sold out',
                          style: TextStyle(color: AppColors.saleRed, fontWeight: FontWeight.w800, fontSize: 12.5)),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: PriceTag(price: item.totalPrice, size: 15.5)),
                      QuantityStepper(
                        compact: true,
                        quantity: item.quantity,
                        onDecrement: () => cart.updateQuantity(item.cartKey, -1),
                        onIncrement: purchasable ? () => cart.updateQuantity(item.cartKey, 1) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label) => Expanded(
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ],
          ),
        );
    return Row(
      children: [
        item(Icons.verified_user_outlined, 'Secure Shopify\ncheckout'),
        item(Icons.storefront_outlined, 'Same store as\ntitepo.com'),
        item(Icons.support_agent_rounded, 'WhatsApp\nsupport'),
      ],
    );
  }
}
