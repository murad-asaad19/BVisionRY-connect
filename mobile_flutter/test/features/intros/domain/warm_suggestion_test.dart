import 'package:connect_mobile/features/intros/domain/warm_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WarmSuggestion.fromJson parses a full row', () {
    final json = <String, dynamic>{
      'target_id': 't1',
      'target_handle': 'alice',
      'target_name': 'Alice',
      'target_photo_url': 'https://x/p.jpg',
      'target_primary_role': 'founder',
      'target_goal_type': 'cofounder',
      'mutual_count': 3,
      'top_mutual_id': 'm1',
      'top_mutual_name': 'Mia',
      'top_mutual_handle': 'mia',
    };
    final s = WarmSuggestion.fromJson(json);
    expect(s.targetId, 't1');
    expect(s.mutualCount, 3);
    expect(s.topMutualName, 'Mia');
    expect(s.targetPhotoUrl, equals('https://x/p.jpg'));
    expect(s.targetPrimaryRole, equals('founder'));
    expect(s.targetGoalType, equals('cofounder'));
  });

  test('WarmSuggestion handles null optional fields', () {
    final json = <String, dynamic>{
      'target_id': 't2',
      'target_handle': 'bob',
      'target_name': 'Bob',
      'target_photo_url': null,
      'target_primary_role': null,
      'target_goal_type': null,
      'mutual_count': 1,
      'top_mutual_id': 'm2',
      'top_mutual_name': 'Mo',
      'top_mutual_handle': 'mo',
    };
    final s = WarmSuggestion.fromJson(json);
    expect(s.targetPhotoUrl, isNull);
    expect(s.targetPrimaryRole, isNull);
    expect(s.targetGoalType, isNull);
    expect(s.mutualCount, 1);
  });
}
