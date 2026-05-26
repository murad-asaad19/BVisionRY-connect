import 'package:connect_mobile/features/opportunities/domain/opportunity_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OpportunityKind', () {
    test('exposes all 8 enum values matching the DB enum', () {
      expect(OpportunityKind.values, hasLength(8));
      expect(
        OpportunityKind.values.map((OpportunityKind e) => e.dbValue).toSet(),
        const <String>{
          'hiring',
          'seeking_role',
          'fundraising',
          'investing',
          'cofounder',
          'advising',
          'seeking_advisor',
          'collaboration',
        },
      );
    });

    test('fromDb resolves every value', () {
      for (final String v in const <String>[
        'hiring',
        'seeking_role',
        'fundraising',
        'investing',
        'cofounder',
        'advising',
        'seeking_advisor',
        'collaboration',
      ]) {
        expect(OpportunityKind.fromDb(v).dbValue, v);
      }
    });

    test('fromDb throws on unknown', () {
      expect(
        () => OpportunityKind.fromDb('mystery'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('i18nKey returns opportunities.kind.<value>', () {
      expect(OpportunityKind.hiring.i18nKey, 'opportunities.kind.hiring');
      expect(
        OpportunityKind.seekingRole.i18nKey,
        'opportunities.kind.seeking_role',
      );
      expect(
        OpportunityKind.seekingAdvisor.i18nKey,
        'opportunities.kind.seeking_advisor',
      );
    });
  });
}
