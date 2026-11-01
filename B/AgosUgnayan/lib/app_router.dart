// All app routes in one place, using go_router. Each screen gets a path
// constant in AppRoutes so we never type a path twice.
// The login, register and role home routes are added in the auth PR.

import 'package:go_router/go_router.dart';

import 'screens/setup_check_screen.dart';

/// Path names for every screen.
class AppRoutes {
  AppRoutes._();

  static const String setupCheck = '/';
}

/// Builds the router. [firebaseReady] is passed to the setup check screen so
/// it can say whether Firebase is connected.
GoRouter buildRouter({required bool firebaseReady}) {
  return GoRouter(
    initialLocation: AppRoutes.setupCheck,
    routes: [
      GoRoute(
        path: AppRoutes.setupCheck,
        builder: (context, state) =>
            SetupCheckScreen(firebaseReady: firebaseReady),
      ),
    ],
  );
}
