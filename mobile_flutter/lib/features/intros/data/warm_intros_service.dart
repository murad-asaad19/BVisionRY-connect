import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/warm_suggestion.dart';

/// Test-seam abstraction over the warm-intro RPC surface:
/// `suggest_warm_intros`, `send_warm_request`, `forward_warm_intro`.
abstract class WarmIntrosGateway {
  Future<Object?> rpc(String name, {Map<String, dynamic>? params});
}

class SupabaseWarmIntrosGateway implements WarmIntrosGateway {
  SupabaseWarmIntrosGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) =>
      _client.rpc(name, params: params);
}

final Provider<WarmIntrosService> warmIntrosServiceProvider =
    Provider<WarmIntrosService>((Ref<WarmIntrosService> ref) {
  return WarmIntrosService(
    SupabaseWarmIntrosGateway(ref.watch(supabaseClientProvider)),
  );
});

/// Wraps the three warm-intro RPCs.
///
/// Per spec §3.3:
/// - `suggest_warm_intros(p_limit)` returns rows of 2nd-degree targets
///   accessible through one or more mutuals.
/// - `send_warm_request(p_mutual_id, p_target_id, p_note)` inserts a
///   `warm_request` intro from the caller to the mutual; raises `23505`
///   when the caller has shotgun-ed the same target across multiple
///   mutuals.
/// - `forward_warm_intro(p_intro_id, p_note)` inserts the resulting
///   `warm_forward` intro from the mutual to the target.
///
/// Each call trims the note before sending so the server-side
/// `char_length(btrim(note))` check operates on the same value the user
/// will see displayed.
class WarmIntrosService {
  WarmIntrosService(this._gateway);

  final WarmIntrosGateway _gateway;

  /// Returns up to [limit] 2nd-degree warm-intro suggestions for the
  /// caller. Default `10` matches the gallery strip's design budget.
  Future<List<WarmSuggestion>> suggestWarmIntros({int limit = 10}) async {
    try {
      final raw = await _gateway.rpc(
        'suggest_warm_intros',
        params: <String, dynamic>{'p_limit': limit},
      );
      final rows = (raw as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();
      return rows.map(WarmSuggestion.fromJson).toList(growable: false);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Asks [mutualId] to introduce the caller to [targetId]. Returns the
  /// inserted intro's uuid.
  Future<String> sendWarmRequest({
    required String mutualId,
    required String targetId,
    required String note,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'send_warm_request',
        params: <String, dynamic>{
          'p_mutual_id': mutualId,
          'p_target_id': targetId,
          'p_note': note.trim(),
        },
      );
      return raw as String;
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Forwards a warm-request intro to the target with an optional note.
  /// Returns the resulting forward intro's uuid.
  Future<String> forwardWarmIntro({
    required String introId,
    required String note,
  }) async {
    try {
      final raw = await _gateway.rpc(
        'forward_warm_intro',
        params: <String, dynamic>{
          'p_intro_id': introId,
          'p_note': note.trim(),
        },
      );
      return raw as String;
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }
}
