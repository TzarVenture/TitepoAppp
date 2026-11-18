import 'package:flutter/material.dart';

/// Titepo palette — brand forest green + warm cream from titepo.com,
/// with playful accents for a kids' store.
class AppColors {
  // Brand
  static const Color primary = Color(0xFF053827); // Forest green (website buttons)
  static const Color primaryDark = Color(0xFF02231A);
  static const Color primaryLight = Color(0xFF0E6B4C);
  static const Color primarySoft = Color(0xFFE3F1EA); // tinted surfaces / chips
  static const Color mint = Color(0xFFCFEBDD);

  // Accents
  static const Color accentYellow = Color(0xFFFFC224);
  static const Color accentYellowLight = Color(0xFFFFF4D4);
  static const Color saleRed = Color(0xFFE04029); // website overlay / sale
  static const Color coralPink = Color(0xFFFD8484);
  static const Color peach = Color(0xFFFFE3D6);
  static const Color sky = Color(0xFFDCEBFF);
  static const Color lilac = Color(0xFFEDE4FF);
  static const Color secondary = coralPink;
  static const Color error = saleRed;

  // Surfaces
  static const Color background = Color(0xFFFBF8F3); // warm cream
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color creamLight = Color(0xFFEFE8E0); // website background_2
  static const Color surfaceGrey = Color(0xFFF4F1EC);

  // Text
  static const Color ink = Color(0xFF14201B);
  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF55615C);
  static const Color textMuted = Color(0xFF8C9590);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Lines
  static const Color border = Color(0xFFE7E2DA);
  static const Color borderLight = Color(0xFFF0ECE6);

  // Feedback
  static const Color success = Color(0xFF12A150);
  static const Color warning = Color(0xFFF59E0B);
  static const Color starYellow = Color(0xFFFFB800);

  // Shimmer
  static const Color shimmerBase = Color(0xFFEDE9E3);
  static const Color shimmerHighlight = Color(0xFFF8F6F2);

  /// Pastel tiles for category bubbles.
  static const List<Color> pastels = [peach, mint, sky, accentYellowLight, lilac, Color(0xFFFFE4EC)];

  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x0F14201B), blurRadius: 18, offset: Offset(0, 6)),
  ];
}
