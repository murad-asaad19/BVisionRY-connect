import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/profile.dart';

/// Test-seam abstraction over the slice of `SupabaseClient` that
/// [PeerProfileService] touches — a single id-based row fetch from
/// `public.profiles`.
///
/// Concrete adapter binds to the live client; widget tests inject an
/// in-memory fake.
abstract class PeerProfileGateway {
  /// `from('profiles').select('id, handle, name, photo_url, primary_role,
  /// verified_github_username').eq('id', id).maybeSingle()`.
  Future<Map<String, dynamic>?> fetchById(String id);
}

class SupabasePeerProfileGateway implements PeerProfileGateway {
  SupabasePeerProfileGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> fetchById(String id) async {
    return _client
        .from('profiles')
        .select(
          'id, handle, name, photo_url, primary_role, verified_github_username',
        )
        .eq('id', id)
        .maybeSingle();
  }
}

/// Lightweight id-based profile lookup used by Intros / Connections UI to
/// resolve a peer's identity (avatar, name, handle, role, verified flag).
///
/// This complements [ProfileService] (caller-only "own" row) and
/// [PublicProfileService] (handle-based, anon-callable). Returns `null`
/// when the row doesn't exist — callers handle that as a fall-back-to-id
/// rendering hint.
class PeerProfileService {
  PeerProfileService(this._gateway);

  final PeerProfileGateway _gateway;

  Future<Profile?> fetchById(String id) async {
    try {
      final Map<String, dynamic>? row = await _gateway.fetchById(id);
      if (row == null) return null;
      return Profile.fromMap(row);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }
}

final Provider<PeerProfileService> peerProfileServiceProvider =
    Provider<PeerProfileService>((Ref<PeerProfileService> ref) {
  return PeerProfileService(
    SupabasePeerProfileGateway(ref.watch(supabaseClientProvider)),
  );
});
