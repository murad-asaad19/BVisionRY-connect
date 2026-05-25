import 'package:shared_preferences/shared_preferences.dart';

/// Common surface for the SharedPreferences-backed Zustand-equivalent stores
/// that must be cleared when the user signs out. Implementations live in
/// the feature phases that own them; Phase 2 ships placeholder stubs.
abstract class PersistedStore {
  /// Clear any persisted state owned by this store.
  Future<void> reset();
}

/// Cached feed-filter selection. Real implementation lands in Phase 5.
class FeedFiltersStore implements PersistedStore {
  static const String _key = 'connect.feed_filters';
  @override
  Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}

/// "Complete your profile" nudge dismissal state. Real implementation lands
/// in Phase 10.
class ProfileNudgeStore implements PersistedStore {
  static const String _key = 'connect.profile_nudge';
  @override
  Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}

/// In-progress onboarding form draft. Real implementation lands in Phase 4.
class OnboardingDraftStore implements PersistedStore {
  static const String _key = 'connect.onboarding_draft';
  @override
  Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}

/// Telemetry consent must be FORCED to opt-out on sign-out per GDPR
/// (spec §5.1). The Phase 14 telemetry controller will subscribe to this
/// key; here we just persist the boolean.
class TelemetryConsentStore implements PersistedStore {
  static const String _key = 'connect.telemetry_consent';

  /// Set the consent flag to `false` (the canonical sign-out behaviour).
  Future<void> forceOptOut() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, false);
  }

  @override
  Future<void> reset() => forceOptOut();
}

/// Bundle of every persisted store that must reset on sign-out. Phases that
/// add new stores expose them on this object so `resetAllOnSignOut` keeps
/// covering the full surface.
class PersistedStores {
  PersistedStores({
    FeedFiltersStore? feed,
    ProfileNudgeStore? nudge,
    OnboardingDraftStore? onboarding,
    TelemetryConsentStore? telemetry,
  }) : feedFilters = feed ?? FeedFiltersStore(),
       profileNudge = nudge ?? ProfileNudgeStore(),
       onboardingDraft = onboarding ?? OnboardingDraftStore(),
       telemetryConsent = telemetry ?? TelemetryConsentStore();

  final FeedFiltersStore feedFilters;
  final ProfileNudgeStore profileNudge;
  final OnboardingDraftStore onboardingDraft;
  final TelemetryConsentStore telemetryConsent;

  /// Reset every persisted store in parallel and force telemetry opt-out.
  /// Tolerates individual failures — never blocks sign-out.
  Future<void> resetAllOnSignOut() async {
    await Future.wait(<Future<void>>[
      feedFilters.reset(),
      profileNudge.reset(),
      onboardingDraft.reset(),
      telemetryConsent.forceOptOut(),
    ]);
  }
}
