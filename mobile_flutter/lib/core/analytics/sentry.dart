import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// True once [initSentry] has successfully initialised SDK.
///
/// [captureException] short-circuits when this is false, keeping the
/// helper safe to call from any code path regardless of consent.
bool _initialized = false;

/// Runtime opt-out flag — flipped by the telemetry toggle in settings so
/// that flipping crash-reports off mid-session immediately stops new
/// [captureException] calls from shipping events, without requiring an
/// app restart. The SDK stays initialised; we just suppress emission.
bool _runtimeDisabled = false;

/// Whether the Sentry SDK has been initialised. Public so the [Telemetry]
/// facade and other callers can short-circuit before hitting the SDK.
bool get isSentryInitialized => _initialized;

/// Whether the user opted out at runtime. Public for tests.
bool get isSentryRuntimeDisabled => _runtimeDisabled;

/// Applies a runtime opt-out / opt-in flip. Settings toggles call this so
/// the change takes effect immediately rather than on next cold boot.
void setSentryRuntimeEnabled(bool enabled) {
  _runtimeDisabled = !enabled;
}

/// 0.1 in production (spec §11.1), 1.0 everywhere else for full traces.
double sampleRateForEnv(String env) => env == 'prod' ? 0.1 : 1.0;

/// Initialises Sentry IF [enabled] is true AND [dsn] is non-empty,
/// then invokes [appRunner]. When disabled, [appRunner] runs directly.
///
/// This signature matches `SentryFlutter.init`'s `appRunner` slot so the
/// caller can wrap `runApp(...)` exactly once. Calling [initSentry] more
/// than once is a no-op after the first successful init.
Future<void> initSentry({
  required String dsn,
  required String environment,
  required bool enabled,
  required FutureOr<void> Function() appRunner,
}) async {
  if (!enabled || dsn.isEmpty) {
    await appRunner();
    return;
  }
  if (_initialized) {
    await appRunner();
    return;
  }
  await SentryFlutter.init(
    (SentryFlutterOptions options) {
      options
        ..dsn = dsn
        ..environment = environment
        ..tracesSampleRate = sampleRateForEnv(environment)
        ..attachScreenshot = false
        // `attachViewHierarchy` is experimental and ships disabled by
        // default — we leave it off explicitly (no setter call needed) to
        // avoid the experimental-member-use warning.
        ..debug = kDebugMode;
    },
    appRunner: () async {
      _initialized = true;
      await appRunner();
    },
  );
}

/// Records an error to Sentry. No-op when SDK is not initialised
/// (e.g. user opted out of crash reports at boot) or when the user has
/// flipped the runtime opt-out via settings.
void captureException(Object error, StackTrace stack) {
  if (!_initialized || _runtimeDisabled) return;
  unawaited(Sentry.captureException(error, stackTrace: stack));
}

@visibleForTesting
void debugResetForTests() {
  _initialized = false;
  _runtimeDisabled = false;
}
