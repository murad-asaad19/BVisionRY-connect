import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.navy,
    required this.navyLight,
    required this.navyDark,
    required this.navyFill,
    required this.onNavy,
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
    navyFill: Color(0xFF0F3460),
    onNavy: Color(0xFFFFFFFF),
    gold: Color(0xFFFFC107),
    goldLight: Color(0xFFFFE187),
    goldPale: Color(0xFFFFF8E1),
    surface: Color(0xFFF8F8F8),
    white: Color(0xFFFFFFFF),
    body: Color(0xFF212529),
    // Darkened from #94A3B8 (2.56:1 — failed WCAG AA) to #5B6675, which
    // clears 4.5:1 AA on white and on the slate100/surface troughs while
    // preserving the gray hierarchy. `muted` carries essential secondary
    // text in 60+ files, so this single edit fixes contrast app-wide.
    muted: Color(0xFF5B6675),
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

  /// Dark theme palette. Brand navy is lightened into a readable blue for
  /// primary surfaces/accents on dark backgrounds; gold is retained as-is
  /// (it reads well on dark). Status foreground colors are lightened and
  /// their backgrounds darkened so each pair clears AA on the dark surface.
  static const AppColors dark = AppColors(
    navy: Color(0xFF4D8AD6),
    navyLight: Color(0xFF6BA3E0),
    navyDark: Color(0xFF0F3460),
    navyFill: Color(0xFF2E6BC0),
    onNavy: Color(0xFFFFFFFF),
    gold: Color(0xFFFFC107),
    goldLight: Color(0xFFFFE187),
    goldPale: Color(0xFF3A341F),
    surface: Color(0xFF0F172A),
    white: Color(0xFF1E293B),
    body: Color(0xFFE8EDF4),
    muted: Color(0xFF9FB0C3),
    border: Color(0xFF334155),
    slate100: Color(0xFF1B2638),
    slate300: Color(0xFF475569),
    successBg: Color(0xFF14331F),
    success: Color(0xFF4ADE80),
    successBorder: Color(0xFF166534),
    warningBg: Color(0xFF3A2E12),
    warning: Color(0xFFFBBF24),
    warningBorder: Color(0xFF92660C),
    dangerBg: Color(0xFF3B1A1A),
    danger: Color(0xFFF87171),
    dangerBorder: Color(0xFF7F1D1D),
    infoBg: Color(0xFF152A45),
    info: Color(0xFF93C5FD),
    infoBorder: Color(0xFF1E40AF),
  );

  final Color navy;
  final Color navyLight;
  final Color navyDark;

  /// Brand-navy FILL for tappable buttons/bubbles (mid-navy in dark so white
  /// text clears AA 5.28:1 AND the control stays distinct from the #0F172A
  /// surface at 3.38:1).
  final Color navyFill;

  /// Always-white text/icon foreground for navy fills/bands.
  final Color onNavy;
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
    Color? navyFill,
    Color? onNavy,
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
      navyFill: navyFill ?? this.navyFill,
      onNavy: onNavy ?? this.onNavy,
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
      navyFill: Color.lerp(navyFill, other.navyFill, t)!,
      onNavy: Color.lerp(onNavy, other.onNavy, t)!,
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
