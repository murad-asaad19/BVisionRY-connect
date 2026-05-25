import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/progress_dots.dart';
import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('ProgressDots states', (tester) async {
    final builder = GoldenBuilder.column(wrap: _wrap)
      ..addScenario('start', const ProgressDots(total: 5, current: 0))
      ..addScenario('middle', const ProgressDots(total: 5, current: 2))
      ..addScenario('near-end', const ProgressDots(total: 5, current: 4))
      ..addScenario('complete', const ProgressDots(total: 5, current: 5))
      ..addScenario('three-dots', const ProgressDots(total: 3, current: 1));
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 500),
    );
    await screenMatchesGolden(tester, 'progress_dots_states');
  });
}

Widget _wrap(Widget child) =>
    Padding(padding: const EdgeInsets.all(16), child: child);
