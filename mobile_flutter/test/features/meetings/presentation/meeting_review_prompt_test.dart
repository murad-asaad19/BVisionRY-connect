import 'package:connect_mobile/features/meetings/data/meetings_service.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_proposal.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_review.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_state.dart';
import 'package:connect_mobile/features/meetings/presentation/meeting_review_prompt.dart';
import 'package:connect_mobile/features/meetings/providers/pending_reviews_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump.dart';

class _MockSvc extends Mock implements MeetingsService {}

void main() {
  setUpAll(() {
    registerFallbackValue(MeetingReviewOutcome.useful);
  });

  testWidgets('renders Useful / Not useful / No-show when reviews pending',
      (tester) async {
    final tree = await wrapWithTheme(
      overrides: [
        pendingMeetingReviewsProvider('c').overrideWith(
          (ref) async => [_confirmedEnded()],
        ),
      ],
      child: const Scaffold(body: MeetingReviewPrompt(conversationId: 'c')),
    );
    await pumpWithI18n(tester, tree);
    expect(find.text('Useful'), findsOneWidget);
    expect(find.text('Not useful'), findsOneWidget);
    expect(find.text('No-show'), findsOneWidget);
  });

  testWidgets('renders nothing when no pending reviews', (tester) async {
    final tree = await wrapWithTheme(
      overrides: [
        pendingMeetingReviewsProvider('c').overrideWith(
          (ref) async => const [],
        ),
      ],
      child: const Scaffold(body: MeetingReviewPrompt(conversationId: 'c')),
    );
    await pumpWithI18n(tester, tree);
    expect(find.text('Useful'), findsNothing);
  });

  testWidgets('Useful tap calls submitMeetingReview', (tester) async {
    final svc = _MockSvc();
    when(
      () => svc.submitMeetingReview(
        meetingId: any(named: 'meetingId'),
        outcome: any(named: 'outcome'),
        note: any(named: 'note'),
      ),
    ).thenAnswer(
      (_) async => MeetingReview(
        id: 'r',
        meetingId: 'm',
        reviewerId: 'me',
        outcome: MeetingReviewOutcome.useful,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    final tree = await wrapWithTheme(
      overrides: [
        pendingMeetingReviewsProvider('c').overrideWith(
          (ref) async => [_confirmedEnded()],
        ),
        meetingsServiceProvider.overrideWithValue(svc),
      ],
      child: const Scaffold(body: MeetingReviewPrompt(conversationId: 'c')),
    );
    await pumpWithI18n(tester, tree);
    await tester.tap(find.byKey(const Key('review-useful')));
    await tester.pump();
    verify(
      () => svc.submitMeetingReview(
        meetingId: 'm',
        outcome: MeetingReviewOutcome.useful,
        note: null,
      ),
    ).called(1);
  });
}

MeetingProposal _confirmedEnded() {
  final past = DateTime.now().toUtc().subtract(const Duration(hours: 2));
  return MeetingProposal(
    id: 'm',
    conversationId: 'c',
    proposedById: 'them',
    slots: [past],
    confirmedSlot: past,
    durationMinutes: 30,
    timezone: 'UTC',
    state: MeetingState.confirmed,
    createdAt: past,
    updatedAt: past,
  );
}
