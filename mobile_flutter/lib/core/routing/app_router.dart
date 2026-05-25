import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_callback_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/auth/presentation/suspended_screen.dart';
import '../../features/auth/providers/profile_provider.dart';
import '../../features/auth/providers/route_guard_provider.dart';
import '../../features/auth/providers/session_provider.dart';
import '../../features/home/presentation/home_screen.dart';
import 'router_refresh.dart';
import 'routes.dart';

/// Placeholder destination for Phase 3 onboarding. The real wizard
/// (goal/identity/roles/about) replaces this in Phase 3.
class _OnboardingGoalStub extends StatelessWidget {
  const _OnboardingGoalStub();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Onboarding (Phase 3 stub)')),
    );
  }
}

/// Application-wide [GoRouter] instance.
///
/// The redirect callback consumes [routeGuardProvider] (which is itself a
/// fold of `sessionProvider` + `profileProvider` + [resolveNextRoute]) and
/// nudges the navigator whenever the resolved next-route differs from the
/// current matched location. `refreshListenable` is driven off the session
/// stream so cold-start deep-link → session → profile transitions all
/// trigger a re-evaluation.
///
/// The `/auth` callback path is pass-through: the [AuthCallbackScreen]
/// runs first, exchanges the deep-link payload for a session, and the
/// resulting state change drives the redirect on the next tick.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((
  Ref<GoRouter> ref,
) {
  // Refresh on every session OR profile state transition so the redirect
  // callback re-evaluates after the deferred profile fetch resolves.
  final RouterRefreshNotifier refresh = RouterRefreshNotifier();
  ref.listen(sessionProvider, (_, __) => refresh.bump());
  ref.listen(profileProvider, (_, __) => refresh.bump());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.signIn,
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      final String? next = ref.read(routeGuardProvider);
      if (next == null) return null; // still loading — keep splash up
      // Don't redirect away from /auth — let the callback screen run.
      if (state.matchedLocation == Routes.authCallback) return null;
      // Avoid loops.
      if (state.matchedLocation == next) return null;
      return next;
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.signIn,
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        path: Routes.signUp,
        builder: (_, __) => const SignUpScreen(),
      ),
      GoRoute(
        path: Routes.authCallback,
        builder: (_, GoRouterState state) =>
            AuthCallbackScreen(uri: state.uri),
      ),
      GoRoute(
        path: Routes.suspended,
        builder: (_, __) => const SuspendedScreen(),
      ),
      GoRoute(
        path: Routes.onboardingGoal,
        builder: (_, __) => const _OnboardingGoalStub(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (_, __) => const HomeScreen(),
      ),
    ],
  );
});
