import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_divider.dart';
import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('AppDivider variants', (tester) async {
    final builder = GoldenBuilder.column(wrap: _wrapPad)
      ..addScenario('plain', const AppDivider())
      ..addScenario('with-label', const AppDivider(label: 'OR'))
      ..addScenario(
        'vertical',
        const SizedBox(
            height: 40, child: AppDivider(orientation: Axis.vertical),),
      );
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 400),
    );
    await screenMatchesGolden(tester, 'app_divider_variants');
  });
}

Widget _wrapPad(Widget child) =>
    Padding(padding: const EdgeInsets.all(8), child: child);
