// Profile tab (replaces the old Settings screen): shows who is logged in and
// has the Log out button at the bottom, behind a confirmation dialog.

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../utils/format.dart';
import '../utils/snackbars.dart';
import '../utils/strings.dart';
import '../utils/theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/info_row.dart';
import 'login_screen.dart';

/// The logged-in user's own profile.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logOut(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.logOutTitle,
      message: AppStrings.logOutMessage,
      confirmLabel: AppStrings.logOut,
    );
    if (!confirmed || !context.mounted) return;
    await AuthService().logOut();
    if (!context.mounted) return;
    showMessage(context, AppStrings.loggedOut);
    // Clear every screen so Back can't return to the app.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// "farmer" -> "Farmer".
  String _roleLabel(String role) => role[0].toUpperCase() + role.substring(1);

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    if (user == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('PROFILE')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                user.name[0].toUpperCase(),
                style: AppTextStyles.pageTitle,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.fieldGap),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Center(child: Chip(label: Text(_roleLabel(user.role)))),
          const SizedBox(height: AppSizes.sectionGap),
          Card(
            child: Column(
              children: [
                InfoRow(icon: Icons.email, label: 'Email', value: user.email),
                InfoRow(
                  icon: Icons.location_on,
                  label: 'Town',
                  value: user.town.isEmpty ? 'Not set' : '${user.town}, Iloilo',
                ),
                InfoRow(
                  icon: Icons.calendar_today,
                  label: 'Member since',
                  value: formatDate(user.createdAt),
                ),
                if (user.role != UserRole.admin)
                  InfoRow(
                    icon: Icons.info_outline,
                    label: 'Account type',
                    value: user.isFarmer
                        ? 'Farmer: you can list crops and answer buyers'
                        : 'Buyer: you can browse crops and post requests',
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.sectionGap * 2),
          // Log out is at the bottom so it is not tapped by mistake.
          OutlinedButton.icon(
            onPressed: () => _logOut(context),
            icon: const Icon(Icons.logout),
            label: const Text(AppStrings.logOut),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              minimumSize: const Size.fromHeight(AppSizes.minTapTarget),
            ),
          ),
        ],
      ),
    );
  }
}
