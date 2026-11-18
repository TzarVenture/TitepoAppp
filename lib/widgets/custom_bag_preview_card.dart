import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class CustomBagPreviewCard extends StatelessWidget {
  final Uint8List? customImageBytes;
  final String? customImageUrl;
  final String? customText;
  final double height;

  const CustomBagPreviewCard({
    super.key,
    this.customImageBytes,
    this.customImageUrl,
    this.customText,
    this.height = 260,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2D6C6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Rope Handles at the top
          Positioned(
            top: 10,
            child: CustomPaint(
              size: const Size(70, 38),
              painter: _BagHandlePainter(),
            ),
          ),

          // 2. Paper Bag Body (Full Coverage Area)
          Positioned(
            top: 42,
            bottom: 14,
            left: 24,
            right: 24,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5EFE3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD6C5AF), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // A. Full Coverage Uploaded Image (Covering the entire bag face)
                    if (customImageBytes != null)
                      Image.memory(
                        customImageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    else
                      // Empty state placeholder
                      Container(
                        color: const Color(0xFFF7F2E7),
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFD6C5AF),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 32,
                                  color: Color(0xFFA67D44),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Full-Bleed Print Area',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFA67D44),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Your uploaded image covers the entire bag',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // B. Top Paper Bag Rim & Fold Shading
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: customImageBytes != null ? 0.35 : 0.08),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                    // C. Handle Eyelet Grommets (Authentic bag detail)
                    Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGrommet(),
                          const SizedBox(width: 44),
                          _buildGrommet(),
                        ],
                      ),
                    ),

                    // D. Custom Text Overlay (Optional child name, age, theme notes)
                    if (customText != null && customText!.trim().isNotEmpty)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            customText!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Top-right Badge if image is fully applied
          if (customImageBytes != null)
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'FULL COVERAGE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accentYellow,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrommet() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFF6B4E26),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _BagHandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9E7843)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.8
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path();
    path.moveTo(6, size.height);
    path.cubicTo(
      6,
      0,
      size.width - 6,
      0,
      size.width - 6,
      size.height,
    );

    // Draw shadow then handle
    canvas.drawPath(path.shift(const Offset(0, 2)), shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
