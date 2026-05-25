import 'package:connect_mobile/features/discovery/data/discovery_service.dart';
import 'package:connect_mobile/features/discovery/domain/daily_match.dart';
import 'package:connect_mobile/features/discovery/domain/discovery_profile.dart';
import 'package:connect_mobile/features/discovery/providers/daily_matches_provider.dart';
import 'package:connect_mobile/features/discovery/providers/midnight_invalidator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_clock.dart';
import '../../../helpers/fake_discovery_service.dart';

DailyMatch _m(String id, {String reason = 'Daily pick'}) => DailyMatch(
      id: id,
      pickUserId: 'u-$id',
      matchReason: reason,
      forDateLocal: DateTime.utc(2026, 5, 25),
      createdAt: DateTime.utc(2026, 5, 25, 4),
      profile: DiscoveryProfile(id: 'u-$id', handle: 'h$id'),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerDiscoveryFallbacks());

  test('fetches once per local day', () async {
    final fake = FakeDiscoveryService();
    when(
      () => fake.fetchDailyMatches(date: any(named: 'date')),
    ).thenAnswer((_) async => <DailyMatch>[_m('a')]);
    final clock = FakeClock(DateTime(2026, 5, 25, 14, 33));
    final container = ProviderContainer(
      overrides: <Override>[
        discoveryServiceProvider.overrideWithValue(fake),
        clockProvider.overrideWithValue(clock.now),
      ],
    );
    addTearDown(container.dispose);

    final r1 = await container.read(dailyMatchesProvider.future);
    expect(r1, hasLength(1));

    // Reading again same day → cached (no new RPC call).
    await container.read(dailyMatchesProvider.future);
    verify(() => fake.fetchDailyMatches(date: any(named: 'date'))).called(1);
  });

  test('refetches when local day rolls', () async {
    final fake = FakeDiscoveryService();
    var call = 0;
    when(
      () => fake.fetchDailyMatches(date: any(named: 'date')),
    ).thenAnswer((_) async => <DailyMatch>[_m('day${++call}')]);
    final clock = FakeClock(DateTime(2026, 5, 25, 23, 50));
    final container = ProviderContainer(
      overrides: <Override>[
        discoveryServiceProvider.overrideWithValue(fake),
        clockProvider.overrideWithValue(clock.now),
      ],
    );
    addTearDown(container.dispose);

    await container.read(dailyMatchesProvider.future);
    clock.advance(const Duration(minutes: 30));
    container.read(midnightInvalidatorProvider.notifier).bumpIfRolled();

    final r2 = await container.read(dailyMatchesProvider.future);
    expect(r2.first.id, 'day2');
  });

  test('markViewed delegates to service and updates state', () async {
    final fake = FakeDiscoveryService();
    when(
      () => fake.fetchDailyMatches(date: any(named: 'date')),
    ).thenAnswer((_) async => <DailyMatch>[_m('a')]);
    when(() => fake.markMatchViewed(any())).thenAnswer((_) async {});
    final clock = FakeClock(DateTime(2026, 5, 25, 14));
    final container = ProviderContainer(
      overrides: <Override>[
        discoveryServiceProvider.overrideWithValue(fake),
        clockProvider.overrideWithValue(clock.now),
      ],
    );
    addTearDown(container.dispose);

    await container.read(dailyMatchesProvider.future);
    await container.read(dailyMatchesProvider.notifier).markViewed('a');
    verify(() => fake.markMatchViewed('a')).called(1);
    final state = await container.read(dailyMatchesProvider.future);
    expect(state.first.viewedAt, isNotNull);
  });
}
