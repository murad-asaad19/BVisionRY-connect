import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/discovery_service.dart';
import '../domain/discovery_profile.dart';
import '../domain/feed_filters.dart';
import '../domain/search_state.dart';
import 'feed_filters_provider.dart';

const int _kPageSize = 20;
const Duration _kDebounce = Duration(milliseconds: 300);

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
    final filters = await ref.watch(feedFiltersProvider.future);
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

  Future<void> applyFilters({
    List<String>? roles,
    List<String>? goalTypes,
    String? country,
  }) async {
    final ctrl = ref.read(feedFiltersProvider.notifier);
    if (roles != null) await ctrl.setRoles(roles);
    if (goalTypes != null) await ctrl.setGoalTypes(goalTypes);
    await ctrl.setCountry(country);
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
      () => _loadPage(filters, cursor: null, existing: const <DiscoveryProfile>[]),
    );
  }
}
