import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';

part 'public_profile_service.freezed.dart';
part 'public_profile_service.g.dart';

/// Trimmed Profile shape returned by `get_public_profile` (spec §3.1).
///
/// The RPC is granted to PUBLIC so anonymous visitors at `/p/:handle` can
/// resolve a profile. We only expose columns that are safe to surface to
/// anon callers: identity, role, location, and the verified GitHub handle
/// (the SQL function gates that column behind `public_investor_page = true`
/// — when false, it returns NULL for the field).
@freezed
class PublicProfile with _$PublicProfile {
  const factory PublicProfile({
    required String id,
    required String handle,
    String? name,
    @JsonKey(name: 'photo_url') String? photoUrl,
    String? headline,
    String? bio,
    @JsonKey(name: 'primary_role') String? primaryRole,
    @Default(<String>[]) List<String> roles,
    String? city,
    String? country,
    @JsonKey(name: 'verified_github_username')
        String? verifiedGithubUsername,
  }) = _PublicProfile;

  factory PublicProfile.fromJson(Map<String, dynamic> json) =>
      _$PublicProfileFromJson(json);
}

/// Test-seam abstraction over the `rpc('get_public_profile', ...)` call.
/// Tests inject a fake; production binds to the live client.
abstract class PublicProfileGateway {
  Future<Object?> getPublicProfile(String handle);
}

class SupabasePublicProfileGateway implements PublicProfileGateway {
  SupabasePublicProfileGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<Object?> getPublicProfile(String handle) {
    return _client.rpc(
      'get_public_profile',
      params: <String, dynamic>{'p_handle': handle},
    );
  }
}

/// Anon-callable lookup behind `/p/:handle`. Returns `null` when the handle
/// doesn't resolve (no row, suspended, private mode on, not onboarded).
///
/// Handle is normalised (lower-cased + trimmed) before being sent — the
/// `profiles.handle` column is citext so the DB compares case-insensitively
/// but lowercase is the canonical stored form and avoids surprises.
class PublicProfileService {
  PublicProfileService(this._gateway);
  final PublicProfileGateway _gateway;

  Future<PublicProfile?> getPublicProfile(String handle) async {
    final String normalised = handle.toLowerCase().trim();
    try {
      final Object? raw = await _gateway.getPublicProfile(normalised);
      // The RPC may return a List<Map> (default Postgrest row shape) or a
      // single Map (when called via SECURITY DEFINER with `returns json`).
      // Guard both.
      if (raw == null) return null;
      if (raw is List) {
        if (raw.isEmpty) return null;
        return PublicProfile.fromJson(
          Map<String, dynamic>.from(raw.first as Map),
        );
      }
      if (raw is Map) {
        return PublicProfile.fromJson(Map<String, dynamic>.from(raw));
      }
      return null;
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }
}

final Provider<PublicProfileService> publicProfileServiceProvider =
    Provider<PublicProfileService>((Ref<PublicProfileService> ref) {
  return PublicProfileService(
    SupabasePublicProfileGateway(ref.watch(supabaseClientProvider)),
  );
});
