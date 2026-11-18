import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Customer details saved on this device. They prefill Shopify checkout
/// (email + phone). Real accounts, order history and addresses live in the
/// Shopify customer account at titepo.com.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;

  UserModel({required this.id, required this.name, required this.email, required this.phone});

  String get firstName => name.trim().split(' ').first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return email.isNotEmpty ? email[0].toUpperCase() : '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'phone': phone};

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
      );
}

class AuthProvider extends ChangeNotifier {
  static const String _userPrefsKey = 'titepo_user_session_v1';
  // Legacy local "accounts" with plaintext passwords — removed for security.
  static const String _legacyUsersDbKey = 'titepo_registered_users_db_v1';

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    loadUserSession();
  }

  Future<void> loadUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacyUsersDbKey);
      final userJson = prefs.getString(_userPrefsKey);
      if (userJson != null && userJson.isNotEmpty) {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
        notifyListeners();
      }
    } catch (_) {
      _currentUser = null;
    }
  }

  /// Validates and saves the customer's details. Returns an error message or null.
  Future<String?> saveProfile({required String name, required String email, required String phone}) async {
    final cleanEmail = email.trim().toLowerCase();
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (name.trim().isEmpty) return 'Please enter your name.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(cleanEmail)) return 'Please enter a valid email address.';
    if (digits.isNotEmpty && !(digits.length == 10 || (digits.length == 12 && digits.startsWith('91')))) {
      return 'Please enter a valid 10-digit mobile number.';
    }

    final user = UserModel(
      id: _currentUser?.id ?? 'local_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: cleanEmail,
      phone: digits.length == 12 ? digits.substring(2) : digits,
    );
    _currentUser = user;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userPrefsKey, jsonEncode(user.toJson()));
    } catch (_) {}
    return null;
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userPrefsKey);
    } catch (_) {}
  }
}
