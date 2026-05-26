import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/opportunities_service.dart';
import '../domain/opportunity_kind.dart';
import '../domain/opportunity_with_author.dart';

/// Page size for the feed. Server-side `list_opportunities` defaults to 20
/// rows per call; the client uses the same constant so `hasMore` flips false
/// the moment a page comes back short.
const int kOpportunitiesPageSize = 20;

/// Immutable snapshot of the feed: items + active filters + pagination
/// bookkeeping.
@immutable
class OpportunitiesFeedState {
  const OpportunitiesFeedState({
    required this.items,
    required this.kinds,
    required this.remoteOnly,
    required this.search,
    required this.hasMore,
    required this.isLoadingMore,
    required this.nextOffset,
  });

  /// The rows fetched so far — never paged twice, never duplicated.
  final List<OpportunityWithAuthor> items;

  /// Active kind filter (server sees `null` when empty).
  final List<OpportunityKind> kinds;

  /// Active `remote_only` filter toggle.
  final bool remoteOnly;

  /// Active free-text search (server sees `null` when empty).
  final String? search;

  /// `true` when the last page came back full (= [kOpportunitiesPageSize]
  /// rows) — the scroll listener calls `loadMore()` while this is set.
  final bool hasMore;

  /// In-flight flag for `loadMore` so concurrent scrolls don't fire dupes.
  final bool isLoadingMore;

  /// Cursor passed as `p_offset` on the next `loadMore` call.
  final int nextOffset;

  /// Sentinel used by [copyWith] to distinguish "didn't pass this argument"
  /// from "pass `null`" — required because `search` is nullable.
  static const Object _sentinel = Object();

  OpportunitiesFeedState copyWith({
    List<OpportunityWithAuthor>? items,
    List<OpportunityKind>? kinds,
    bool? remoteOnly,
    Object? search = _sentinel,
    bool? hasMore,
    bool? isLoadingMore,
    int? nextOffset,
  }) {
    return OpportunitiesFeedState(
      items: items ?? this.items,
      kinds: kinds ?? this.kinds,
      remoteOnly: remoteOnly ?? this.remoteOnly,
      search: identical(search, _sentinel) ? this.search : search as String?,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      nextOffset: nextOffset ?? this.nextOffset,
    );
  }
}

/// Paginated AsyncNotifier backing the public opportunities feed.
///
/// State machine:
///   - Initial `build()` issues `list_opportunities` with the default filters
///     (no kinds, `remote_only=false`, no search) and seeds the cursor.
///   - `setFilters(...)` resets to page 1 with the new filters.
///   - `loadMore()` issues the next page (no-op when `hasMore` is false or a
///     load is in flight); preserves filter state.
///   - `refresh()` re-issues page 1 with the current filters (used by
///     pull-to-refresh and by the create / update / close mutations).
class OpportunitiesFeedNotifier extends AsyncNotifier<OpportunitiesFeedState> {
  @override
  Future<OpportunitiesFeedState> build() async {
    return _initialLoad(
      kinds: const <OpportunityKind>[],
      remoteOnly: false,
      search: null,
    );
  }

  Future<OpportunitiesFeedState> _initialLoad({
    required List<OpportunityKind> kinds,
    required bool remoteOnly,
    required String? search,
  }) async {
    final OpportunitiesService service = ref.read(opportunitiesServiceProvider);
    final List<OpportunityWithAuthor> rows = await service.listOpportunities(
      kinds: kinds,
      remoteOnly: remoteOnly,
      search: search,
      limit: kOpportunitiesPageSize,
      offset: 0,
    );
    return OpportunitiesFeedState(
      items: rows,
      kinds: kinds,
      remoteOnly: remoteOnly,
      search: search,
      hasMore: rows.length == kOpportunitiesPageSize,
      isLoadingMore: false,
      nextOffset: rows.length,
    );
  }

  /// Resets to page 1 with [kinds], [remoteOnly], [search] applied.
  /// Preserves the loading state so consumers don't see a flicker.
  Future<void> setFilters({
    required List<OpportunityKind> kinds,
    required bool remoteOnly,
    required String? search,
  }) async {
    state = const AsyncValue<OpportunitiesFeedState>.loading()
        .copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => _initialLoad(
        kinds: kinds,
        remoteOnly: remoteOnly,
        search: search,
      ),
    );
  }

  /// Appends the next page to the existing item list. No-op when there's
  /// nothing more to load or a fetch is already in flight.
  Future<void> loadMore() async {
    final OpportunitiesFeedState? current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncValue<OpportunitiesFeedState>.data(
      current.copyWith(isLoadingMore: true),
    );
    try {
      final List<OpportunityWithAuthor> rows =
          await ref.read(opportunitiesServiceProvider).listOpportunities(
                kinds: current.kinds,
                remoteOnly: current.remoteOnly,
                search: current.search,
                limit: kOpportunitiesPageSize,
                offset: current.nextOffset,
              );
      state = AsyncValue<OpportunitiesFeedState>.data(
        current.copyWith(
          items: <OpportunityWithAuthor>[...current.items, ...rows],
          hasMore: rows.length == kOpportunitiesPageSize,
          isLoadingMore: false,
          nextOffset: current.nextOffset + rows.length,
        ),
      );
    } catch (e, st) {
      state = AsyncValue<OpportunitiesFeedState>.error(e, st);
    }
  }

  /// Re-issues page 1 with the currently active filters.
  Future<void> refresh() async {
    final OpportunitiesFeedState? current = state.valueOrNull;
    state = const AsyncValue<OpportunitiesFeedState>.loading()
        .copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => _initialLoad(
        kinds: current?.kinds ?? const <OpportunityKind>[],
        remoteOnly: current?.remoteOnly ?? false,
        search: current?.search,
      ),
    );
  }
}

final AsyncNotifierProvider<OpportunitiesFeedNotifier, OpportunitiesFeedState>
    opportunitiesFeedProvider =
    AsyncNotifierProvider<OpportunitiesFeedNotifier, OpportunitiesFeedState>(
        OpportunitiesFeedNotifier.new);
