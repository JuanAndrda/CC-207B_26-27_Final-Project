// TEMPORARY screen that proves setup works: the theme loads and we can see
// whether Firebase is connected. The auth PR replaces it with the login screen.

import 'package:flutter/material.dart';

import '../utils/strings.dart';
import '../utils/theme.dart';

/// Shows the app name, tagline and Firebase connection status.
class SetupCheckScreen extends StatelessWidget {
  const SetupCheckScreen({super.key, required this.firebaseReady});

  /// True when main.dart connected to Firebase successfully.
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.appName.toUpperCase())),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.tagline.toUpperCase(),
              style: AppTextStyles.eyebrow,
            ),
            const SizedBox(height: AppSizes.labelGap),
            Text(AppStrings.setupDone, style: AppTextStyles.pageTitle),
            const SizedBox(height: AppSizes.sectionGap),
            Chip(
              avatar: Icon(
                firebaseReady ? Icons.cloud_done_outlined : Icons.cloud_off,
                color: firebaseReady ? AppColors.primaryDark : AppColors.danger,
              ),
              label: Text(
                firebaseReady
                    ? AppStrings.firebaseConnected
                    : AppStrings.firebaseNotSetUp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
