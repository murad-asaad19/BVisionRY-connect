import 'package:connect_mobile/features/chat/presentation/widgets/conversation_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

void main() {
  testWidgets('renders peer name and headline', (tester) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: Scaffold(
          appBar: ConversationAppBar(
            peerName: 'Ada Lovelace',
            peerHandle: 'ada',
            peerPhotoUrl: null,
            peerHeadline: 'Mathematician',
            isMuted: false,
            isVerified: false,
            isTyping: false,
            onTapProfile: () {},
            onToggleMute: () {},
            onReport: () {},
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Mathematician'), findsOneWidget);
  });

  testWidgets('swaps subtitle to "typing..." when isTyping', (tester) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: Scaffold(
          appBar: ConversationAppBar(
            peerName: 'Ada',
            peerHandle: 'ada',
            peerPhotoUrl: null,
            peerHeadline: 'Mathematician',
            isMuted: false,
            isVerified: false,
            isTyping: true,
            onTapProfile: () {},
            onToggleMute: () {},
            onReport: () {},
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );
    expect(find.text('Mathematician'), findsNothing);
    expect(find.textContaining('typing'), findsOneWidget);
  });
}
