import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/shopify_auth_service.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool isGuest;
  final String? accessToken;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.isGuest = false,
    this.accessToken,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'isGuest': isGuest,
        if (accessToken != null) 'accessToken': accessToken,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        isGuest: json['isGuest'] ?? false,
        accessToken: json['accessToken'],
      );
}

class AuthProvider extends ChangeNotifier {
  static const String _userPrefsKey = 'titepo_user_session_v1';
  final ShopifyAuthService _authService = ShopifyAuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    loadUserSession();
  }

  /// Load user session from SharedPreferences on app startup
  Future<void> loadUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString(_userPrefsKey);
      if (userJson != null && userJson.isNotEmpty) {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
        notifyListeners();
      }
    } catch (e) {
      _currentUser = null;
    }
  }

  /// Save user session
  Future<void> _saveUserSession(UserModel user) async {
    _currentUser = user;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userPrefsKey, jsonEncode(user.toJson()));
    } catch (e) {
      // Ignore
    }
  }

  /// Real customer login with Email + Password
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.loginCustomer(
        email: email,
        password: password,
      );

      if (result.isSuccess && result.user != null) {
        await _saveUserSession(result.user!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.errorMessage ?? 'Unable to sign in. Please verify your credentials.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: Please check your network and try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Real customer registration
  Future<bool> registerCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.registerCustomer(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
      );

      if (result.isSuccess && result.user != null) {
        await _saveUserSession(result.user!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.errorMessage ?? 'Registration failed. Please check your details.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error: Failed to connect to store. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Open official Shopify Web Login portal
  Future<void> openOfficialShopifyLogin() async {
    await _authService.openShopifyOfficialAccountLogin();
  }

  /// Send password recovery link
  Future<String?> sendPasswordReset(String email) async {
    return await _authService.sendPasswordResetEmail(email);
  }

  /// Quick Guest Checkout session
  Future<bool> continueAsGuest({
    required String email,
    required String name,
    required String phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final user = UserModel(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Guest Customer' : name.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      isGuest: true,
    );

    await _saveUserSession(user);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Logout
  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userPrefsKey);
    } catch (e) {
      // Ignore
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
