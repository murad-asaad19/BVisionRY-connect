import 'package:flutter/foundation.dart';

/// Telemetry surface for the app — wired in Phase 14.
///
/// Provides no-op stubs so Phase 1+2+3 code can call into the API without
/// pulling in Sentry / Firebase wiring. Each method becomes the real
/// integration point in `flutter-rebuild-14-telemetry.md`:
///
/// - [initSentry]: install `SentryFlutter.init` (skipped in debug builds).
/// - [initFirebase]: install Firebase + Crashlytics + Analytics; gated by
///   `Env.firebaseEnabled` so dev rigs without a `google-services.json`
///   keep booting.
/// - [recordError]: forward to `Sentry.captureException` (and optionally
///   `FirebaseCrashlytics.recordError`).
abstract final class Telemetry {
  /// Initialise Sentry. No-op in debug builds and in Phase 1 — wired in
  /// Phase 14.
  static Future<void> initSentry() async {
    if (kDebugMode) return;
    // Implemented in Phase 14.
  }

  /// Initialise Firebase. No-op until Phase 14, where the call is gated
  /// by `Env.firebaseEnabled`.
  static Future<void> initFirebase() async {
    // Implemented in Phase 14 (gated by Env.firebaseEnabled).
  }

  /// Surface an error to the telemetry pipeline. Prints to stderr in
  /// debug builds so the developer can see it; the production
  /// implementation routes to Sentry + Crashlytics.
  static void recordError(Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('telemetry.recordError: $error\n$stack');
    }
  }

  /// Record a breadcrumb for Sentry / Crashlytics. No-op until Phase 14;
  /// Phase 12 calls this from push foreground + tap handlers so Phase 14
  /// has nothing extra to wire.
  static void recordBreadcrumb({
    required String category,
    required String message,
  }) {
    if (kDebugMode) {
      debugPrint('telemetry.breadcrumb [$category] $message');
    }
  }
}
