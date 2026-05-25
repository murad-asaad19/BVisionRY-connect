import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('Skeleton primitives + composites', (tester) async {
    final builder = GoldenBuilder.column(wrap: _wrap)
      ..addScenario(
        'small line',
        const SizedBox(
          width: 240,
          child: Skeleton(width: 120, height: 10, animate: false),
        ),
      )
      ..addScenario(
        'wide bar',
        const SizedBox(
          width: 280,
          child: Skeleton(height: 14, animate: false),
        ),
      )
      ..addScenario('list row', const SkeletonListRow(animate: false))
      ..addScenario(
        'profile',
        const SkeletonProfile(sections: 2, animate: false),
      );
    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(theme: buildAppTheme(Brightness.light)),
      surfaceSize: const Size(360, 1100),
    );
    // Settle the animation to t=0 so the snapshot stays deterministic.
    await tester.pump();
    await screenMatchesGolden(tester, 'skeleton_composites');
  });
}

Widget _wrap(Widget child) =>
    Padding(padding: const EdgeInsets.all(12), child: child);
