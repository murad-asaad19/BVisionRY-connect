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
import '../../features/chat/presentation/chats_screen_stub.dart';
import '../../features/connections/presentation/network_screen_stub.dart';
import '../../features/discovery/presentation/search_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/intros/presentation/inbox_screen_stub.dart';
import '../../features/onboarding/presentation/about_step.dart';
import '../../features/onboarding/presentation/goal_step.dart';
import '../../features/onboarding/presentation/identity_step.dart';
import '../../features/onboarding/presentation/roles_step.dart';
import '../../features/opportunities/presentation/opportunities_screen_stub.dart';
import '../../features/profile/presentation/profile_edit_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/public_profile_screen.dart';
import '../../features/shell/presentation/tab_shell.dart';
import '../../features/verification/presentation/verification_screen.dart';
import 'route_guard.dart';
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
///
/// The 5 main tabs (`/home`, `/inbox`, `/network`, `/opportunities`,
/// `/chats`) live inside a [StatefulShellRoute.indexedStack] hosted by
/// [TabShell] so navigation between tabs preserves their stack state.
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
      // /p/:handle (and any future anon-allowed prefix) is reachable without
      // a session — never redirect away from these locations.
      if (isAnonAllowed(state.matchedLocation)) return null;
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
      GoRoute(path: Routes.signIn, builder: (_, __) => const SignInScreen()),
      GoRoute(path: Routes.signUp, builder: (_, __) => const SignUpScreen()),
      GoRoute(
        path: Routes.authCallback,
        builder: (_, GoRouterState state) => AuthCallbackScreen(uri: state.uri),
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
        path: Routes.search,
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.profileEdit,
        builder: (_, __) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/p/:handle',
        builder: (_, GoRouterState state) =>
            PublicProfileScreen(handle: state.pathParameters['handle']!),
      ),
      GoRoute(
        path: Routes.settingsVerification,
        builder: (_, __) => const VerificationScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, StatefulNavigationShell shell) =>
            TabShell(navigationShell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.home,
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.inbox,
                builder: (_, __) => const InboxScreenStub(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.network,
                builder: (_, __) => const NetworkScreenStub(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.opportunities,
                builder: (_, __) => const OpportunitiesScreenStub(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.chats,
                builder: (_, __) => const ChatsScreenStub(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
