import 'package:connect_mobile/features/meetings/data/meetings_service.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_proposal.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_state.dart';
import 'package:connect_mobile/features/meetings/presentation/confirm_meeting_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump.dart';

class _MockSvc extends Mock implements MeetingsService {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  testWidgets('ConfirmMeetingSheet lists slots as radio buttons + Confirm',
      (tester) async {
    final svc = _MockSvc();
    final proposal = _proposed(
      slots: [
        DateTime.now().toUtc().add(const Duration(days: 1)),
        DateTime.now().toUtc().add(const Duration(days: 2)),
      ],
    );
    final tree = await wrapWithTheme(
      overrides: [meetingsServiceProvider.overrideWithValue(svc)],
      child: ConfirmMeetingSheet(proposal: proposal),
    );
    await pumpWithI18n(tester, tree);
    // ignore: deprecated_member_use_from_same_package, deprecated_member_use
    expect(find.byType(RadioListTile<DateTime>), findsNWidgets(2));
    expect(find.text('Confirm'), findsWidgets);
  });

  testWidgets('Confirm tap calls confirmMeeting on the service', (tester) async {
    final svc = _MockSvc();
    final slot = DateTime.now().toUtc().add(const Duration(days: 1));
    final proposal = _proposed(slots: [slot]);
    when(() => svc.confirmMeeting(any(), any())).thenAnswer(
      (_) async => proposal.copyWith(state: MeetingState.confirmed),
    );
    // Trailing-comma guard for any inserted future text.
    final tree = await wrapWithTheme(
      overrides: [meetingsServiceProvider.overrideWithValue(svc)],
      child: ConfirmMeetingSheet(proposal: proposal),
    );
    await pumpWithI18n(tester, tree);
    await tester.tap(find.byKey(const Key('confirm-submit')));
    await tester.pumpAndSettle();
    verify(() => svc.confirmMeeting('m', slot)).called(1);
  });
}

MeetingProposal _proposed({required List<DateTime> slots}) => MeetingProposal(
      id: 'm',
      conversationId: 'c',
      proposedById: 'them',
      slots: slots,
      durationMinutes: 30,
      timezone: 'UTC',
      state: MeetingState.proposed,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
