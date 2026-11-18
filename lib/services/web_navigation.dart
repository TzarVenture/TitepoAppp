import 'package:url_launcher/url_launcher.dart';

/// Helpers shared by the in-app Shopify web views (checkout, account, order status).
class WebNavigation {
  static const _webSchemes = {'http', 'https', 'about', 'data', 'blob', 'javascript'};

  /// True when [url] must be handed to another app (UPI, WhatsApp, tel, mail…).
  static bool isExternal(String url) {
    final scheme = Uri.tryParse(url)?.scheme.toLowerCase() ?? '';
    if (scheme.isEmpty) return false;
    if (!_webSchemes.contains(scheme)) return true;
    final host = Uri.tryParse(url)?.host ?? '';
    return host.contains('wa.me') || host.contains('api.whatsapp.com');
  }

  /// Opens UPI / payment-app / intent links in the right external app.
  /// Returns true if something was launched.
  static Future<bool> launchExternal(String url) async {
    final candidates = <Uri>[];

    if (url.startsWith('intent://')) {
      // Android intent URI used by payment gateways, e.g.
      // intent://pay?pa=x@upi#Intent;scheme=upi;package=com.phonepe.app;end
      final hashIdx = url.indexOf('#Intent;');
      final body = hashIdx > 0 ? url.substring('intent://'.length, hashIdx) : url.substring('intent://'.length);
      final params = hashIdx > 0 ? url.substring(hashIdx + 8) : '';
      final scheme = RegExp(r'scheme=([^;]+)').firstMatch(params)?.group(1);
      final fallback = RegExp(r'S\.browser_fallback_url=([^;]+)').firstMatch(params)?.group(1);
      if (scheme != null) candidates.add(Uri.parse('$scheme://$body'));
      if (fallback != null) candidates.add(Uri.parse(Uri.decodeComponent(fallback)));
    } else {
      final uri = Uri.tryParse(url);
      if (uri != null) candidates.add(uri);
    }

    for (final uri in candidates) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return true;
      } catch (_) {}
    }
    return false;
  }

  /// Shopify thank-you / order-status pages across checkout versions:
  ///   /checkouts/cn/<token>/thank-you, /checkouts/c/<token>/thank_you,
  ///   /<shop_id>/checkouts/<token>/thank_you, /<shop_id>/orders/<token>
  static bool isOrderConfirmation(String url) {
    final u = url.toLowerCase();
    return RegExp(r'thank[-_]you').hasMatch(u) || RegExp(r'/\d+/orders/[a-z0-9]+').hasMatch(u);
  }

  /// JavaScript that returns the order name / confirmation number shown on
  /// Shopify's thank-you page, or an empty string if not yet rendered.
  static const String extractOrderNumberJs = r'''
(function () {
  try {
    var t = (document.body && document.body.innerText) || '';
    var m = t.match(/Order\s*(?:number|no\.?)?\s*#\s*([A-Za-z0-9-]+)/i)
         || t.match(/Confirmation\s*(?:number|code)?\s*#?\s*:?\s*([A-Z0-9]{4,})/i)
         || t.match(/#\s*(\d{3,})/);
    if (m) return m[1];
    if (window.Shopify && Shopify.checkout && Shopify.checkout.order_id) return String(Shopify.checkout.order_id);
  } catch (e) {}
  return '';
})();
''';

  /// Final total (incl. shipping) shown on the thank-you page, e.g. "1,249.00".
  static const String extractTotalJs = r'''
(function () {
  try {
    var t = (document.body && document.body.innerText) || '';
    var re = /\bTotal\b[^\d₹]*(?:INR|Rs\.?|₹)?\s*₹?\s*([\d,]+(?:\.\d{1,2})?)/gi, m, last = '';
    while ((m = re.exec(t)) !== null) { last = m[1]; }
    return last;
  } catch (e) { return ''; }
})();
''';

  /// Email the customer used, when visible on the thank-you page.
  static const String extractEmailJs = r'''
(function () {
  try {
    var t = (document.body && document.body.innerText) || '';
    var m = t.match(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/);
    return m ? m[0] : '';
  } catch (e) { return ''; }
})();
''';
}
