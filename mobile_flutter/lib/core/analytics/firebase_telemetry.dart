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
///
/// Pref changes take effect on next launch (per spec): we don't re-call
/// these setters on toggle changes — the toggle UI just writes to
/// `TelemetryStore`, and `main.dart` re-applies on next cold start.
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
