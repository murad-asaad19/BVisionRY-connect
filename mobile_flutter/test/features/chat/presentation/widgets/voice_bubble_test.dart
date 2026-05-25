import 'package:connect_mobile/features/chat/domain/transcript_status.dart';
import 'package:connect_mobile/features/chat/presentation/widgets/text_bubble.dart';
import 'package:connect_mobile/features/chat/presentation/widgets/voice_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

void main() {
  testWidgets('renders mm:ss duration label', (tester) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: const Scaffold(
          body: VoiceBubble(
            messageId: 'm1',
            mediaPath: 'c1/m1/voice.m4a',
            durationMs: 90000,
            variant: BubbleVariant.them,
          ),
        ),
      ),
    );
    expect(find.text('1:30'), findsOneWidget);
  });

  testWidgets('shows "Show transcript" toggle when transcript is ready', (
    tester,
  ) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: const Scaffold(
          body: VoiceBubble(
            messageId: 'm1',
            mediaPath: 'c1/m1/voice.m4a',
            durationMs: 30000,
            variant: BubbleVariant.them,
            transcript: 'hello world',
            transcriptStatus: TranscriptStatus.ready,
          ),
        ),
      ),
    );
    expect(find.textContaining('Show transcript'), findsOneWidget);
  });

  testWidgets('expands transcript on tap when ready', (tester) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: const Scaffold(
          body: VoiceBubble(
            messageId: 'm1',
            mediaPath: 'c1/m1/voice.m4a',
            durationMs: 30000,
            variant: BubbleVariant.them,
            transcript: 'hello world',
            transcriptStatus: TranscriptStatus.ready,
          ),
        ),
      ),
    );
    expect(find.text('hello world'), findsNothing);
    await tester.tap(find.textContaining('Show transcript'));
    await tester.pumpAndSettle();
    expect(find.text('hello world'), findsOneWidget);
  });

  testWidgets('shows pending placeholder while transcript processes', (
    tester,
  ) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: const Scaffold(
          body: VoiceBubble(
            messageId: 'm1',
            mediaPath: 'c1/m1/voice.m4a',
            durationMs: 30000,
            variant: BubbleVariant.them,
            transcriptStatus: TranscriptStatus.processing,
          ),
        ),
      ),
    );
    expect(find.textContaining('Transcript'), findsOneWidget);
  });
}
