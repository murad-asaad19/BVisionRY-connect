import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

ThemeData buildAppTheme(Brightness brightness) {
  final AppColors colors =
      brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final typography = AppTypography.dosisInter();
  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    scaffoldBackgroundColor: colors.surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.navy,
      brightness: brightness,
      primary: colors.navy,
      secondary: colors.gold,
      surface: colors.surface, // matches scaffoldBackgroundColor
      surfaceContainerHighest: colors.white, // card whites use this slot
      surfaceContainer: colors.white,
      error: colors.danger,
    ),
    textTheme: TextTheme(
      displayLarge: typography.displayXl,
      displayMedium: typography.displayLg,
      headlineMedium: typography.displayMd,
      titleMedium: typography.displaySm,
      labelLarge: typography.displayXs,
      bodyLarge: typography.bodyLg,
      bodyMedium: typography.bodyMd,
      bodySmall: typography.bodySm,
    ),
    extensions: <ThemeExtension<dynamic>>[
      colors,
      typography,
      AppSpacing.standard,
      AppRadii.standard,
    ],
    // Phase 15: native-feeling page transitions (Cupertino slide on iOS,
    // fade-upwards on Android).
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
