class ProductModel {
  final String id;
  final String title;
  final String handle;
  final String description;
  final String vendor;
  final String productType;
  final double price;
  final double? compareAtPrice;
  final List<String> images;
  final List<ProductVariant> variants;
  final List<String> tags;
  final bool available;
  final double rating;
  final int reviewsCount;

  ProductModel({
    required this.id,
    required this.title,
    required this.handle,
    required this.description,
    required this.vendor,
    required this.productType,
    required this.price,
    this.compareAtPrice,
    required this.images,
    required this.variants,
    required this.tags,
    this.available = true,
    this.rating = 4.9,
    this.reviewsCount = 24,
  });

  /// Formatted rating string e.g. "4.8", "4.9", "5.0"
  String get formattedRating => rating.toStringAsFixed(1);

  /// Primary image URL
  String get mainImage => images.isNotEmpty
      ? images.first
      : 'https://cdn.shopify.com/s/files/1/0000/0000/assets/placeholder.png';

  /// Whether product has discount
  bool get isOnSale => compareAtPrice != null && compareAtPrice! > price;

  /// Discount percentage (e.g. 20)
  int get discountPercentage {
    if (!isOnSale || compareAtPrice == 0) return 0;
    return (((compareAtPrice! - price) / compareAtPrice!) * 100).round();
  }

  /// Construct from Shopify API JSON format (`/products.json` or `/products/handle.json`)
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Images parsing
    List<String> parsedImages = [];
    if (json['images'] is List) {
      for (var img in json['images']) {
        if (img is Map && img['src'] != null) {
          parsedImages.add(img['src'].toString());
        } else if (img is String) {
          parsedImages.add(img);
        }
      }
    } else if (json['image'] != null) {
      if (json['image'] is Map && json['image']['src'] != null) {
        parsedImages.add(json['image']['src'].toString());
      }
    }

    // Variants parsing
    List<ProductVariant> parsedVariants = [];
    double minPrice = 0.0;
    double? maxComparePrice;

    if (json['variants'] is List && (json['variants'] as List).isNotEmpty) {
      for (var v in json['variants']) {
        if (v is Map<String, dynamic>) {
          var variantObj = ProductVariant.fromJson(v);
          parsedVariants.add(variantObj);
        }
      }
      minPrice = parsedVariants.first.price;
      maxComparePrice = parsedVariants.first.compareAtPrice;
    } else {
      minPrice = _toDouble(json['price'] ?? json['variants']?[0]?['price'] ?? 0);
      maxComparePrice = _toDouble(json['compare_at_price'] ?? json['variants']?[0]?['compare_at_price']);
    }

    // Tags parsing
    List<String> parsedTags = [];
    if (json['tags'] is String) {
      parsedTags = (json['tags'] as String).split(',').map((e) => e.trim()).toList();
    } else if (json['tags'] is List) {
      parsedTags = (json['tags'] as List).map((e) => e.toString()).toList();
    }

    int rawId = 1;
    if (json['id'] is num) {
      rawId = (json['id'] as num).toInt();
    } else if (json['id'] is String) {
      rawId = int.tryParse(json['id']) ?? 1;
    }

    double calcRating = 4.8 + (rawId % 3) * 0.1;
    double cleanRating = double.parse(calcRating.toStringAsFixed(1));

    return ProductModel(
      id: json['id']?.toString() ?? json['handle'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Titepo Product',
      handle: json['handle']?.toString() ?? '',
      description: json['body_html']?.toString() ?? json['description']?.toString() ?? '',
      vendor: json['vendor']?.toString() ?? 'Titepo',
      productType: json['product_type']?.toString() ?? 'Kids Toy',
      price: minPrice,
      compareAtPrice: maxComparePrice,
      images: parsedImages,
      variants: parsedVariants,
      tags: parsedTags,
      available: json['available'] ?? true,
      rating: cleanRating,
      reviewsCount: 15 + (rawId % 40),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'handle': handle,
      'description': description,
      'vendor': vendor,
      'productType': productType,
      'price': price,
      'compareAtPrice': compareAtPrice,
      'images': images,
      'variants': variants.map((v) => v.toJson()).toList(),
      'tags': tags,
      'available': available,
    };
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) {
      return double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }
    return 0.0;
  }
}

class ProductVariant {
  final String id;
  final String title;
  final double price;
  final double? compareAtPrice;
  final bool available;

  ProductVariant({
    required this.id,
    required this.title,
    required this.price,
    this.compareAtPrice,
    this.available = true,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Default Title',
      price: ProductModel._toDouble(json['price']),
      compareAtPrice: json['compare_at_price'] != null ? ProductModel._toDouble(json['compare_at_price']) : null,
      available: json['available'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'compareAtPrice': compareAtPrice,
        'available': available,
      };
}
