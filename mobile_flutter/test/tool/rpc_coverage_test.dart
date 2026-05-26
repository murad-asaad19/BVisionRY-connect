import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('verify_rpc_coverage.dart succeeds (every required RPC has a caller)',
      () async {
    final result = await Process.run(
      'dart',
      ['run', 'tool/verify_rpc_coverage.dart'],
    );
    expect(
      result.exitCode,
      equals(0),
      reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
    );
  });
}
