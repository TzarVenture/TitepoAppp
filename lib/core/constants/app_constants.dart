class AppConstants {
  static const String appName = 'Titepo';
  static const String appTagline = 'Kids Toys & Birthday Return Gifts';

  // ── Shopify store connection ────────────────────────────────────────────
  /// Primary storefront domain (same store that powers titepo.com).
  static const String storeDomain = 'https://titepo.com';

  /// Storefront API version used for cart + checkout.
  static const String storefrontApiVersion = '2025-07';

  /// Optional public Storefront access token (Shopify Admin → Headless /
  /// Develop apps). The cart & checkout flow works without it (tokenless
  /// access); adding one raises rate limits.
  static const String storefrontAccessToken = '';

  /// Shopify shop ID — used for the new Customer Accounts portal.
  static const String shopId = '82447925463';
  static const String customerAccountUrl = 'https://shopify.com/$shopId/account';
  static const String customerOrdersUrl = 'https://shopify.com/$shopId/account/orders';

  // ── Support ─────────────────────────────────────────────────────────────
  static const String supportEmail = 'titepo@tzar.co';
  static const String supportPhone = '+91 7304056607';
  static const String supportWhatsApp = 'https://wa.me/917304056607';
  static const String instagramUrl = 'https://www.instagram.com/titepotoystore?igsh=YXMwNXFncm95NWVj';

  static const String defaultCurrencySymbol = '₹';

  // Collections highlighted on the website's "Shop by Categories" section.
  static const List<Map<String, String>> featuredCategories = [
    {'handle': 'return-gift', 'title': 'Return Gifts', 'icon': '🎁'},
    {'handle': 'cars', 'title': 'Cars', 'icon': '🏎️'},
    {'handle': 'bags', 'title': 'Bags', 'icon': '🎒'},
    {'handle': 'drinkware', 'title': 'Drinkware', 'icon': '🥤'},
    {'handle': 'lunch-box', 'title': 'Lunch Boxes', 'icon': '🍱'},
    {'handle': 'mug', 'title': 'Mugs', 'icon': '☕'},
    {'handle': 'stationary', 'title': 'Stationery', 'icon': '✏️'},
    {'handle': 'accessories', 'title': 'Accessories', 'icon': '🧸'},
  ];

  /// Collection handles that are internal / not useful as shopping categories.
  static const Set<String> hiddenCollections = {
    'frontpage',
    'custom-products',
    'raksha-bandhan',
  };

  // Announcement strip (keep claims in sync with the live store).
  static const List<String> marqueeMessages = [
    '🎁 Return gift solutions for every party',
    '🔒 100% secure Shopify checkout',
    '🧸 Safe, non-toxic & kid-friendly products',
    '💬 Bulk & custom orders — chat with us on WhatsApp',
  ];
}
