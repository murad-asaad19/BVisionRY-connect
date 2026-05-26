import 'package:connect_mobile/features/settings/data/telemetry_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TelemetryStore', () {
    test('defaults both flags to false on cold start (opt-OUT)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final TelemetryStore store = TelemetryStore();
      await store.rehydrate();
      expect(store.snapshot.analyticsEnabled, isFalse);
      expect(store.snapshot.crashReportsEnabled, isFalse);
    });

    test('rehydrates persisted values across instances', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'telemetry.analyticsEnabled': true,
        'telemetry.crashReportsEnabled': true,
      });
      final TelemetryStore store = TelemetryStore();
      await store.rehydrate();
      expect(store.snapshot.analyticsEnabled, isTrue);
      expect(store.snapshot.crashReportsEnabled, isTrue);
    });

    test('setAnalyticsEnabled persists and updates snapshot', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final TelemetryStore store = TelemetryStore();
      await store.rehydrate();
      await store.setAnalyticsEnabled(true);
      expect(store.snapshot.analyticsEnabled, isTrue);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('telemetry.analyticsEnabled'), isTrue);
    });

    test('setCrashReportsEnabled persists and updates snapshot', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final TelemetryStore store = TelemetryStore();
      await store.rehydrate();
      await store.setCrashReportsEnabled(true);
      expect(store.snapshot.crashReportsEnabled, isTrue);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('telemetry.crashReportsEnabled'), isTrue);
    });

    test('signOutReset forces BOTH flags to false and persists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'telemetry.analyticsEnabled': true,
        'telemetry.crashReportsEnabled': true,
      });
      final TelemetryStore store = TelemetryStore();
      await store.rehydrate();
      expect(store.snapshot.analyticsEnabled, isTrue);

      await store.signOutReset();

      expect(store.snapshot.analyticsEnabled, isFalse);
      expect(store.snapshot.crashReportsEnabled, isFalse);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('telemetry.analyticsEnabled'), isFalse);
      expect(prefs.getBool('telemetry.crashReportsEnabled'), isFalse);
    });

    test('snapshot is immutable — equality by value', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final TelemetryStore store = TelemetryStore();
      await store.rehydrate();
      final TelemetryPrefs a = store.snapshot;
      final TelemetryPrefs b = store.snapshot;
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('throws StateError if accessed before rehydrate', () {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final TelemetryStore store = TelemetryStore();
      expect(() => store.snapshot, throwsStateError);
    });
  });
}
