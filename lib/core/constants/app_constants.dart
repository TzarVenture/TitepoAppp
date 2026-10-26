class AppConstants {
  static const String appName = 'Titepo';
  static const String appTagline = "Kids Toys & Birthday Return Gifts";
  static const String storeDomain = 'https://titepo.com';
  static const String storefrontAccessToken = ''; // Enter Storefront Access Token if generated in Shopify Admin
  static const String customerAccountUrl = 'https://titepo.com/account/login';
  static const String orderTrackingUrl = 'https://titepo.com/account/orders';
  static const String supportEmail = 'titepo@tzar.co';
  static const String supportPhone = '+91 98765 43210';
  static const String supportWhatsApp = 'https://wa.me/919876543210';
  static const String instagramUrl = 'https://www.instagram.com/titepotoystore?igsh=YXMwNXFncm95NWVj';
  static const double freeShippingThreshold = 500.0;
  static const double defaultShippingFee = 50.0;
  static const String defaultCurrencySymbol = '₹';

  // Categories
  static const List<Map<String, String>> featuredCategories = [
    {'handle': 'return-gift', 'title': 'Return Gifts', 'icon': '🎁'},
    {'handle': 'cars', 'title': 'Die-Cast Cars', 'icon': '🏎️'},
    {'handle': 'bags', 'title': 'School Bags', 'icon': '🎒'},
    {'handle': 'drinkware', 'title': 'Water Bottles', 'icon': '🥤'},
    {'handle': 'lunch-box', 'title': 'Lunch Boxes', 'icon': '🍱'},
    {'handle': 'mug', 'title': 'Cute Mugs', 'icon': '☕'},
    {'handle': 'stationary', 'title': 'Stationery', 'icon': '✏️'},
    {'handle': 'new-arrival', 'title': 'New Arrivals', 'icon': '✨'},
  ];

  // Marquee Messages
  static const List<String> marqueeMessages = [
    '🔥 10% OFF SITEWIDE - USE CODE: TITEPO10',
    '🎁 WE DO RETURN GIFT SOLUTIONS | ENQUIRE NOW',
    '🚚 FREE SHIPPING ON ORDERS OVER ₹500',
    '⭐ 100% SAFE & NON-TOXIC KIDS PRODUCTS',
  ];
}
