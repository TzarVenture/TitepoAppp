import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Answers follow the policies published on titepo.com/policies.
    final faqs = [
      {
        'q': 'How do I order return gift bags?',
        'a': 'Open the Gift Bags tab: choose a themed or custom bag, add the gifts to go inside, and pick how many bags you need. '
            'Everything is added to your cart with your choices attached to the order. For large or bulk orders, '
            'message us on WhatsApp for a quote.',
      },
      {
        'q': 'How much is shipping and how long does delivery take?',
        'a': 'We ship across India. Shipping charges are shown at checkout before you pay. Orders are usually dispatched '
            'within 1–5 business days (excluding Sundays and public holidays), with an estimated delivery time of '
            '7–10 working days. Express delivery (3–4 working days) is available at an extra charge — contact us after ordering.',
      },
      {
        'q': 'How can I track my order?',
        'a': 'Once your order is dispatched you\'ll receive the tracking number and courier details (DTDC, Blue Dart, '
            'Ecom Express or Delhivery). You can also open Account → Orders in the app, or sign in to your titepo.com account.',
      },
      {
        'q': 'What is the return policy?',
        'a': 'Returns can be requested within 7 days of delivery for unused items in original packaging with tags and invoice. '
            'Soft/plush toys, ceramic mugs, sale items and gift cards are non-returnable. For damaged, missing or '
            'lost-in-transit items an unboxing video is required. See Account → Refund policy for full details.',
      },
      {
        'q': 'Can I change or cancel my order?',
        'a': 'Contact us as soon as possible on WhatsApp or at titepo@tzar.co with your order number — we\'ll do our best '
            'to help before the order is dispatched.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = faqs[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: ExpansionTile(
              shape: const Border(),
              title: Text(
                item['q']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Text(
                    item['a']!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
