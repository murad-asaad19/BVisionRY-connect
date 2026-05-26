import 'package:connect_mobile/features/auth/providers/session_provider.dart';
import 'package:connect_mobile/features/opportunities/data/opportunities_service.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_kind.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_status.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_with_author.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_with_counts.dart';
import 'package:connect_mobile/features/opportunities/presentation/opportunity_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/pump.dart';

class _FakeService extends Mock implements OpportunitiesService {}

OpportunityWithCounts _detail({
  String authorId = 'b',
  bool expressed = false,
  OpportunityStatus status = OpportunityStatus.open,
  DateTime? expiresAt,
  int count = 0,
}) {
  return OpportunityWithCounts(
    withAuthor: OpportunityWithAuthor(
      opportunity: Opportunity(
        id: 'oid',
        authorId: authorId,
        kind: OpportunityKind.hiring,
        title: 'Senior PM',
        body: 'Looking for someone great.',
        tags: const <String>['pm'],
        remoteOk: true,
        status: status,
        expiresAt: expiresAt ?? DateTime.utc(2026, 7, 25),
        createdAt: DateTime.utc(2026, 5, 24),
        updatedAt: DateTime.utc(2026, 5, 24),
      ),
      authorHandle: 'jane',
      authorName: 'Jane',
    ),
    interestedCount: count,
    viewerHasExpressedInterest: expressed,
  );
}

void main() {
  setUpAll(() => registerFallbackValue(OpportunityKind.hiring));

  Future<void> pumpWith(
    WidgetTester tester,
    _FakeService fake,
  ) async {
    await tester.pumpWidget(
      await wrapWithTheme(
        child: const OpportunityDetailScreen(opportunityId: 'oid'),
        overrides: <Override>[
          opportunitiesServiceProvider.overrideWithValue(fake),
          sessionProvider.overrideWith((_) => const Stream<Session?>.empty()),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('detail loads from provider and shows title + body',
      (tester) async {
    final _FakeService fake = _FakeService();
    when(() => fake.getOpportunity('oid'))
        .thenAnswer((_) async => _detail());
    await pumpWith(tester, fake);
    expect(find.text('Senior PM'), findsOneWidget);
    expect(find.text('Looking for someone great.'), findsOneWidget);
  });

  testWidgets('non-author + open + not-expressed shows CTA', (tester) async {
    final _FakeService fake = _FakeService();
    when(() => fake.getOpportunity('oid'))
        .thenAnswer((_) async => _detail());
    await pumpWith(tester, fake);
    expect(find.text('Express interest'), findsOneWidget);
  });

  testWidgets('non-author + expressed shows banner', (tester) async {
    final _FakeService fake = _FakeService();
    when(() => fake.getOpportunity('oid'))
        .thenAnswer((_) async => _detail(expressed: true));
    await pumpWith(tester, fake);
    expect(find.text('You expressed interest'), findsOneWidget);
    expect(find.text('Express interest'), findsNothing);
  });

  testWidgets('non-author + closed hides CTA', (tester) async {
    final _FakeService fake = _FakeService();
    when(() => fake.getOpportunity('oid'))
        .thenAnswer((_) async => _detail(status: OpportunityStatus.closed));
    await pumpWith(tester, fake);
    expect(find.text('Express interest'), findsNothing);
  });

  testWidgets('non-author + expired hides CTA', (tester) async {
    final _FakeService fake = _FakeService();
    when(() => fake.getOpportunity('oid')).thenAnswer(
      (_) async => _detail(expiresAt: DateTime.utc(2025, 1, 1)),
    );
    await pumpWith(tester, fake);
    expect(find.text('Express interest'), findsNothing);
  });
}
