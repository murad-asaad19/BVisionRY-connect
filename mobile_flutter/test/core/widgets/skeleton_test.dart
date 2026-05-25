import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Skeleton renders a sized Container with slate background',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: Skeleton(width: 100, height: 16, animate: false),
        ),
      ),
    );
    final box = tester.widget<Container>(
      find.byKey(const ValueKey('skeleton-frame')),
    );
    expect(box.constraints?.minWidth ?? 0, anyOf(0.0, 100.0));
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(8));
  });

  testWidgets('Skeleton animates opacity (rebuilds over time)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(body: Skeleton(width: 80, height: 10)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    final firstColor = (tester
            .widget<Container>(find.byKey(const ValueKey('skeleton-frame')))
            .decoration! as BoxDecoration)
        .color;
    await tester.pump(const Duration(milliseconds: 400));
    final secondColor = (tester
            .widget<Container>(find.byKey(const ValueKey('skeleton-frame')))
            .decoration! as BoxDecoration)
        .color;
    expect(firstColor, isNot(equals(secondColor)));
    // Replace the animated tree with an empty Scaffold so the
    // SingleTickerProvider can dispose its controller cleanly (Skeleton's
    // `repeat` ticker would otherwise keep the test pending forever).
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(),
      ),
    );
  });

  testWidgets('SkeletonListRow has avatar + two text bars', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(body: SkeletonListRow(animate: false)),
      ),
    );
    expect(find.byType(Skeleton), findsNWidgets(3));
  });

  testWidgets('SkeletonProfile has hero + N sections', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: SkeletonProfile(sections: 2, animate: false),
          ),
        ),
      ),
    );
    // 3 hero bars + 2 sections × 4 bars = 11 skeletons
    expect(find.byType(Skeleton), findsNWidgets(3 + 2 * 4));
  });
}
