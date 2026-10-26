import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/storage_service.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _isLoading = true;
  Map<String, bool> _preferences = {
    'order_updates': true,
    'whatsapp_tracking': true,
    'return_gift_specials': true,
    'price_drops': false,
    'festive_promos': true,
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await StorageService.loadNotificationPreferences();
    if (mounted) {
      setState(() {
        _preferences = prefs;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggle(String key, bool value) async {
    setState(() {
      _preferences[key] = value;
    });
    await StorageService.saveNotificationPreferences(_preferences);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentYellowLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentYellow),
                    ),
                    child: Row(
                      children: [
                        const Text('🔔', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personalize Your Alerts',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Choose which updates you would like to receive. We never spam.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'ORDERS & SHIPMENTS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildSwitchCard(
                    title: 'Order Status & Tracking Updates',
                    subtitle: 'Notifications when your order is placed, dispatched, or out for delivery',
                    icon: Icons.local_shipping_outlined,
                    value: _preferences['order_updates'] ?? true,
                    onChanged: (val) => _toggle('order_updates', val),
                  ),

                  const SizedBox(height: 10),

                  _buildSwitchCard(
                    title: 'WhatsApp Shipment Alerts',
                    subtitle: 'Receive courier tracking links and delivery OTP directly on WhatsApp',
                    icon: Icons.chat_bubble_outline_rounded,
                    value: _preferences['whatsapp_tracking'] ?? true,
                    onChanged: (val) => _toggle('whatsapp_tracking', val),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'GIFTS & PROMOTIONS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildSwitchCard(
                    title: 'Return Gift & Bulk Party Specials',
                    subtitle: 'Curated catalogs, party checklists, and exclusive bulk discount tiers',
                    icon: Icons.card_giftcard_rounded,
                    value: _preferences['return_gift_specials'] ?? true,
                    onChanged: (val) => _toggle('return_gift_specials', val),
                  ),

                  const SizedBox(height: 10),

                  _buildSwitchCard(
                    title: 'Price Drops & Restock Alerts',
                    subtitle: 'Instant alert when toys on your wishlist drop in price or get restocked',
                    icon: Icons.trending_down_rounded,
                    value: _preferences['price_drops'] ?? false,
                    onChanged: (val) => _toggle('price_drops', val),
                  ),

                  const SizedBox(height: 10),

                  _buildSwitchCard(
                    title: 'Festive Offers & Coupon Codes',
                    subtitle: 'Early access to Children\'s Day, Diwali, and seasonal sale events',
                    icon: Icons.local_offer_outlined,
                    value: _preferences['festive_promos'] ?? true,
                    onChanged: (val) => _toggle('festive_promos', val),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
