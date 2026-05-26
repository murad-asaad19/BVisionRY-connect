import 'package:connect_mobile/features/settings/data/telemetry_store.dart';
import 'package:connect_mobile/features/settings/providers/telemetry_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('telemetryProvider', () {
    test('defaults to disabled when no prefs are stored', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final TelemetryPrefs prefs =
          await container.read(telemetryProvider.future);
      expect(prefs.analyticsEnabled, isFalse);
      expect(prefs.crashReportsEnabled, isFalse);
    });

    test('rehydrates persisted values', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'telemetry.analyticsEnabled': true,
        'telemetry.crashReportsEnabled': true,
      });
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final TelemetryPrefs prefs =
          await container.read(telemetryProvider.future);
      expect(prefs.analyticsEnabled, isTrue);
      expect(prefs.crashReportsEnabled, isTrue);
    });

    test('setAnalyticsEnabled updates state and persists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(telemetryProvider.future);
      await container
          .read(telemetryProvider.notifier)
          .setAnalyticsEnabled(true);

      final TelemetryPrefs? updated =
          container.read(telemetryProvider).valueOrNull;
      expect(updated?.analyticsEnabled, isTrue);
      final SharedPreferences sp = await SharedPreferences.getInstance();
      expect(sp.getBool('telemetry.analyticsEnabled'), isTrue);
    });

    test('setCrashReportsEnabled updates state and persists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(telemetryProvider.future);
      await container
          .read(telemetryProvider.notifier)
          .setCrashReportsEnabled(true);

      final TelemetryPrefs? updated =
          container.read(telemetryProvider).valueOrNull;
      expect(updated?.crashReportsEnabled, isTrue);
    });

    test('signOutReset forces both flags to false', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'telemetry.analyticsEnabled': true,
        'telemetry.crashReportsEnabled': true,
      });
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(telemetryProvider.future);
      await container.read(telemetryProvider.notifier).signOutReset();

      final TelemetryPrefs? updated =
          container.read(telemetryProvider).valueOrNull;
      expect(updated?.analyticsEnabled, isFalse);
      expect(updated?.crashReportsEnabled, isFalse);
    });

    test('telemetryReadyProvider completes after rehydration', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(telemetryReadyProvider.future);
      // After ready, snapshot is safely readable.
      final TelemetryStore store = container.read(telemetryStoreProvider);
      expect(store.snapshot, equals(TelemetryPrefs.disabled));
    });

    test('telemetryStoreProvider exposes the same store as the notifier',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(telemetryReadyProvider.future);
      final TelemetryStore store = container.read(telemetryStoreProvider);
      await store.setAnalyticsEnabled(true);

      // Re-rehydrate notifier to pick up the underlying store changes.
      container.invalidate(telemetryProvider);
      final TelemetryPrefs prefs =
          await container.read(telemetryProvider.future);
      expect(prefs.analyticsEnabled, isTrue);
    });
  });
}
