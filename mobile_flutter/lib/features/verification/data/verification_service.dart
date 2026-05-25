import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';

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
}

final Provider<VerificationService> verificationServiceProvider =
    Provider<VerificationService>((Ref<VerificationService> ref) {
  return VerificationService(
    SupabaseVerificationGateway(ref.watch(supabaseClientProvider)),
  );
});
