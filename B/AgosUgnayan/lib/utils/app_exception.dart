// The one error type that services throw to screens. It always carries a
// friendly message that is safe to show, never raw Firebase or Dart errors.

import 'strings.dart';

/// Turns any error into text that is safe to show the user. An [AppException]
/// keeps its own message; anything else becomes the generic message.
String friendlyMessage(Object? error) {
  if (error is AppException) return error.message;
  return AppStrings.genericError;
}

/// An error with a message that can be shown to the user as-is.
class AppException implements Exception {
  const AppException(this.message);

  /// Friendly text from AppStrings, e.g. "Could not connect…".
  final String message;

  @override
  String toString() => message;
}
