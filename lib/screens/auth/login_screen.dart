import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  final bool isFromCheckout;
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    this.isFromCheckout = false,
    this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login Controllers
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;

  // Register Controllers
  final TextEditingController _regFirstNameController = TextEditingController();
  final TextEditingController _regLastNameController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _regPhoneController = TextEditingController();
  bool _obscureRegPassword = true;

  // Guest Controllers
  final TextEditingController _guestNameController = TextEditingController();
  final TextEditingController _guestEmailController = TextEditingController();
  final TextEditingController _guestPhoneController = TextEditingController();

  final _formKeyLogin = GlobalKey<FormState>();
  final _formKeyRegister = GlobalKey<FormState>();
  final _formKeyGuest = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regFirstNameController.dispose();
    _regLastNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regPhoneController.dispose();
    _guestNameController.dispose();
    _guestEmailController.dispose();
    _guestPhoneController.dispose();
    super.dispose();
  }

  void _handleSuccess() {
    if (!mounted) return;
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    } else {
      Navigator.pop(context, true);
    }
  }

  void _submitLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.clearError();

    if (!_formKeyLogin.currentState!.validate()) return;

    final success = await auth.loginWithEmail(
      email: _loginEmailController.text.trim(),
      password: _loginPasswordController.text.trim(),
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${auth.currentUser?.name ?? "Customer"}! 🎉'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _handleSuccess();
    }
  }

  void _submitRegister() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.clearError();

    if (!_formKeyRegister.currentState!.validate()) return;

    final success = await auth.registerCustomer(
      firstName: _regFirstNameController.text.trim(),
      lastName: _regLastNameController.text.trim(),
      email: _regEmailController.text.trim(),
      password: _regPasswordController.text.trim(),
      phone: _regPhoneController.text.trim(),
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Welcome to Titepo 🎉'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _handleSuccess();
    }
  }

  void _submitGuestCheckout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.clearError();

    if (!_formKeyGuest.currentState!.validate()) return;

    final success = await auth.continueAsGuest(
      name: _guestNameController.text.trim(),
      email: _guestEmailController.text.trim(),
      phone: _guestPhoneController.text.trim(),
    );

    if (success) {
      _handleSuccess();
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _loginEmailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Reset Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered email address. We will open Shopify\'s recovery portal to send your reset link.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              Navigator.pop(ctx);
              await auth.sendPasswordReset(emailController.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening password reset portal...'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isFromCheckout ? 'Checkout Sign In' : 'Account Login'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Branding Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
              color: AppColors.primary,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.accentYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.card_giftcard_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.isFromCheckout
                        ? 'Sign In to Complete Checkout'
                        : 'Welcome to Titepo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isFromCheckout
                        ? 'Log in to securely process your order & save delivery tracking.'
                        : AppConstants.appTagline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.accentYellowLight,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            if (widget.isFromCheckout)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentYellowLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentYellow),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: AppColors.textPrimary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your cart items are saved! Sign in or choose Guest to proceed.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Tab Bar Switcher (Uniform Segmented Pill)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFECEFF1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                tabs: const [
                  Tab(height: 38, text: '🔑 Sign In'),
                  Tab(height: 38, text: '📝 Register'),
                  Tab(height: 38, text: '⚡ Shopify / Guest'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Error Banner if Backend returned an error
            if (auth.errorMessage != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.saleRed.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.saleRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        auth.errorMessage!,
                        style: const TextStyle(color: AppColors.saleRed, fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Tab View with dynamic forms
            SizedBox(
              height: 520,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Sign In Form
                  _buildSignInTab(auth),

                  // Tab 2: Create Account Form
                  _buildRegisterTab(auth),

                  // Tab 3: Official Shopify Web Login & Guest Checkout
                  _buildShopifyAndGuestTab(auth),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: SIGN IN FORM
  Widget _buildSignInTab(AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKeyLogin,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            const Text(
              'Sign In with Your Email',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter your email and password to access your account.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),

            // Email Field
            TextFormField(
              controller: _loginEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter your email';
                if (!val.contains('@') || !val.contains('.')) return 'Enter a valid email address';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Password Field
            TextFormField(
              controller: _loginPasswordController,
              obscureText: _obscureLoginPassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureLoginPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please enter your password';
                return null;
              },
            ),

            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Sign In Button
            ElevatedButton(
              onPressed: auth.isLoading ? null : _submitLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: auth.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Log In & Continue',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                    ),
            ),

            const SizedBox(height: 16),

            // Switch to Register
            Center(
              child: TextButton(
                onPressed: () {
                  auth.clearError();
                  _tabController.animateTo(1);
                },
                child: const Text(
                  'New to Titepo? Create Account ➔',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 2: REGISTER FORM
  Widget _buildRegisterTab(AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKeyRegister,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            const Text(
              'Create Your Titepo Account',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Join 50,000+ parents for orders, party gifts & exclusive offers.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),

            // First & Last Name
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _regFirstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _regLastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Phone Number
            TextFormField(
              controller: _regPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile Number (+91)',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.trim().length < 10) return 'Enter 10-digit mobile number';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Email Address
            TextFormField(
              controller: _regEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please enter email';
                if (!val.contains('@') || !val.contains('.')) return 'Enter valid email address';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Password
            TextFormField(
              controller: _regPasswordController,
              obscureText: _obscureRegPassword,
              decoration: InputDecoration(
                labelText: 'Create Password (min. 6 characters)',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureRegPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),

            const SizedBox(height: 18),

            // Register Button
            ElevatedButton(
              onPressed: auth.isLoading ? null : _submitRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: auth.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Create Account & Proceed',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                    ),
            ),

            const SizedBox(height: 14),

            // Switch back to Login
            Center(
              child: TextButton(
                onPressed: () {
                  auth.clearError();
                  _tabController.animateTo(0);
                },
                child: const Text(
                  'Already have an account? Sign In ➔',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 3: SHOPIFY OFFICIAL LOGIN & GUEST CHECKOUT
  Widget _buildShopifyAndGuestTab(AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),

          // Official Shopify Web Authentication Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Official Titepo Shopify Login',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Directly access your official account on titepo.com with real verification codes from Shopify. View all your historical orders and tracking statuses.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => auth.openOfficialShopifyLogin(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_browser, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Open Official Shopify Sign-In ➔',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('OR QUICK GUEST CHECKOUT', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 14),

          // Guest Form
          Form(
            key: _formKeyGuest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _guestNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _guestEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address for Order Invoice',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter email';
                    if (!val.contains('@') || !val.contains('.')) return 'Enter valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _guestPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number for Delivery Updates',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => val == null || val.trim().length < 10 ? 'Enter valid 10-digit number' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _submitGuestCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentYellow,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Continue to Checkout as Guest ➔',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
