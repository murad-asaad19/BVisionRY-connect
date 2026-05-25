import 'package:flutter/material.dart';

@immutable
class AppRadii extends ThemeExtension<AppRadii> {
  const AppRadii({
    required this.card,
    required this.button,
    required this.input,
    required this.modalTop,
    required this.pill,
  });

  static const AppRadii standard = AppRadii(
    card: 14,
    button: 10,
    input: 10,
    modalTop: 24,
    pill: 999,
  );

  final double card;
  final double button;
  final double input;
  final double modalTop;
  final double pill;

  @override
  AppRadii copyWith({
    double? card,
    double? button,
    double? input,
    double? modalTop,
    double? pill,
  }) {
    return AppRadii(
      card: card ?? this.card,
      button: button ?? this.button,
      input: input ?? this.input,
      modalTop: modalTop ?? this.modalTop,
      pill: pill ?? this.pill,
    );
  }

  @override
  AppRadii lerp(ThemeExtension<AppRadii>? other, double t) {
    if (other is! AppRadii) return this;
    return AppRadii(
      card: _lerp(card, other.card, t),
      button: _lerp(button, other.button, t),
      input: _lerp(input, other.input, t),
      modalTop: _lerp(modalTop, other.modalTop, t),
      pill: _lerp(pill, other.pill, t),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
