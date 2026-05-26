import 'package:connect_mobile/features/meetings/domain/meeting_review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MeetingReviewOutcome.fromJson maps the three DB values', () {
    expect(MeetingReviewOutcome.fromJson('useful'), MeetingReviewOutcome.useful);
    expect(
      MeetingReviewOutcome.fromJson('not_useful'),
      MeetingReviewOutcome.notUseful,
    );
    expect(MeetingReviewOutcome.fromJson('no_show'), MeetingReviewOutcome.noShow);
    expect(() => MeetingReviewOutcome.fromJson('bad'), throwsArgumentError);
  });

  test('MeetingReviewOutcome.ratingScore matches get_profile_signals mapping',
      () {
    expect(MeetingReviewOutcome.useful.ratingScore, 5);
    expect(MeetingReviewOutcome.notUseful.ratingScore, 2);
    expect(MeetingReviewOutcome.noShow.ratingScore, 1);
  });

  test('MeetingReview.fromJson parses RPC row', () {
    final r = MeetingReview.fromJson({
      'id': 'rid',
      'meeting_id': 'mid',
      'reviewer_id': 'uid',
      'outcome': 'useful',
      'note': 'great',
      'created_at': '2026-05-25T10:00:00Z',
    });
    expect(r.outcome, MeetingReviewOutcome.useful);
    expect(r.note, 'great');
  });
}
