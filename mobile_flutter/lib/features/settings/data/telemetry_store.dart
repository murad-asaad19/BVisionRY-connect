import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Immutable snapshot of telemetry consent.
///
/// Defaults to opt-OUT (both `false`) per spec §11.3 (GDPR).
@immutable
class TelemetryPrefs {
  const TelemetryPrefs({
    required this.analyticsEnabled,
    required this.crashReportsEnabled,
  });

  static const TelemetryPrefs disabled = TelemetryPrefs(
    analyticsEnabled: false,
    crashReportsEnabled: false,
  );

  final bool analyticsEnabled;
  final bool crashReportsEnabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TelemetryPrefs &&
          other.analyticsEnabled == analyticsEnabled &&
          other.crashReportsEnabled == crashReportsEnabled;

  @override
  int get hashCode => Object.hash(analyticsEnabled, crashReportsEnabled);

  TelemetryPrefs copyWith({bool? analyticsEnabled, bool? crashReportsEnabled}) =>
      TelemetryPrefs(
        analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
        crashReportsEnabled: crashReportsEnabled ?? this.crashReportsEnabled,
      );
}

/// SharedPreferences-backed telemetry consent store.
///
/// Spec §11.3 — defaults to both `false` (opt-OUT). On sign-out:
/// `signOutReset()` forces both back to `false` so the next user on the
/// device starts opted-out.
///
/// Boot sequence: callers MUST `await rehydrate()` before reading [snapshot].
/// Telemetry init (Sentry / Firebase) MUST be gated on rehydration completing,
/// otherwise we'd default-init Sentry while prefs are still unknown.
class TelemetryStore {
  TelemetryStore();

  static const String keyAnalytics = 'telemetry.analyticsEnabled';
  static const String keyCrashReports = 'telemetry.crashReportsEnabled';

  TelemetryPrefs? _snapshot;

  /// Returns the current consent snapshot.
  ///
  /// Throws [StateError] if [rehydrate] has not been awaited yet.
  TelemetryPrefs get snapshot {
    final TelemetryPrefs? s = _snapshot;
    if (s == null) {
      throw StateError(
        'TelemetryStore.snapshot accessed before rehydrate() completed',
      );
    }
    return s;
  }

  /// Loads persisted consent from SharedPreferences.
  ///
  /// Safe to call multiple times — subsequent calls re-read from disk.
  Future<void> rehydrate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _snapshot = TelemetryPrefs(
      analyticsEnabled: prefs.getBool(keyAnalytics) ?? false,
      crashReportsEnabled: prefs.getBool(keyCrashReports) ?? false,
    );
  }

  Future<void> setAnalyticsEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyAnalytics, value);
    _snapshot = snapshot.copyWith(analyticsEnabled: value);
  }

  Future<void> setCrashReportsEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyCrashReports, value);
    _snapshot = snapshot.copyWith(crashReportsEnabled: value);
  }

  /// GDPR — sign-out forces BOTH flags to `false`.
  ///
  /// Called from `AuthService.signOut`. Bypasses [snapshot]'s state check so
  /// it is safe to call before [rehydrate] (e.g. if sign-out runs during a
  /// crash recovery path).
  Future<void> signOutReset() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyAnalytics, false);
    await prefs.setBool(keyCrashReports, false);
    _snapshot = TelemetryPrefs.disabled;
  }
}
