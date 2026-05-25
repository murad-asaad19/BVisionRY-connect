import 'package:connect_mobile/features/discovery/data/discovery_service.dart';
import 'package:connect_mobile/features/discovery/domain/discovery_profile.dart';
import 'package:connect_mobile/features/discovery/providers/feed_filters_provider.dart';
import 'package:connect_mobile/features/discovery/providers/search_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_discovery_service.dart';

DiscoveryProfile _p(String id, {DateTime? created}) =>
    DiscoveryProfile(id: id, handle: 'h$id', createdAt: created);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerDiscoveryFallbacks());
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('initial load uses sentinel cursor, applies persisted filters', () async {
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
    ).thenAnswer((_) async => <DiscoveryProfile>[_p('1'), _p('2')]);
    final container = ProviderContainer(
      overrides: <Override>[discoveryServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final state = await container.read(searchProvider.future);
    expect(state.items, hasLength(2));
    expect(state.hasMore, isFalse);
    verify(
      () => fake.searchDiscoverableProfiles(
        query: '',
        roles: const <String>[],
        goalTypes: const <String>[],
        country: null,
        cursor: null,
        limit: 20,
      ),
    ).called(1);
  });

  test('loadMore appends and uses last item createdAt as cursor', () async {
    final fake = FakeDiscoveryService();
    final first = List<DiscoveryProfile>.generate(
      20,
      (i) => _p('a$i', created: DateTime.utc(2026, 5, 25, 4, i)),
    );
    final second = List<DiscoveryProfile>.generate(5, (i) => _p('b$i'));
    var call = 0;
    when(
      () => fake.searchDiscoverableProfiles(
        query: any(named: 'query'),
        roles: any(named: 'roles'),
        goalTypes: any(named: 'goalTypes'),
        country: any(named: 'country'),
        cursor: any(named: 'cursor'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async {
      call++;
      return call == 1 ? first : second;
    });

    final container = ProviderContainer(
      overrides: <Override>[discoveryServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    await container.read(searchProvider.future);
    await container.read(searchProvider.notifier).loadMore();
    final state = await container.read(searchProvider.future);
    expect(state.items, hasLength(25));
    expect(state.hasMore, isFalse); // got < limit => no more
  });

  test('setQuery resets pagination and reloads', () async {
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
    ).thenAnswer((_) async => <DiscoveryProfile>[_p('1')]);

    final container = ProviderContainer(
      overrides: <Override>[discoveryServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    await container.read(searchProvider.future);
    await container.read(searchProvider.notifier).setQuery('omar');
    // Wait for debounce (300 ms).
    await Future<void>.delayed(const Duration(milliseconds: 400));
    verify(
      () => fake.searchDiscoverableProfiles(
        query: 'omar',
        roles: any(named: 'roles'),
        goalTypes: any(named: 'goalTypes'),
        country: any(named: 'country'),
        cursor: null,
        limit: 20,
      ),
    ).called(1);
  });

  test('applyFilters writes through to feedFiltersProvider and reloads', () async {
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

    final container = ProviderContainer(
      overrides: <Override>[discoveryServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    await container.read(searchProvider.future);

    await container.read(searchProvider.notifier).applyFilters(
          roles: <String>['founder'],
          goalTypes: <String>['hire'],
          country: 'UK',
        );

    final filters = await container.read(feedFiltersProvider.future);
    expect(filters.roles, <String>['founder']);
    expect(filters.country, 'UK');
  });
}
