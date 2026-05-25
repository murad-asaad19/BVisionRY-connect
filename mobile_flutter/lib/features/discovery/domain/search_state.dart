import 'package:freezed_annotation/freezed_annotation.dart';

import 'discovery_profile.dart';

part 'search_state.freezed.dart';

/// Paginated search result snapshot held by [SearchController].
///
/// Pagination is keyset-style — [cursor] is the last seen
/// `created_at` and is sent as `p_cursor` on the next RPC call.
@freezed
class SearchState with _$SearchState {
  const factory SearchState({
    @Default(<DiscoveryProfile>[]) List<DiscoveryProfile> items,
    DateTime? cursor,
    @Default(true) bool hasMore,
    @Default(false) bool loadingMore,
  }) = _SearchState;
}
