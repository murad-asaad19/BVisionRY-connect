// Phase 15 — coverage gate.
//
// Parses `coverage/lcov.info` (when present) and asserts line coverage
// is at or above the 70% threshold. Skips when the file isn't there so
// local devs running a subset of tests aren't penalised.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lcov.info line coverage >= 70%', () {
    final file = File('coverage/lcov.info');
    if (!file.existsSync()) {
      markTestSkipped('coverage/lcov.info not generated (run with --coverage)');
      return;
    }
    final lines = file.readAsLinesSync();
    var hit = 0;
    var total = 0;
    for (final line in lines) {
      if (line.startsWith('LH:')) hit += int.parse(line.substring(3));
      if (line.startsWith('LF:')) total += int.parse(line.substring(3));
    }
    final pct = total == 0 ? 0.0 : (hit / total) * 100;
    stdout.writeln(
      'Coverage: ${pct.toStringAsFixed(2)}% ($hit / $total lines hit)',
    );
    expect(pct, greaterThanOrEqualTo(70.0));
  });
}
