import 'package:connect_mobile/features/meetings/data/meetings_service.dart';
import 'package:connect_mobile/features/meetings/presentation/propose_meeting_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump.dart';

class _MockSvc extends Mock implements MeetingsService {}

void main() {
  setUpAll(() {
    registerFallbackValue(<DateTime>[]);
  });

  testWidgets('ProposeMeetingSheet shows three slot rows + duration + URL',
      (tester) async {
    final svc = _MockSvc();
    final tree = await wrapWithTheme(
      overrides: [meetingsServiceProvider.overrideWithValue(svc)],
      child: const Scaffold(body: ProposeMeetingSheet(conversationId: 'c')),
    );
    await pumpWithI18n(tester, tree);
    expect(find.byKey(const Key('propose-slot-0')), findsOneWidget);
    expect(find.byKey(const Key('propose-slot-1')), findsOneWidget);
    expect(find.byKey(const Key('propose-slot-2')), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);
    expect(find.byKey(const Key('propose-url')), findsOneWidget);
    expect(find.byKey(const Key('propose-submit')), findsOneWidget);
  });

  testWidgets('duration stepper increases by 15 per tap', (tester) async {
    final svc = _MockSvc();
    final tree = await wrapWithTheme(
      overrides: [meetingsServiceProvider.overrideWithValue(svc)],
      child: const Scaffold(body: ProposeMeetingSheet(conversationId: 'c')),
    );
    await pumpWithI18n(tester, tree);
    // Default 30, after one plus tap should be 45.
    await tester.tap(find.byKey(const Key('propose-duration-plus')));
    await tester.pump();
    expect(find.text('45 min'), findsOneWidget);
  });
}
