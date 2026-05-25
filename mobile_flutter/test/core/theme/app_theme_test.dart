import 'package:connect_mobile/core/theme/app_colors.dart';
import 'package:connect_mobile/core/theme/app_radii.dart';
import 'package:connect_mobile/core/theme/app_spacing.dart';
import 'package:connect_mobile/core/theme/app_theme.dart';
import 'package:connect_mobile/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppTheme registers all four ThemeExtensions', (tester) async {
    late ThemeData captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Builder(
          builder: (ctx) {
            captured = Theme.of(ctx);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(captured.extension<AppColors>(), isNotNull);
    expect(captured.extension<AppTypography>(), isNotNull);
    expect(captured.extension<AppSpacing>(), isNotNull);
    expect(captured.extension<AppRadii>(), isNotNull);
    expect(captured.extension<AppColors>()!.navy, const Color(0xFF0F3460));
  });
}
