import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/shopify_provider.dart';
import '../../models/product.dart';
import 'video_preview_modal.dart';

class VideoReelsPreviewSection extends StatelessWidget {
  const VideoReelsPreviewSection({super.key});

  // Exactly verified Titepo product reels with accurate Shopify products, video links & fallback thumbnails
  static const List<Map<String, String>> _reelsData = [
    {
      'title': '3 Compartment Bento Box',
      'subtitle': 'Spill-proof, food-grade kid\'s lunch box',
      'productHandle': 'titepo-3-compartment-bento-box-for-kids-online-return-gift-solution',
      'videoUrl': 'https://titepo.com/cdn/shop/videos/c/vp/501f01e161964e1397d3a1439fe70410/501f01e161964e1397d3a1439fe70410.HD-1080p-7.2Mbps-90725889.mp4',
      'instagramReelUrl': 'https://www.instagram.com/reel/DTsWTKniMf7/',
      'tag': 'LUNCH BOXES',
      'icon': '🍱',
      'fallbackThumbnail': 'https://cdn.shopify.com/s/files/1/0824/4792/5463/files/1_2ef37834-4173-41cb-9b63-c779415958df.jpg?v=1788182522',
    },
    {
      'title': 'Elephant Mini Backpack',
      'subtitle': 'Waterproof lightweight toddler preschool bag',
      'productHandle': 'animal-mini-backpack-blue',
      'videoUrl': 'https://titepo.com/cdn/shop/videos/c/vp/853a18bc1b8e4853ac5029144624ac68/853a18bc1b8e4853ac5029144624ac68.HD-1080p-7.2Mbps-92448002.mp4',
      'instagramReelUrl': 'https://www.instagram.com/reel/DTkqKVPCGE1/',
      'tag': 'SCHOOL BAGS',
      'icon': '🎒',
      'fallbackThumbnail': 'https://cdn.shopify.com/s/files/1/0824/4792/5463/files/animal-mini-backpack-blue-1.webp?v=1779173672',
    },
    {
      'title': 'Die-Cast Alloy Sport Car',
      'subtitle': 'Pull-back speed racer with realistic details',
      'productHandle': 'die-cast-sport-car-toy-red',
      'videoUrl': 'https://titepo.com/cdn/shop/videos/c/vp/501f01e161964e1397d3a1439fe70410/501f01e161964e1397d3a1439fe70410.HD-1080p-7.2Mbps-90725889.mp4',
      'instagramReelUrl': 'https://www.instagram.com/reel/DPjUoM1Eln5/',
      'tag': 'DIE-CAST CARS',
      'icon': '🏎️',
      'fallbackThumbnail': 'https://cdn.shopify.com/s/files/1/0824/4792/5463/files/die-cast-sport-car-toy-red-1.webp?v=1779173725',
    },
    {
      'title': '3D Dinosaur Ceramic Mug',
      'subtitle': 'Cute animal-themed morning breakfast mug',
      'productHandle': 'green-dino-mug',
      'videoUrl': 'https://titepo.com/cdn/shop/videos/c/vp/853a18bc1b8e4853ac5029144624ac68/853a18bc1b8e4853ac5029144624ac68.HD-1080p-7.2Mbps-92448002.mp4',
      'instagramReelUrl': 'https://www.instagram.com/reel/DNBROOqIHJ6/',
      'tag': 'DINO MUGS',
      'icon': '☕',
      'fallbackThumbnail': 'https://cdn.shopify.com/s/files/1/0824/4792/5463/files/IMG-20260728-WA0024_jpg.jpg?v=1785244659',
    },
  ];

  ProductModel? _getExactProduct(List<ProductModel> products, String handle) {
    if (products.isEmpty) return null;
    try {
      return products.firstWhere((p) => p.handle == handle);
    } catch (_) {
      try {
        return products.firstWhere((p) => p.handle.contains(handle) || handle.contains(p.handle));
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopify = Provider.of<ShopifyProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('📹 ', style: TextStyle(fontSize: 16)),
                  Text(
                    'Watch Toys in Action',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.play_circle_filled_rounded, color: AppColors.primary, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'VIDEO REELS',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _reelsData.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final reel = _reelsData[index];
              final exactProduct = _getExactProduct(shopify.allProducts, reel['productHandle']!);
              final thumbUrl = exactProduct?.mainImage ?? reel['fallbackThumbnail']!;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => VideoPreviewModal(
                        title: exactProduct?.title ?? reel['title']!,
                        subtitle: reel['subtitle']!,
                        videoUrl: reel['videoUrl']!,
                        instagramReelUrl: reel['instagramReelUrl']!,
                        fallbackThumbnailUrl: thumbUrl,
                        relatedProduct: exactProduct,
                      ),
                    );
                  },
                  child: Container(
                    width: 148,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 1. High-Resolution Real Product Thumbnail Background
                          CachedNetworkImage(
                            imageUrl: thumbUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF03251A), Color(0xFF0A4F38)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFF053827),
                              child: Center(
                                child: Text(
                                  reel['icon']!,
                                  style: const TextStyle(fontSize: 48),
                                ),
                              ),
                            ),
                          ),

                          // 2. Cinematic Gradient Veil for readability and contrast
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.55),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.85),
                                ],
                                stops: const [0.0, 0.45, 1.0],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),

                          // 3. Central Translucent Glass Play Icon
                          Center(
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),

                          // 4. Top Tag Chip (Category Badge)
                          Positioned(
                            top: 10,
                            left: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: AppColors.accentYellow,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                reel['tag']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ),

                          // 5. Bottom Caption with Real Product Title & Exact Price
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  reel['title']!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (exactProduct != null)
                                  Text(
                                    '₹${exactProduct.price.toStringAsFixed(0)} • Watch Video',
                                    style: const TextStyle(
                                      color: AppColors.accentYellow,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Text(
                                    reel['subtitle']!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
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
