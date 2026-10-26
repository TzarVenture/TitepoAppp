import 'package:flutter/material.dart';

/// Titepo Brand Color Palette derived from Shopify website
class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF053827); // Deep Forest Green
  static const Color primaryDark = Color(0xFF03251A);
  static const Color primaryLight = Color(0xFF0A5C41);

  // Accent Colors
  static const Color accentYellow = Color(0xFFFFC224); // Warm Gold / Yellow Badge
  static const Color accentYellowLight = Color(0xFFFFF4D4);
  static const Color saleRed = Color(0xFFE04029); // Sale tag & Offer red
  static const Color coralPink = Color(0xFFFD8484); // Secondary accent
  static const Color secondary = coralPink;
  static const Color error = saleRed;

  // Neutral Backgrounds & Surfaces
  static const Color background = Color(0xFFF9F6F0); // Warm Cream Surface
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color creamLight = Color(0xFFEFE8E0);
  static const Color surfaceGrey = Color(0xFFF2F4F7);

  // Text Colors
  static const Color textPrimary = Color(0xFF121212);
  static const Color textSecondary = Color(0xFF555555);
  static const Color textMuted = Color(0xFF888888);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF0F0F0);

  // Feedback Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color starYellow = Color(0xFFFFB800);

  // Shimmer colors
  static const Color shimmerBase = Color(0xFFEBEBF0);
  static const Color shimmerHighlight = Color(0xFFF5F5FA);
}
