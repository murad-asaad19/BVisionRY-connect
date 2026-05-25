import 'dart:async';

import 'package:connect_mobile/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // google_fonts triggers a fire-and-forget HTTP fetch on first use of each
  // family/variant. In offline test runs that future rejects and the runner
  // attributes it to whichever test was active when the microtask drained.
  // Build the typography table once inside a guarded zone so the network
  // failures don't bubble up as test failures — the TextStyle size/height/
  // weight values we assert are literal constants we pass in and do not
  // require the font file to have actually loaded.
  late AppTypography t;
  setUpAll(() {
    runZonedGuarded(
      () {
        t = AppTypography.dosisInter();
      },
      (Object error, StackTrace stack) {
        // Swallow google_fonts network errors in unit tests.
      },
    );
  });

  test('AppTypography exposes Dosis display + Inter body scale per spec §8.2', () {
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

  test('AppTypography line heights match spec ratios', () {
    expect((t.displayXl.height ?? 0) * t.displayXl.fontSize!, closeTo(34, 0.01));
    expect((t.displayLg.height ?? 0) * t.displayLg.fontSize!, closeTo(26, 0.01));
    expect((t.displayMd.height ?? 0) * t.displayMd.fontSize!, closeTo(22, 0.01));
    expect((t.displaySm.height ?? 0) * t.displaySm.fontSize!, closeTo(18, 0.01));
    expect((t.displayXs.height ?? 0) * t.displayXs.fontSize!, closeTo(14, 0.01));
    expect((t.bodyLg.height ?? 0) * t.bodyLg.fontSize!, closeTo(20, 0.01));
    expect((t.bodyMd.height ?? 0) * t.bodyMd.fontSize!, closeTo(18, 0.01));
    expect((t.bodySm.height ?? 0) * t.bodySm.fontSize!, closeTo(15, 0.01));
    expect((t.bodyXs.height ?? 0) * t.bodyXs.fontSize!, closeTo(13, 0.01));
  });

  test('AppTypography weights — display=700/600, body=400', () {
    expect(t.displayXl.fontWeight, FontWeight.w700);
    expect(t.displayLg.fontWeight, FontWeight.w700);
    expect(t.displayMd.fontWeight, FontWeight.w700);
    expect(t.displaySm.fontWeight, FontWeight.w700);
    expect(t.displayXs.fontWeight, FontWeight.w600);
    expect(t.bodyLg.fontWeight, FontWeight.w400);
    expect(t.bodyMd.fontWeight, FontWeight.w400);
    expect(t.bodySm.fontWeight, FontWeight.w400);
    expect(t.bodyXs.fontWeight, FontWeight.w400);
  });
}
