import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Titepo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.card_giftcard, color: AppColors.accentYellow, size: 50),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'TITEPO',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const Text(
                    AppConstants.appTagline,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Our Story & Purpose',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'At Titepo, we specialize in offering unique, creative, and high-quality birthday party return gifts for kids. Since 2017, we have been helping parents create memorable celebrations with thoughtful gifts that children truly love.\n\nOur store features a wide range of return gift options, including toys, die-cast cars, school bags, water bottles, bento lunch boxes, stationery, and personalized hamper solutions.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.55),
            ),

            const SizedBox(height: 24),

            const Text(
              'Why Choose Titepo?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            _buildFeatureTile(
              'Handpicked Collection',
              'Every toy is carefully chosen to ensure top standards of safety, creativity, and learning.',
            ),
            _buildFeatureTile(
              'Fast Next-Day Dispatch',
              'We prioritize bringing joy quickly with fast, reliable shipping across India.',
            ),
            _buildFeatureTile(
              'Dedicated Support',
              'Our friendly customer support team is always ready to help you at titepo@tzar.co.',
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
