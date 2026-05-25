import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/daily_match.dart';
import '../domain/discovery_profile.dart';

/// Riverpod accessor for the [DiscoveryService] singleton.
final Provider<DiscoveryService> discoveryServiceProvider =
    Provider<DiscoveryService>((Ref<DiscoveryService> ref) {
  return DiscoveryService(ref.watch(supabaseClientProvider));
});

/// Thin wrapper over the four Supabase RPCs the Discovery feature consumes:
///
/// - `get_daily_matches(p_for_date)` — today's picks for the caller
/// - `mark_match_viewed(p_match_id)` — best-effort view-tracking
/// - `is_mutual_match(p_other)` — used by profile screens
/// - `search_discoverable_profiles(...)` — keyset-paginated discoverable feed
///
/// Errors are normalised through [mapPostgrestError] so providers downstream
/// receive typed [AppException]s. `markMatchViewed` is the one exception —
/// failures are swallowed silently because the call is idempotent and
/// fired-and-forget from a visibility detector.
class DiscoveryService {
  DiscoveryService(this._client);

  final SupabaseClient _client;

  /// Sentinel matching the Postgres default for
  /// `search_discoverable_profiles(p_cursor default '9999-12-31')` —
  /// used as the keyset cursor for the first page.
  static final DateTime _maxCursor = DateTime.utc(9999, 12, 31);

  /// Fetches today's daily matches.
  ///
  /// When [date] is provided, sends it as `p_for_date` (YYYY-MM-DD). When
  /// omitted, the server defaults to the caller's current local day.
  Future<List<DailyMatch>> fetchDailyMatches({DateTime? date}) async {
    try {
      final params = <String, dynamic>{};
      if (date != null) {
        params['p_for_date'] = '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';
      }
      final rows = await _client.rpc<List<Map<String, dynamic>>>(
        'get_daily_matches',
        params: params,
      );
      return rows.map(DailyMatch.fromJson).toList(growable: false);
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Stamps `viewed_at` on a match row. The server enforces caller-owned +
  /// still-null; we swallow all errors silently so visibility detectors
  /// never surface them to the UI.
  Future<void> markMatchViewed(String matchId) async {
    try {
      await _client.rpc<void>(
        'mark_match_viewed',
        params: <String, dynamic>{'p_match_id': matchId},
      );
    } catch (_) {
      // intentional: idempotent + best-effort.
    }
  }

  /// Returns `true` when the caller and [otherUserId] are mutually connected.
  Future<bool> isMutualMatch(String otherUserId) async {
    try {
      final v = await _client.rpc<bool>(
        'is_mutual_match',
        params: <String, dynamic>{'p_other': otherUserId},
      );
      return v;
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Keyset-paginated search over discoverable profiles. `cursor` is the
  /// `created_at` of the last seen row; pass `null` for the first page
  /// (a max-date sentinel is sent under the hood).
  Future<List<DiscoveryProfile>> searchDiscoverableProfiles({
    String query = '',
    List<String> roles = const <String>[],
    List<String> goalTypes = const <String>[],
    String? country,
    DateTime? cursor,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_query': query,
        'p_roles': roles,
        'p_goal_types': goalTypes,
        'p_country': country,
        'p_cursor': (cursor ?? _maxCursor).toUtc().toIso8601String(),
        'p_limit': limit,
      };
      final rows = await _client.rpc<List<Map<String, dynamic>>>(
        'search_discoverable_profiles',
        params: params,
      );
      return rows
          .map((m) => DiscoveryProfile.fromJson(m.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }
}
