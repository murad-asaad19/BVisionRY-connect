import 'package:connect_mobile/features/opportunities/domain/opportunity.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_kind.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_status.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_with_author.dart';
import 'package:connect_mobile/features/opportunities/presentation/opportunity_card.dart';
import 'package:connect_mobile/features/opportunities/presentation/opportunity_kind_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump.dart';

OpportunityWithAuthor _build({
  bool remoteOk = true,
  List<String> tags = const <String>['pm', 'fintech'],
  String? city = 'Lisbon',
  String? country = 'PT',
  OpportunityStatus status = OpportunityStatus.open,
}) {
  return OpportunityWithAuthor(
    opportunity: Opportunity(
      id: 'a' * 36,
      authorId: 'b' * 36,
      kind: OpportunityKind.hiring,
      title: 'Senior PM',
      body: 'Looking for a senior PM with shipping experience.',
      tags: tags,
      remoteOk: remoteOk,
      locationCity: city,
      locationCountry: country,
      status: status,
      expiresAt: DateTime.utc(2026, 7, 25),
      createdAt: DateTime.utc(2026, 5, 24),
      updatedAt: DateTime.utc(2026, 5, 24),
    ),
    authorHandle: 'jane',
    authorName: 'Jane Doe',
  );
}

void main() {
  group('OpportunityCard', () {
    testWidgets('renders title, body excerpt, tags', (tester) async {
      await tester.pumpWidget(
        await wrapWithTheme(
          child: Scaffold(
            body: OpportunityCard(data: _build(), interestedCount: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Senior PM'), findsOneWidget);
      expect(find.textContaining('Looking for'), findsOneWidget);
      expect(find.text('pm'), findsOneWidget);
      expect(find.text('fintech'), findsOneWidget);
      expect(find.byType(OpportunityKindPill), findsOneWidget);
    });

    testWidgets('shows Remote pill only when remote_ok=true', (tester) async {
      await tester.pumpWidget(
        await wrapWithTheme(
          child: Scaffold(
            body: OpportunityCard(
              data: _build(remoteOk: false),
              interestedCount: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Remote only'), findsNothing);

      await tester.pumpWidget(
        await wrapWithTheme(
          child: Scaffold(
            body: OpportunityCard(data: _build(), interestedCount: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Remote only'), findsOneWidget);
    });

    testWidgets('onTap fires when card is tapped', (tester) async {
      int taps = 0;
      await tester.pumpWidget(
        await wrapWithTheme(
          child: Scaffold(
            body: OpportunityCard(
              data: _build(),
              interestedCount: 0,
              onTap: () => taps++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Senior PM'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('renders closed status pill when statusOverlay+closed',
        (tester) async {
      await tester.pumpWidget(
        await wrapWithTheme(
          child: Scaffold(
            body: OpportunityCard(
              data: _build(status: OpportunityStatus.closed),
              interestedCount: 0,
              statusOverlay: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Closed'), findsOneWidget);
    });
  });
}
