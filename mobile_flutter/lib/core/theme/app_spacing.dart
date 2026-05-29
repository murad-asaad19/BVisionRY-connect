import 'package:flutter/material.dart';

/// Spacing scale on a 4px grid.
///
/// [xs]..[xxl] are the canonical ramp that should replace hardcoded
/// `SizedBox`/`EdgeInsets` literals across the app (use with [Gap] or
/// `EdgeInsets.all(spacing.md)`). The semantic aliases [gutter], [card],
/// [cardLg] and [section] are retained (and point at the ramp) so existing
/// consumers and core widgets keep working unchanged.
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.gutter,
    required this.card,
    required this.cardLg,
    required this.section,
  });

  static const AppSpacing standard = AppSpacing(
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 20,
    xxl: 24,
    // Semantic aliases (unchanged values) — keep call sites stable.
    gutter: 16,
    card: 12,
    cardLg: 16,
    section: 24,
  );

  /// 4 — tight inner padding, icon/label gaps.
  final double xs;

  /// 8 — the most common inter-element gap.
  final double sm;

  /// 12 — card inner padding, related-element spacing.
  final double md;

  /// 16 — screen gutter, comfortable block spacing.
  final double lg;

  /// 20 — generous block spacing.
  final double xl;

  /// 24 — section separation.
  final double xxl;

  /// Screen edge gutter (alias of [lg]).
  final double gutter;

  /// Default card inner padding (alias of [md]).
  final double card;

  /// Large card inner padding (alias of [lg]).
  final double cardLg;

  /// Vertical separation between sections (alias of [xxl]).
  final double section;

  @override
  AppSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? gutter,
    double? card,
    double? cardLg,
    double? section,
  }) {
    return AppSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      gutter: gutter ?? this.gutter,
      card: card ?? this.card,
      cardLg: cardLg ?? this.cardLg,
      section: section ?? this.section,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      xs: _lerp(xs, other.xs, t),
      sm: _lerp(sm, other.sm, t),
      md: _lerp(md, other.md, t),
      lg: _lerp(lg, other.lg, t),
      xl: _lerp(xl, other.xl, t),
      xxl: _lerp(xxl, other.xxl, t),
      gutter: _lerp(gutter, other.gutter, t),
      card: _lerp(card, other.card, t),
      cardLg: _lerp(cardLg, other.cardLg, t),
      section: _lerp(section, other.section, t),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
