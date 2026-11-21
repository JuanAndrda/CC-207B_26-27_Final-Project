// Login form: email and password, validated before we call Firebase.

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_exception.dart';
import '../utils/snackbars.dart';
import '../utils/strings.dart';
import '../utils/theme.dart';
import '../utils/validators.dart';
import '../widgets/loading_button.dart';
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
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.pagePadding * 1.5),
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.eco, size: 56, color: AppColors.primary),
              const SizedBox(height: AppSizes.small),
              Text(
                AppStrings.appName.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppTextStyles.pageTitle,
              ),
              Text(
                AppStrings.tagline.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppTextStyles.eyebrow,
              ),
              const SizedBox(height: 32),
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
                    icon: Icon(
                      _hidePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                  ),
                ),
                validator: Validators.password,
                onFieldSubmitted: (_) => _logIn(),
              ),
              const SizedBox(height: AppSizes.sectionGap * 1.5),
              LoadingButton(
                label: 'Log in',
                isLoading: _isLoading,
                onPressed: _logIn,
              ),
              const SizedBox(height: AppSizes.small),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text('No account yet? Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
