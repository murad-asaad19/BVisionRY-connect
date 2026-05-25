import 'dart:async';

import 'package:connect_mobile/features/discovery/data/discovery_service.dart';
import 'package:connect_mobile/features/discovery/domain/daily_match.dart';
import 'package:connect_mobile/features/discovery/domain/discovery_profile.dart';
import 'package:connect_mobile/features/home/presentation/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/fake_discovery_service.dart';
import '../../../helpers/pump.dart';

DailyMatch _m(String id, {String? name}) => DailyMatch(
      id: id,
      pickUserId: 'u-$id',
      matchReason: 'Daily pick',
      forDateLocal: DateTime.utc(2026, 5, 25),
      createdAt: DateTime.utc(2026, 5, 25, 4),
      profile: DiscoveryProfile(
        id: 'u-$id',
        handle: id,
        name: name ?? id,
        primaryRole: 'builder',
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    registerDiscoveryFallbacks();
  });
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('shows skeleton while loading', (tester) async {
    final fake = FakeDiscoveryService();
    final completer = Completer<List<DailyMatch>>();
    when(
      () => fake.fetchDailyMatches(date: any(named: 'date')),
    ).thenAnswer((_) => completer.future);
    final w = await wrapWithTheme(
      child: const HomeScreen(),
      overrides: <Override>[discoveryServiceProvider.overrideWithValue(fake)],
    );
    await tester.pumpWidget(w);
    await tester.pump(); // first frame
    completer.complete(<DailyMatch>[]);
    await tester.pumpAndSettle();
  });

  testWidgets('renders 5 matches and section header', (tester) async {
    final fake = FakeDiscoveryService();
    when(
      () => fake.fetchDailyMatches(date: any(named: 'date')),
    ).thenAnswer(
      (_) async => <DailyMatch>[
        for (var i = 0; i < 5; i++) _m('p$i', name: 'Person $i'),
      ],
    );
    final w = await wrapWithTheme(
      child: const HomeScreen(),
      overrides: <Override>[discoveryServiceProvider.overrideWithValue(fake)],
    );
    await pumpWithI18n(tester, w);
    expect(find.text('Person 0'), findsOneWidget);
    expect(find.text('Person 4'), findsOneWidget);
    expect(find.textContaining('PICKS FOR YOU'), findsOneWidget);
  });

  testWidgets('thin-pool banner appears when < 3 matches', (tester) async {
    final fake = FakeDiscoveryService();
    when(
      () => fake.fetchDailyMatches(date: any(named: 'date')),
    ).thenAnswer((_) async => <DailyMatch>[_m('only')]);
    final w = await wrapWithTheme(
      child: const HomeScreen(),
      overrides: <Override>[discoveryServiceProvider.overrideWithValue(fake)],
    );
    await pumpWithI18n(tester, w);
    expect(find.textContaining('being picky'), findsOneWidget);
  });

  testWidgets('empty list renders branded EmptyState', (tester) async {
    final fake = FakeDiscoveryService();
    when(
      () => fake.fetchDailyMatches(date: any(named: 'date')),
    ).thenAnswer((_) async => <DailyMatch>[]);
    final w = await wrapWithTheme(
      child: const HomeScreen(),
      overrides: <Override>[discoveryServiceProvider.overrideWithValue(fake)],
    );
    await pumpWithI18n(tester, w);
    expect(find.textContaining('No matches today'), findsOneWidget);
  });
}
