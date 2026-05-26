import 'package:connect_mobile/features/meetings/data/meeting_playbook_service.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_playbook.dart';
import 'package:connect_mobile/features/meetings/presentation/meeting_playbook_card.dart';
import 'package:connect_mobile/features/meetings/providers/meeting_playbook_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump.dart';

class _MockSvc extends Mock implements MeetingPlaybookService {}

void main() {
  testWidgets('shows "Generate playbook" CTA when cache empty', (tester) async {
    final svc = _MockSvc();
    final tree = await wrapWithTheme(
      overrides: [
        meetingPlaybookServiceProvider.overrideWithValue(svc),
        meetingPlaybookProvider('mid').overrideWith((ref) async => null),
      ],
      child: const Scaffold(body: MeetingPlaybookCard(meetingId: 'mid')),
    );
    await pumpWithI18n(tester, tree);
    expect(find.text('Generate playbook'), findsOneWidget);
  });

  testWidgets('disables Regenerate within 1 hour of generated_at',
      (tester) async {
    final svc = _MockSvc();
    final fresh = _playbook(
      generatedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
    );
    final tree = await wrapWithTheme(
      overrides: [
        meetingPlaybookServiceProvider.overrideWithValue(svc),
        meetingPlaybookProvider('mid').overrideWith((ref) async => fresh),
      ],
      child: const Scaffold(body: MeetingPlaybookCard(meetingId: 'mid')),
    );
    await pumpWithI18n(tester, tree);
    expect(find.text('Try again in 1 hour'), findsOneWidget);
  });

  testWidgets('enables Regenerate after 1 hour past generated_at',
      (tester) async {
    final svc = _MockSvc();
    final old = _playbook(
      generatedAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
    );
    final tree = await wrapWithTheme(
      overrides: [
        meetingPlaybookServiceProvider.overrideWithValue(svc),
        meetingPlaybookProvider('mid').overrideWith((ref) async => old),
      ],
      child: const Scaffold(body: MeetingPlaybookCard(meetingId: 'mid')),
    );
    await pumpWithI18n(tester, tree);
    expect(find.text('Regenerate'), findsOneWidget);
  });
}

MeetingPlaybook _playbook({required DateTime generatedAt}) => MeetingPlaybook(
      meetingId: 'mid',
      viewerId: 'vid',
      targetId: 'tid',
      summary: 'About them.',
      sharedInterests: const ['a', 'b'],
      conversationStarters: const ['Ask X', 'Mention Y'],
      doNotes: const ['Do this'],
      dontNotes: const ['Avoid that'],
      generatedAt: generatedAt,
    );
