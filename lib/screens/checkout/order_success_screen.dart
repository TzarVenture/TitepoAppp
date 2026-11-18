import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../widgets/ui_kit.dart';
import '../main_navigation.dart';
import '../web/store_web_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final OrderModel order;
  const OrderSuccessScreen({super.key, required this.order});

  Future<void> _shareArtwork() async {
    final text = 'Hi Titepo team! I just placed order ${order.orderId} for custom return gift bags. '
        'Sharing my artwork/design here.';
    await launchUrl(
      Uri.parse('${AppConstants.supportWhatsApp}?text=${Uri.encodeComponent(text)}'),
      mode: LaunchMode.externalApplication,
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome(context);
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            children: [
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, size: 64, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Order placed!', textAlign: TextAlign.center, style: AppTheme.display(size: 30, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                order.email != null
                    ? 'A confirmation has been sent to ${order.email}.'
                    : 'Shopify has sent your order confirmation by email/SMS.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _kv('Order', order.orderId, bold: true),
                      _kv('Date', Formatters.formatDate(order.orderDate)),
                      _kv('Items', '${order.itemCount}'),
                      _kv('Total paid', Formatters.formatPrice(order.totalAmount), bold: true),
                      if (order.discountCode != null) _kv('Discount code', order.discountCode!),
                    ],
                  ),
                ),
              ),
              if (order.hasCustomBag) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentYellowLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('One more step for your custom bags',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 4),
                      const Text('Send us your artwork on WhatsApp so we can print it on your bags.',
                          style: TextStyle(fontSize: 13)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                        onPressed: _shareArtwork,
                        icon: const Icon(Icons.chat_rounded),
                        label: const Text('Share artwork on WhatsApp'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              ...order.items.take(4).map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(width: 52, height: 52, child: AppNetworkImage(url: i.image, width: 160)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(i.product.displayTitle,
                              maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Text('×${i.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  )),
              if (order.items.length > 4)
                Text('+ ${order.items.length - 4} more items', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 20),
              if (order.statusUrl != null)
                OutlinedButton.icon(
                  onPressed: () => StoreWebScreen.open(context, order.statusUrl!, 'Order ${order.orderId}'),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('View order status'),
                ),
              const SizedBox(height: 10),
              FilledButton(onPressed: () => _goHome(context), child: const Text('Continue shopping')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(k, style: const TextStyle(color: AppColors.textSecondary)),
            const Spacer(),
            Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 15.5 : 14)),
          ],
        ),
      );
}
