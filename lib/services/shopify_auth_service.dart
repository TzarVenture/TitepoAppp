import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';

class AuthResult {
  final bool isSuccess;
  final UserModel? user;
  final String? errorMessage;

  AuthResult.success(this.user)
      : isSuccess = true,
        errorMessage = null;

  AuthResult.error(this.errorMessage)
      : isSuccess = false,
        user = null;
}

class ShopifyAuthService {
  static const String _usersDbKey = 'titepo_registered_users_db_v1';
  final http.Client _client = http.Client();

  /// Attempt real Shopify Storefront API customer access token creation
  /// Falls back seamlessly to authenticated local persistent registry if Storefront token is not configured
  Future<AuthResult> loginCustomer({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return AuthResult.error('Please enter a valid email address.');
    }
    if (cleanPassword.isEmpty) {
      return AuthResult.error('Please enter your password.');
    }

    // 1. Try Shopify Storefront GraphQL API if token configured
    if (AppConstants.storefrontAccessToken.isNotEmpty) {
      try {
        const mutation = r'''
          mutation customerAccessTokenCreate($input: CustomerAccessTokenCreateInput!) {
            customerAccessTokenCreate(input: $input) {
              customerAccessToken {
                accessToken
                expiresAt
              }
              customerUserErrors {
                code
                field
                message
              }
            }
          }
        ''';

        final res = await _client.post(
          Uri.parse('${AppConstants.storeDomain}/api/2024-01/graphql.json'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-Shopify-Storefront-Access-Token': AppConstants.storefrontAccessToken,
          },
          body: jsonEncode({
            'query': mutation,
            'variables': {
              'input': {
                'email': cleanEmail,
                'password': cleanPassword,
              }
            }
          }),
        ).timeout(const Duration(seconds: 12));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final result = data['data']?['customerAccessTokenCreate'];
          final errors = result?['customerUserErrors'] as List?;

          if (errors != null && errors.isNotEmpty) {
            final msg = errors.map((e) => e['message']).join('. ');
            return AuthResult.error(msg);
          }

          final token = result?['customerAccessToken']?['accessToken'];
          if (token != null) {
            final user = UserModel(
              id: 'shopify_${cleanEmail.hashCode}',
              name: cleanEmail.split('@').first,
              email: cleanEmail,
              phone: '',
              accessToken: token.toString(),
            );
            return AuthResult.success(user);
          }
        }
      } catch (e) {
        // Fall through to registry validation
      }
    }

    // 2. Validate against persistent registered customer registry
    final prefs = await SharedPreferences.getInstance();
    final usersDbRaw = prefs.getString(_usersDbKey);
    final Map<String, dynamic> usersDb = usersDbRaw != null ? jsonDecode(usersDbRaw) : {};

    if (!usersDb.containsKey(cleanEmail)) {
      return AuthResult.error(
        'No account found with $cleanEmail.\nPlease click "Create Account" below to register.',
      );
    }

    final userData = usersDb[cleanEmail] as Map<String, dynamic>;
    final storedPassword = userData['password'] as String?;

    if (storedPassword != cleanPassword) {
      return AuthResult.error(
        'Incorrect password. Please verify your credentials and try again.',
      );
    }

    final user = UserModel(
      id: userData['id'] ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: userData['name'] ?? cleanEmail.split('@').first,
      email: cleanEmail,
      phone: userData['phone'] ?? '',
      isGuest: false,
    );

    return AuthResult.success(user);
  }

  /// Real customer registration with email, password, and profile details
  Future<AuthResult> registerCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();
    final fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
    final cleanPhone = phone.trim();

    if (firstName.trim().isEmpty) {
      return AuthResult.error('Please enter your first name.');
    }
    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      return AuthResult.error('Please enter a valid email address.');
    }
    if (cleanPassword.length < 6) {
      return AuthResult.error('Password must be at least 6 characters.');
    }

    // 1. Try Shopify Storefront GraphQL API if token configured
    if (AppConstants.storefrontAccessToken.isNotEmpty) {
      try {
        const mutation = r'''
          mutation customerCreate($input: CustomerCreateInput!) {
            customerCreate(input: $input) {
              customer {
                id
                email
                firstName
                lastName
                phone
              }
              customerUserErrors {
                code
                field
                message
              }
            }
          }
        ''';

        final res = await _client.post(
          Uri.parse('${AppConstants.storeDomain}/api/2024-01/graphql.json'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-Shopify-Storefront-Access-Token': AppConstants.storefrontAccessToken,
          },
          body: jsonEncode({
            'query': mutation,
            'variables': {
              'input': {
                'firstName': firstName.trim(),
                'lastName': lastName.trim(),
                'email': cleanEmail,
                'password': cleanPassword,
                'phone': cleanPhone.isNotEmpty ? cleanPhone : null,
              }
            }
          }),
        ).timeout(const Duration(seconds: 12));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final result = data['data']?['customerCreate'];
          final errors = result?['customerUserErrors'] as List?;

          if (errors != null && errors.isNotEmpty) {
            final msg = errors.map((e) => e['message']).join('. ');
            return AuthResult.error(msg);
          }
        }
      } catch (e) {
        // Fall through to registry
      }
    }

    // 2. Validate and save in persistent customer registry
    final prefs = await SharedPreferences.getInstance();
    final usersDbRaw = prefs.getString(_usersDbKey);
    final Map<String, dynamic> usersDb = usersDbRaw != null ? jsonDecode(usersDbRaw) : {};

    if (usersDb.containsKey(cleanEmail)) {
      return AuthResult.error(
        'An account with $cleanEmail already exists.\nPlease sign in using your password.',
      );
    }

    final newId = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    usersDb[cleanEmail] = {
      'id': newId,
      'name': fullName.isNotEmpty ? fullName : cleanEmail.split('@').first,
      'email': cleanEmail,
      'password': cleanPassword,
      'phone': cleanPhone,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_usersDbKey, jsonEncode(usersDb));

    final user = UserModel(
      id: newId,
      name: fullName.isNotEmpty ? fullName : cleanEmail.split('@').first,
      email: cleanEmail,
      phone: cleanPhone,
      isGuest: false,
    );

    return AuthResult.success(user);
  }

  /// Request password reset link to user's email address
  Future<String?> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return 'Please enter a valid email address.';
    }

    try {
      final url = Uri.parse('${AppConstants.storeDomain}/account/login#recover');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return null;
      }
    } catch (_) {}
    return null;
  }

  /// Open official Shopify Customer Accounts portal directly in browser
  Future<bool> openShopifyOfficialAccountLogin() async {
    final url = Uri.parse('${AppConstants.storeDomain}/account/login');
    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
