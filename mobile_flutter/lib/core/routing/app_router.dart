import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_callback_screen.dart';
import '../../features/auth/presentation/consent_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/auth/presentation/suspended_screen.dart';
import '../../features/auth/providers/auth_service_provider.dart';
import '../../features/auth/providers/profile_provider.dart';
import '../../features/auth/providers/route_guard_provider.dart';
import '../../features/auth/providers/session_provider.dart';
import '../../features/chat/presentation/conversation_screen.dart';
import '../../features/discovery/presentation/network_screen.dart';
import '../../features/discovery/presentation/search_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/intros/presentation/inbox_screen.dart';
import '../../features/intros/presentation/intro_detail_screen.dart';
import '../../features/meetings/presentation/meeting_review_screen.dart';
import '../../features/meetings/presentation/post_meeting_prompt_modal.dart';
import '../../features/office_hours/presentation/my_bookings_screen.dart';
import '../../features/office_hours/presentation/office_hours_settings_screen.dart';
import '../../features/onboarding/presentation/about_step.dart';
import '../../features/onboarding/presentation/bio_draft_step.dart';
import '../../features/onboarding/presentation/goal_step.dart';
import '../../features/onboarding/presentation/roles_step.dart';
import '../../features/opportunities/presentation/edit_opportunity_screen.dart';
import '../../features/opportunities/presentation/interested_list_screen.dart';
import '../../features/opportunities/presentation/my_opportunities_screen.dart';
import '../../features/opportunities/presentation/new_opportunity_screen.dart';
import '../../features/opportunities/presentation/opportunities_feed_screen.dart';
import '../../features/opportunities/presentation/opportunity_detail_screen.dart';
import '../../features/privacy/presentation/blocked_users_screen.dart';
import '../../features/privacy/presentation/reports_history_screen.dart';
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
import '../../features/waitlist/presentation/invite_friends_screen.dart';
import '../../features/waitlist/presentation/waitlist_screen.dart';
import '../i18n/i18n.dart';
import '../theme/app_colors.dart';
import '../widgets/app_shell.dart';
import '../widgets/widgets.dart';
import 'not_found_screen.dart';
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
/// The 5 main tabs (`/home`, `/network`, `/inbox`, `/opportunities`,
/// `/profile`) live inside a [StatefulShellRoute.indexedStack] hosted by
/// [AppShell] so navigation between tabs preserves their stack state. The
/// chats list is a segment of the Inbox, not its own tab.
///
/// The app boots into [Routes.splash] (`/`) — a bare spinner shown while
/// the guard resolves session + profile. As soon as `routeGuardProvider`
/// returns a concrete target the redirect moves the user off the splash.
///
/// Any location that matches no route (bad deep link, malformed
/// `router.go(...)` payload from an FCM handler) falls through to
/// [errorBuilder] → [NotFoundScreen]; [Routes.notFound] is also a real
/// route so it can be navigated to explicitly.
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
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    // Unmatched locations (bad deep links / malformed push payloads) render
    // the branded NotFoundScreen instead of GoRouter's default error page.
    errorBuilder: (_, __) => const NotFoundScreen(),
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
      // Same carve-out for the unauthed auth family: when the guard says
      // /sign-in, let the user move freely between /sign-in, /sign-up
      // and /auth without bouncing them back. /suspended is intentionally
      // NOT in this list — a suspended user who taps Sign-out has their
      // session cleared and the guard then resolves to /sign-in; if we
      // suppressed that redirect they would be trapped on /suspended
      // with no way to reach the sign-in screen.
      if (next == Routes.signIn &&
          (state.matchedLocation == Routes.signUp ||
              state.matchedLocation == Routes.authCallback)) {
        return null;
      }
      // Consent gate: while the guard wants /consent, let the user finish the
      // surfaces that record consent inline (sign-up form, auth callback)
      // without being bounced back to /consent mid-flow. The legal docs the
      // consent checkbox links to are anon-allowed (see route_guard's
      // _kAnonAllowedPrefixes), so they pass the top-of-redirect check and
      // need no carve-out here.
      if (next == Routes.consent &&
          (state.matchedLocation == Routes.signUp ||
              state.matchedLocation == Routes.authCallback)) {
        return null;
      }
      // Once the guard decided the user is fully ready (default landing
      // is /home), let them push to any feature route freely. Only force
      // a redirect when they're stuck on an auth / onboarding / suspended
      // gate that no longer applies.
      if (next == Routes.home &&
          state.matchedLocation != Routes.splash &&
          state.matchedLocation != Routes.signIn &&
          state.matchedLocation != Routes.signUp &&
          state.matchedLocation != Routes.authCallback &&
          state.matchedLocation != Routes.suspended &&
          state.matchedLocation != Routes.consent &&
          !state.matchedLocation.startsWith('/onboarding/')) {
        return null;
      }
      return next;
    },
    routes: <RouteBase>[
      // Initial location while the route guard resolves session + profile.
      // The redirect bounces off this the moment a concrete target exists.
      GoRoute(path: Routes.splash, builder: (_, __) => const _SplashScreen()),
      // Explicit not-found target (also wired into [errorBuilder] above).
      GoRoute(
        path: Routes.notFound,
        builder: (_, __) => const NotFoundScreen(),
      ),
      GoRoute(path: Routes.signIn, builder: (_, __) => const SignInScreen()),
      GoRoute(
        path: Routes.signUp,
        // `?invite=CODE` arrives from an invite deep link (see main._dispatchUri
        // → router.go('/sign-up?invite=...')) and pre-fills the invite field.
        builder: (_, GoRouterState state) =>
            SignUpScreen(initialInviteCode: state.uri.queryParameters['invite']),
      ),
      GoRoute(
        path: Routes.authCallback,
        builder: (_, GoRouterState state) => AuthCallbackScreen(uri: state.uri),
      ),
      GoRoute(
        path: Routes.suspended,
        builder: (_, __) => const SuspendedScreen(),
      ),
      // Post-auth age-gate + consent interstitial (see route guard). Reached
      // when an authed profile has no recorded consent (OAuth / magic-link).
      GoRoute(
        path: Routes.consent,
        builder: (_, __) => const ConsentScreen(),
      ),
      // Pre-auth join-the-waitlist screen (anon-allowed — see route_guard).
      GoRoute(
        path: Routes.waitlist,
        builder: (_, __) => const WaitlistScreen(),
      ),
      // Share-my-invites surface (authed; reached from Settings).
      GoRoute(
        path: Routes.inviteFriends,
        builder: (_, __) => const InviteFriendsScreen(),
      ),
      GoRoute(
        path: Routes.onboardingGoal,
        builder: (_, __) => const GoalStep(),
      ),
      GoRoute(
        path: Routes.onboardingRoles,
        builder: (_, __) => const RolesStep(),
      ),
      GoRoute(
        path: Routes.onboardingBio,
        builder: (_, __) => const BioDraftStep(),
      ),
      GoRoute(
        path: Routes.onboardingAbout,
        builder: (_, __) => const AboutStep(),
      ),
      GoRoute(
        path: Routes.search,
        builder: (_, __) => const SearchScreen(),
      ),
      // NOTE: Routes.profile is NOT a top-level route — it lives as a
      // StatefulShellBranch below so the user's own profile is a first-class
      // bottom-nav tab (see the shell branches). profileEdit stays full-screen
      // (pushed over the profile tab with a back button).
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
        path: Routes.reportsHistory,
        builder: (_, __) => const ReportsHistoryScreen(),
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
      // G2 "Did this meeting happen?" prompt — on Yes the modal pushes to
      // the G3 full-screen review (`/review/full`).
      GoRoute(
        path: '/meetings/:meetingId/review',
        builder: (_, GoRouterState state) => PostMeetingPromptModal(
          meetingId: state.pathParameters['meetingId']!,
          peerHandle: state.uri.queryParameters['handle'],
          whenLabel: state.uri.queryParameters['when'],
        ),
      ),
      // G3 — full-screen post-connection review. Reached from the G2 prompt
      // (Yes-it-happened) or as a stand-alone deep-link target.
      GoRoute(
        path: '/meetings/:meetingId/review/full',
        builder: (_, GoRouterState state) => MeetingReviewScreen(
          meetingId: state.pathParameters['meetingId']!,
          peerHandle: state.uri.queryParameters['handle'],
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
        // Android system-back from any non-home tab routes to /home first
        // (matching platform expectation) instead of exiting the app. On
        // the home tab the pop is allowed through so back exits as usual.
        builder: (_, __, StatefulNavigationShell shell) {
          final bool onHomeTab = shell.currentIndex == 0;
          return PopScope(
            canPop: onHomeTab,
            onPopInvokedWithResult: (bool didPop, Object? result) {
              if (didPop) return;
              shell.goBranch(0, initialLocation: true);
            },
            child: AppShell(navigationShell: shell),
          );
        },
        // Branch order MUST mirror the tab order in [ConnectBottomNavBar]:
        // Home(0) / Network(1) / Inbox(2) / Opportunities(3) / Profile(4).
        // The chats list is folded into the Inbox (a segment), so there is no
        // standalone Chats branch; the conversation thread (/chats/:id) lives
        // outside the shell as a full-screen push.
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
                path: Routes.network,
                builder: (_, __) => const NetworkScreen(),
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
                path: Routes.opportunities,
                builder: (_, __) => const OpportunitiesFeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.profile,
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Bare boot screen shown at [Routes.splash] while `routeGuardProvider`
/// resolves session + profile. The redirect replaces it with the user's
/// real landing as soon as a concrete target is available, so this only
/// ever flashes for a frame or two on cold start.
class _SplashScreen extends ConsumerWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    // Drive the splash exit off the guard directly. Watching
    // [routeGuardProvider] here (rather than relying solely on the router's
    // refreshListenable) gives the guard a live subscriber, so it recomputes
    // and notifies the instant session + profile settle. This closes a
    // cold-start race: the router's initial redirect runs while the profile is
    // still loading (guard → null, stay on splash), and the later refresh bump
    // is not reliably acted on — leaving a returning user stuck on an endless
    // spinner. With this watch the splash self-resolves the moment a concrete
    // target exists.
    final String? next = ref.watch(routeGuardProvider);
    if (next != null && next != Routes.splash) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        // Only move while we're actually on the splash, so we never stomp a
        // navigation the user/router performed after the gate resolved.
        if (GoRouterState.of(context).matchedLocation == Routes.splash) {
          context.go(next);
        }
      });
    }

    if (!profile.hasError) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // A persistent profile-fetch failure (expired/revoked session, backend
    // outage) must never trap a returning user on an endless spinner —
    // offer recovery (retry the fetch, or sign out to re-authenticate).
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.error_outline, color: colors.danger, size: 32),
              const SizedBox(height: 12),
              Text(
                context.t('errors.title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: context.t('common.retry'),
                variant: AppButtonVariant.outline,
                fullWidth: false,
                onPressed: () => ref.invalidate(profileProvider),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: context.t('settings.signOut'),
                variant: AppButtonVariant.outlineDanger,
                fullWidth: false,
                onPressed: () => ref.read(authServiceProvider).signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
