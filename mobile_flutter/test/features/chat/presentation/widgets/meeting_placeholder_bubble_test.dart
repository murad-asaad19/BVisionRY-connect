import 'package:connect_mobile/features/chat/presentation/widgets/meeting_placeholder_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

void main() {
  testWidgets('renders Phase-8 placeholder copy and icon', (tester) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: const Scaffold(body: MeetingPlaceholderBubble()),
      ),
    );
    expect(find.text('Meeting proposal (Phase 8)'), findsOneWidget);
  });
}
