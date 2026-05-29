import 'routes.dart';

/// Path prefixes anon visitors may reach without bouncing through /sign-in.
///
/// `/p/:handle` is the canonical public profile preview. `/waitlist` is the
/// pre-auth join-the-waitlist screen reachable from sign-in. `/legal/` (Terms
/// of Service + Privacy Policy) are public documents linked from the sign-up
/// form and the consent interstitial, so they must be readable with no session
/// and from any gate state. The route guard returns `null` (no redirect) for
/// any location matching one of these prefixes, even when there is no current
/// session.
const Set<String> _kAnonAllowedPrefixes = <String>{'/p/', '/waitlist', '/legal/'};

/// Returns `true` when [location] is a public-only path that the route guard
/// must let through without a session.
bool isAnonAllowed(String location) {
  for (final String prefix in _kAnonAllowedPrefixes) {
    if (location.startsWith(prefix)) return true;
  }
  return false;
}

/// Pure state-machine for the post-auth routing contract (spec §5.3).
///
/// Returns the absolute path to navigate to, or `null` when the caller
/// should keep showing the splash spinner (session or profile still
/// loading). Inputs are plain booleans so this stays trivially testable.
///
/// When [currentLocation] points at an anon-allowed path the guard returns
/// `null` regardless of session state — anon users may freely visit
/// `/p/:handle` previews.
///
/// [consentRecorded] gates the age + legal consent interstitial: an authed
/// user whose profile carries no recorded consent (OAuth / magic-link / handle
/// sign-ups that skip the sign-up form's inline gate) is routed to
/// [Routes.consent] before onboarding. Defaults to `true` so the many existing
/// callers / tests that don't supply it keep their prior behaviour (no gate).
String? resolveNextRoute({
  required bool sessionLoading,
  required bool hasSession,
  bool profileLoading = false,
  bool suspended = false,
  bool consentRecorded = true,
  bool onboarded = false,
  String? currentLocation,
}) {
  if (currentLocation != null && isAnonAllowed(currentLocation)) return null;
  if (sessionLoading) return null;
  if (!hasSession) return Routes.signIn;
  if (profileLoading) return null;
  if (suspended) return Routes.suspended;
  if (!consentRecorded) return Routes.consent;
  if (!onboarded) return Routes.onboardingGoal;
  return Routes.home;
}
