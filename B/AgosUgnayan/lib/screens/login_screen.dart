// Login form: email and password, validated before we call Firebase.

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_exception.dart';
import '../utils/snackbars.dart';
import '../utils/strings.dart';
import '../utils/theme.dart';
import '../utils/validators.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/loading_button.dart';
import '../widgets/responsive_body.dart';
import 'home_screen.dart';
import 'register_screen.dart';

/// Lets an existing user log in, or go to Register.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _logIn() async {
    // Stop here if any field shows an error.
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService().logIn(
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showError(context, friendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            const _Hero(),
            // On a wide screen the form stays a comfortable width.
            ResponsiveBody(
              maxWidth: 440,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSizes.small),
                    const Text(
                      'Welcome back',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: AppSizes.fieldGap),
                    ..._fields(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The email and password fields, the Log in button and the Register link.
  List<Widget> _fields() {
    return [
      TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(labelText: 'Email'),
        keyboardType: TextInputType.emailAddress,
        validator: Validators.email,
      ),
      const SizedBox(height: AppSizes.fieldGap),
      TextFormField(
        controller: _passwordController,
        obscureText: _hidePassword,
        decoration: InputDecoration(
          labelText: 'Password',
          suffixIcon: IconButton(
            tooltip: _hidePassword ? 'Show password' : 'Hide password',
            icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _hidePassword = !_hidePassword),
          ),
        ),
        validator: Validators.password,
        onFieldSubmitted: (_) => _logIn(),
      ),
      const SizedBox(height: AppSizes.sectionGap),
      LoadingButton(label: 'Log in', isLoading: _isLoading, onPressed: _logIn),
      const SizedBox(height: AppSizes.small),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('New to AgosUgnayan?'),
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
            child: const Text('Create an account'),
          ),
        ],
      ),
    ];
  }
}

/// Green banner with the logo, the app name and the tagline (website .hero).
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: ResponsiveBody(
          maxWidth: 440,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.pagePadding,
              28,
              AppSizes.pagePadding,
              30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(size: 52),
                const SizedBox(height: 12),
                Text(
                  AppStrings.appName,
                  style: AppTextStyles.logo.copyWith(fontSize: 40, height: 0.9),
                ),
                const SizedBox(height: 12),
                const Text(
                  AppStrings.tagline,
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
