import 'package:connect_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppColors exposes every brand token with correct hex', () {
    const c = AppColors.light;
    expect(c.navy, const Color(0xFF0F3460));
    expect(c.navyLight, const Color(0xFF1A4A80));
    expect(c.navyDark, const Color(0xFF0A2340));
    expect(c.navyFill, const Color(0xFF0F3460));
    expect(c.onNavy, const Color(0xFFFFFFFF));
    expect(c.gold, const Color(0xFFFFC107));
    expect(c.goldLight, const Color(0xFFFFE187));
    expect(c.goldPale, const Color(0xFFFFF8E1));
    expect(c.surface, const Color(0xFFF8F8F8));
    expect(c.white, const Color(0xFFFFFFFF));
    expect(c.body, const Color(0xFF212529));
    // Darkened from #94A3B8 to clear WCAG AA contrast on white/slate troughs.
    expect(c.muted, const Color(0xFF5B6675));
    expect(c.border, const Color(0xFFE5E7EB));
    expect(c.slate100, const Color(0xFFF1F5F9));
    expect(c.slate300, const Color(0xFFCBD5E1));
    expect(c.successBg, const Color(0xFFDCFCE7));
    expect(c.success, const Color(0xFF15803D));
    expect(c.successBorder, const Color(0xFF4ADE80));
    expect(c.warningBg, const Color(0xFFFEF3C7));
    expect(c.warning, const Color(0xFFB45309));
    expect(c.warningBorder, const Color(0xFFFBBF24));
    expect(c.dangerBg, const Color(0xFFFEE2E2));
    expect(c.danger, const Color(0xFFB91C1C));
    expect(c.dangerBorder, const Color(0xFFEF4444));
    expect(c.infoBg, const Color(0xFFDBEAFE));
    expect(c.info, const Color(0xFF1D4ED8));
    expect(c.infoBorder, const Color(0xFF93C5FD));
  });
}
