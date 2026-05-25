import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/onboarding_draft.dart';

/// SharedPreferences-backed persistence for the in-progress onboarding draft.
/// Used by [OnboardingDraftNotifier] to rehydrate the wizard after an app
/// restart so the user does not lose typed text when the OS evicts the
/// process mid-flow.
///
/// The `v1` suffix on the storage key lets us bump the schema and ignore
/// older payloads (we degrade silently to `null` rather than throwing).
class OnboardingDraftRepository {
  OnboardingDraftRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'onboarding.draft.v1';

  /// Returns the persisted draft, or `null` when nothing is stored or the
  /// stored payload cannot be parsed (corrupt JSON, schema drift).
  Future<OnboardingDraft?> read() async {
    final String? raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return OnboardingDraft.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  /// Persists [draft] to SharedPreferences, overwriting any prior payload.
  Future<void> write(OnboardingDraft draft) async {
    await _prefs.setString(_key, jsonEncode(draft.toJson()));
  }

  /// Removes the persisted draft. Called on submit success and on `reset()`.
  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}

/// Shared `SharedPreferences` future — overridden in tests so the providers
/// graph stays test-friendly even when nothing else in Phase 1/2 created
/// this provider.
final FutureProvider<SharedPreferences> sharedPreferencesProvider =
    FutureProvider<SharedPreferences>(
  (Ref<AsyncValue<SharedPreferences>> ref) => SharedPreferences.getInstance(),
);

/// Public accessor for the draft repository. Async because acquiring a
/// `SharedPreferences` handle requires one round-trip to the platform.
final FutureProvider<OnboardingDraftRepository>
    onboardingDraftRepositoryProvider =
    FutureProvider<OnboardingDraftRepository>(
  (Ref<AsyncValue<OnboardingDraftRepository>> ref) async {
    final SharedPreferences prefs =
        await ref.watch(sharedPreferencesProvider.future);
    return OnboardingDraftRepository(prefs);
  },
);
