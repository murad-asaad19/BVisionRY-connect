import 'routes.dart';

/// Path prefixes anon visitors may reach without bouncing through /sign-in.
///
/// `/p/:handle` is the canonical public profile preview. The route guard
/// returns `null` (no redirect) for any location matching one of these
/// prefixes, even when there is no current session.
const Set<String> _kAnonAllowedPrefixes = <String>{'/p/'};

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
String? resolveNextRoute({
  required bool sessionLoading,
  required bool hasSession,
  bool profileLoading = false,
  bool suspended = false,
  bool onboarded = false,
  String? currentLocation,
}) {
  if (currentLocation != null && isAnonAllowed(currentLocation)) return null;
  if (sessionLoading) return null;
  if (!hasSession) return Routes.signIn;
  if (profileLoading) return null;
  if (suspended) return Routes.suspended;
  if (!onboarded) return Routes.onboardingGoal;
  return Routes.home;
}
