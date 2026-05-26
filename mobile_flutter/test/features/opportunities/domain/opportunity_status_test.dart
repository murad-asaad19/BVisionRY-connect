import 'package:connect_mobile/features/opportunities/domain/opportunity_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OpportunityStatus', () {
    test('has 3 values', () {
      expect(OpportunityStatus.values, hasLength(3));
      expect(OpportunityStatus.open.dbValue, 'open');
      expect(OpportunityStatus.closed.dbValue, 'closed');
      expect(OpportunityStatus.archived.dbValue, 'archived');
    });

    test('fromDb works and rejects unknowns', () {
      expect(OpportunityStatus.fromDb('open'), OpportunityStatus.open);
      expect(OpportunityStatus.fromDb('closed'), OpportunityStatus.closed);
      expect(OpportunityStatus.fromDb('archived'), OpportunityStatus.archived);
      expect(
        () => OpportunityStatus.fromDb('zombie'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
