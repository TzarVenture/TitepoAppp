import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import 'fullscreen_image_viewer.dart';

class EnhancedProductImageGallery extends StatefulWidget {
  final List<String> images;
  final String fallbackImage;
  final bool isOnSale;
  final int discountPercent;

  const EnhancedProductImageGallery({
    super.key,
    required this.images,
    required this.fallbackImage,
    required this.isOnSale,
    required this.discountPercent,
  });

  @override
  State<EnhancedProductImageGallery> createState() => _EnhancedProductImageGalleryState();
}

class _EnhancedProductImageGalleryState extends State<EnhancedProductImageGallery> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullscreen(int index) {
    final list = widget.images.isNotEmpty ? widget.images : [widget.fallbackImage];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenImageViewer(
          images: list,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayImages = widget.images.isNotEmpty ? widget.images : [widget.fallbackImage];

    return Column(
      children: [
        // Main Viewer with Pinch-to-Zoom capability
        Stack(
          children: [
            SizedBox(
              height: 350,
              width: double.infinity,
              child: PageView.builder(
                controller: _pageController,
                itemCount: displayImages.length,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemBuilder: (context, index) {
                  final imgUrl = displayImages[index];
                  return GestureDetector(
                    onTap: () => _openFullscreen(index),
                    child: Container(
                      color: Colors.white,
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 3.0,
                        clipBehavior: Clip.none,
                        child: Hero(
                          tag: 'product_image_$index',
                          child: CachedNetworkImage(
                            imageUrl: imgUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_rounded, size: 64, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Sale discount pill top-left
            if (widget.isOnSale)
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.saleRed,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.saleRed.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '-${widget.discountPercent}% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

            // Tap to zoom hint badge top-right
            Positioned(
              top: 14,
              right: 14,
              child: GestureDetector(
                onTap: () => _openFullscreen(_currentIndex),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Pinch to Zoom',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Slide counter pill bottom-right
            if (displayImages.length > 1)
              Positioned(
                bottom: 12,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${displayImages.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),

        // Bottom thumbnail selector strip
        if (displayImages.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: displayImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, idx) {
                final isSelected = _currentIndex == idx;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      idx,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.borderLight,
                        width: isSelected ? 2.2 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 6,
                              ),
                            ]
                          : [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: displayImages[idx],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
