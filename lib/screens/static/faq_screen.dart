import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'q': 'How can I order Birthday Return Gift packages?',
        'a': 'You can browse our Return Gifts section or tap the "Return Gift Solutions" button anywhere in the app to request custom curated hampers. We offer special bulk discounts up to 30%!',
      },
      {
        'q': 'What are the shipping charges and delivery time?',
        'a': 'We offer FREE shipping on all orders over ₹500 across India! Orders under ₹500 have a nominal shipping fee of ₹50. Standard delivery takes 3 to 5 business days.',
      },
      {
        'q': 'Can I modify or cancel my order after placing it?',
        'a': 'Yes, orders can be modified or canceled within 24 hours of placing the order before dispatch. Please email us at titepo@tzar.co with your order ID as soon as possible.',
      },
      {
        'q': 'Are Titepo toys safe and non-toxic for children?',
        'a': 'Absolutely! Every toy and accessory at Titepo is carefully handpicked and tested to ensure it meets strict quality, safety, and non-toxic standards for children.',
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
