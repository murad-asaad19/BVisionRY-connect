import 'package:connect_mobile/core/analytics/firebase_telemetry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('initFirebaseTelemetry', () {
    test('short-circuits when firebaseEnabled=false', () async {
      bool analyticsCalled = false;
      bool crashlyticsCalled = false;

      await initFirebaseTelemetry(
        firebaseEnabled: false,
        analyticsEnabled: true,
        crashReportsEnabled: true,
        setAnalyticsCollection: (bool _) async {
          analyticsCalled = true;
        },
        setCrashlyticsCollection: (bool _) async {
          crashlyticsCalled = true;
        },
      );

      expect(analyticsCalled, isFalse);
      expect(crashlyticsCalled, isFalse);
    });

    test('applies analyticsEnabled=true when firebaseEnabled=true', () async {
      bool? analyticsArg;
      bool? crashArg;

      await initFirebaseTelemetry(
        firebaseEnabled: true,
        analyticsEnabled: true,
        crashReportsEnabled: false,
        setAnalyticsCollection: (bool v) async => analyticsArg = v,
        setCrashlyticsCollection: (bool v) async => crashArg = v,
      );

      expect(analyticsArg, isTrue);
      expect(crashArg, isFalse);
    });

    test('applies both disabled when user opted out', () async {
      bool? analyticsArg;
      bool? crashArg;

      await initFirebaseTelemetry(
        firebaseEnabled: true,
        analyticsEnabled: false,
        crashReportsEnabled: false,
        setAnalyticsCollection: (bool v) async => analyticsArg = v,
        setCrashlyticsCollection: (bool v) async => crashArg = v,
      );

      expect(analyticsArg, isFalse);
      expect(crashArg, isFalse);
    });

    test('applies mixed consent independently', () async {
      bool? analyticsArg;
      bool? crashArg;

      await initFirebaseTelemetry(
        firebaseEnabled: true,
        analyticsEnabled: false,
        crashReportsEnabled: true,
        setAnalyticsCollection: (bool v) async => analyticsArg = v,
        setCrashlyticsCollection: (bool v) async => crashArg = v,
      );

      expect(analyticsArg, isFalse);
      expect(crashArg, isTrue);
    });

    test(
        'integration: short-circuit on Env.firebaseEnabled=false does not '
        'touch native', () async {
      // If we accidentally hit the real Firebase singleton without
      // `Firebase.initializeApp()`, it would throw. We expect this to
      // complete normally.
      await expectLater(
        initFirebaseTelemetry(
          firebaseEnabled: false,
          analyticsEnabled: true,
          crashReportsEnabled: true,
        ),
        completes,
      );
    });
  });
}
