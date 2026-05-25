import 'package:connect_mobile/core/theme/app_radii.dart';
import 'package:connect_mobile/core/theme/app_spacing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppSpacing scale matches spec §8.3', () {
    const s = AppSpacing.standard;
    expect(s.gutter, 16);
    expect(s.card, 12);
    expect(s.cardLg, 16);
    expect(s.section, 24);
  });

  test('AppRadii matches gallery values', () {
    const r = AppRadii.standard;
    expect(r.card, 14);
    expect(r.button, 10);
    expect(r.input, 10);
    expect(r.modalTop, 24);
    expect(r.pill, 999);
  });
}
