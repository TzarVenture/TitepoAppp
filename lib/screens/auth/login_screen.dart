import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/titepo_brand_logo.dart';
import '../web/store_web_screen.dart';

/// Sign-in: the real Titepo (Shopify) customer account, plus saving your
/// details on this device so checkout is pre-filled.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().currentUser;
    if (u != null) {
      _name.text = u.name;
      _email.text = u.email;
      _phone.text = u.phone;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final err = await context.read<AuthProvider>().saveProfile(
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
        );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = err;
    });
    if (err == null) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = context.watch<AuthProvider>().isLoggedIn;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          const Center(child: TitepoBrandLogo(height: 52)),
          const SizedBox(height: 20),
          Text(editing ? 'Your details' : 'Welcome to Titepo',
              textAlign: TextAlign.center, style: AppTheme.display(size: 28, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Save your details for faster checkout. Your orders are linked to this email on titepo.com.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: const InputDecoration(
              labelText: 'Mobile number (optional)',
              prefixText: '+91 ',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            onSubmitted: (_) => _save(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: AppColors.saleRed, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(editing ? 'Save changes' : 'Continue'),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or', style: Theme.of(context).textTheme.bodySmall),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => StoreWebScreen.open(context, AppConstants.customerAccountUrl, 'My Titepo account'),
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('Sign in to titepo.com account'),
          ),
          const SizedBox(height: 8),
          Text(
            'View all orders, invoices and saved addresses. Shopify sends a one-time code to your email — no password needed.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
