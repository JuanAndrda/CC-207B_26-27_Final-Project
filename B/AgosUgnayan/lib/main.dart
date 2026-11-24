// App entry point: catches every error so it gets logged, connects to
// Firebase, then starts the app with our theme.
// For now it opens a placeholder page; each member's screens replace it.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'utils/app_logger.dart';
import 'utils/strings.dart';
import 'utils/theme.dart';

void main() {
  // runZonedGuarded catches errors from async code that nothing else caught.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Errors inside Flutter widgets (build, layout, paint) come here.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppLogger.error('Flutter error', details.exception, details.stack);
    };
    final firebaseReady = await connectFirebase();
    runApp(AgosUgnayanApp(firebaseReady: firebaseReady));
  }, (error, stack) => AppLogger.error('Uncaught error', error, stack));
}

/// Connects to Firebase using lib/firebase_options.dart.
/// Returns false (instead of crashing) when the file still has placeholder
/// values or the connection fails, so the app can explain what to do.
Future<bool> connectFirebase() async {
  final options = DefaultFirebaseOptions.currentPlatform;
  if (options.apiKey == 'REPLACE_ME') {
    AppLogger.info('Firebase skipped: run `flutterfire configure` first.');
    return false;
  }
  try {
    await Firebase.initializeApp(options: options);
    return true;
  } on FirebaseException catch (e, stack) {
    AppLogger.error('Firebase.initializeApp failed', e, stack);
    return false;
  }
}

/// The root widget: applies the theme and opens the first page.
class AgosUgnayanApp extends StatelessWidget {
  const AgosUgnayanApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _PlaceholderPage(firebaseReady: firebaseReady),
    );
  }
}

/// Temporary first page so the app runs before the real screens are added.
/// Replace `home:` above with the start screen once it is merged.
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo.png', height: 96),
              const SizedBox(height: 16),
              Text(
                firebaseReady
                    ? 'Connected to Firebase. Screens coming soon.'
                    : 'Firebase is not set up yet on this computer.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
