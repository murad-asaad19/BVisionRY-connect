/// Canonical catalog of every named path in the app.
///
/// Add new routes here so the rest of the codebase can refer to them
/// symbolically; never inline path strings in `context.go(...)` calls.
/// Dynamic routes (those with an id segment) are exposed as static helpers
/// that return the resolved path string.
abstract final class Routes {
  // Top-level / auth
  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String authCallback = '/auth';
  static const String suspended = '/suspended';

  // Onboarding flow
  static const String onboardingGoal = '/onboarding/goal';
  static const String onboardingIdentity = '/onboarding/identity';
  static const String onboardingRoles = '/onboarding/roles';
  static const String onboardingAbout = '/onboarding/about';

  // App shell tabs
  static const String home = '/home';
  static const String inbox = '/inbox';
  static const String network = '/network';
  static const String opportunities = '/opportunities';
  static const String chats = '/chats';

  // Connections list (full-screen, dedicated route)
  static const String connections = '/connections';

  // Discovery
  static const String search = '/search';

  // Detail routes (dynamic)
  static String chat(String id) => '/chats/$id';
  static String intro(String id) => '/intros/$id';
  static String opportunity(String id) => '/opportunities/$id';
  static String publicProfile(String handle) => '/p/$handle';
  static String meetingReview(String meetingId) =>
      '/meetings/$meetingId/review';

  // Opportunities sub-routes (composer / edit / interested-list / my list).
  // The opportunity detail route is exposed by [opportunity] above.
  static const String opportunityNew = '/opportunities/new';
  static const String myOpportunities = '/opportunities/mine';
  static String opportunityEdit(String id) => '/opportunities/$id/edit';
  static String opportunityInterested(String id) =>
      '/opportunities/$id/interested';

  // Profile
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';

  // My bookings (office hours bookings list)
  static const String myBookings = '/bookings';

  // Settings
  static const String settings = '/settings';
  static const String settingsAccount = '/settings/account';
  static const String settingsPrivacy = '/settings/privacy';
  static const String settingsNotifications = '/settings/notifications';
  static const String settingsVerification = '/settings/verification';
  static const String settingsBlocked = '/settings/blocked-users';
  static const String settingsOfficeHours = '/settings/office-hours';
  static const String settingsHelp = '/settings/help';

  // Legal
  static const String legalPrivacy = '/legal/privacy';
  static const String legalTerms = '/legal/terms';

  // Misc
  static const String notFound = '/404';
}
