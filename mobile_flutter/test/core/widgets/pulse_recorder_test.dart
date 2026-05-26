import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/pulse_recorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PulseRecorder renders a stack with mic icon when not recording',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(Brightness.light),
      home: const Scaffold(body: PulseRecorder(isRecording: false, size: 80)),
    ));
    expect(find.byIcon(Icons.mic), findsOneWidget);
    // give 1 pump but don't pumpAndSettle (animation is repeating).
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('PulseRecorder starts repeating when isRecording=true',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(Brightness.light),
      home: const Scaffold(body: PulseRecorder(isRecording: true, size: 80)),
    ));
    expect(find.byType(PulseRecorder), findsOneWidget);
    // advance some animation frames to ensure no exceptions
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    // Stop animation so pumpWidget() in teardown doesn't hang.
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(Brightness.light),
      home: const Scaffold(body: PulseRecorder(isRecording: false, size: 80)),
    ));
  });
}
