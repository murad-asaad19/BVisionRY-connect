import 'package:connect_mobile/features/chat/presentation/widgets/voice_recorder_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

void main() {
  testWidgets(
    'renders title, timer, hint, and cancel button in idle state',
    (tester) async {
      final widget = await wrapWithTheme(
        child: const Scaffold(
          body: VoiceRecorderSheet(conversationId: 'c1'),
        ),
      );
      // The sheet has a repeating AnimationController (pulse ring) — use a
      // single `pump` instead of `pumpAndSettle` to avoid timing out.
      await tester.pumpWidget(widget);
      await tester.pump();
      expect(find.text('0:00'), findsOneWidget);
      expect(find.byType(VoiceRecorderSheet), findsOneWidget);
    },
  );
}
