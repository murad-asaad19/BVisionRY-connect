import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_shadows.dart';
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
      // Brand-tinted halos read as muddy on the dark surface — drop to the
      // flat set there and keep the tinted elevation only on light.
      brightness == Brightness.dark ? AppShadows.none : AppShadows.from(colors),
    ],
    // Give the OFF switch state a visible track + outline so it doesn't
    // vanish against white cards (M3 default tracks are nearly invisible).
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll<Color>(Color(0xFFFFFFFF)),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) return colors.slate100;
        if (states.contains(WidgetState.selected)) return colors.gold;
        return const Color(0xFFE2E8F0);
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) return colors.border;
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFE0A800);
        }
        return colors.slate300;
      }),
      trackOutlineWidth: const WidgetStatePropertyAll<double>(1.5),
    ),
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
