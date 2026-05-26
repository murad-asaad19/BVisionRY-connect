@Tags(<String>['integration'])
library;

import 'package:connect_mobile/core/i18n/locale_loader.dart';
import 'package:connect_mobile/core/i18n/locale_notifier.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_proposal.dart';
import 'package:connect_mobile/features/meetings/domain/meeting_state.dart';
import 'package:connect_mobile/features/meetings/presentation/meeting_card_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Lightweight Phase 8 smoke test.
///
/// Boots [MeetingCardBubble] for each [MeetingState] inside a
/// [ProviderScope] and asserts the bubble renders the right action
/// surface without crashing. Marked with the `integration` tag so the
/// default `flutter test` run skips it; CI runs `flutter test --tags
/// integration` on a connected device.
///
/// A fuller propose → confirm → ICS → review happy-path requires two
/// authenticated sessions plus a stubbed `meeting-playbook` edge
/// function — that lives in the CI workflow on top of Supabase test
/// project credentials and is out of scope for this smoke.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MeetingCardBubble boots cleanly for every state',
      (tester) async {
    final loader = LocaleLoader();
    await loader.load('en');
    for (final state in MeetingState.values) {
      final p = _proposalFor(state);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [localeLoaderProvider.overrideWithValue(loader)],
          child: MaterialApp(
            theme: buildAppTheme(Brightness.light),
            home: Scaffold(
              body: MeetingCardBubble(proposal: p, viewerId: 'me'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(MeetingCardBubble), findsOneWidget);
    }
  });
}

MeetingProposal _proposalFor(MeetingState state) {
  final slot = DateTime.now().toUtc().add(const Duration(days: 1));
  return MeetingProposal(
    id: 'm',
    conversationId: 'c',
    proposedById: state == MeetingState.cancelled ? 'me' : 'them',
    slots: [slot],
    confirmedSlot: state == MeetingState.confirmed ? slot : null,
    durationMinutes: 30,
    timezone: 'UTC',
    state: state,
    createdAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );
}
