import 'package:connect_mobile/features/opportunities/data/opportunities_service.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_kind.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_status.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_with_author.dart';
import 'package:connect_mobile/features/opportunities/providers/opportunities_feed_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeService extends Mock implements OpportunitiesService {}

OpportunityWithAuthor _opp(
  String id, {
  OpportunityKind kind = OpportunityKind.hiring,
}) {
  return OpportunityWithAuthor(
    opportunity: Opportunity(
      id: id,
      authorId: 'a',
      kind: kind,
      title: 'T-$id',
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
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(OpportunityKind.hiring);
  });

  group('opportunitiesFeedProvider', () {
    test('initial load returns first page and sets hasMore=true when full',
        () async {
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
        (_) async => List<OpportunityWithAuthor>.generate(
          20,
          (int i) => _opp('id-$i'),
        ),
      );

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          opportunitiesServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      final OpportunitiesFeedState state =
          await container.read(opportunitiesFeedProvider.future);
      expect(state.items, hasLength(20));
      expect(state.hasMore, isTrue);
      expect(state.nextOffset, 20);
    });

    test('initial load with under-full page sets hasMore=false', () async {
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
        (_) async => List<OpportunityWithAuthor>.generate(
          7,
          (int i) => _opp('id-$i'),
        ),
      );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          opportunitiesServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);
      final OpportunitiesFeedState state =
          await container.read(opportunitiesFeedProvider.future);
      expect(state.hasMore, isFalse);
      expect(state.nextOffset, 7);
    });

    test('loadMore appends and bumps nextOffset', () async {
      final _FakeService fake = _FakeService();
      int call = 0;
      when(
        () => fake.listOpportunities(
          kinds: any(named: 'kinds'),
          remoteOnly: any(named: 'remoteOnly'),
          search: any(named: 'search'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async {
        call++;
        return List<OpportunityWithAuthor>.generate(
          20,
          (int i) => _opp('p$call-$i'),
        );
      });
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          opportunitiesServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);
      await container.read(opportunitiesFeedProvider.future);
      await container.read(opportunitiesFeedProvider.notifier).loadMore();
      final OpportunitiesFeedState state =
          container.read(opportunitiesFeedProvider).value!;
      expect(state.items, hasLength(40));
      expect(state.nextOffset, 40);
      expect(state.hasMore, isTrue);
    });

    test('loadMore is a no-op when hasMore=false', () async {
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
        (_) async => List<OpportunityWithAuthor>.generate(
          3,
          (int i) => _opp('id-$i'),
        ),
      );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          opportunitiesServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);
      await container.read(opportunitiesFeedProvider.future);
      await container.read(opportunitiesFeedProvider.notifier).loadMore();
      verify(
        () => fake.listOpportunities(
          kinds: any(named: 'kinds'),
          remoteOnly: any(named: 'remoteOnly'),
          search: any(named: 'search'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).called(1);
    });

    test('setFilters resets items and nextOffset', () async {
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
        (_) async => List<OpportunityWithAuthor>.generate(
          3,
          (int i) => _opp('id-$i'),
        ),
      );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          opportunitiesServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);
      await container.read(opportunitiesFeedProvider.future);
      await container.read(opportunitiesFeedProvider.notifier).setFilters(
        kinds: const <OpportunityKind>[OpportunityKind.cofounder],
        remoteOnly: true,
        search: 'pm',
      );
      final OpportunitiesFeedState state =
          container.read(opportunitiesFeedProvider).value!;
      expect(state.kinds, <OpportunityKind>[OpportunityKind.cofounder]);
      expect(state.remoteOnly, isTrue);
      expect(state.search, 'pm');
      expect(state.nextOffset, 3);
    });

    test('refresh re-fetches page 1 with current filters', () async {
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
        (_) async => List<OpportunityWithAuthor>.generate(
          5,
          (int i) => _opp('id-$i'),
        ),
      );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          opportunitiesServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);
      await container.read(opportunitiesFeedProvider.future);
      await container.read(opportunitiesFeedProvider.notifier).refresh();
      verify(
        () => fake.listOpportunities(
          kinds: any(named: 'kinds'),
          remoteOnly: any(named: 'remoteOnly'),
          search: any(named: 'search'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).called(2);
    });
  });
}
