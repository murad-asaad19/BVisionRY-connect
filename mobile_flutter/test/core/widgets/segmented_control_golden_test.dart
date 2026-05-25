import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('SegmentedControl states', (tester) async {
    final builder = GoldenBuilder.column(wrap: _wrap)
      ..addScenario(
        'two-segment - first selected',
        SegmentedControl<String>(
          options: const [
            SegmentedOption(value: 'list', label: 'List'),
            SegmentedOption(value: 'map', label: 'Map'),
          ],
          value: 'list',
          onChange: (_) {},
        ),
      )
      ..addScenario(
        'three-segment - middle selected',
        SegmentedControl<String>(
          options: const [
            SegmentedOption(value: 'all', label: 'All'),
            SegmentedOption(value: 'verified', label: 'Verified'),
            SegmentedOption(value: 'mentors', label: 'Mentors'),
          ],
          value: 'verified',
          onChange: (_) {},
        ),
      );
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 320),
    );
    await screenMatchesGolden(tester, 'segmented_control_states');
  });
}

Widget _wrap(Widget child) =>
    Padding(padding: const EdgeInsets.all(12), child: child);
