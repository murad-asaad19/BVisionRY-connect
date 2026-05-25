import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.navy,
    required this.navyLight,
    required this.navyDark,
    required this.gold,
    required this.goldLight,
    required this.goldPale,
    required this.surface,
    required this.white,
    required this.body,
    required this.muted,
    required this.border,
    required this.slate100,
    required this.slate300,
    required this.successBg,
    required this.success,
    required this.successBorder,
    required this.warningBg,
    required this.warning,
    required this.warningBorder,
    required this.dangerBg,
    required this.danger,
    required this.dangerBorder,
    required this.infoBg,
    required this.info,
    required this.infoBorder,
  });

  static const AppColors light = AppColors(
    navy: Color(0xFF0F3460),
    navyLight: Color(0xFF1A4A80),
    navyDark: Color(0xFF0A2340),
    gold: Color(0xFFFFC107),
    goldLight: Color(0xFFFFE187),
    goldPale: Color(0xFFFFF8E1),
    surface: Color(0xFFF8F8F8),
    white: Color(0xFFFFFFFF),
    body: Color(0xFF212529),
    muted: Color(0xFF94A3B8),
    border: Color(0xFFE5E7EB),
    slate100: Color(0xFFF1F5F9),
    slate300: Color(0xFFCBD5E1),
    successBg: Color(0xFFDCFCE7),
    success: Color(0xFF15803D),
    successBorder: Color(0xFF4ADE80),
    warningBg: Color(0xFFFEF3C7),
    warning: Color(0xFFB45309),
    warningBorder: Color(0xFFFBBF24),
    dangerBg: Color(0xFFFEE2E2),
    danger: Color(0xFFB91C1C),
    dangerBorder: Color(0xFFEF4444),
    infoBg: Color(0xFFDBEAFE),
    info: Color(0xFF1D4ED8),
    infoBorder: Color(0xFF93C5FD),
  );

  final Color navy;
  final Color navyLight;
  final Color navyDark;
  final Color gold;
  final Color goldLight;
  final Color goldPale;
  final Color surface;
  final Color white;
  final Color body;
  final Color muted;
  final Color border;
  final Color slate100;
  final Color slate300;
  final Color successBg;
  final Color success;
  final Color successBorder;
  final Color warningBg;
  final Color warning;
  final Color warningBorder;
  final Color dangerBg;
  final Color danger;
  final Color dangerBorder;
  final Color infoBg;
  final Color info;
  final Color infoBorder;

  @override
  AppColors copyWith({
    Color? navy,
    Color? navyLight,
    Color? navyDark,
    Color? gold,
    Color? goldLight,
    Color? goldPale,
    Color? surface,
    Color? white,
    Color? body,
    Color? muted,
    Color? border,
    Color? slate100,
    Color? slate300,
    Color? successBg,
    Color? success,
    Color? successBorder,
    Color? warningBg,
    Color? warning,
    Color? warningBorder,
    Color? dangerBg,
    Color? danger,
    Color? dangerBorder,
    Color? infoBg,
    Color? info,
    Color? infoBorder,
  }) {
    return AppColors(
      navy: navy ?? this.navy,
      navyLight: navyLight ?? this.navyLight,
      navyDark: navyDark ?? this.navyDark,
      gold: gold ?? this.gold,
      goldLight: goldLight ?? this.goldLight,
      goldPale: goldPale ?? this.goldPale,
      surface: surface ?? this.surface,
      white: white ?? this.white,
      body: body ?? this.body,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      slate100: slate100 ?? this.slate100,
      slate300: slate300 ?? this.slate300,
      successBg: successBg ?? this.successBg,
      success: success ?? this.success,
      successBorder: successBorder ?? this.successBorder,
      warningBg: warningBg ?? this.warningBg,
      warning: warning ?? this.warning,
      warningBorder: warningBorder ?? this.warningBorder,
      dangerBg: dangerBg ?? this.dangerBg,
      danger: danger ?? this.danger,
      dangerBorder: dangerBorder ?? this.dangerBorder,
      infoBg: infoBg ?? this.infoBg,
      info: info ?? this.info,
      infoBorder: infoBorder ?? this.infoBorder,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      navy: Color.lerp(navy, other.navy, t)!,
      navyLight: Color.lerp(navyLight, other.navyLight, t)!,
      navyDark: Color.lerp(navyDark, other.navyDark, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldLight: Color.lerp(goldLight, other.goldLight, t)!,
      goldPale: Color.lerp(goldPale, other.goldPale, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      white: Color.lerp(white, other.white, t)!,
      body: Color.lerp(body, other.body, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      slate100: Color.lerp(slate100, other.slate100, t)!,
      slate300: Color.lerp(slate300, other.slate300, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerBorder: Color.lerp(dangerBorder, other.dangerBorder, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoBorder: Color.lerp(infoBorder, other.infoBorder, t)!,
    );
  }
}
