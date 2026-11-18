import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/contact_support_modal.dart';
import '../../widgets/titepo_brand_logo.dart';
import '../auth/login_screen.dart';
import '../orders/order_history_screen.dart';
import '../orders/order_tracking_screen.dart';
import '../return_gift/return_gift_solutions_screen.dart';
import '../static/faq_screen.dart';
import '../static/about_screen.dart';
import 'customer_addresses_screen.dart';
import 'notification_preferences_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _launchInstagram() async {
    final Uri url = Uri.parse(AppConstants.instagramUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openContactSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ContactSupportModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'My Account',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: AppColors.primary, size: 22),
            tooltip: 'Contact Support',
            onPressed: () => _openContactSupport(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // 1. User Hero Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar or Brand Icon
                  if (auth.isLoggedIn && user?.name.isNotEmpty == true)
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: AppColors.accentYellowLight,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: AppColors.accentYellow, width: 2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          user!.name[0].toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: AppColors.accentYellowLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 28),
                        ),
                      ),
                    ),

                  const SizedBox(width: 14),

                  // Name & Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.isLoggedIn ? user!.name : 'Welcome to Titepo',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          auth.isLoggedIn
                              ? (user!.email.isNotEmpty ? user.email : user.phone)
                              : 'Safe & Non-Toxic Kids Gifting',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (auth.isLoggedIn) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '✓ Verified Member',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Action Button (Login or Logout)
                  if (!auth.isLoggedIn)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Log In',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12.5),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: AppColors.saleRed, size: 22),
                      tooltip: 'Log Out',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Log Out'),
                            content: const Text('Are you sure you want to sign out of your Titepo account?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  auth.logout();
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.saleRed, foregroundColor: Colors.white),
                                child: const Text('Log Out'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Quick Actions 4-Grid (Orders, Tracking, Addresses, Support)
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.local_shipping_outlined,
                    title: 'My Orders',
                    subtitle: 'Active & past',
                    iconColor: AppColors.primary,
                    bgColor: AppColors.primary.withValues(alpha: 0.08),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.radar_rounded,
                    title: 'Track Shipment',
                    subtitle: 'Live AWB status',
                    iconColor: const Color(0xFF0284C7),
                    bgColor: const Color(0xFFE0F2FE),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.location_on_outlined,
                    title: 'Addresses',
                    subtitle: 'Saved delivery spots',
                    iconColor: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFDCFCE7),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CustomerAddressesScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.support_agent_rounded,
                    title: 'Help & Support',
                    subtitle: 'WhatsApp & Call',
                    iconColor: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFEF3C7),
                    onTap: () => _openContactSupport(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3. Signature Party Return Gift Hampers Showcase Banner
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReturnGiftSolutionsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF053827), Color(0xFF0F5A41)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accentYellow.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accentYellow.withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.card_giftcard_rounded, color: AppColors.accentYellow, size: 26),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentYellow,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '🎉 PARTY GIFTING SPECIAL',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Custom Return Gift Hampers',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Personalized bags + bulk toys for kids',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.accentYellow),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 4. Grouped Settings & Preferences Card (iOS / Material 3 Grouped List)
            Material(
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.borderLight, width: 1.2),
              ),
              child: Column(
                children: [
                  _buildGroupedMenuItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notification Preferences',
                    subtitle: 'Order tracking & WhatsApp alerts',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.borderLight),
                  _buildGroupedMenuItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Customer Care & Helpdesk',
                    subtitle: 'Live WhatsApp chat & assistance',
                    onTap: () => _openContactSupport(context),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.borderLight),
                  _buildGroupedMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'FAQ & Help Center',
                    subtitle: 'Frequently asked questions',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FaqScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.borderLight),
                  _buildGroupedMenuItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About Titepo',
                    subtitle: 'Our story & non-toxic promise',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.borderLight),
                  _buildGroupedMenuItem(
                    icon: Icons.camera_alt_outlined,
                    title: 'Follow on Instagram',
                    subtitle: '@titepotoystore',
                    onTap: _launchInstagram,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 5. Official Brand Footer
            const TitepoBrandLogo(height: 32),
            const SizedBox(height: 8),
            Text(
              'Handcrafted with ❤️ for memorable celebrations',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Titepo Mobile App v1.0.0 • © 2026 Titepo',
              style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
        onTap: onTap,
      ),
    );
  }
}
