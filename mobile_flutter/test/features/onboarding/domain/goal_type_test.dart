import 'package:connect_mobile/features/onboarding/domain/goal_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GoalType enum has the eight spec values in snake_case', () {
    expect(GoalType.values.map((GoalType g) => g.wire).toList(), const <String>[
      'hire',
      'be_hired',
      'co_found',
      'invest',
      'take_investment',
      'advise',
      'find_advisor',
      'peer_connect',
    ]);
  });

  test('GoalType.fromWire is case-strict and returns null on unknown', () {
    expect(GoalType.fromWire('hire'), GoalType.hire);
    expect(GoalType.fromWire('be_hired'), GoalType.beHired);
    expect(GoalType.fromWire('Hire'), isNull);
    expect(GoalType.fromWire('nope'), isNull);
    expect(GoalType.fromWire(null), isNull);
  });

  test('GoalType.i18nLabelKey points at discovery.goalLabel.<wire>', () {
    expect(GoalType.hire.i18nLabelKey, 'discovery.goalLabel.hire');
    expect(
      GoalType.peerConnect.i18nLabelKey,
      'discovery.goalLabel.peer_connect',
    );
  });
}
