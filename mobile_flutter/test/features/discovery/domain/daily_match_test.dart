import 'package:connect_mobile/features/discovery/domain/daily_match.dart';
import 'package:connect_mobile/features/discovery/domain/discovery_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DailyMatch.fromJson parses get_daily_matches row shape', () {
    final json = <String, dynamic>{
      'id': '11111111-1111-1111-1111-111111111111',
      'pick_user_id': '22222222-2222-2222-2222-222222222222',
      'match_reason': 'Complementary goals',
      'for_date_local': '2026-05-25',
      'viewed_at': null,
      'created_at': '2026-05-25T04:01:00Z',
      'name': 'Omar Daher',
      'handle': 'omar',
      'photo_url': 'https://x/o.png',
      'headline': 'Senior backend',
      'bio': null,
      'city': 'London',
      'country': 'UK',
      'primary_role': 'builder',
      'roles': const <String>['builder'],
      'goal_type': 'find_advisor',
    };
    final m = DailyMatch.fromJson(json);
    expect(m.id, '11111111-1111-1111-1111-111111111111');
    expect(m.matchReason, 'Complementary goals');
    expect(m.viewedAt, isNull);
    expect(m.profile.handle, 'omar');
    expect(m.profile.roles, <String>['builder']);
    expect(m.forDateLocal, DateTime.utc(2026, 5, 25));
  });

  test('DiscoveryProfile.fromJson tolerates null optional fields', () {
    final p = DiscoveryProfile.fromJson(<String, dynamic>{
      'id': '22222222-2222-2222-2222-222222222222',
      'handle': 'omar',
      'name': null,
      'photo_url': null,
      'headline': null,
      'bio': null,
      'city': null,
      'country': null,
      'primary_role': null,
      'roles': const <String>[],
      'goal_type': null,
    });
    expect(p.handle, 'omar');
    expect(p.name, isNull);
    expect(p.roles, isEmpty);
  });
}
