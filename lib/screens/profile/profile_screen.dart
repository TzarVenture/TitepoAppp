import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../auth/login_screen.dart';
import '../orders/order_history_screen.dart';
import '../orders/order_tracking_screen.dart';
import '../static/about_screen.dart';
import '../static/faq_screen.dart';
import '../web/store_web_screen.dart';
import '../wishlist/wishlist_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Future<void> _launch(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final wishCount = context.select<WishlistProvider, int>((w) => w.wishlistProducts.length);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.accentYellow,
                  child: user != null
                      ? Text(user.initials,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.ink))
                      : const Icon(Icons.person_rounded, color: AppColors.ink, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user != null ? 'Hi, ${user.firstName}!' : 'Hello there!',
                          style: AppTheme.display(size: 22, color: Colors.white, weight: FontWeight.w800)),
                      Text(
                        user?.email ?? 'Add your details for faster checkout',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(backgroundColor: Colors.white24),
                  onPressed: () => _push(context, const LoginScreen()),
                  icon: Icon(user != null ? Icons.edit_rounded : Icons.arrow_forward_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _quick(context, Icons.receipt_long_rounded, 'Orders', () => _push(context, const OrderHistoryScreen())),
              const SizedBox(width: 10),
              _quick(context, Icons.local_shipping_outlined, 'Track', () => _push(context, const OrderTrackingScreen())),
              const SizedBox(width: 10),
              _quick(context, Icons.favorite_border_rounded, wishCount > 0 ? 'Wishlist ($wishCount)' : 'Wishlist',
                  () => _push(context, const WishlistScreen())),
            ],
          ),
          _group('Titepo account', [
            _tile(Icons.verified_user_outlined, 'Sign in to titepo.com',
                'Orders, invoices & addresses from the website',
                () => StoreWebScreen.open(context, AppConstants.customerAccountUrl, 'My Titepo account')),
          ]),
          _group('Help', [
            _tile(Icons.chat_outlined, 'Chat on WhatsApp', AppConstants.supportPhone,
                () => _launch(AppConstants.supportWhatsApp)),
            _tile(Icons.mail_outline_rounded, 'Email us', AppConstants.supportEmail,
                () => _launch('mailto:${AppConstants.supportEmail}')),
            _tile(Icons.help_outline_rounded, 'FAQs', null, () => _push(context, const FaqScreen())),
          ]),
          _group('Store policies', [
            _tile(Icons.assignment_return_outlined, 'Refund policy', null,
                () => StoreWebScreen.open(context, '${AppConstants.storeDomain}/policies/refund-policy', 'Refund policy')),
            _tile(Icons.local_shipping_outlined, 'Shipping policy', null,
                () => StoreWebScreen.open(context, '${AppConstants.storeDomain}/policies/shipping-policy', 'Shipping policy')),
            _tile(Icons.privacy_tip_outlined, 'Privacy policy', null,
                () => StoreWebScreen.open(context, '${AppConstants.storeDomain}/policies/privacy-policy', 'Privacy policy')),
            _tile(Icons.gavel_outlined, 'Terms of service', null,
                () => StoreWebScreen.open(context, '${AppConstants.storeDomain}/policies/terms-of-service', 'Terms of service')),
          ]),
          _group('More', [
            _tile(Icons.info_outline_rounded, 'About Titepo', null, () => _push(context, const AboutScreen())),
            _tile(Icons.camera_alt_outlined, 'Follow on Instagram', '@titepotoystore',
                () => _launch(AppConstants.instagramUrl)),
            _tile(Icons.language_rounded, 'Visit titepo.com', null, () => _launch(AppConstants.storeDomain)),
          ]),
          if (user != null) ...[
            const SizedBox(height: 20),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.saleRed),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Remove your details?'),
                    content: const Text('Your saved name, email and phone will be removed from this device.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
                    ],
                  ),
                );
                if (ok == true) await auth.logout();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ],
          const SizedBox(height: 12),
          Center(child: Text('Titepo · ${AppConstants.appTagline}', style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _quick(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _group(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
          child: Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11.5, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                tiles[i],
                if (i < tiles.length - 1) const Divider(indent: 60),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(IconData icon, String title, String? subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12.5)) : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
