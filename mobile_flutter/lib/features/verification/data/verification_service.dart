import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/verification_request.dart';

/// Test-seam abstraction over the `rpc(...)` calls the verification flow
/// makes. Concrete adapter binds to the live client; tests inject a fake.
abstract class VerificationGateway {
  Future<Object?> rpc(String name, {Map<String, dynamic>? params});
}

class SupabaseVerificationGateway implements VerificationGateway {
  SupabaseVerificationGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) =>
      _client.rpc(name, params: params);
}

/// Wraps the two SECURITY DEFINER GitHub-verification RPCs (spec §3.1,
/// §17.3). Column-level UPDATE on `profiles.verified_*` is revoked from
/// `authenticated`, so these RPCs are the ONLY path to set or clear those
/// columns.
class VerificationService {
  VerificationService(this._gateway);
  final VerificationGateway _gateway;

  /// Marks the caller's profile as verified with the supplied GitHub
  /// username + numeric id. The RPC itself enforces ownership; the client
  /// only normalises the handle (lowercase + trim) before sending.
  Future<void> setGithubVerification({
    required String username,
    required int githubId,
  }) async {
    try {
      await _gateway.rpc(
        'set_github_verification',
        params: <String, dynamic>{
          'p_github_username': username.toLowerCase().trim(),
          'p_github_id': githubId,
        },
      );
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Clears the caller's verified GitHub identity. No-arg RPC — the SQL
  /// function reads `auth.uid()` itself to identify the caller.
  Future<void> clearGithubVerification() async {
    try {
      await _gateway.rpc('clear_github_verification');
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Submits a manual-review verification proof for [kind] via
  /// `submit_verification`. The row lands `pending` for the team to review.
  ///
  /// [payload] carries whatever evidence the kind needs (e.g. a work email, a
  /// /team-page URL, a Crunchbase URL, portfolio links) for the human
  /// reviewer; the server defaults it to `{}`. Raises a typed exception
  /// (`already_pending` / `already_approved`) when a live submission already
  /// exists for this kind — see `mapPostgrestError`.
  Future<void> submitVerification(
    VerificationKind kind, {
    Map<String, dynamic>? payload,
  }) async {
    try {
      await _gateway.rpc(
        'submit_verification',
        params: <String, dynamic>{
          'p_kind': kind.wire,
          if (payload != null) 'p_payload': payload,
        },
      );
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Returns the caller's own verification submissions (one row per live
  /// proof) via `list_my_verifications`, newest-first. Rows carrying an enum
  /// value this client doesn't recognise are dropped.
  Future<List<VerificationRequest>> listMyVerifications() async {
    try {
      final Object? raw = await _gateway.rpc('list_my_verifications');
      if (raw == null) return const <VerificationRequest>[];
      return (raw as List<dynamic>)
          .map((Object? r) => Map<String, dynamic>.from(r! as Map))
          .map(VerificationRequest.fromJson)
          .whereType<VerificationRequest>()
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }
}

final Provider<VerificationService> verificationServiceProvider =
    Provider<VerificationService>((Ref<VerificationService> ref) {
  return VerificationService(
    SupabaseVerificationGateway(ref.watch(supabaseClientProvider)),
  );
});
