import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'sentry.dart' as sentry;

/// Lightweight telemetry facade used by Phase 12 push handlers and any
/// other non-feature code that wants to record a breadcrumb or surface an
/// error without depending directly on the Sentry SDK.
///
/// All methods are safe to call regardless of consent / init state:
///
/// - When Sentry is not initialised (user opted out OR `SENTRY_DSN` empty),
///   every method is a no-op (with a debug-mode `debugPrint` so devs can
///   still trace the call locally).
/// - When Sentry is initialised, [recordBreadcrumb] forwards to
///   `Sentry.addBreadcrumb` and [recordError] forwards to
///   [sentry.captureException].
abstract final class Telemetry {
  /// Records a Sentry breadcrumb. No-op when Sentry is not initialised.
  static void recordBreadcrumb({
    required String category,
    required String message,
  }) {
    if (!sentry.isSentryInitialized) {
      if (kDebugMode) {
        debugPrint('telemetry.breadcrumb [$category] $message');
      }
      return;
    }
    Sentry.addBreadcrumb(
      Breadcrumb(category: category, message: message),
    );
  }

  /// Surface an error to the telemetry pipeline. Routes to
  /// [sentry.captureException], which itself is a no-op when Sentry is
  /// not initialised.
  static void recordError(Object error, StackTrace stack) {
    if (kDebugMode && !sentry.isSentryInitialized) {
      debugPrint('telemetry.recordError: $error\n$stack');
    }
    sentry.captureException(error, stack);
  }
}
