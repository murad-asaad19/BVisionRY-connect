import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/telemetry_store.dart';

/// Singleton telemetry store — shared by the [TelemetryNotifier] and any
/// non-Riverpod call sites (e.g. `AuthService.signOut` consumes the
/// notifier directly).
final Provider<TelemetryStore> telemetryStoreProvider =
    Provider<TelemetryStore>((Ref<TelemetryStore> ref) {
  return TelemetryStore();
});

/// Riverpod surface for telemetry consent.
///
/// `build()` rehydrates the store from SharedPreferences. UI listens to
/// this provider to render toggle state; callers mutate via the notifier.
class TelemetryNotifier extends AsyncNotifier<TelemetryPrefs> {
  late TelemetryStore _store;

  @override
  Future<TelemetryPrefs> build() async {
    _store = ref.watch(telemetryStoreProvider);
    await _store.rehydrate();
    return _store.snapshot;
  }

  Future<void> setAnalyticsEnabled(bool value) async {
    await _store.setAnalyticsEnabled(value);
    state = AsyncData<TelemetryPrefs>(_store.snapshot);
  }

  Future<void> setCrashReportsEnabled(bool value) async {
    await _store.setCrashReportsEnabled(value);
    state = AsyncData<TelemetryPrefs>(_store.snapshot);
  }

  /// Called from `AuthService.signOut`. Forces both flags to `false`.
  Future<void> signOutReset() async {
    await _store.signOutReset();
    state = AsyncData<TelemetryPrefs>(_store.snapshot);
  }
}

/// AsyncNotifierProvider exposing the user's telemetry consent. UI reads
/// the [AsyncValue] and renders accordingly — `loading` until rehydration
/// completes, `data` once the [TelemetryStore] has been read.
final AsyncNotifierProvider<TelemetryNotifier, TelemetryPrefs>
    telemetryProvider =
    AsyncNotifierProvider<TelemetryNotifier, TelemetryPrefs>(
  TelemetryNotifier.new,
);

/// Completes when `TelemetryStore.rehydrate()` resolves.
///
/// `main.dart` gates the entire boot sequence on this future so we never
/// initialize Sentry/Firebase with unknown consent state.
final FutureProvider<void> telemetryReadyProvider =
    FutureProvider<void>((Ref<void> ref) async {
  await ref.watch(telemetryProvider.future);
});
