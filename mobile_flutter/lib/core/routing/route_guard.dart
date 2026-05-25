import 'routes.dart';

/// Pure state-machine for the post-auth routing contract (spec §5.3).
///
/// Returns the absolute path to navigate to, or `null` when the caller
/// should keep showing the splash spinner (session or profile still
/// loading). Inputs are plain booleans so this stays trivially testable.
String? resolveNextRoute({
  required bool sessionLoading,
  required bool hasSession,
  bool profileLoading = false,
  bool suspended = false,
  bool onboarded = false,
}) {
  if (sessionLoading) return null;
  if (!hasSession) return Routes.signIn;
  if (profileLoading) return null;
  if (suspended) return Routes.suspended;
  if (!onboarded) return Routes.onboardingGoal;
  return Routes.home;
}
