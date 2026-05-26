import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('verify_rpc_coverage.dart succeeds (every required RPC has a caller)',
      () async {
    // Run via the platform-appropriate dart binary; `dart.bat` on Windows.
    final exe = Platform.isWindows ? 'dart.bat' : 'dart';
    final result = await Process.run(
      exe,
      ['run', 'tool/verify_rpc_coverage.dart'],
      runInShell: true,
    );
    expect(
      result.exitCode,
      equals(0),
      reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
    );
  });
}
