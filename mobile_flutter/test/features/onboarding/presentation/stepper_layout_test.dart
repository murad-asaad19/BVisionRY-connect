import 'package:connect_mobile/features/onboarding/presentation/stepper_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump.dart';

void main() {
  testWidgets('renders step counter with current/total/stepName',
      (WidgetTester tester) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: const StepperLayout(
          stepIndex: 1,
          stepNameKey: 'onboarding.stepName.identity',
          child: Text('inner-body'),
        ),
      ),
    );

    expect(find.text('inner-body'), findsOneWidget);
    // Step counter contains "Step 2 of 4" pattern.
    expect(find.textContaining('2'), findsWidgets);
    expect(find.textContaining('4'), findsWidgets);
  });

  testWidgets('back button calls onBack when provided',
      (WidgetTester tester) async {
    int backCount = 0;
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: StepperLayout(
          stepIndex: 1,
          stepNameKey: 'onboarding.stepName.identity',
          onBack: () => backCount++,
          child: const Text('inner-body'),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Back'));
    expect(backCount, 1);
  });

  testWidgets('no back button when onBack is omitted',
      (WidgetTester tester) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: const StepperLayout(
          stepIndex: 0,
          stepNameKey: 'onboarding.stepName.goal',
          child: Text('inner'),
        ),
      ),
    );
    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('progress dots render 4 bars', (WidgetTester tester) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: const StepperLayout(
          stepIndex: 0,
          stepNameKey: 'onboarding.stepName.goal',
          child: Text('inner'),
        ),
      ),
    );

    // ProgressDots primitive marks each segment with key `progress-dot-<i>`.
    for (int i = 0; i < StepperLayout.totalSteps; i++) {
      expect(find.byKey(ValueKey<String>('progress-dot-$i')), findsOneWidget);
    }
  });

  testWidgets('renders footer when provided', (WidgetTester tester) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: const StepperLayout(
          stepIndex: 0,
          stepNameKey: 'onboarding.stepName.goal',
          footer: Text('footer-content'),
          child: Text('inner'),
        ),
      ),
    );
    expect(find.text('footer-content'), findsOneWidget);
  });
}
