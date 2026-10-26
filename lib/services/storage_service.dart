import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class StorageService {
  static const String _cartKey = 'titepo_cart_v1';
  static const String _wishlistKey = 'titepo_wishlist_v1';
  static const String _searchHistoryKey = 'titepo_search_history_v1';
  static const String _customerAddressesKey = 'titepo_customer_addresses_v1';
  static const String _notificationsKey = 'titepo_notification_prefs_v1';

  /// Save notification preferences
  static Future<void> saveNotificationPreferences(Map<String, bool> prefsMap) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_notificationsKey, jsonEncode(prefsMap));
    } catch (_) {}
  }

  /// Load notification preferences with defaults
  static Future<Map<String, bool>> loadNotificationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_notificationsKey);
      if (data != null && data.isNotEmpty) {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v == true));
        }
      }
    } catch (_) {}
    return {
      'order_updates': true,
      'whatsapp_tracking': true,
      'return_gift_specials': true,
      'price_drops': false,
      'festive_promos': true,
    };
  }

  /// Save recent search queries (max 10)
  static Future<void> saveSearchHistory(List<String> queries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_searchHistoryKey, queries.take(10).toList());
    } catch (_) {}
  }

  /// Load recent search history
  static Future<List<String>> loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_searchHistoryKey) ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Save saved addresses
  static Future<void> saveAddresses(List<String> addressesJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_customerAddressesKey, addressesJson);
    } catch (_) {}
  }

  /// Load saved addresses
  static Future<List<String>> loadAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_customerAddressesKey) ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Save cart items to SharedPreferences
  static Future<void> saveCart(List<CartItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList =
          items.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(_cartKey, jsonList);
    } catch (e) {
      // Ignore storage errors gracefully
    }
  }

  /// Load cart items from SharedPreferences
  static Future<List<CartItem>> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList = prefs.getStringList(_cartKey);
      if (jsonList == null || jsonList.isEmpty) return [];

      return jsonList
          .map((itemStr) => CartItem.fromJson(jsonDecode(itemStr)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save wishlist products
  static Future<void> saveWishlist(List<ProductModel> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList =
          products.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList(_wishlistKey, jsonList);
    } catch (e) {
      // Ignore storage errors gracefully
    }
  }

  /// Load wishlist products
  static Future<List<ProductModel>> loadWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList = prefs.getStringList(_wishlistKey);
      if (jsonList == null || jsonList.isEmpty) return [];

      return jsonList
          .map((itemStr) => ProductModel.fromJson(jsonDecode(itemStr)))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
