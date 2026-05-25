// ProfileSignals model — the row shape returned by `get_profile_signals`.
//
// Source of truth: spec §3.1 and the §17.6 "hide rating until 3+ reviews"
// gate, which we double-guard at the model layer so callers cannot
// accidentally render a partial average.
import 'package:connect_mobile/features/profile/domain/profile_signals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileSignals', () {
    test('parses RPC row (with rating)', () {
      final ProfileSignals s = ProfileSignals.fromJson(<String, dynamic>{
        'mutual_connection_count': 3,
        'mutual_top_user_ids': <String>['a', 'b', 'c'],
        'avg_meeting_rating': 4.3,
        'total_meeting_reviews': 5,
      });
      expect(s.mutualConnectionCount, 3);
      expect(s.mutualTopUserIds, <String>['a', 'b', 'c']);
      expect(s.avgMeetingRating, 4.3);
      expect(s.totalMeetingReviews, 5);
      expect(s.showRating, isTrue);
    });

    test('hides rating when fewer than 3 reviews (per spec §17.6)', () {
      final ProfileSignals s = ProfileSignals.fromJson(<String, dynamic>{
        'mutual_connection_count': 0,
        'mutual_top_user_ids': <String>[],
        'avg_meeting_rating': 4.0,
        'total_meeting_reviews': 2,
      });
      expect(s.showRating, isFalse);
    });

    test('hides rating when avg is null even if total >= 3', () {
      final ProfileSignals s = ProfileSignals.fromJson(<String, dynamic>{
        'mutual_connection_count': 0,
        'mutual_top_user_ids': <String>[],
        'avg_meeting_rating': null,
        'total_meeting_reviews': 5,
      });
      expect(s.showRating, isFalse);
    });

    test('parses numeric avg returned as int', () {
      final ProfileSignals s = ProfileSignals.fromJson(<String, dynamic>{
        'mutual_connection_count': 1,
        'mutual_top_user_ids': <String>['a'],
        'avg_meeting_rating': 5,
        'total_meeting_reviews': 4,
      });
      expect(s.avgMeetingRating, 5.0);
    });

    test('empty constant returns zeros', () {
      const ProfileSignals s = ProfileSignals.empty;
      expect(s.mutualConnectionCount, 0);
      expect(s.mutualTopUserIds, isEmpty);
      expect(s.avgMeetingRating, isNull);
      expect(s.totalMeetingReviews, 0);
      expect(s.showRating, isFalse);
    });
  });
}
