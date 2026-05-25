import 'package:connect_mobile/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppTypography exposes Dosis display + Inter body scale per spec §8.2', () {
    final t = AppTypography.dosisInter();
    expect(t.displayXl.fontSize, 28);
    expect(t.displayLg.fontSize, 20);
    expect(t.displayMd.fontSize, 16);
    expect(t.displaySm.fontSize, 13);
    expect(t.displayXs.fontSize, 11);
    expect(t.bodyLg.fontSize, 14);
    expect(t.bodyMd.fontSize, 12);
    expect(t.bodySm.fontSize, 11);
    expect(t.bodyXs.fontSize, 10);
    expect(t.displayMd.fontWeight, FontWeight.w700);
    expect(t.bodyMd.fontWeight, FontWeight.w400);
  });
}
