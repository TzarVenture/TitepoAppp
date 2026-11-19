import 'web_safe_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_theme.dart';
import '../core/utils/formatters.dart';
import '../providers/cart_provider.dart';
import '../screens/cart/cart_screen.dart';

/// Shopify CDN image with sizing hint, placeholder and error state.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final int? width; // requested CDN width in px
  final Color background;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.background = AppColors.surfaceGrey,
  });

  static String sized(String url, int? width) {
    if (width == null || url.isEmpty || !url.contains('cdn.shopify.com')) return url;
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.replace(queryParameters: {...uri.queryParameters, 'width': '$width'}).toString();
  }

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: background,
        alignment: Alignment.center,
        child: const Icon(Icons.toys_outlined, color: AppColors.textMuted, size: 32),
      );
    }
    return Container(
      color: background,
      child: WebSafeNetworkImage(
        imageUrl: sized(url, width),
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 220),
        placeholder: (_, __) => const SizedBox.expand(),
        errorWidget: (_, __, ___) =>
            const Center(child: Icon(Icons.toys_outlined, color: AppColors.textMuted, size: 32)),
      ),
    );
  }
}

class PriceTag extends StatelessWidget {
  final double price;
  final double? compareAt;
  final double size;
  final bool showPercent;

  const PriceTag({super.key, required this.price, this.compareAt, this.size = 16, this.showPercent = false});

  @override
  Widget build(BuildContext context) {
    final onSale = compareAt != null && compareAt! > price;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        Text(
          Formatters.formatPrice(price),
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        if (onSale)
          Text(
            Formatters.formatPrice(compareAt),
            style: TextStyle(
              fontSize: size * 0.72,
              color: AppColors.textMuted,
              decoration: TextDecoration.lineThrough,
              fontWeight: FontWeight.w500,
            ),
          ),
        if (onSale && showPercent)
          Text(
            '${Formatters.calculateDiscount(price, compareAt)}% off',
            style: TextStyle(fontSize: size * 0.72, color: AppColors.success, fontWeight: FontWeight.w800),
          ),
      ],
    );
  }
}

class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final bool compact;

  const QuantityStepper({
    super.key,
    required this.quantity,
    this.onDecrement,
    this.onIncrement,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = compact ? 32.0 : 42.0;
    Widget btn(IconData icon, VoidCallback? onTap) => InkResponse(
          onTap: onTap,
          radius: s / 1.6,
          child: SizedBox(
            width: s,
            height: s,
            child: Icon(icon, size: compact ? 16 : 20, color: onTap == null ? AppColors.textMuted : AppColors.ink),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(quantity <= 1 ? Icons.delete_outline_rounded : Icons.remove_rounded, onDecrement),
          SizedBox(
            width: compact ? 26 : 34,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: compact ? 14 : 16),
            ),
          ),
          btn(Icons.add_rounded, onIncrement),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel = 'See all',
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(20, 28, 12, 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.display(size: 22)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                  ),
              ],
            ),
          ),
          if (onAction != null && actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Bag icon with live item-count badge; opens the cart.
class CartIconButton extends StatelessWidget {
  final Color color;
  const CartIconButton({super.key, this.color = AppColors.ink});

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartProvider, int>((c) => c.totalItemCount);
    return IconButton(
      tooltip: 'Cart',
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: AppColors.saleRed,
        child: Icon(Icons.shopping_bag_outlined, color: color),
      ),
    );
  }
}

void showAppSnack(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 2),
    action: actionLabel != null && onAction != null ? SnackBarAction(label: actionLabel, onPressed: onAction) : null,
  ));
}
