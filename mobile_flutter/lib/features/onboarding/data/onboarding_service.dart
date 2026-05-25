import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/onboarding_draft.dart';

/// Test-seam abstraction over the `profiles.update(...).eq('id', userId)`
/// chain. The concrete [_SupabaseProfileUpdateRunner] delegates to the real
/// Supabase client; tests inject an in-memory fake.
abstract class ProfileUpdateRunner {
  Future<void> update({
    required String userId,
    required Map<String, dynamic> patch,
  });
}

class _SupabaseProfileUpdateRunner implements ProfileUpdateRunner {
  _SupabaseProfileUpdateRunner(this._client);
  final SupabaseClient _client;

  @override
  Future<void> update({
    required String userId,
    required Map<String, dynamic> patch,
  }) async {
    await _client.from('profiles').update(patch).eq('id', userId);
  }
}

/// Finalises the four-step wizard by PATCH-ing every column the user filled
/// in plus setting `onboarded = true`. The DB trigger
/// `profiles_set_goal_updated_at` will populate `goal_updated_at` whenever
/// `goal_text` changes, so we don't send that column explicitly.
class OnboardingService {
  OnboardingService(this._runner);
  final ProfileUpdateRunner _runner;

  /// Submits the [draft] for [userId]. Throws [StateError] if the draft is
  /// missing a `goalType` — the caller should have caught that via
  /// [OnboardingSubmissionSchema] before calling this method.
  Future<void> submitOnboarding({
    required String userId,
    required OnboardingDraft draft,
  }) async {
    if (draft.goalType == null) {
      throw StateError(
        'OnboardingService.submitOnboarding: draft.goalType is null. '
        'Call OnboardingSubmissionSchema.firstError before submitting.',
      );
    }

    final Map<String, dynamic> patch = <String, dynamic>{
      'name': draft.name,
      'handle': draft.handle,
      // Empty strings round-trip as null so we don't store '' in
      // nullable text columns (the column CHECKs allow null but reject
      // zero-length non-null strings for headline/bio).
      'headline': _nullIfEmpty(draft.headline),
      'bio': _nullIfEmpty(draft.bio),
      'roles': draft.roles,
      'primary_role': draft.primaryRole,
      'city': draft.city,
      'country': draft.country,
      'goal_text': draft.goalText,
      'goal_type': draft.goalType!.wire,
      'onboarded': true,
    };

    try {
      await _runner.update(userId: userId, patch: patch);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  static String? _nullIfEmpty(String? v) => (v == null || v.isEmpty) ? null : v;
}

final Provider<OnboardingService> onboardingServiceProvider =
    Provider<OnboardingService>((Ref<OnboardingService> ref) {
  return OnboardingService(
    _SupabaseProfileUpdateRunner(ref.watch(supabaseClientProvider)),
  );
});
