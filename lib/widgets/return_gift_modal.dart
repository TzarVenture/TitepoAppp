import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

class ReturnGiftModal extends StatefulWidget {
  const ReturnGiftModal({super.key});

  @override
  State<ReturnGiftModal> createState() => _ReturnGiftModalState();
}

class _ReturnGiftModalState extends State<ReturnGiftModal> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _kidsCountController = TextEditingController(text: '15');
  final _budgetController = TextEditingController(text: '200');
  String _ageGroup = '4-7 Years';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _kidsCountController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _sendWhatsAppEnquiry() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final count = _kidsCountController.text.trim();
    final budget = _budgetController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name and phone number'),
          backgroundColor: AppColors.saleRed,
        ),
      );
      return;
    }

    final message = Uri.encodeComponent(
      'Hello Titepo Team! 👋\n'
      'I am inquiring about Birthday Return Gift Solutions.\n\n'
      '👤 Name: $name\n'
      '📱 Phone: $phone\n'
      '👶 Number of Kids: $count\n'
      '🎂 Age Group: $_ageGroup\n'
      '💰 Budget per Gift: ₹$budget\n\n'
      'Please share curated hamper options and bulk discounts!',
    );

    final cleanPhone = AppConstants.supportPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (mounted) Navigator.pop(context);
    } else {
      _submitEmailEnquiry();
    }
  }

  void _submitEmailEnquiry() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final count = _kidsCountController.text.trim();
    final budget = _budgetController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name and phone number'),
          backgroundColor: AppColors.saleRed,
        ),
      );
      return;
    }

    final message = Uri.encodeComponent(
      'Hello Titepo Team! I am interested in Birthday Return Gift Solutions.\n\n'
      'Name: $name\n'
      'Phone: $phone\n'
      'Number of Kids: $count\n'
      'Age Group: $_ageGroup\n'
      'Budget per Gift: ₹$budget\n'
      'Please share curated hampers & discount options!',
    );

    final url = Uri.parse('mailto:${AppConstants.supportEmail}?subject=Return Gift Solutions Enquiry&body=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enquiry submitted! Titepo team will contact you within 24 hours 🎉'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.accentYellowLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🎁', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Return Gift Solutions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Special Bulk Discounts Up to 30% OFF',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'Looking for ready-to-gift packages for your child\'s birthday party? Fill out the quick details below:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Parent Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name / Parent Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),

            // Phone
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number / WhatsApp',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Kids count & Budget
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kidsCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'No. of Kids',
                      prefixIcon: Icon(Icons.group_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Budget/Kid (₹)',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Age group selection
            const Text(
              'Kids Age Group:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['1-3 Years', '4-7 Years', '8-12 Years', 'Mixed Group'].map((group) {
                final isSelected = _ageGroup == group;
                return ChoiceChip(
                  label: Text(group),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _ageGroup = group);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // WhatsApp Direct Action Button (Fastest response)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _sendWhatsAppEnquiry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_outlined, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Enquire on WhatsApp (Instant)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Email Enquiry Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: _submitEmailEnquiry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.email_outlined, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Send via Email',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
