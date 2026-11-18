import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

/// Official Titepo Brand Logo widget matching the Shopify website identity.
/// Displays the signature deep forest green typography with the amber gold dot on 'i'
/// and the TM emblem, utilizing high-res transparent assets with a vector fallback.
class TitepoBrandLogo extends StatelessWidget {
  final double height;
  final Color? textColor;
  final bool showTm;
  final VoidCallback? onTap;

  const TitepoBrandLogo({
    super.key,
    this.height = 36,
    this.textColor,
    this.showTm = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final logoWidget = Image.asset(
      'assets/images/titepo_header_logo_2x.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to 1x transparent asset
        return Image.asset(
          'assets/images/titepo_header_logo_transparent.png',
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildVectorLogo(),
        );
      },
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: logoWidget,
      );
    }

    return logoWidget;
  }

  /// High-fidelity vector fallback matching the brand typography
  Widget _buildVectorLogo() {
    final effectiveColor = textColor ?? AppColors.primary;
    final fontSize = height * 0.78;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'T',
          style: GoogleFonts.plusJakartaSans(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: effectiveColor,
            letterSpacing: -0.5,
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Text(
              'i',
              style: GoogleFonts.plusJakartaSans(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: effectiveColor,
                letterSpacing: -0.5,
              ),
            ),
            Positioned(
              top: height * 0.12,
              child: Container(
                width: height * 0.22,
                height: height * 0.22,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFC224),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      offset: Offset(0, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Text(
          'tepo',
          style: GoogleFonts.plusJakartaSans(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: effectiveColor,
            letterSpacing: -0.8,
          ),
        ),
        if (showTm)
          Container(
            margin: EdgeInsets.only(bottom: height * 0.40, left: 3),
            padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC224),
              shape: BoxShape.circle,
              border: Border.all(
                color: effectiveColor,
                width: 1.0,
              ),
            ),
            child: Text(
              'TM',
              style: TextStyle(
                fontSize: height * 0.16,
                fontWeight: FontWeight.w900,
                color: effectiveColor,
                height: 1.0,
              ),
            ),
          ),
      ],
    );
  }
}
