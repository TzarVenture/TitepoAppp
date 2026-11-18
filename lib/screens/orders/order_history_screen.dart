import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../services/storage_service.dart';
import '../../widgets/ui_kit.dart';
import '../web/store_web_screen.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<OrderModel>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = StorageService.loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My orders'),
        actions: [
          IconButton(
            tooltip: 'Track an order',
            icon: const Icon(Icons.local_shipping_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderTrackingScreen())),
          ),
        ],
      ),
      body: FutureBuilder<List<OrderModel>>(
        future: _orders,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final orders = snap.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _orders = StorageService.loadOrders());
              await _orders;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _AccountOrdersBanner(),
                const SizedBox(height: 18),
                if (orders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('No orders from this device yet', style: AppTheme.display(size: 20)),
                        const SizedBox(height: 4),
                        Text(
                          'Orders you place in the app appear here.\nOrders from the website are in your Titepo account above.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                else ...[
                  Text('Placed from this device', style: AppTheme.display(size: 18)),
                  const SizedBox(height: 10),
                  ...orders.map((o) => _OrderCard(order: o)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AccountOrdersBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => StoreWebScreen.open(context, AppConstants.customerOrdersUrl, 'My Titepo account'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(Icons.account_circle_outlined, color: Colors.white, size: 34),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('All orders & live tracking',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  SizedBox(height: 2),
                  Text('Sign in to your Titepo account with the email used at checkout.',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(order.orderId, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Placed',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ),
                const Spacer(),
                Text(Formatters.formatDate(order.orderDate), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: order.items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(width: 56, child: AppNetworkImage(url: order.items[i].image, width: 160)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('${order.itemCount} items · ', style: Theme.of(context).textTheme.bodyMedium),
                Text(Formatters.formatPrice(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
                if (order.statusUrl != null)
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                    onPressed: () => StoreWebScreen.open(context, order.statusUrl!, 'Order ${order.orderId}'),
                    icon: const Icon(Icons.local_shipping_outlined, size: 18),
                    label: const Text('Track'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
