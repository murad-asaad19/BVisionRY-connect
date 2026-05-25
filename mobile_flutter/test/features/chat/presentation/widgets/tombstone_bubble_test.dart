import 'package:connect_mobile/features/chat/presentation/widgets/text_bubble.dart';
import 'package:connect_mobile/features/chat/presentation/widgets/tombstone_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

void main() {
  testWidgets('renders localised "Message deleted" copy', (tester) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: const Scaffold(
          body: TombstoneBubble(variant: BubbleVariant.them),
        ),
      ),
    );
    expect(find.text('Message deleted'), findsOneWidget);
  });
}
