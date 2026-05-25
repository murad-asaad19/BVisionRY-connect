// ProfileSignalsService — wraps the `get_profile_signals` RPC which returns
// the (mutual_connection_count, mutual_top_user_ids, avg_meeting_rating,
// total_meeting_reviews) tuple per spec §3.1.
import 'package:connect_mobile/features/profile/data/profile_signals_service.dart';
import 'package:connect_mobile/features/profile/domain/profile_signals.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGateway implements ProfileSignalsGateway {
  String? capturedTarget;
  Object? response;
  Object? throwable;

  @override
  Future<Object?> getProfileSignals(String targetUserId) async {
    capturedTarget = targetUserId;
    if (throwable != null) {
      // ignore: only_throw_errors
      throw throwable!;
    }
    return response;
  }
}

void main() {
  group('ProfileSignalsService', () {
    test('fetchSignals returns parsed signals when the row exists', () async {
      final _FakeGateway g = _FakeGateway()
        ..response = <Map<String, dynamic>>[
          <String, dynamic>{
            'mutual_connection_count': 4,
            'mutual_top_user_ids': <String>['a', 'b', 'c', 'd'],
            'avg_meeting_rating': 4.5,
            'total_meeting_reviews': 6,
          }
        ];
      final ProfileSignalsService svc = ProfileSignalsService(g);
      final ProfileSignals signals = await svc.fetchSignals('t');
      expect(g.capturedTarget, 't');
      expect(signals.mutualConnectionCount, 4);
      expect(signals.totalMeetingReviews, 6);
      expect(signals.showRating, isTrue);
    });

    test('returns the empty record when the RPC returns an empty list',
        () async {
      final _FakeGateway g = _FakeGateway()
        ..response = <Map<String, dynamic>>[];
      final ProfileSignalsService svc = ProfileSignalsService(g);
      final ProfileSignals signals = await svc.fetchSignals('self');
      expect(signals.mutualConnectionCount, 0);
      expect(signals.showRating, isFalse);
    });

    test('returns the empty record when the RPC returns null', () async {
      final _FakeGateway g = _FakeGateway(); // response stays null
      final ProfileSignalsService svc = ProfileSignalsService(g);
      final ProfileSignals signals = await svc.fetchSignals('self');
      expect(signals.mutualConnectionCount, 0);
    });

    test('accepts a single Map row (RPC may unwrap with `returns ... rows 1`)',
        () async {
      final _FakeGateway g = _FakeGateway()
        ..response = <String, dynamic>{
          'mutual_connection_count': 2,
          'mutual_top_user_ids': <String>['a', 'b'],
          'avg_meeting_rating': null,
          'total_meeting_reviews': 0,
        };
      final ProfileSignalsService svc = ProfileSignalsService(g);
      final ProfileSignals signals = await svc.fetchSignals('t');
      expect(signals.mutualConnectionCount, 2);
      expect(signals.showRating, isFalse);
    });

    test('double-guards the §17.6 hide-rating rule on the parse path',
        () async {
      // Server already returns null when total < 3, but if it ever regresses
      // and sends an avg with total=2, the model-layer guard MUST still hide.
      final _FakeGateway g = _FakeGateway()
        ..response = <Map<String, dynamic>>[
          <String, dynamic>{
            'mutual_connection_count': 0,
            'mutual_top_user_ids': <String>[],
            'avg_meeting_rating': 4.0,
            'total_meeting_reviews': 2,
          }
        ];
      final ProfileSignalsService svc = ProfileSignalsService(g);
      final ProfileSignals signals = await svc.fetchSignals('t');
      expect(signals.showRating, isFalse);
    });
  });
}
