/// Product as returned by the Shopify storefront JSON endpoints
/// (`/products.json`, `/products/{handle}.json`, `/collections/{h}/products.json`).
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
  final List<ProductOption> options;
  final List<String> tags;
  final bool available;
  final DateTime? publishedAt;

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
    this.options = const [],
    required this.tags,
    this.available = true,
    this.publishedAt,
  });

  /// Title without the SEO suffix the store appends ("| Online Return Gift Solution").
  String get displayTitle {
    final idx = title.indexOf('|');
    final t = idx > 0 ? title.substring(0, idx) : title;
    return t.trim();
  }

  String get mainImage => images.isNotEmpty ? images.first : '';

  bool get isOnSale => compareAtPrice != null && compareAtPrice! > price;

  int get discountPercentage {
    if (!isOnSale || compareAtPrice == 0) return 0;
    return (((compareAtPrice! - price) / compareAtPrice!) * 100).round();
  }

  /// Whether the product has real choices (more than the "Default Title" variant).
  bool get hasRealVariants =>
      variants.length > 1 || (variants.isNotEmpty && variants.first.title != 'Default Title');

  /// First variant that can actually be purchased.
  ProductVariant? get firstAvailableVariant {
    for (final v in variants) {
      if (v.available) return v;
    }
    return variants.isNotEmpty ? variants.first : null;
  }

  String get webUrl => 'https://titepo.com/products/$handle';

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Images: REST (`images: [{src}]`), cached (`images: [String]`) or suggest (`image: String`).
    final parsedImages = <String>[];
    final imageIdToSrc = <String, String>{};
    if (json['images'] is List) {
      for (final img in json['images']) {
        if (img is Map && img['src'] != null) {
          final src = img['src'].toString();
          parsedImages.add(src);
          if (img['id'] != null) imageIdToSrc[img['id'].toString()] = src;
        } else if (img is String) {
          parsedImages.add(img);
        }
      }
    }
    if (parsedImages.isEmpty) {
      final img = json['image'] ?? json['featured_image'];
      if (img is Map && img['src'] != null) {
        parsedImages.add(img['src'].toString());
      } else if (img is Map && img['url'] != null) {
        parsedImages.add(img['url'].toString());
      } else if (img is String && img.isNotEmpty) {
        parsedImages.add(img.startsWith('//') ? 'https:$img' : img);
      }
    }

    final parsedVariants = <ProductVariant>[];
    if (json['variants'] is List) {
      for (final v in json['variants']) {
        if (v is Map<String, dynamic>) {
          parsedVariants.add(ProductVariant.fromJson(v, imageIdToSrc: imageIdToSrc));
        }
      }
    }

    final parsedOptions = <ProductOption>[];
    if (json['options'] is List) {
      for (final o in json['options']) {
        if (o is Map && o['name'] != null) {
          final values = (o['values'] as List? ?? []).map((e) => e.toString()).toList();
          parsedOptions.add(ProductOption(name: o['name'].toString(), values: values));
        }
      }
    }

    double price;
    double? compareAt;
    if (parsedVariants.isNotEmpty) {
      final ref = parsedVariants.firstWhere((v) => v.available, orElse: () => parsedVariants.first);
      price = ref.price;
      compareAt = ref.compareAtPrice;
    } else {
      // Predictive-search / cached formats.
      price = _toDouble(json['price'] ?? json['price_min']);
      final cmp = json['compare_at_price'] ?? json['compareAtPrice'] ?? json['compare_at_price_min'];
      compareAt = cmp == null ? null : _toDouble(cmp);
      if (compareAt == 0) compareAt = null;
    }

    var parsedTags = <String>[];
    if (json['tags'] is String) {
      parsedTags = (json['tags'] as String)
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (json['tags'] is List) {
      parsedTags = (json['tags'] as List).map((e) => e.toString()).toList();
    }

    bool available;
    if (json['available'] is bool) {
      available = json['available'] as bool;
    } else if (parsedVariants.isNotEmpty) {
      available = parsedVariants.any((v) => v.available);
    } else {
      available = true;
    }

    return ProductModel(
      id: json['id']?.toString() ?? json['handle']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Titepo Product',
      handle: json['handle']?.toString() ?? '',
      description: json['body_html']?.toString() ?? json['description']?.toString() ?? json['body']?.toString() ?? '',
      vendor: json['vendor']?.toString() ?? 'Titepo',
      productType: json['product_type']?.toString() ?? json['productType']?.toString() ?? json['type']?.toString() ?? '',
      price: price,
      compareAtPrice: compareAt,
      images: parsedImages,
      variants: parsedVariants,
      options: parsedOptions,
      tags: parsedTags,
      available: available,
      publishedAt: DateTime.tryParse(json['published_at']?.toString() ?? json['publishedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
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
        'options': options.map((o) => {'name': o.name, 'values': o.values}).toList(),
        'tags': tags,
        'available': available,
        'publishedAt': publishedAt?.toIso8601String(),
      };

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }
    return 0.0;
  }
}

class ProductOption {
  final String name;
  final List<String> values;

  const ProductOption({required this.name, required this.values});
}

class ProductVariant {
  final String id;
  final String title;
  final double price;
  final double? compareAtPrice;
  final bool available;
  final List<String> optionValues;
  final String? image;

  ProductVariant({
    required this.id,
    required this.title,
    required this.price,
    this.compareAtPrice,
    this.available = true,
    this.optionValues = const [],
    this.image,
  });

  /// Numeric Shopify variant id (null when the id is not a real Shopify id).
  String? get shopifyId => RegExp(r'^\d+$').hasMatch(id) ? id : null;

  String get storefrontGid => 'gid://shopify/ProductVariant/$id';

  factory ProductVariant.fromJson(Map<String, dynamic> json, {Map<String, String> imageIdToSrc = const {}}) {
    final opts = <String>[];
    for (final k in ['option1', 'option2', 'option3']) {
      final v = json[k];
      if (v != null) opts.add(v.toString());
    }
    if (opts.isEmpty && json['optionValues'] is List) {
      opts.addAll((json['optionValues'] as List).map((e) => e.toString()));
    }

    String? image;
    if (json['featured_image'] is Map && json['featured_image']['src'] != null) {
      image = json['featured_image']['src'].toString();
    } else if (json['image_id'] != null) {
      image = imageIdToSrc[json['image_id'].toString()];
    } else if (json['image'] is String) {
      image = json['image'] as String;
    }

    final cmpRaw = json['compare_at_price'] ?? json['compareAtPrice'];
    double? cmp = cmpRaw == null ? null : ProductModel._toDouble(cmpRaw);
    if (cmp == 0) cmp = null;

    return ProductVariant(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Default Title',
      price: ProductModel._toDouble(json['price']),
      compareAtPrice: cmp,
      available: json['available'] is bool ? json['available'] as bool : true,
      optionValues: opts,
      image: image,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'compareAtPrice': compareAtPrice,
        'available': available,
        'optionValues': optionValues,
        'image': image,
      };
}
