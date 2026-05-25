import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/app_filter_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('AppFilterChip states', (tester) async {
    final builder = GoldenBuilder.column(wrap: _wrap)
      ..addScenario(
        'inactive',
        AppFilterChip(label: 'Mentors', active: false, onTap: () {}),
      )
      ..addScenario(
        'active',
        AppFilterChip(label: 'Mentors', active: true, onTap: () {}),
      )
      ..addScenario(
        'with-icon',
        AppFilterChip(
          label: 'Verified',
          active: false,
          icon: Icons.verified,
          onTap: () {},
        ),
      )
      ..addScenario(
        'with-count',
        AppFilterChip(label: 'All', active: true, count: 42, onTap: () {}),
      );
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 400),
    );
    await screenMatchesGolden(tester, 'app_filter_chip_states');
  });
}

Widget _wrap(Widget child) => Align(
      alignment: Alignment.centerLeft,
      child: Padding(padding: const EdgeInsets.all(8), child: child),
    );
