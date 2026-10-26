import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AgeFilterRails extends StatelessWidget {
  final String selectedAge;
  final ValueChanged<String> onSelectAge;

  const AgeFilterRails({
    super.key,
    required this.selectedAge,
    required this.onSelectAge,
  });

  static const List<Map<String, String>> ageGroups = [
    {'label': 'All Ages', 'age': 'all', 'desc': 'Everything'},
    {'label': '0-2 Years', 'age': '0-2', 'desc': 'Toddlers & Infants'},
    {'label': '3-5 Years', 'age': '3-5', 'desc': 'Preschool Fun'},
    {'label': '6-8 Years', 'age': '6-8', 'desc': 'Early School'},
    {'label': '9-12 Years', 'age': '9-12', 'desc': 'Pre-Teens'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('🎯 ', style: TextStyle(fontSize: 16)),
              Text(
                'Shop by Age Group',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: ageGroups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final group = ageGroups[index];
              final isSelected = selectedAge == group['age'];

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => onSelectAge(group['age']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.borderLight,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        group['label']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
