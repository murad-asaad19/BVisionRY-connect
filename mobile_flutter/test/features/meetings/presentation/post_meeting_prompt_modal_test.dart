import 'package:connect_mobile/features/meetings/data/meetings_service.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_review.dart';
import 'package:connect_mobile/features/meetings/presentation/post_meeting_prompt_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump.dart';

class _MockSvc extends Mock implements MeetingsService {}

void main() {
  setUpAll(() {
    registerFallbackValue(MeetingReviewOutcome.useful);
  });

  testWidgets('renders three G2 prompt buttons + fallback note',
      (tester) async {
    final svc = _MockSvc();
    final tree = await wrapWithTheme(
      overrides: [meetingsServiceProvider.overrideWithValue(svc)],
      child: const PostMeetingPromptModal(meetingId: 'mid'),
    );
    await pumpWithI18n(tester, tree);
    expect(find.byKey(const Key('post-prompt-yes')), findsOneWidget);
    expect(find.byKey(const Key('post-prompt-rescheduled')), findsOneWidget);
    expect(find.byKey(const Key('post-prompt-no-show')), findsOneWidget);
    expect(find.text('Did this meeting happen?'), findsOneWidget);
  });

  testWidgets('Rescheduled tap submits rescheduled outcome', (tester) async {
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
        meetingId: 'mid',
        reviewerId: 'me',
        outcome: MeetingReviewOutcome.rescheduled,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    final tree = await wrapWithTheme(
      overrides: [meetingsServiceProvider.overrideWithValue(svc)],
      child: const PostMeetingPromptModal(meetingId: 'mid'),
    );
    await pumpWithI18n(tester, tree);
    await tester.tap(find.byKey(const Key('post-prompt-rescheduled')));
    await tester.pump();
    verify(
      () => svc.submitMeetingReview(
        meetingId: 'mid',
        outcome: MeetingReviewOutcome.rescheduled,
        note: null,
      ),
    ).called(1);
  });

  testWidgets('No-show tap submits no-show outcome', (tester) async {
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
        meetingId: 'mid',
        reviewerId: 'me',
        outcome: MeetingReviewOutcome.noShow,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    final tree = await wrapWithTheme(
      overrides: [meetingsServiceProvider.overrideWithValue(svc)],
      child: const PostMeetingPromptModal(meetingId: 'mid'),
    );
    await pumpWithI18n(tester, tree);
    await tester.tap(find.byKey(const Key('post-prompt-no-show')));
    await tester.pump();
    verify(
      () => svc.submitMeetingReview(
        meetingId: 'mid',
        outcome: MeetingReviewOutcome.noShow,
        note: null,
      ),
    ).called(1);
  });
}
