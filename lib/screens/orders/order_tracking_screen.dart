import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_theme.dart';
import '../../models/order.dart';
import '../../services/storage_service.dart';
import '../web/store_web_screen.dart';

/// Track an order. Live status always comes from Shopify — either the
/// order-status link saved at checkout, or the customer's Titepo account.
class OrderTrackingScreen extends StatefulWidget {
  final String? initialOrderId;
  const OrderTrackingScreen({super.key, this.initialOrderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final _controller = TextEditingController();
  String? _message;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrderId != null) _controller.text = widget.initialOrderId!;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final query = _controller.text.trim().replaceAll('#', '');
    if (query.isEmpty) return;
    final orders = await StorageService.loadOrders();
    OrderModel? match;
    for (final o in orders) {
      if (o.orderId.replaceAll('#', '').toLowerCase() == query.toLowerCase()) {
        match = o;
        break;
      }
    }
    if (!mounted) return;
    if (match?.statusUrl != null) {
      setState(() => _message = null);
      StoreWebScreen.open(context, match!.statusUrl!, 'Order ${match.orderId}');
    } else {
      setState(() => _message =
          'Order #$query wasn\'t placed from this device. Sign in to your Titepo account to see it, or ask us on WhatsApp.');
    }
  }

  Future<void> _whatsApp() async {
    final q = _controller.text.trim();
    final text = q.isEmpty
        ? 'Hi Titepo team, I need help tracking my order.'
        : 'Hi Titepo team, could you please share a tracking update for my order #${q.replaceAll('#', '')}?';
    await launchUrl(Uri.parse('${AppConstants.supportWhatsApp}?text=${Uri.encodeComponent(text)}'),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track order')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Where\'s my order?', style: AppTheme.display(size: 26)),
          const SizedBox(height: 4),
          Text('Enter the order number from your confirmation email or SMS.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _track(),
            decoration: const InputDecoration(
              hintText: 'e.g. 1042',
              prefixIcon: Icon(Icons.tag_rounded),
            ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_message!, style: const TextStyle(color: AppColors.saleRed, fontSize: 13)),
            ),
          const SizedBox(height: 14),
          FilledButton(onPressed: _track, child: const Text('Track')),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 18),
          _option(
            icon: Icons.account_circle_outlined,
            title: 'My Titepo account',
            subtitle: 'All orders, invoices and courier tracking from titepo.com',
            onTap: () => StoreWebScreen.open(context, AppConstants.customerOrdersUrl, 'My Titepo account'),
          ),
          const SizedBox(height: 12),
          _option(
            icon: Icons.chat_outlined,
            title: 'Ask on WhatsApp',
            subtitle: 'Our team replies with your latest status',
            onTap: _whatsApp,
          ),
        ],
      ),
    );
  }

  Widget _option({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.primarySoft,
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
