// App entry point: catches every error so it gets logged, connects to
// Firebase, then starts the app with our theme and router.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_router.dart';
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

/// The root widget: applies the theme and the router.
class AgosUgnayanApp extends StatefulWidget {
  const AgosUgnayanApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  State<AgosUgnayanApp> createState() => _AgosUgnayanAppState();
}

class _AgosUgnayanAppState extends State<AgosUgnayanApp> {
  // Created once here, not in build(), so hot reload keeps the current page.
  late final _router = buildRouter(firebaseReady: widget.firebaseReady);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: _router,
      // On web, keep the phone layout from Figma centered on wide screens.
      builder: (context, child) => ColoredBox(
        color: AppColors.border,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        ),
      ),
    );
  }
}
