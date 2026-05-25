import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_signals.freezed.dart';
part 'profile_signals.g.dart';

/// Decoder for `avg_meeting_rating` — the RPC may serialise the column as an
/// int (e.g. exactly `5`), as a double (`4.3`), or as null when the user
/// has fewer than 3 meeting reviews. We funnel everything through `num` so
/// either numeric encoding round-trips to a `double?`.
double? _avgFromJson(Object? value) =>
    value == null ? null : (value as num).toDouble();

/// Output shape of the `get_profile_signals` RPC (spec §3.1).
///
/// `avgMeetingRating` is NULL until at least 3 meeting reviews exist — the
/// SQL function enforces this floor server-side, and [showRating] is a
/// belt-and-braces guard the UI consults before rendering, per spec §17.6.
@freezed
class ProfileSignals with _$ProfileSignals {
  const ProfileSignals._();

  const factory ProfileSignals({
    @JsonKey(name: 'mutual_connection_count')
    @Default(0)
        int mutualConnectionCount,
    @JsonKey(name: 'mutual_top_user_ids')
    @Default(<String>[])
        List<String> mutualTopUserIds,
    @JsonKey(name: 'avg_meeting_rating', fromJson: _avgFromJson)
        double? avgMeetingRating,
    @JsonKey(name: 'total_meeting_reviews')
    @Default(0)
        int totalMeetingReviews,
  }) = _ProfileSignals;

  /// All-zeros / no-rating signals row. Used when the RPC returns an empty
  /// record (self-view, blocked pair) so the row controller never has to
  /// branch on null. Spelled as a static-const indirection (rather than a
  /// second freezed union case) so it keeps the same shape and `showRating`
  /// helper as a parsed row.
  static const ProfileSignals empty = ProfileSignals();

  factory ProfileSignals.fromJson(Map<String, dynamic> json) =>
      _$ProfileSignalsFromJson(json);

  /// Per spec §17.6 — the average rating MUST be hidden until the user has
  /// 3 or more meeting reviews. Belt-and-braces guard against a future RPC
  /// regression that drops the floor.
  bool get showRating =>
      avgMeetingRating != null && totalMeetingReviews >= 3;
}
