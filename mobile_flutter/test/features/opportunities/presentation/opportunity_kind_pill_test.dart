import 'package:connect_mobile/core/widgets/pill.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_kind.dart';
import 'package:connect_mobile/features/opportunities/presentation/opportunity_kind_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump.dart';

void main() {
  group('OpportunityKindPill', () {
    testWidgets('renders localized label for each kind', (tester) async {
      for (final OpportunityKind k in OpportunityKind.values) {
        await tester.pumpWidget(
          await wrapWithTheme(
            child: Scaffold(body: OpportunityKindPill(kind: k)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Pill), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('OpportunityKindPill.variantFor', () {
    test('maps hiring + seekingRole to solid', () {
      expect(
        OpportunityKindPill.variantFor(OpportunityKind.hiring),
        PillVariant.solid,
      );
      expect(
        OpportunityKindPill.variantFor(OpportunityKind.seekingRole),
        PillVariant.solid,
      );
    });

    test('maps cofounder to navy', () {
      expect(
        OpportunityKindPill.variantFor(OpportunityKind.cofounder),
        PillVariant.navy,
      );
    });

    test('maps collaboration to info', () {
      expect(
        OpportunityKindPill.variantFor(OpportunityKind.collaboration),
        PillVariant.info,
      );
    });

    test('maps fundraising + investing to default', () {
      expect(
        OpportunityKindPill.variantFor(OpportunityKind.fundraising),
        PillVariant.defaultVariant,
      );
      expect(
        OpportunityKindPill.variantFor(OpportunityKind.investing),
        PillVariant.defaultVariant,
      );
    });

    test('maps advising + seekingAdvisor to muted', () {
      expect(
        OpportunityKindPill.variantFor(OpportunityKind.advising),
        PillVariant.muted,
      );
      expect(
        OpportunityKindPill.variantFor(OpportunityKind.seekingAdvisor),
        PillVariant.muted,
      );
    });
  });
}
