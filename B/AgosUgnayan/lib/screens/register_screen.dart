// Register form: name, email, password, role (farmer or buyer) and town,
// plus the privacy notice the user must agree to (RA 10173).

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';
import '../utils/snackbars.dart';
import '../utils/theme.dart';
import '../utils/validators.dart';
import '../widgets/dropdown_field.dart';
import '../widgets/loading_button.dart';
import 'home_screen.dart';

/// Creates a new farmer or buyer account.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = UserRole.farmer;
  String? _town = 'Leon';
  bool _agreed = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      showError(context, 'Please agree to the privacy notice to continue.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService().register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _role,
        town: _town!,
      );
      if (!mounted) return;
      // Remove Login and Register from the back stack: go straight home.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showError(context, friendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('REGISTER')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          children: [
            const Text('I am a…', style: AppTextStyles.eyebrow),
            const SizedBox(height: AppSizes.labelGap),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: UserRole.farmer,
                  label: Text('Farmer'),
                  icon: Icon(Icons.agriculture),
                ),
                ButtonSegment(
                  value: UserRole.buyer,
                  label: Text('Buyer'),
                  icon: Icon(Icons.shopping_basket),
                ),
              ],
              selected: {_role},
              onSelectionChanged: (value) =>
                  setState(() => _role = value.first),
            ),
            const SizedBox(height: AppSizes.sectionGap),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full name',
                hintText: 'e.g. Pedro Santos',
              ),
              textCapitalization: TextCapitalization.words,
              validator: Validators.name,
            ),
            const SizedBox(height: AppSizes.fieldGap),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: AppSizes.fieldGap),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: Validators.password,
            ),
            const SizedBox(height: AppSizes.fieldGap),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Confirm password'),
              obscureText: true,
              // Compare with whatever is in the password field right now.
              validator: (value) =>
                  Validators.matches(_passwordController.text)(value),
            ),
            const SizedBox(height: AppSizes.fieldGap),
            DropdownField(
              label: 'Town',
              items: kTowns,
              value: _town,
              onChanged: (value) => setState(() => _town = value),
            ),
            const SizedBox(height: AppSizes.fieldGap),
            CheckboxListTile(
              value: _agreed,
              onChanged: (value) => setState(() => _agreed = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'I agree that AgosUgnayan saves my name, email and town so '
                'buyers and farmers can find and message me. We do not share '
                'them with anyone else. (Data Privacy Act, RA 10173)',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: AppSizes.sectionGap),
            LoadingButton(
              label: 'Create account',
              isLoading: _isLoading,
              onPressed: _register,
            ),
          ],
        ),
      ),
    );
  }
}
