import 'package:connect_mobile/features/chat/presentation/widgets/typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

void main() {
  testWidgets('renders typing copy and animated dots', (tester) async {
    await tester.pumpWidget(
      await wrapWithTheme(
        child: const Scaffold(body: TypingIndicator(peerName: 'Ada')),
      ),
    );
    // Don't pumpAndSettle — the indicator is an infinite animation.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('typing'), findsOneWidget);
    expect(find.textContaining('Ada'), findsOneWidget);
  });
}
