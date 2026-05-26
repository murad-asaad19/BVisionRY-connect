import 'package:connect_mobile/features/meetings/data/meetings_service.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_proposal.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_state.dart';
import 'package:connect_mobile/features/meetings/providers/pending_reviews_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSvc extends Mock implements MeetingsService {}

void main() {
  test('pendingMeetingReviewsProvider proxies through MeetingsService',
      () async {
    final svc = _MockSvc();
    final p = MeetingProposal(
      id: 'm',
      conversationId: 'c',
      proposedById: 'them',
      slots: [DateTime.now().toUtc().subtract(const Duration(hours: 2))],
      confirmedSlot: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
      durationMinutes: 30,
      timezone: 'UTC',
      state: MeetingState.confirmed,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    when(() => svc.pendingMeetingReviews(conversationId: any(named: 'conversationId')))
        .thenAnswer((_) async => [p]);
    final container = ProviderContainer(
      overrides: [meetingsServiceProvider.overrideWithValue(svc)],
    );
    addTearDown(container.dispose);
    final result = await container.read(
      pendingMeetingReviewsProvider('c').future,
    );
    expect(result, hasLength(1));
    verify(() => svc.pendingMeetingReviews(conversationId: 'c')).called(1);
  });
}
