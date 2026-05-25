import 'dart:io';

import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/media/data/voice_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('start + stop returns mime audio/m4a and a non-negative duration', () async {
    final clockValues = <DateTime>[
      DateTime.utc(2026, 5, 25, 10, 0, 0),
      DateTime.utc(2026, 5, 25, 10, 0, 0, 500),
    ];
    var i = 0;
    final rec = VoiceRecorder.test(
      backend: FakeVoiceRecorderBackend(),
      tempDirProvider: () async => Directory.systemTemp,
      clock: () => clockValues[i < clockValues.length ? i++ : clockValues.length - 1],
    );
    await rec.start();
    final result = await rec.stop();
    expect(result.mime, 'audio/m4a');
    expect(result.durationMs, greaterThanOrEqualTo(0));
    rec.dispose();
  });

  test('start throws ValidationException when permission denied', () async {
    final rec = VoiceRecorder.test(
      backend: FakeVoiceRecorderBackend(permission: false),
      tempDirProvider: () async => Directory.systemTemp,
    );
    await expectLater(rec.start(), throwsA(isA<ValidationException>()));
    rec.dispose();
  });

  test('cancel marks backend cancelled', () async {
    final backend = FakeVoiceRecorderBackend();
    final rec = VoiceRecorder.test(
      backend: backend,
      tempDirProvider: () async => Directory.systemTemp,
    );
    await rec.start();
    await rec.cancel();
    expect(backend.cancelled, isTrue);
    rec.dispose();
  });
}
