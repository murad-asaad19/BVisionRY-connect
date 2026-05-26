import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory two-bool telemetry preference state used by the Phase 13
/// Account screen. Phase 14 replaces this with a SharedPreferences-backed
/// persisted store and wires it into Sentry / Firebase Analytics /
/// Crashlytics init gates.
@immutable
class TelemetryState {
  const TelemetryState({
    this.analyticsEnabled = false,
    this.crashReportsEnabled = false,
  });

  /// Phase 14 routes this into `Telemetry.captureEvent` gating.
  final bool analyticsEnabled;

  /// Phase 14 routes this into `FirebaseCrashlytics.setCrashlyticsCollection
  /// Enabled`.
  final bool crashReportsEnabled;

  TelemetryState copyWith({bool? analyticsEnabled, bool? crashReportsEnabled}) {
    return TelemetryState(
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      crashReportsEnabled: crashReportsEnabled ?? this.crashReportsEnabled,
    );
  }
}

/// StateNotifier exposing two boolean toggles. Mutations log via
/// `debugPrint` so the dev console makes the boundary obvious until
/// Phase 14 wires the real telemetry collectors.
class TelemetryStore extends StateNotifier<TelemetryState> {
  TelemetryStore() : super(const TelemetryState());

  void setAnalyticsEnabled(bool value) {
    state = state.copyWith(analyticsEnabled: value);
    debugPrint('[telemetry stub] analyticsEnabled=$value '
        '(Phase 14 will persist + wire to Sentry/Analytics)');
  }

  void setCrashReportsEnabled(bool value) {
    state = state.copyWith(crashReportsEnabled: value);
    debugPrint('[telemetry stub] crashReportsEnabled=$value '
        '(Phase 14 will persist + wire to Crashlytics)');
  }
}

/// The single [TelemetryStore] instance the Account screen toggles read /
/// write through.
final StateNotifierProvider<TelemetryStore, TelemetryState>
    telemetryStoreProvider =
    StateNotifierProvider<TelemetryStore, TelemetryState>(
  (Ref<TelemetryState> ref) => TelemetryStore(),
);
