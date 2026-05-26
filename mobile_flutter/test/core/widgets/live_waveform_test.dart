import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/live_waveform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LiveWaveform renders AudioWaveforms when controller provided',
      (tester) async {
    final controller = RecorderController();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(body: LiveWaveform(controller: controller)),
      ),
    );
    expect(find.byType(AudioWaveforms), findsOneWidget);
    controller.dispose();
  });
}
