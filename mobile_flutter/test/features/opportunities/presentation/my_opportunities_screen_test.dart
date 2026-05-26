import 'package:connect_mobile/features/auth/providers/session_provider.dart';
import 'package:connect_mobile/features/opportunities/data/opportunities_service.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_kind.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_status.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_with_author.dart';
import 'package:connect_mobile/features/opportunities/presentation/my_opportunities_screen.dart';
import 'package:connect_mobile/features/opportunities/presentation/opportunity_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/pump.dart';

class _FakeService extends Mock implements OpportunitiesService {}

OpportunityWithAuthor _opp(String id, OpportunityStatus status) {
  return OpportunityWithAuthor(
    opportunity: Opportunity(
      id: id,
      authorId: 'a',
      kind: OpportunityKind.hiring,
      title: 'T-$id',
      body: 'Body for $id with enough chars to render.',
      tags: const <String>[],
      remoteOk: false,
      status: status,
      expiresAt: DateTime.utc(2026, 7, 1),
      createdAt: DateTime.utc(2026, 5, 1),
      updatedAt: DateTime.utc(2026, 5, 1),
    ),
    authorHandle: 'me',
    authorName: 'Me',
    interestedCount: 1,
  );
}

void main() {
  testWidgets('empty state renders when provider returns []', (tester) async {
    final _FakeService fake = _FakeService();
    when(() => fake.listMyOpportunities())
        .thenAnswer((_) async => const <OpportunityWithAuthor>[]);
    await tester.pumpWidget(
      await wrapWithTheme(
        child: const MyOpportunitiesScreen(),
        overrides: <Override>[
          opportunitiesServiceProvider.overrideWithValue(fake),
          sessionProvider.overrideWith((_) => const Stream<Session?>.empty()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("You haven't posted yet"), findsOneWidget);
  });

  testWidgets('renders one card per opportunity', (tester) async {
    final _FakeService fake = _FakeService();
    when(() => fake.listMyOpportunities()).thenAnswer(
      (_) async => <OpportunityWithAuthor>[
        _opp('a', OpportunityStatus.open),
        _opp('b', OpportunityStatus.closed),
      ],
    );
    await tester.pumpWidget(
      await wrapWithTheme(
        child: const MyOpportunitiesScreen(),
        overrides: <Override>[
          opportunitiesServiceProvider.overrideWithValue(fake),
          sessionProvider.overrideWith((_) => const Stream<Session?>.empty()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OpportunityCard), findsNWidgets(2));
    expect(find.text('Closed'), findsOneWidget);
  });
}
