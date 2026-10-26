import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 0,
    locale: 'en_IN',
  );

  /// Format double or string price to ₹1,299 format
  static String formatPrice(dynamic price) {
    if (price == null) return '₹0';
    double val = 0.0;
    if (price is double) {
      val = price;
    } else if (price is int) {
      val = price.toDouble();
    } else if (price is String) {
      val = double.tryParse(price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }
    return _currencyFormat.format(val);
  }

  /// Format DateTime to readable string e.g. "Oct 21, 2026"
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Calculate percentage discount: (original - price) / original * 100
  static int calculateDiscount(dynamic price, dynamic compareAtPrice) {
    double p = _toDouble(price);
    double cp = _toDouble(compareAtPrice);
    if (cp <= p || cp <= 0) return 0;
    return (((cp - p) / cp) * 100).round();
  }

  /// Clean raw HTML tags from product descriptions
  static String cleanHtml(String? htmlString) {
    if (htmlString == null || htmlString.isEmpty) return '';
    final exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    String clean = htmlString.replaceAll(exp, ' ').trim();
    // Replace multiple whitespaces
    return clean.replaceAll(RegExp(r'\s+'), ' ');
  }

  static double _toDouble(dynamic val) {
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) {
      return double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }
    return 0.0;
  }
}
