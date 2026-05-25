import 'package:connect_mobile/features/discovery/domain/feed_filters.dart';
import 'package:connect_mobile/features/discovery/providers/feed_filters_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('default state is empty FeedFilters', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final f = await container.read(feedFiltersProvider.future);
    expect(f, const FeedFilters());
  });

  test('setQuery does not persist, but persists everything else', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(feedFiltersProvider.future);
    final ctrl = container.read(feedFiltersProvider.notifier);
    await ctrl.setQuery('omar');
    await ctrl.setRoles(<String>['founder']);
    await ctrl.setCountry('UK');

    final prefs = await SharedPreferences.getInstance();
    final persisted = prefs.getString('discovery.feedFilters');
    expect(persisted, isNotNull);
    expect(persisted, isNot(contains('omar')));
    expect(persisted, contains('founder'));
    expect(persisted, contains('UK'));
  });

  test('rehydrates persisted filters on init', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'discovery.feedFilters':
          '{"roles":["founder"],"goalTypes":[],"country":"UK"}',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final f = await container.read(feedFiltersProvider.future);
    expect(f.roles, <String>['founder']);
    expect(f.country, 'UK');
    expect(f.query, isEmpty);
  });
}
