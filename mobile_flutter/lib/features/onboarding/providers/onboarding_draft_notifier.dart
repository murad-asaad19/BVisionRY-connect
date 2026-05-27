import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_draft_repository.dart';
import '../domain/goal_type.dart';
import '../domain/onboarding_draft.dart';

/// Wizard state for the four-step onboarding flow. Every mutation writes
/// through to [OnboardingDraftRepository] so the draft survives an app
/// restart. The roles/primaryRole consistency invariant — primary must be a
/// member of roles or null — is enforced inside [updateRoles].
class OnboardingDraftNotifier extends AsyncNotifier<OnboardingDraft> {
  OnboardingDraftRepository? _repo;

  @override
  Future<OnboardingDraft> build() async {
    _repo = await ref.watch(onboardingDraftRepositoryProvider.future);
    return (await _repo!.read()) ?? const OnboardingDraft();
  }

  OnboardingDraft get _current => state.value ?? const OnboardingDraft();

  /// Stores [next] both in the Riverpod state and SharedPreferences. All
  /// updaters route through here.
  Future<void> _persist(OnboardingDraft next) async {
    state = AsyncData<OnboardingDraft>(next);
    await _repo?.write(next);
  }

  Future<void> updateGoalText(String value) =>
      _persist(_current.copyWith(goalText: value));

  Future<void> updateGoalType(GoalType? value) =>
      _persist(_current.copyWith(goalType: value));

  Future<void> updateName(String value) =>
      _persist(_current.copyWith(name: value));

  Future<void> updateHandle(String value) =>
      _persist(_current.copyWith(handle: value));

  /// Replaces the roles list. If the existing [primaryRole] is no longer a
  /// member of the new list it is cleared, preventing an inconsistent state
  /// from ever being persisted. When the user has selected at least one
  /// role but hasn't picked a primary yet, default the primary to the
  /// first role in the list — removes the "Next is disabled with no
  /// indication why" friction. The user can still change it manually via
  /// the primary-role pill row.
  Future<void> updateRoles(List<String> roles) {
    OnboardingDraft next = _current.copyWith(roles: roles);
    if (next.primaryRole != null && !next.roles.contains(next.primaryRole)) {
      next = next.copyWith(primaryRole: null);
    }
    if (next.primaryRole == null && next.roles.isNotEmpty) {
      next = next.copyWith(primaryRole: next.roles.first);
    }
    return _persist(next);
  }

  Future<void> updatePrimaryRole(String? role) =>
      _persist(_current.copyWith(primaryRole: role));

  Future<void> updateCity(String value) =>
      _persist(_current.copyWith(city: value));

  Future<void> updateCountry(String value) =>
      _persist(_current.copyWith(country: value));

  Future<void> updateHeadline(String? value) =>
      _persist(_current.copyWith(headline: value));

  Future<void> updateBio(String? value) =>
      _persist(_current.copyWith(bio: value));

  /// Clears persisted draft and rewinds wizard state to empty. Called by
  /// [OnboardingService] after a successful submit.
  Future<void> reset() async {
    await _repo?.clear();
    state = const AsyncData<OnboardingDraft>(OnboardingDraft());
  }
}

final AsyncNotifierProvider<OnboardingDraftNotifier, OnboardingDraft>
    onboardingDraftProvider =
    AsyncNotifierProvider<OnboardingDraftNotifier, OnboardingDraft>(
  OnboardingDraftNotifier.new,
);
