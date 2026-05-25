import 'package:connect_mobile/features/onboarding/domain/goal_type.dart';
import 'package:connect_mobile/features/onboarding/domain/onboarding_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OnboardingDraft() default constructor produces empty draft', () {
    const OnboardingDraft d = OnboardingDraft();
    expect(d.goalText, isEmpty);
    expect(d.goalType, isNull);
    expect(d.name, isEmpty);
    expect(d.handle, isEmpty);
    expect(d.roles, isEmpty);
    expect(d.primaryRole, isNull);
    expect(d.city, isEmpty);
    expect(d.country, isEmpty);
    expect(d.headline, isNull);
    expect(d.bio, isNull);
  });

  test('copyWith updates a single field without touching others', () {
    const OnboardingDraft base = OnboardingDraft();
    final OnboardingDraft updated = base.copyWith(name: 'Ada', handle: 'ada');
    expect(updated.name, 'Ada');
    expect(updated.handle, 'ada');
    expect(updated.goalText, isEmpty);
  });

  test('round-trips through toJson/fromJson preserving GoalType', () {
    const OnboardingDraft d = OnboardingDraft(
      goalText: 'Raising pre-seed',
      goalType: GoalType.takeInvestment,
      name: 'Ada',
      handle: 'ada',
      roles: <String>['founder'],
      primaryRole: 'founder',
      city: 'Berlin',
      country: 'Germany',
      headline: 'Hardware founder',
      bio: 'Built three startups.',
    );
    final OnboardingDraft restored = OnboardingDraft.fromJson(d.toJson());
    expect(restored, equals(d));
    expect(restored.goalType, GoalType.takeInvestment);
  });

  test('JSON keys use snake_case for server-aligned fields', () {
    const OnboardingDraft d = OnboardingDraft(
      goalText: 'Hi',
      goalType: GoalType.hire,
      primaryRole: 'founder',
    );
    final Map<String, dynamic> json = d.toJson();
    expect(json.containsKey('goal_text'), isTrue);
    expect(json.containsKey('goal_type'), isTrue);
    expect(json.containsKey('primary_role'), isTrue);
    expect(json['goal_type'], 'hire');
  });

  test('unknown goal_type wire value deserialises to null', () {
    final OnboardingDraft restored = OnboardingDraft.fromJson(<String, dynamic>{
      'goal_text': '',
      'goal_type': 'made_up_value',
      'name': '',
      'handle': '',
      'roles': <String>[],
      'primary_role': null,
      'city': '',
      'country': '',
      'headline': null,
      'bio': null,
    });
    expect(restored.goalType, isNull);
  });
}
