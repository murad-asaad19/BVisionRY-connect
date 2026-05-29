import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/onboarding_draft.dart';

/// Test-seam abstraction over the `finish_onboarding(...)` RPC. The concrete
/// [_SupabaseFinishOnboardingRunner] delegates to the real Supabase client;
/// tests inject an in-memory fake.
abstract class FinishOnboardingRunner {
  Future<void> finish(Map<String, dynamic> params);
}

class _SupabaseFinishOnboardingRunner implements FinishOnboardingRunner {
  _SupabaseFinishOnboardingRunner(this._client);
  final SupabaseClient _client;

  @override
  Future<void> finish(Map<String, dynamic> params) async {
    await _client.rpc<dynamic>('finish_onboarding', params: params);
  }
}

/// Finalises the four-step wizard via the `finish_onboarding` SECURITY
/// DEFINER RPC. Direct `profiles.update({...,'onboarded':true})` is rejected
/// (42501) because migration `20260606000000_rls_hardening.sql` revokes
/// column-level UPDATE on `onboarded` from authenticated; the RPC sets the
/// whole payload + flips the flag atomically under definer privileges.
class OnboardingService {
  OnboardingService(this._runner);
  final FinishOnboardingRunner _runner;

  /// Submits the [draft]. The server reads the caller's id from `auth.uid()`,
  /// so no explicit user id is forwarded. Throws [StateError] if the draft is
  /// missing a `goalType` — the caller should have caught that via
  /// [OnboardingSubmissionSchema] before calling this method.
  Future<void> submitOnboarding({
    required OnboardingDraft draft,
  }) async {
    if (draft.goalType == null) {
      throw StateError(
        'OnboardingService.submitOnboarding: draft.goalType is null. '
        'Call OnboardingSubmissionSchema.firstError before submitting.',
      );
    }

    final Map<String, dynamic> params = <String, dynamic>{
      'p_name': draft.name,
      'p_handle': draft.handle,
      // Empty strings round-trip as null so we don't store '' in
      // nullable text columns (the column CHECKs allow null but reject
      // zero-length non-null strings for headline/bio).
      'p_headline': _nullIfEmpty(draft.headline),
      'p_bio': _nullIfEmpty(draft.bio),
      'p_roles': draft.roles,
      'p_primary_role': draft.primaryRole,
      'p_city': draft.city,
      'p_country': draft.country,
      'p_goal_type': draft.goalType!.wire,
      'p_goal_text': draft.goalText,
    };

    try {
      await _runner.finish(params);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  static String? _nullIfEmpty(String? v) => (v == null || v.isEmpty) ? null : v;
}

final Provider<OnboardingService> onboardingServiceProvider =
    Provider<OnboardingService>((Ref<OnboardingService> ref) {
  return OnboardingService(
    _SupabaseFinishOnboardingRunner(ref.watch(supabaseClientProvider)),
  );
});
