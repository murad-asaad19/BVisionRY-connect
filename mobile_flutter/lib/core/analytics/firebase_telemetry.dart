import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Setter signature so tests can inject fakes instead of the native
/// singletons.
typedef SetCollectionEnabled = Future<void> Function(bool enabled);

Future<void> _defaultAnalytics(bool enabled) =>
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);

Future<void> _defaultCrashlytics(bool enabled) =>
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);

/// Wires user consent into the Firebase native plugins.
///
/// Spec §11.2 — short-circuits when [firebaseEnabled] is false (e.g.
/// Expo-Go equivalent / dev builds without google-services config). When
/// enabled, applies the user's two booleans to autocollection toggles.
/// The RN app has no custom `logEvent` calls — analytics relies on Firebase
/// autocollect.
Future<void> initFirebaseTelemetry({
  required bool firebaseEnabled,
  required bool analyticsEnabled,
  required bool crashReportsEnabled,
  @visibleForTesting SetCollectionEnabled? setAnalyticsCollection,
  @visibleForTesting SetCollectionEnabled? setCrashlyticsCollection,
}) async {
  if (!firebaseEnabled) return;

  final SetCollectionEnabled analytics =
      setAnalyticsCollection ?? _defaultAnalytics;
  final SetCollectionEnabled crashlytics =
      setCrashlyticsCollection ?? _defaultCrashlytics;

  await analytics(analyticsEnabled);
  await crashlytics(crashReportsEnabled);
}

/// Live toggle hook called by [TelemetryNotifier.setAnalyticsEnabled] so
/// flipping the switch in settings takes effect immediately. No-op when
/// Firebase isn't enabled in this build.
Future<void> applyAnalyticsCollectionLive(
  bool enabled, {
  required bool firebaseEnabled,
  @visibleForTesting SetCollectionEnabled? setAnalyticsCollection,
}) async {
  if (!firebaseEnabled) return;
  await (setAnalyticsCollection ?? _defaultAnalytics)(enabled);
}

/// Live toggle hook called by [TelemetryNotifier.setCrashReportsEnabled].
/// Toggles Firebase Crashlytics autocollection mid-session in addition to
/// the Sentry runtime opt-out in `core/analytics/sentry.dart`.
Future<void> applyCrashlyticsCollectionLive(
  bool enabled, {
  required bool firebaseEnabled,
  @visibleForTesting SetCollectionEnabled? setCrashlyticsCollection,
}) async {
  if (!firebaseEnabled) return;
  await (setCrashlyticsCollection ?? _defaultCrashlytics)(enabled);
}
