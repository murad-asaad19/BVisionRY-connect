import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/pill.dart';
import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('Pill variants', (tester) async {
    final builder = GoldenBuilder.column(wrap: _wrap)
      ..addScenario('default', const Pill(label: 'Default'))
      ..addScenario(
        'solid',
        const Pill(label: 'Solid', variant: PillVariant.solid),
      )
      ..addScenario(
        'navy',
        const Pill(label: 'Navy', variant: PillVariant.navy),
      )
      ..addScenario(
        'outline',
        const Pill(label: 'Outline', variant: PillVariant.outline),
      )
      ..addScenario(
        'muted',
        const Pill(label: 'Muted', variant: PillVariant.muted),
      )
      ..addScenario(
        'success',
        const Pill(label: 'Success', variant: PillVariant.success),
      )
      ..addScenario(
        'warning',
        const Pill(label: 'Warning', variant: PillVariant.warning),
      )
      ..addScenario(
        'danger',
        const Pill(label: 'Danger', variant: PillVariant.danger),
      )
      ..addScenario(
        'info',
        const Pill(label: 'Info', variant: PillVariant.info),
      )
      ..addScenario(
        'md-size',
        const Pill(label: 'Medium', size: PillSize.md),
      );
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 860),
    );
    await screenMatchesGolden(tester, 'pill_variants');
  });
}

Widget _wrap(Widget child) => Align(
      alignment: Alignment.centerLeft,
      child: Padding(padding: const EdgeInsets.all(8), child: child),
    );
