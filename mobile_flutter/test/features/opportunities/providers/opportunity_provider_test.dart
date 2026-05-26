import 'package:connect_mobile/features/opportunities/data/opportunities_service.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_kind.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_status.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_with_author.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_with_counts.dart';
import 'package:connect_mobile/features/opportunities/providers/opportunity_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeService extends Mock implements OpportunitiesService {}

OpportunityWithCounts _detail(String id) {
  return OpportunityWithCounts(
    withAuthor: OpportunityWithAuthor(
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
    ),
    interestedCount: 3,
    viewerHasExpressedInterest: false,
  );
}

void main() {
  test('opportunityProvider(id) fetches single opportunity from service',
      () async {
    final _FakeService fake = _FakeService();
    when(() => fake.getOpportunity('oid')).thenAnswer(
      (_) async => _detail('oid'),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        opportunitiesServiceProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);
    final OpportunityWithCounts r =
        await container.read(opportunityProvider('oid').future);
    expect(r.interestedCount, 3);
    expect(r.withAuthor.opportunity.id, 'oid');
  });
}
