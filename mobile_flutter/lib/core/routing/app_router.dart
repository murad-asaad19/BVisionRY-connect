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
import '../../features/chat/presentation/chats_list_screen.dart';
import '../../features/chat/presentation/conversation_screen.dart';
import '../../features/connections/presentation/connections_screen.dart';
import '../../features/discovery/presentation/network_screen.dart';
import '../../features/discovery/presentation/search_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/intros/presentation/inbox_screen.dart';
import '../../features/intros/presentation/intro_detail_screen.dart';
import '../../features/meetings/presentation/post_meeting_prompt_modal.dart';
import '../../features/office_hours/presentation/my_bookings_screen.dart';
import '../../features/office_hours/presentation/office_hours_settings_screen.dart';
import '../../features/onboarding/presentation/about_step.dart';
import '../../features/onboarding/presentation/goal_step.dart';
import '../../features/onboarding/presentation/identity_step.dart';
import '../../features/onboarding/presentation/roles_step.dart';
import '../../features/opportunities/presentation/edit_opportunity_screen.dart';
import '../../features/opportunities/presentation/interested_list_screen.dart';
import '../../features/opportunities/presentation/my_opportunities_screen.dart';
import '../../features/opportunities/presentation/new_opportunity_screen.dart';
import '../../features/opportunities/presentation/opportunities_feed_screen.dart';
import '../../features/opportunities/presentation/opportunity_detail_screen.dart';
import '../../features/privacy/presentation/blocked_users_screen.dart';
import '../../features/profile/presentation/profile_edit_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/public_profile_screen.dart';
import '../../features/settings/presentation/account_screen.dart';
import '../../features/settings/presentation/help_screen.dart';
import '../../features/settings/presentation/language_screen.dart';
import '../../features/settings/presentation/legal_screen.dart';
import '../../features/settings/presentation/notifications_settings_screen.dart';
import '../../features/settings/presentation/privacy_settings_screen.dart';
import '../../features/settings/presentation/settings_home_screen.dart';
import '../../features/verification/presentation/verification_screen.dart';
import '../widgets/app_shell.dart';
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
      GoRoute(
        path: Routes.settingsBlocked,
        builder: (_, __) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: Routes.settingsOfficeHours,
        builder: (_, __) => const OfficeHoursSettingsScreen(),
      ),
      GoRoute(
        path: Routes.myBookings,
        builder: (_, __) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: '/intros/:id',
        builder: (_, GoRouterState state) =>
            IntroDetailScreen(introId: state.pathParameters['id']!),
      ),
      // Opportunities composer + my-list routes (outside the tab shell so
      // they take over the full screen with a back button).
      GoRoute(
        path: Routes.opportunityNew,
        builder: (_, __) => const NewOpportunityScreen(),
      ),
      GoRoute(
        path: Routes.myOpportunities,
        builder: (_, __) => const MyOpportunitiesScreen(),
      ),
      // /opportunities/:id (detail) + nested /edit + /interested.
      GoRoute(
        path: '/opportunities/:id',
        builder: (_, GoRouterState state) => OpportunityDetailScreen(
          opportunityId: state.pathParameters['id']!,
        ),
        routes: <RouteBase>[
          GoRoute(
            path: 'edit',
            builder: (_, GoRouterState state) => EditOpportunityScreen(
              opportunityId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'interested',
            builder: (_, GoRouterState state) => InterestedListScreen(
              opportunityId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.connections,
        builder: (_, __) => const ConnectionsScreen(),
      ),
      // Conversation thread lives OUTSIDE the StatefulShellRoute so it
      // takes over the full screen (no bottom-tab chrome) and is
      // reachable via push from the chats tab, connections list, and
      // intro acceptance flow.
      GoRoute(
        path: '/chats/:id',
        builder: (_, GoRouterState state) => ConversationScreen(
          conversationId: state.pathParameters['id']!,
        ),
      ),
      // Push deep link from a `meeting_review_pending` notification.
      // Opens the full-screen review modal pre-bound to the meeting id.
      GoRoute(
        path: '/meetings/:meetingId/review',
        builder: (_, GoRouterState state) => PostMeetingPromptModal(
          meetingId: state.pathParameters['meetingId']!,
          peerHandle: state.uri.queryParameters['handle'],
          whenLabel: state.uri.queryParameters['when'],
        ),
      ),
      // Settings, Legal & Language — outside the StatefulShellRoute so the
      // bottom-nav chrome retracts when drilling into a settings stack.
      GoRoute(
        path: Routes.settings,
        builder: (_, __) => const SettingsHomeScreen(),
      ),
      GoRoute(
        path: Routes.settingsAccount,
        builder: (_, __) => const AccountScreen(),
      ),
      GoRoute(
        path: Routes.settingsPrivacy,
        builder: (_, __) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: Routes.settingsNotifications,
        builder: (_, __) => const NotificationsSettingsScreen(),
      ),
      GoRoute(
        path: Routes.settingsHelp,
        builder: (_, __) => HelpScreen(),
      ),
      GoRoute(
        path: Routes.settingsLanguage,
        builder: (_, __) => const LanguageScreen(),
      ),
      GoRoute(
        path: Routes.legalPrivacy,
        builder: (_, __) => const LegalScreen(kind: LegalKind.privacy),
      ),
      GoRoute(
        path: Routes.legalTerms,
        builder: (_, __) => const LegalScreen(kind: LegalKind.terms),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, StatefulNavigationShell shell) =>
            AppShell(navigationShell: shell),
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
                builder: (_, __) => const InboxScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.network,
                builder: (_, __) => const NetworkScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.opportunities,
                builder: (_, __) => const OpportunitiesFeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.chats,
                builder: (_, __) => const ChatsListScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
