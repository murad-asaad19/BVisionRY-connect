import 'package:connect_mobile/features/settings/data/telemetry_store.dart';
import 'package:connect_mobile/features/settings/providers/telemetry_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('telemetryReadyProvider gates telemetryProvider data state', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'telemetry.analyticsEnabled': true,
      'telemetry.crashReportsEnabled': true,
    });
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    // Before await: provider is in loading state.
    final AsyncValue<TelemetryPrefs> initial =
        container.read(telemetryProvider);
    expect(initial.isLoading, isTrue);

    // After awaiting the ready future: data is populated.
    await container.read(telemetryReadyProvider.future);
    final AsyncValue<TelemetryPrefs> settled =
        container.read(telemetryProvider);
    expect(settled.isLoading, isFalse);
    expect(
      settled.requireValue,
      const TelemetryPrefs(
        analyticsEnabled: true,
        crashReportsEnabled: true,
      ),
    );
  });

  test('signOutReset emits new state through provider listener', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'telemetry.analyticsEnabled': true,
      'telemetry.crashReportsEnabled': true,
    });
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(telemetryReadyProvider.future);

    final List<TelemetryPrefs> snapshots = <TelemetryPrefs>[];
    container.listen<AsyncValue<TelemetryPrefs>>(
      telemetryProvider,
      (AsyncValue<TelemetryPrefs>? _, AsyncValue<TelemetryPrefs> next) {
        final TelemetryPrefs? v = next.valueOrNull;
        if (v != null) snapshots.add(v);
      },
      fireImmediately: true,
    );

    await container.read(telemetryProvider.notifier).signOutReset();

    expect(snapshots.last, TelemetryPrefs.disabled);
  });
}
