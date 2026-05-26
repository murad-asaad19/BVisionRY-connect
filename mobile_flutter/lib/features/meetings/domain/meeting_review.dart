import 'package:freezed_annotation/freezed_annotation.dart';

part 'meeting_review.freezed.dart';

/// Outcome the reviewer reports for a completed meeting (spec §2.9).
///
/// The [ratingScore] mapping is the exact translation
/// `get_profile_signals` applies when rolling reviews into trust
/// signals — keep it in sync with the server function.
enum MeetingReviewOutcome {
  useful('useful', 5),
  notUseful('not_useful', 2),
  noShow('no_show', 1);

  const MeetingReviewOutcome(this.dbValue, this.ratingScore);

  /// Wire value for the `outcome` column.
  final String dbValue;

  /// 1-5 score used by `get_profile_signals` (spec §3.5).
  final int ratingScore;

  static MeetingReviewOutcome fromJson(String v) => switch (v) {
        'useful' => MeetingReviewOutcome.useful,
        'not_useful' => MeetingReviewOutcome.notUseful,
        'no_show' => MeetingReviewOutcome.noShow,
        _ => throw ArgumentError('Unknown outcome: $v'),
      };

  String toJson() => dbValue;
}

/// One row from `public.meeting_reviews` (spec §2.9).
///
/// Created by `submit_meeting_review`. The note is optional; the
/// outcome is the load-bearing field that feeds `get_profile_signals`.
@freezed
class MeetingReview with _$MeetingReview {
  const factory MeetingReview({
    required String id,
    required String meetingId,
    required String reviewerId,
    required MeetingReviewOutcome outcome,
    String? note,
    required DateTime createdAt,
  }) = _MeetingReview;

  factory MeetingReview.fromJson(Map<String, dynamic> json) => MeetingReview(
        id: json['id'] as String,
        meetingId: json['meeting_id'] as String,
        reviewerId: json['reviewer_id'] as String,
        outcome: MeetingReviewOutcome.fromJson(json['outcome'] as String),
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      );
}
