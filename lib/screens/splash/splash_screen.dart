import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/shopify_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Main choreographed entrance controller
  late AnimationController _entranceController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _taglineSlide;
  late Animation<double> _taglineFade;
  late Animation<double> _shimmerProgress;

  // Continuous floating/breathing controller
  late AnimationController _floatController;

  // Loading progress bar controller
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    // 1. Entrance timeline (1400ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    _taglineSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeIn),
      ),
    );

    _shimmerProgress = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeInOut),
      ),
    );

    // 2. Floating & Ambient Breathing Controller (2400ms loop)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // 3. Simulated/Real Loading Controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _entranceController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final shopifyProvider = Provider.of<ShopifyProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);

    // Start loading the catalogue, but don't hold the splash for all of it:
    // continue as soon as there is something to show (cached products or the
    // first page), or after 4s at most. The home screen fills in the rest.
    shopifyProvider.loadCatalogData();
    await Future.wait([
      cartProvider.initCart().catchError((_) {}),
      wishlistProvider.initWishlist().catchError((_) {}),
      Future.delayed(const Duration(milliseconds: 1200)),
      Future.any([
        shopifyProvider.firstContentReady,
        Future.delayed(const Duration(seconds: 4)),
      ]),
    ]);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavigation(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0), // Signature Titepo warm cream
      body: Stack(
        children: [
          // 1. Ambient Animated Background Blobs / Floating Orbs
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              final val = _floatController.value;
              return Stack(
                children: [
                  Positioned(
                    top: -60 + (val * 16),
                    right: -60 - (val * 12),
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFC224).withValues(alpha: 0.18),
                            const Color(0xFFFFC224).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80 - (val * 16),
                    left: -70 + (val * 10),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.12),
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. Centerpiece: Advanced Animated Titepo Brand Logo
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_entranceController, _floatController]),
              builder: (context, child) {
                final floatOffset = math.sin(_floatController.value * math.pi) * 4.0;

                return Transform.translate(
                  offset: Offset(0, floatOffset),
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Glow & Logo Display
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Soft golden glow behind logo
                              Container(
                                width: 220,
                                height: 90,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFC224).withValues(alpha: 0.22),
                                      blurRadius: 36,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                              ),

                              // Official Titepo Brand Logo Image (clean transparent asset)
                              Image.asset(
                                'assets/images/titepo_logo_transparent.png',
                                width: 220,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => _buildFallbackVectorLogo(),
                              ),

                              // Shimmer Light Reflection Sweep over the logo
                              if (_shimmerProgress.value >= -0.5 && _shimmerProgress.value <= 1.5)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: SizedBox(
                                    width: 220,
                                    height: 80,
                                    child: Transform.translate(
                                      offset: Offset(_shimmerProgress.value * 220, 0),
                                      child: Transform.rotate(
                                        angle: 0.35,
                                        child: Container(
                                          width: 38,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.white.withValues(alpha: 0.0),
                                                Colors.white.withValues(alpha: 0.45),
                                                Colors.white.withValues(alpha: 0.0),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Brand Tagline with Smooth Staggered Slide-Up
                          Transform.translate(
                            offset: Offset(0, _taglineSlide.value),
                            child: FadeTransition(
                              opacity: _taglineFade,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.accentYellowLight,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppColors.accentYellow.withValues(alpha: 0.7),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFC224).withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  AppConstants.appTagline.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Bottom Animated Loading Bar & Trust Subtitle
          Positioned(
            bottom: 46,
            left: 36,
            right: 36,
            child: Column(
              children: [
                // Smooth Capsule Progress Bar
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, _) {
                    return Container(
                      height: 5,
                      width: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5DECE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 140 * _progressController.value,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF053827), Color(0xFF0A5C41)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  '100% Safe & Non-Toxic Kids Toys',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// High-fidelity Vector Fallback matching the exact screenshot typography if asset is resolving
  Widget _buildFallbackVectorLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'T',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 54,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            shadows: const [
              Shadow(color: Color(0xFF021B13), offset: Offset(0, 3), blurRadius: 2),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Text(
              'i',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 54,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                shadows: const [
                  Shadow(color: Color(0xFF021B13), offset: Offset(0, 3), blurRadius: 2),
                ],
              ),
            ),
            Positioned(
              top: 6,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFC224),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0xFFC48A00), offset: Offset(0, 1.5), blurRadius: 1),
                  ],
                ),
              ),
            ),
          ],
        ),
        Text(
          'tepo',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 54,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: -1.0,
            shadows: const [
              Shadow(color: Color(0xFF021B13), offset: Offset(0, 3), blurRadius: 2),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 22, left: 3),
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC224),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 1.2),
          ),
          child: const Text(
            'TM',
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
