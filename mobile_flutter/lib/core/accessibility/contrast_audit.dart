import 'dart:math';

import 'package:flutter/painting.dart';

/// Phase 15 — WCAG 2.1 contrast-ratio helpers.
///
/// Implements the relative-luminance formula per WCAG 2.1 §1.4.3 so
/// theme tokens can be audited against AA / AAA thresholds in tests.
double _channel(int v) {
  final s = v / 255.0;
  return s <= 0.03928 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4).toDouble();
}

double luminance(Color c) =>
    0.2126 * _channel((c.r * 255).round()) +
    0.7152 * _channel((c.g * 255).round()) +
    0.0722 * _channel((c.b * 255).round());

double contrastRatio(Color a, Color b) {
  final la = luminance(a);
  final lb = luminance(b);
  final hi = max(la, lb);
  final lo = min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}
