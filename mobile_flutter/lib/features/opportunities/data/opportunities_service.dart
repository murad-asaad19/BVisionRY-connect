import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_map.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/interested_user.dart';
import '../domain/opportunity_kind.dart';
import '../domain/opportunity_with_author.dart';
import '../domain/opportunity_with_counts.dart';

/// Test-seam abstraction over the Supabase RPC surface the Opportunities
/// feature touches. Mirrors the gateway pattern used by `IntrosService` /
/// `OfficeHoursService` so tests can fake every RPC without spinning up
/// Supabase.
abstract class OpportunitiesGateway {
  /// Generic RPC dispatch — all 7 opportunity RPCs flow through here.
  Future<Object?> rpc(String name, {Map<String, dynamic>? params});
}

/// Live adapter backed by [SupabaseClient].
class SupabaseOpportunitiesGateway implements OpportunitiesGateway {
  SupabaseOpportunitiesGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) =>
      _client.rpc(name, params: params);
}

/// Thin wrapper over the seven Opportunities RPCs (spec §3.7):
///
/// `list_opportunities`, `get_opportunity`, `create_opportunity`,
/// `update_opportunity`, `close_opportunity`, `express_interest`,
/// `list_my_opportunities`, `list_interested`.
///
/// All Postgrest errors are funnelled through [mapPostgrestError] so the UI
/// receives typed [AppException]s — `ForbiddenException` for `list_interested`
/// gating violations, `DuplicateException` for idempotent `express_interest`
/// re-clicks, `ValidationException` for server-side range checks.
class OpportunitiesService {
  OpportunitiesService(this._gateway);

  final OpportunitiesGateway _gateway;

