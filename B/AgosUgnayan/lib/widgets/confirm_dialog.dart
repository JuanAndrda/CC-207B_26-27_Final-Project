// A reusable confirmation dialog for destructive actions such as delete,
// log out or discarding a form. Buttons say what they do ("Delete"), not
// "Yes" / "No".

import 'package:flutter/material.dart';

import '../utils/strings.dart';
import '../utils/theme.dart';

/// Shows a confirmation dialog and returns true only if the user tapped the
/// confirm button. Tapping Cancel or outside the dialog returns false.
///
/// Example:
/// ```dart
/// final ok = await showConfirmDialog(
///   context,
///   title: 'Delete this crop?',
///   message: 'Tomato, 50 kg will be removed from the marketplace.',
///   confirmLabel: AppStrings.delete,
/// );
/// if (!ok || !context.mounted) return;
/// ```
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = AppStrings.cancel,
  bool isDestructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: isDestructive
                ? AppColors.danger
                : AppColors.primaryDark,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  // showDialog returns null when the user taps outside, so treat it as Cancel.
  return result ?? false;
}

/// Asks "Discard changes?" before leaving a form with unsaved edits.
/// Use it inside a PopScope's onPopInvokedWithResult.
Future<bool> showDiscardChangesDialog(BuildContext context) {
  return showConfirmDialog(
    context,
    title: AppStrings.discardTitle,
    message: AppStrings.discardMessage,
    confirmLabel: AppStrings.discard,
    cancelLabel: AppStrings.keepEditing,
  );
}
