import 'package:connect_mobile/core/accessibility/contrast_audit.dart';
import 'package:connect_mobile/core/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const c = AppColors.light;

  test('body text on white passes WCAG AA (>= 4.5)', () {
    expect(contrastRatio(c.body, c.white), greaterThanOrEqualTo(4.5));
  });

  test('body text on surface passes AA', () {
    expect(contrastRatio(c.body, c.surface), greaterThanOrEqualTo(4.5));
  });

  test('gold on navy passes AA for large text (>= 3.0)', () {
    expect(contrastRatio(c.gold, c.navy), greaterThanOrEqualTo(3.0));
  });

  test('muted text on white reaches the captions threshold (>= 2.5)', () {
    // muted (#94A3B8) is intentionally used only for non-essential captions.
    expect(contrastRatio(c.muted, c.white), greaterThanOrEqualTo(2.5));
  });

  test('danger text on dangerBg passes AA', () {
    expect(contrastRatio(c.danger, c.dangerBg), greaterThanOrEqualTo(4.5));
  });
}
