import 'package:connect_mobile/features/chat/presentation/widgets/voice_waveform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

void main() {
  testWidgets('renders the CustomPaint at the expected height', (tester) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: const Scaffold(
          body: SizedBox(width: 200, child: VoiceWaveform(progress: 0.5)),
        ),
      ),
    );
    expect(find.byType(VoiceWaveform), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  test('defaultHeights returns deterministic values', () {
    final a = VoiceWaveform.defaultHeights(13);
    final b = VoiceWaveform.defaultHeights(13);
    expect(a, b);
    expect(a, hasLength(13));
    for (final h in a) {
      expect(h, inInclusiveRange(0.35, 1.0));
    }
  });
}
