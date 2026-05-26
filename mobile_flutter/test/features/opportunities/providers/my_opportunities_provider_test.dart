import 'package:connect_mobile/features/opportunities/data/opportunities_service.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_kind.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_status.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_with_author.dart';
import 'package:connect_mobile/features/opportunities/providers/my_opportunities_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeService extends Mock implements OpportunitiesService {}

OpportunityWithAuthor _opp(String id) {
  return OpportunityWithAuthor(
    opportunity: Opportunity(
      id: id,
      authorId: 'a',
      kind: OpportunityKind.hiring,
      title: 'T',
      body: 'B' * 20,
      tags: const <String>[],
      remoteOk: false,
      status: OpportunityStatus.open,
      expiresAt: DateTime.utc(2026, 7, 1),
      createdAt: DateTime.utc(2026, 5, 1),
      updatedAt: DateTime.utc(2026, 5, 1),
    ),
    authorHandle: 'jane',
    authorName: 'Jane',
    interestedCount: 2,
  );
}

void main() {
  test('myOpportunitiesProvider returns rows from service', () async {
    final _FakeService fake = _FakeService();
    when(() => fake.listMyOpportunities()).thenAnswer(
      (_) async => <OpportunityWithAuthor>[_opp('a'), _opp('b')],
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        opportunitiesServiceProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);
    final r = await container.read(myOpportunitiesProvider.future);
    expect(r, hasLength(2));
    expect(r.first.interestedCount, 2);
  });
}
