import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/discovery_service.dart';
import '../domain/discovery_profile.dart';
import '../domain/feed_filters.dart';
import '../domain/search_state.dart';
import 'feed_filters_provider.dart';

const int _kPageSize = 20;
const Duration _kDebounce = Duration(milliseconds: 300);

/// Sentinel marker used by [SearchController.applyFilters] to distinguish
/// "caller passed no value for this argument" from "caller explicitly passed
/// `null` to clear it". Defined as a private const Object so it cannot
/// collide with any caller-supplied value.
const Object _kUnset = Object();

/// Async-loaded, debounce-paginated search controller backed by
/// `search_discoverable_profiles`. Keyset cursor is the last seen item's
/// `created_at`; the service shim sends a max-date sentinel for the first
/// page.
final AsyncNotifierProvider<SearchController, SearchState> searchProvider =
    AsyncNotifierProvider<SearchController, SearchState>(
  SearchController.new,
);

class SearchController extends AsyncNotifier<SearchState> {
  Timer? _debounce;

  @override
  Future<SearchState> build() async {
    ref.onDispose(() => _debounce?.cancel());
    // NB: We deliberately use `ref.read` (not `ref.watch`) for the initial
    // load so writes to `feedFiltersProvider` from our own setters don't
    // re-trigger `build()`. Reloads are driven explicitly via `_reload()`.
    final filters = await ref.read(feedFiltersProvider.future);
    return _loadPage(
      filters,
      cursor: null,
      existing: const <DiscoveryProfile>[],
    );
  }

  Future<SearchState> _loadPage(
    FeedFilters filters, {
    required DateTime? cursor,
    required List<DiscoveryProfile> existing,
  }) async {
    final service = ref.read(discoveryServiceProvider);
    final rows = await service.searchDiscoverableProfiles(
      query: filters.query,
      roles: filters.roles,
      goalTypes: filters.goalTypes,
      country: filters.country,
      cursor: cursor,
      limit: _kPageSize,
    );
    return SearchState(
      items: <DiscoveryProfile>[...existing, ...rows],
      cursor: rows.isEmpty ? cursor : rows.last.createdAt,
      hasMore: rows.length >= _kPageSize,
    );
  }

  Future<void> loadMore() async {
    final cur = state.value;
    if (cur == null || !cur.hasMore || cur.loadingMore) return;
    state = AsyncData(cur.copyWith(loadingMore: true));
    final filters = await ref.read(feedFiltersProvider.future);
    state = await AsyncValue.guard<SearchState>(
      () => _loadPage(filters, cursor: cur.cursor, existing: cur.items),
    );
  }

  Future<void> setQuery(String query) async {
    final ctrl = ref.read(feedFiltersProvider.notifier);
    await ctrl.setQuery(query);
    _debounce?.cancel();
    _debounce = Timer(_kDebounce, _reload);
  }

  /// Updates any subset of {roles, goalTypes, country} and triggers a single
  /// reload.
  ///
  /// Each parameter defaults to the [_kUnset] sentinel — callers that omit
  /// an argument leave that filter untouched. Pass `null` for [country] to
  /// explicitly clear the country filter, and an empty list for [roles] /
  /// [goalTypes] to clear those.
  Future<void> applyFilters({
    Object? roles = _kUnset,
    Object? goalTypes = _kUnset,
    Object? country = _kUnset,
  }) async {
    final ctrl = ref.read(feedFiltersProvider.notifier);
    if (!identical(roles, _kUnset)) {
      await ctrl.setRoles(roles as List<String>);
    }
    if (!identical(goalTypes, _kUnset)) {
      await ctrl.setGoalTypes(goalTypes as List<String>);
    }
    if (!identical(country, _kUnset)) {
      await ctrl.setCountry(country as String?);
    }
    await _reload();
  }

  Future<void> resetFilters() async {
    await ref.read(feedFiltersProvider.notifier).reset();
    await _reload();
  }

  Future<void> _reload() async {
    state = const AsyncLoading<SearchState>().copyWithPrevious(state);
    final filters = await ref.read(feedFiltersProvider.future);
    state = await AsyncValue.guard<SearchState>(
      () => _loadPage(
        filters,
        cursor: null,
        existing: const <DiscoveryProfile>[],
      ),
    );
  }
}
