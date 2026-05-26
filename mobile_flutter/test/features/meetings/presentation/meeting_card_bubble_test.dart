import 'package:connect_mobile/features/meetings/domain/meeting_proposal.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_state.dart';
import 'package:connect_mobile/features/meetings/presentation/meeting_card_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump.dart';

void main() {
  testWidgets(
    'proposed + proposer: shows Cancel proposal, no Confirm/Decline',
    (tester) async {
      final p = _proposed(proposedBy: 'me');
      final tree = await wrapWithTheme(
        child: Scaffold(body: MeetingCardBubble(proposal: p, viewerId: 'me')),
      );
      await pumpWithI18n(tester, tree);
      expect(find.text('Cancel proposal'), findsOneWidget);
      expect(find.text('Confirm'), findsNothing);
      expect(find.text('Decline'), findsNothing);
    },
  );

  testWidgets(
    'proposed + recipient: shows Confirm + Decline, no Cancel',
    (tester) async {
      final p = _proposed(proposedBy: 'them');
      final tree = await wrapWithTheme(
        child: Scaffold(body: MeetingCardBubble(proposal: p, viewerId: 'me')),
      );
      await pumpWithI18n(tester, tree);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      expect(find.text('Cancel proposal'), findsNothing);
    },
  );

  testWidgets(
    'confirmed: shows Add to calendar + Meeting playbook',
    (tester) async {
      final p = _confirmed();
      final tree = await wrapWithTheme(
        child: Scaffold(body: MeetingCardBubble(proposal: p, viewerId: 'me')),
      );
      await pumpWithI18n(tester, tree);
      expect(find.text('Add to calendar'), findsOneWidget);
      expect(find.text('Meeting playbook'), findsOneWidget);
    },
  );

  testWidgets('declined: shows status pill only, no action buttons',
      (tester) async {
    final p = _proposed(proposedBy: 'me')
        .copyWith(state: MeetingState.declined);
    final tree = await wrapWithTheme(
      child: Scaffold(body: MeetingCardBubble(proposal: p, viewerId: 'me')),
    );
    await pumpWithI18n(tester, tree);
    expect(find.text('Declined'), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
    expect(find.text('Cancel proposal'), findsNothing);
    expect(find.text('Add to calendar'), findsNothing);
  });

  testWidgets('cancelled: same as declined, no action buttons',
      (tester) async {
    final p = _proposed(proposedBy: 'me')
        .copyWith(state: MeetingState.cancelled);
    final tree = await wrapWithTheme(
      child: Scaffold(body: MeetingCardBubble(proposal: p, viewerId: 'me')),
    );
    await pumpWithI18n(tester, tree);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
    expect(find.text('Cancel proposal'), findsNothing);
  });
}

MeetingProposal _proposed({required String proposedBy}) => MeetingProposal(
      id: 'm',
      conversationId: 'c',
      proposedById: proposedBy,
      slots: [DateTime.now().toUtc().add(const Duration(days: 1))],
      durationMinutes: 30,
      timezone: 'UTC',
      state: MeetingState.proposed,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

MeetingProposal _confirmed() => MeetingProposal(
      id: 'm',
      conversationId: 'c',
      proposedById: 'them',
      slots: [DateTime.now().toUtc().add(const Duration(days: 1))],
      confirmedSlot: DateTime.now().toUtc().add(const Duration(days: 1)),
      durationMinutes: 30,
      timezone: 'UTC',
      state: MeetingState.confirmed,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
