import 'package:connect_mobile/features/discovery/data/discovery_service.dart';
import 'package:connect_mobile/features/discovery/domain/discovery_profile.dart';
import 'package:connect_mobile/features/discovery/presentation/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_discovery_service.dart';
import '../../../helpers/pump.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerDiscoveryFallbacks());
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('renders empty state when no results', (tester) async {
    final fake = FakeDiscoveryService();
    when(
      () => fake.searchDiscoverableProfiles(
        query: any(named: 'query'),
        roles: any(named: 'roles'),
        goalTypes: any(named: 'goalTypes'),
        country: any(named: 'country'),
        cursor: any(named: 'cursor'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => const <DiscoveryProfile>[]);

    final w = await wrapWithTheme(
      child: const SearchScreen(),
      overrides: <Override>[discoveryServiceProvider.overrideWithValue(fake)],
    );
    await pumpWithI18n(tester, w);
    expect(find.textContaining('No results'), findsOneWidget);
  });

  testWidgets('renders rows for returned profiles', (tester) async {
    final fake = FakeDiscoveryService();
    when(
      () => fake.searchDiscoverableProfiles(
        query: any(named: 'query'),
        roles: any(named: 'roles'),
        goalTypes: any(named: 'goalTypes'),
        country: any(named: 'country'),
        cursor: any(named: 'cursor'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => const <DiscoveryProfile>[
        DiscoveryProfile(id: '1', handle: 'omar', name: 'Omar Daher'),
        DiscoveryProfile(id: '2', handle: 'lina', name: 'Lina Maatouk'),
      ],
    );
    final w = await wrapWithTheme(
      child: const SearchScreen(),
      overrides: <Override>[discoveryServiceProvider.overrideWithValue(fake)],
    );
    await pumpWithI18n(tester, w);
    expect(find.text('Omar Daher'), findsOneWidget);
    expect(find.text('Lina Maatouk'), findsOneWidget);
  });
}
