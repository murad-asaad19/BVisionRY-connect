import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_stepper.dart';
import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('AppStepper variants', (tester) async {
    final builder = GoldenBuilder.column(wrap: _wrap)
      ..addScenario(
        'middle',
        AppStepper(value: 5, onChanged: (_) {}),
      )
      ..addScenario(
        'at min',
        AppStepper(value: 0, onChanged: (_) {}),
      )
      ..addScenario(
        'at max',
        AppStepper(value: 99, onChanged: (_) {}),
      )
      ..addScenario(
        'with suffix',
        AppStepper(value: 30, suffix: ' min', onChanged: (_) {}),
      );
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 520),
    );
    await screenMatchesGolden(tester, 'app_stepper_variants');
  });
}

Widget _wrap(Widget child) => Align(
      alignment: Alignment.centerLeft,
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
