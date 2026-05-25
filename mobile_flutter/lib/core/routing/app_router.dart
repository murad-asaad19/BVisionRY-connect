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
import '../../features/onboarding/presentation/about_step.dart';
import '../../features/onboarding/presentation/goal_step.dart';
import '../../features/onboarding/presentation/identity_step.dart';
import '../../features/onboarding/presentation/roles_step.dart';
import 'router_refresh.dart';
import 'routes.dart';

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
      // Once the guard decided the user belongs in onboarding, let them
      // move between the four steps freely — without this carve-out the
      // redirect would yank them back to /onboarding/goal the moment Goal
      // pushes /onboarding/identity (since `onboarded=false` always
      // resolves to /onboarding/goal until submitOnboarding flips it).
      if (next == Routes.onboardingGoal &&
          state.matchedLocation.startsWith('/onboarding/')) {
        return null;
      }
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
        builder: (_, __) => const GoalStep(),
      ),
      GoRoute(
        path: Routes.onboardingIdentity,
        builder: (_, __) => const IdentityStep(),
      ),
      GoRoute(
        path: Routes.onboardingRoles,
        builder: (_, __) => const RolesStep(),
      ),
      GoRoute(
        path: Routes.onboardingAbout,
        builder: (_, __) => const AboutStep(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (_, __) => const HomeScreen(),
      ),
    ],
  );
});
