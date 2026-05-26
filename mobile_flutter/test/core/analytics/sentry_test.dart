import 'package:connect_mobile/core/analytics/sentry.dart' as telemetry;
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(telemetry.debugResetForTests);

  group('initSentry', () {
    test('runs appRunner directly when enabled=false', () async {
      bool ran = false;
      await telemetry.initSentry(
        dsn: 'https://example@sentry.io/1',
        environment: 'dev',
        enabled: false,
        appRunner: () async => ran = true,
      );
      expect(ran, isTrue);
      expect(telemetry.isSentryInitialized, isFalse);
    });

    test('runs appRunner directly when dsn is empty', () async {
      bool ran = false;
      await telemetry.initSentry(
        dsn: '',
        environment: 'prod',
        enabled: true,
        appRunner: () async => ran = true,
      );
      expect(ran, isTrue);
      expect(telemetry.isSentryInitialized, isFalse);
    });

    test('captureException is a no-op when not initialized', () {
      // We never called initSentry with enabled=true, so this must not throw
      // and must not record anywhere observable.
      expect(
        () => telemetry.captureException(Exception('x'), StackTrace.current),
        returnsNormally,
      );
    });

    test('sampleRateForEnv returns 0.1 in prod, 1.0 elsewhere', () {
      expect(telemetry.sampleRateForEnv('prod'), 0.1);
      expect(telemetry.sampleRateForEnv('preview'), 1.0);
      expect(telemetry.sampleRateForEnv('dev'), 1.0);
    });
  });

  group('captureException gating', () {
    test('does nothing when not initialized', () {
      telemetry.debugResetForTests();
      expect(telemetry.isSentryInitialized, isFalse);
      // Should not throw or call anything.
      telemetry.captureException(Exception('x'), StackTrace.current);
    });
  });
}
