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

  testWidgets('renders three outcome cards + Skip', (tester) async {
    final svc = _MockSvc();
    final tree = await wrapWithTheme(
      overrides: [meetingsServiceProvider.overrideWithValue(svc)],
      child: const PostMeetingPromptModal(meetingId: 'mid'),
    );
    await pumpWithI18n(tester, tree);
    expect(find.text('Useful'), findsAtLeast(1));
    expect(find.text('Not useful'), findsOneWidget);
    expect(find.text('No-show'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
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
        meetingId: 'mid',
        reviewerId: 'me',
        outcome: MeetingReviewOutcome.useful,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    final tree = await wrapWithTheme(
      overrides: [meetingsServiceProvider.overrideWithValue(svc)],
      child: const PostMeetingPromptModal(meetingId: 'mid'),
    );
    await pumpWithI18n(tester, tree);
    await tester.tap(find.byKey(const Key('post-review-useful')));
    await tester.pump();
    verify(
      () => svc.submitMeetingReview(
        meetingId: 'mid',
        outcome: MeetingReviewOutcome.useful,
        note: null,
      ),
    ).called(1);
  });
}
