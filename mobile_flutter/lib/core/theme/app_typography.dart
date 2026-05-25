import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.displayXl,
    required this.displayLg,
    required this.displayMd,
    required this.displaySm,
    required this.displayXs,
    required this.bodyLg,
    required this.bodyMd,
    required this.bodySm,
    required this.bodyXs,
  });

  factory AppTypography.dosisInter() {
    TextStyle dosis(double size, double lh, FontWeight w) => GoogleFonts.dosis(
          fontSize: size,
          height: lh / size,
          fontWeight: w,
        );
    TextStyle inter(double size, double lh, FontWeight w) => GoogleFonts.inter(
          fontSize: size,
          height: lh / size,
          fontWeight: w,
        );
    return AppTypography(
      displayXl: dosis(28, 34, FontWeight.w700),
      displayLg: dosis(20, 26, FontWeight.w700),
      displayMd: dosis(16, 22, FontWeight.w700),
      displaySm: dosis(13, 18, FontWeight.w700),
      displayXs: dosis(11, 14, FontWeight.w600),
      bodyLg: inter(14, 20, FontWeight.w400),
      bodyMd: inter(12, 18, FontWeight.w400),
      bodySm: inter(11, 15, FontWeight.w400),
      bodyXs: inter(10, 13, FontWeight.w400),
    );
  }

  final TextStyle displayXl;
  final TextStyle displayLg;
  final TextStyle displayMd;
  final TextStyle displaySm;
  final TextStyle displayXs;
  final TextStyle bodyLg;
  final TextStyle bodyMd;
  final TextStyle bodySm;
  final TextStyle bodyXs;

  @override
  AppTypography copyWith({
    TextStyle? displayXl,
    TextStyle? displayLg,
    TextStyle? displayMd,
    TextStyle? displaySm,
    TextStyle? displayXs,
    TextStyle? bodyLg,
    TextStyle? bodyMd,
    TextStyle? bodySm,
    TextStyle? bodyXs,
  }) {
    return AppTypography(
      displayXl: displayXl ?? this.displayXl,
      displayLg: displayLg ?? this.displayLg,
      displayMd: displayMd ?? this.displayMd,
      displaySm: displaySm ?? this.displaySm,
      displayXs: displayXs ?? this.displayXs,
      bodyLg: bodyLg ?? this.bodyLg,
      bodyMd: bodyMd ?? this.bodyMd,
      bodySm: bodySm ?? this.bodySm,
      bodyXs: bodyXs ?? this.bodyXs,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    return AppTypography(
      displayXl: TextStyle.lerp(displayXl, other.displayXl, t)!,
      displayLg: TextStyle.lerp(displayLg, other.displayLg, t)!,
      displayMd: TextStyle.lerp(displayMd, other.displayMd, t)!,
      displaySm: TextStyle.lerp(displaySm, other.displaySm, t)!,
      displayXs: TextStyle.lerp(displayXs, other.displayXs, t)!,
      bodyLg: TextStyle.lerp(bodyLg, other.bodyLg, t)!,
      bodyMd: TextStyle.lerp(bodyMd, other.bodyMd, t)!,
      bodySm: TextStyle.lerp(bodySm, other.bodySm, t)!,
      bodyXs: TextStyle.lerp(bodyXs, other.bodyXs, t)!,
    );
  }
}
