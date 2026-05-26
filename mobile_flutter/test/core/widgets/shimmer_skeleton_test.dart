import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/widgets/shimmer_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  testWidgets(
    'ShimmerSkeleton wraps child in a Shimmer when animate=true',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const Scaffold(
            body: ShimmerSkeleton(width: 120, height: 16),
          ),
        ),
      );
      expect(find.byType(Shimmer), findsOneWidget);
    },
  );

  testWidgets(
    'ShimmerSkeleton paints a plain container when animate=false',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const Scaffold(
            body: ShimmerSkeleton(width: 120, height: 16, animate: false),
          ),
        ),
      );
      expect(find.byType(Shimmer), findsNothing);
      expect(find.byType(Container), findsOneWidget);
    },
  );
}
