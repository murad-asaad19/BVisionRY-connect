import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/profile_signals.dart';

/// Test-seam abstraction over the `rpc('get_profile_signals', ...)` call.
abstract class ProfileSignalsGateway {
  Future<Object?> getProfileSignals(String targetUserId);
}

class SupabaseProfileSignalsGateway implements ProfileSignalsGateway {
  SupabaseProfileSignalsGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<Object?> getProfileSignals(String targetUserId) {
    return _client.rpc(
      'get_profile_signals',
      params: <String, dynamic>{'p_target': targetUserId},
    );
  }
}

/// Fetches the meeting + mutual-connection signals for a third-party profile.
///
/// Returns [ProfileSignals.empty] when the RPC returns nothing — self-view,
/// blocked pair, and brand-new account all funnel through that single empty
/// record so the UI layer never has to branch on null. Spec §3.1.
class ProfileSignalsService {
  ProfileSignalsService(this._gateway);
  final ProfileSignalsGateway _gateway;

  Future<ProfileSignals> fetchSignals(String targetUserId) async {
    try {
      final Object? raw = await _gateway.getProfileSignals(targetUserId);
      if (raw == null) return ProfileSignals.empty;
      if (raw is List) {
        if (raw.isEmpty) return ProfileSignals.empty;
        return ProfileSignals.fromJson(
          Map<String, dynamic>.from(raw.first as Map),
        );
      }
      if (raw is Map) {
        return ProfileSignals.fromJson(Map<String, dynamic>.from(raw));
      }
      return ProfileSignals.empty;
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }
}

final Provider<ProfileSignalsService> profileSignalsServiceProvider =
    Provider<ProfileSignalsService>((Ref<ProfileSignalsService> ref) {
  return ProfileSignalsService(
    SupabaseProfileSignalsGateway(ref.watch(supabaseClientProvider)),
  );
});
