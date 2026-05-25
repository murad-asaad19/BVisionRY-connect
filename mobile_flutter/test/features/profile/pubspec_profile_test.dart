// Verifies Phase 4 dependency wiring: share_plus + url_launcher are declared
// in pubspec.yaml so the Profile feature can launch the share sheet and open
// GitHub OAuth in the system browser. url_launcher was added in Phase 2; we
// guard both here so a future regression that drops either dep is caught at
// test time.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pubspec declares Phase 4 deps (share_plus, url_launcher)', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('share_plus:'));
    expect(pubspec, contains('url_launcher:'));
  });
}
