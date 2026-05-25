import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_filters.freezed.dart';
part 'feed_filters.g.dart';

/// User-selectable feed filters shared by the search screen and the home
/// thin-pool nudge. Mirrors the RN `feedFiltersStore` shape (Zustand) so
/// values can be hydrated from either app's `shared_preferences`.
///
/// Convention: only [roles], [goalTypes], [country] are persisted; [query]
/// is intentionally NOT persisted (matches the RN store's partial-persist).
@freezed
class FeedFilters with _$FeedFilters {
  const FeedFilters._();

  const factory FeedFilters({
    @Default('') String query,
    @Default(<String>[]) List<String> roles,
    @Default(<String>[]) List<String> goalTypes,
    String? country,
  }) = _FeedFilters;

  factory FeedFilters.fromJson(Map<String, dynamic> json) =>
      _$FeedFiltersFromJson(json);

  /// True when any filter is set — used to decide whether the inline filter
  /// bar should render the "+ Filter" affordance vs the active chips.
  bool get isActive =>
      query.isNotEmpty ||
      roles.isNotEmpty ||
      goalTypes.isNotEmpty ||
      country != null;

  /// Returns a JSON map suitable for persisting to `shared_preferences`,
  /// stripping the [query] (which is session-only, never persisted).
  Map<String, dynamic> persistedJson() {
    final json = toJson();
    json.remove('query');
    return json;
  }
}
