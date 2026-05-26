import 'package:connect_mobile/features/meetings/domain/meeting_proposal.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_state.dart';
import 'package:connect_mobile/features/meetings/presentation/meeting_card_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump.dart';

/// Permission / state-gating smoke test for [MeetingCardBubble].
///
/// Asserts the four state-driven button-visibility rules in one place so
/// regressions in the state→actions switch are caught immediately:
///
/// 1. Proposer never sees Confirm (server would raise `42501`).
/// 2. Proposer sees Cancel only when state == proposed.
/// 3. Add-to-calendar appears only when state == confirmed.
/// 4. Declined / cancelled show no action buttons at all.
void main() {
  group('MeetingCardBubble permission gating', () {
    testWidgets('proposer NEVER sees the Confirm button', (tester) async {
      for (final state in MeetingState.values) {
        final p = _make(proposedBy: 'me', state: state);
        final tree = await wrapWithTheme(
          child: Scaffold(body: MeetingCardBubble(proposal: p, viewerId: 'me')),
        );
        await pumpWithI18n(tester, tree);
        expect(
          find.text('Confirm'),
          findsNothing,
          reason: 'state=$state should not show Confirm on proposer side',
        );
      }
    });

    testWidgets('Cancel only shows while state == proposed', (tester) async {
      for (final state in MeetingState.values) {
        final p = _make(proposedBy: 'me', state: state);
        final tree = await wrapWithTheme(
          child: Scaffold(body: MeetingCardBubble(proposal: p, viewerId: 'me')),
        );
        await pumpWithI18n(tester, tree);
        final found = find.text('Cancel proposal').evaluate().isNotEmpty;
        expect(
          found,
          state == MeetingState.proposed,
          reason: 'state=$state cancel-visible mismatch',
        );
      }
    });

    testWidgets('Add to calendar only shows when state == confirmed',
        (tester) async {
      for (final state in MeetingState.values) {
        final p = _make(proposedBy: 'them', state: state);
        final tree = await wrapWithTheme(
          child: Scaffold(body: MeetingCardBubble(proposal: p, viewerId: 'me')),
        );
        await pumpWithI18n(tester, tree);
        final found = find.text('Add to calendar').evaluate().isNotEmpty;
        expect(
          found,
          state == MeetingState.confirmed,
          reason: 'state=$state add-to-calendar visibility mismatch',
        );
      }
    });

    testWidgets('Declined / cancelled show no action buttons', (tester) async {
      for (final state in [MeetingState.declined, MeetingState.cancelled]) {
        for (final viewerId in ['me', 'other']) {
          final p = _make(proposedBy: 'me', state: state);
          final tree = await wrapWithTheme(
            child: Scaffold(
              body: MeetingCardBubble(proposal: p, viewerId: viewerId),
            ),
          );
          await pumpWithI18n(tester, tree);
          expect(find.text('Confirm'), findsNothing);
          expect(find.text('Decline'), findsNothing);
          expect(find.text('Cancel proposal'), findsNothing);
          expect(find.text('Add to calendar'), findsNothing);
        }
      }
    });
  });
}

MeetingProposal _make({
  required String proposedBy,
  required MeetingState state,
}) {
  final slot = DateTime.now().toUtc().add(const Duration(days: 1));
  return MeetingProposal(
    id: 'm',
    conversationId: 'c',
    proposedById: proposedBy,
    slots: [slot],
    confirmedSlot: state == MeetingState.confirmed ? slot : null,
    durationMinutes: 30,
    timezone: 'UTC',
    state: state,
    createdAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );
}
