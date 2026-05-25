// profileSignalsProvider — family-keyed FutureProvider over
// ProfileSignalsService. Empty record short-circuits to ProfileSignals.empty.
import 'package:connect_mobile/features/profile/data/profile_signals_service.dart';
import 'package:connect_mobile/features/profile/domain/profile_signals.dart';
import 'package:connect_mobile/features/profile/providers/profile_signals_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGateway implements ProfileSignalsGateway {
  _FakeGateway(this.byTarget);
  final Map<String, Object?> byTarget;
  final Map<String, int> calls = <String, int>{};

  @override
  Future<Object?> getProfileSignals(String targetUserId) async {
    calls[targetUserId] = (calls[targetUserId] ?? 0) + 1;
    return byTarget[targetUserId];
  }
}

void main() {
  test('returns the parsed signals row when the RPC has data', () async {
    final _FakeGateway gateway = _FakeGateway(<String, Object?>{
      't': <Map<String, dynamic>>[
        <String, dynamic>{
          'mutual_connection_count': 2,
          'mutual_top_user_ids': <String>['a', 'b'],
          'avg_meeting_rating': 4.5,
          'total_meeting_reviews': 5,
        },
      ],
    });
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        profileSignalsServiceProvider
            .overrideWithValue(ProfileSignalsService(gateway)),
      ],
    );
    addTearDown(container.dispose);

    final ProfileSignals signals =
        await container.read(profileSignalsProvider('t').future);
    expect(signals.mutualConnectionCount, 2);
    expect(signals.showRating, isTrue);
  });

  test('returns ProfileSignals.empty for empty results', () async {
    final _FakeGateway gateway = _FakeGateway(<String, Object?>{});
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        profileSignalsServiceProvider
            .overrideWithValue(ProfileSignalsService(gateway)),
      ],
    );
    addTearDown(container.dispose);

    final ProfileSignals signals =
        await container.read(profileSignalsProvider('self').future);
    expect(signals.mutualConnectionCount, 0);
    expect(signals.showRating, isFalse);
  });

  test('dedupes equivalent reads for the same target id', () async {
    final _FakeGateway gateway = _FakeGateway(<String, Object?>{
      't': <Map<String, dynamic>>[
        <String, dynamic>{
          'mutual_connection_count': 1,
          'mutual_top_user_ids': <String>['a'],
          'avg_meeting_rating': null,
          'total_meeting_reviews': 0,
        },
      ],
    });
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        profileSignalsServiceProvider
            .overrideWithValue(ProfileSignalsService(gateway)),
      ],
    );
    addTearDown(container.dispose);

    final Future<ProfileSignals> a =
        container.read(profileSignalsProvider('t').future);
    final Future<ProfileSignals> b =
        container.read(profileSignalsProvider('t').future);
    await Future.wait<ProfileSignals>(<Future<ProfileSignals>>[a, b]);
    expect(gateway.calls['t'], 1);
  });
}
