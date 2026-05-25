import 'package:connect_mobile/features/discovery/domain/feed_filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FeedFilters defaults are empty', () {
    const f = FeedFilters();
    expect(f.query, isEmpty);
    expect(f.roles, isEmpty);
    expect(f.goalTypes, isEmpty);
    expect(f.country, isNull);
    expect(f.isActive, isFalse);
  });

  test('isActive true when any filter set', () {
    expect(const FeedFilters(query: 'a').isActive, isTrue);
    expect(const FeedFilters(roles: <String>['founder']).isActive, isTrue);
    expect(const FeedFilters(goalTypes: <String>['hire']).isActive, isTrue);
    expect(const FeedFilters(country: 'UK').isActive, isTrue);
  });

  test('persistedJson omits query (matches RN feedFiltersStore)', () {
    const f = FeedFilters(
      query: 'omar',
      roles: <String>['founder'],
      country: 'UK',
    );
    final json = f.persistedJson();
    expect(json.containsKey('query'), isFalse);
    expect(json['roles'], <String>['founder']);
    expect(json['country'], 'UK');
  });
}
