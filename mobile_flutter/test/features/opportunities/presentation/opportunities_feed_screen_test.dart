import 'package:connect_mobile/features/auth/providers/session_provider.dart';
import 'package:connect_mobile/features/opportunities/data/opportunities_service.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_kind.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_status.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_with_author.dart';
import 'package:connect_mobile/features/opportunities/presentation/opportunities_feed_screen.dart';
import 'package:connect_mobile/features/opportunities/presentation/opportunity_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/pump.dart';

class _FakeService extends Mock implements OpportunitiesService {}

OpportunityWithAuthor _opp(String id) {
  return OpportunityWithAuthor(
    opportunity: Opportunity(
      id: id,
      authorId: 'a',
      kind: OpportunityKind.hiring,
      title: 'Title-$id',
      body: 'Body content for $id with enough chars.',
      tags: const <String>['pm'],
      remoteOk: false,
      status: OpportunityStatus.open,
      expiresAt: DateTime.utc(2026, 7, 1),
      createdAt: DateTime.utc(2026, 5, 1),
      updatedAt: DateTime.utc(2026, 5, 1),
    ),
    authorHandle: 'jane',
    authorName: 'Jane',
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(OpportunityKind.hiring);
  });

  testWidgets('renders empty state when feed returns no rows', (tester) async {
    final _FakeService fake = _FakeService();
    when(
      () => fake.listOpportunities(
        kinds: any(named: 'kinds'),
        remoteOnly: any(named: 'remoteOnly'),
        search: any(named: 'search'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => const <OpportunityWithAuthor>[]);

    await tester.pumpWidget(
      await wrapWithTheme(
        child: const OpportunitiesFeedScreen(),
        overrides: <Override>[
          opportunitiesServiceProvider.overrideWithValue(fake),
          sessionProvider.overrideWith((_) => const Stream<Session?>.empty()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No opportunities yet'), findsOneWidget);
  });

  testWidgets('renders one OpportunityCard per row', (tester) async {
    final _FakeService fake = _FakeService();
    when(
      () => fake.listOpportunities(
        kinds: any(named: 'kinds'),
        remoteOnly: any(named: 'remoteOnly'),
        search: any(named: 'search'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer(
      (_) async =>
          <OpportunityWithAuthor>[_opp('a'), _opp('b'), _opp('c')],
    );

    await tester.pumpWidget(
      await wrapWithTheme(
        child: const OpportunitiesFeedScreen(),
        overrides: <Override>[
          opportunitiesServiceProvider.overrideWithValue(fake),
          sessionProvider.overrideWith((_) => const Stream<Session?>.empty()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OpportunityCard), findsNWidgets(3));
  });
}
