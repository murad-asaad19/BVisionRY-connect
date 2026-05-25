import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import 'routes.dart';

/// Application-wide [GoRouter] instance.
///
/// Phase 1 wires only the sign-in stub and home stub; later phases extend
/// the routes list and attach a `refreshListenable` driven by the route
/// guard providers so navigation reacts to auth/profile state changes.
final Provider<GoRouter> appRouterProvider =
    Provider<GoRouter>((Ref<GoRouter> ref) {
  return GoRouter(
    initialLocation: Routes.signIn,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.signIn,
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (_, __) => const HomeScreen(),
      ),
    ],
  );
});
