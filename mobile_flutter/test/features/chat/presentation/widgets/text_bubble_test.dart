import 'package:connect_mobile/features/chat/presentation/widgets/text_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

void main() {
  testWidgets('renders body and gates edited badge by isEdited',
      (tester) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: const Scaffold(
          body: TextBubble(
            body: 'hello flutter',
            variant: BubbleVariant.them,
            isEdited: true,
          ),
        ),
      ),
    );
    expect(find.text('hello flutter'), findsOneWidget);
    expect(find.textContaining('edited'), findsOneWidget);
  });

  testWidgets('hides edited badge when isEdited is false', (tester) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: const Scaffold(
          body: TextBubble(
            body: 'hi',
            variant: BubbleVariant.me,
          ),
        ),
      ),
    );
    expect(find.text('hi'), findsOneWidget);
    expect(find.textContaining('edited'), findsNothing);
  });

  testWidgets('fires onLongPress when bubble is long-pressed', (tester) async {
    var taps = 0;
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: Scaffold(
          body: TextBubble(
            body: 'hold me',
            variant: BubbleVariant.me,
            onLongPress: () => taps++,
          ),
        ),
      ),
    );
    await tester.longPress(find.text('hold me'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });
}
