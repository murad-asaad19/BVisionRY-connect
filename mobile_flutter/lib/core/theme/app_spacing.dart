import 'package:flutter/material.dart';

@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    required this.gutter,
    required this.card,
    required this.cardLg,
    required this.section,
  });

  static const AppSpacing standard = AppSpacing(
    gutter: 16,
    card: 12,
    cardLg: 16,
    section: 24,
  );

  final double gutter;
  final double card;
  final double cardLg;
  final double section;

  @override
  AppSpacing copyWith({
    double? gutter,
    double? card,
    double? cardLg,
    double? section,
  }) {
    return AppSpacing(
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
      gutter: _lerp(gutter, other.gutter, t),
      card: _lerp(card, other.card, t),
      cardLg: _lerp(cardLg, other.cardLg, t),
      section: _lerp(section, other.section, t),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