  /// `list_opportunities(p_kinds, p_remote_only, p_search, p_limit, p_offset)`
  ///
  /// Returns the public feed (RLS pre-filtered to status=open, not expired,
  /// not blocked, author onboarded / non-private / not-suspended). Pass an
  /// empty [kinds] list to disable the kind filter (server sees `null`).
  Future<List<OpportunityWithAuthor>> listOpportunities({
    required List<OpportunityKind> kinds,
    required bool remoteOnly,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final Object? raw = await _gateway.rpc(
        'list_opportunities',
        params: <String, dynamic>{
          'p_kinds': kinds.isEmpty
              ? null
              : kinds.map((OpportunityKind k) => k.dbValue).toList(),
          'p_remote_only': remoteOnly,
          'p_search': search,
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      final List<Map<String, dynamic>> rows = _rows(raw);
      return rows.map(OpportunityWithAuthor.fromJson).toList(growable: false);
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `get_opportunity(p_id)` — returns the detail row including running
  /// `interested_count` and `viewer_has_expressed_interest`. Throws
  /// [NotFoundException] when the row is missing (e.g. RLS-hidden, deleted,
  /// or expired); the UI maps this to a tailored "no longer available"
  /// empty state.
  Future<OpportunityWithCounts> getOpportunity(String id) async {
    try {
      final Object? raw = await _gateway.rpc(
        'get_opportunity',
        params: <String, dynamic>{'p_id': id},
      );
      final List<Map<String, dynamic>> rows = _rows(raw);
      if (rows.isEmpty) {
        throw NotFoundException('opportunities.detail.notFound');
      }
      return OpportunityWithCounts.fromJson(rows.first);
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `create_opportunity(...)` — returns the new row's id.
  Future<String> createOpportunity({
    required OpportunityKind kind,
    required String title,
    required String body,
    required List<String> tags,
    String? locationCity,
    String? locationCountry,
    required bool remoteOk,
    required DateTime expiresAt,
  }) async {
    try {
      final Object? raw = await _gateway.rpc(
        'create_opportunity',
        params: <String, dynamic>{
          'p_kind': kind.dbValue,
          'p_title': title,
          'p_body': body,
          'p_tags': tags,
          'p_location_city': locationCity,
          'p_location_country': locationCountry,
          'p_remote_ok': remoteOk,
          'p_expires_at': expiresAt.toUtc().toIso8601String(),
        },
      );
      return raw as String;
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `update_opportunity(...)` — author-only. The RPC `RETURNS void`, so this
  /// returns `void`: callers invalidate `opportunityProvider`/feeds to repaint
  /// from the canonical fetch. (Previously this parsed a row from the void
  /// response, which threw on the always-null result and surfaced a *successful*
  /// edit as a save failure — review P1.)
  Future<void> updateOpportunity({
    required String id,
    required OpportunityKind kind,
    required String title,
    required String body,
    required List<String> tags,
    String? locationCity,
    String? locationCountry,
    required bool remoteOk,
    required DateTime expiresAt,
  }) async {
    try {
      await _gateway.rpc(
        'update_opportunity',
        params: <String, dynamic>{
          'p_id': id,
          'p_kind': kind.dbValue,
          'p_title': title,
          'p_body': body,
          'p_tags': tags,
          'p_location_city': locationCity,
          'p_location_country': locationCountry,
          'p_remote_ok': remoteOk,
          'p_expires_at': expiresAt.toUtc().toIso8601String(),
        },
      );
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `close_opportunity(p_id)` — author-only; flips `status='closed'` and
  /// stamps `closed_at=now()`. RPC `RETURNS void`; callers invalidate to
  /// repaint with the Closed state (see [updateOpportunity] for the prior
  /// false-failure bug this avoids).
  Future<void> closeOpportunity(String id) async {
    try {
      await _gateway.rpc(
        'close_opportunity',
        params: <String, dynamic>{'p_id': id},
      );
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `express_interest(p_opportunity_id, p_note)` — idempotent server-side.
  /// `note` is optional (server accepts `null`); when provided it must be
  /// 10–500 chars (the screen-level guard catches this before round-trip).
  Future<void> expressInterest({
    required String opportunityId,
    String? note,
  }) async {
    try {
      await _gateway.rpc(
        'express_interest',
        params: <String, dynamic>{
          'p_opportunity_id': opportunityId,
          'p_note': note,
        },
      );
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `list_my_opportunities()` — the caller's posts in any status, ordered
  /// by `created_at desc`. Each row carries `interested_count` so the My
  /// Opportunities screen can render the footer without a second roundtrip.
  Future<List<OpportunityWithAuthor>> listMyOpportunities() async {
    try {
      final Object? raw = await _gateway.rpc('list_my_opportunities');
      final List<Map<String, dynamic>> rows = _rows(raw);
      return rows.map(OpportunityWithAuthor.fromJson).toList(growable: false);
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// `list_interested(p_opportunity_id)` — author-only view of users who
  /// expressed interest. Non-authors get [ForbiddenException] (42501) and
  /// the UI renders a `Not allowed` empty state.
  Future<List<InterestedUser>> listInterested(String opportunityId) async {
    try {
      final Object? raw = await _gateway.rpc(
        'list_interested',
        params: <String, dynamic>{'p_opportunity_id': opportunityId},
      );
      final List<Map<String, dynamic>> rows = _rows(raw);
      return rows.map(InterestedUser.fromJson).toList(growable: false);
    } catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// Normalises a List-of-maps RPC payload into a typed list.
  static List<Map<String, dynamic>> _rows(Object? raw) {
    if (raw == null) return const <Map<String, dynamic>>[];
    return (raw as List)
        .map((Object? r) => Map<String, dynamic>.from(r! as Map))
        .toList(growable: false);
  }
}

/// Riverpod handle to the configured [OpportunitiesService] singleton.
final Provider<OpportunitiesService> opportunitiesServiceProvider =
    Provider<OpportunitiesService>((Ref<OpportunitiesService> ref) {
  return OpportunitiesService(
    SupabaseOpportunitiesGateway(ref.watch(supabaseClientProvider)),
  );
});
