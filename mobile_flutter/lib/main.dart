import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/analytics/firebase_telemetry.dart';
import 'core/analytics/sentry.dart' as telemetry;
import 'core/analytics/sentry_error_boundary.dart';
import 'core/env.dart';
import 'core/i18n/locale_notifier.dart';
import 'core/push/firebase_init.dart';
import 'core/routing/app_router.dart';
import 'core/supabase/supabase_client.dart';
import 'features/auth/providers/auth_lifecycle.dart';
import 'features/auth/providers/auth_service_provider.dart';
import 'features/auth/providers/session_provider.dart';
import 'features/settings/settings_providers.dart';

/// Top-level FCM background message handler.
///
/// FCM v18+ requires this be a top-level `@pragma('vm:entry-point')`
/// function so the Dart isolate can be re-entered from the platform's
/// background message dispatcher.
///
/// We don't render anything here - the system notification is built by the
/// FCM SDK from the `notification` payload server-side via `send-push`.
/// Initialising Firebase ensures plugin-side state (e.g. analytics) is
/// available; everything else is a no-op.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await ensureFirebaseInitialized();
  // See spec section 10.4: data-only background messages are surfaced
  // server-side via `send-push`. No client-side rendering needed here.
}

/// Application bootstrap.
///
/// Order matters — spec §11 telemetry boot sequence (Phase 14):
///
/// 1. Initialise the Flutter binding so plugins can be registered.
/// 2. Validate production invariants (throws when prod placeholders linger).
/// 3. Build the [ProviderContainer] (single instance shared with [ConnectApp]).
/// 4. **Telemetry gate** — `await container.read(telemetryReadyProvider
///    .future)` so the persisted consent state is loaded BEFORE any
///    telemetry sub-system is wired. We snapshot the prefs right after.
/// 5. Boot Supabase (always, regardless of telemetry).
/// 6. If `Env.firebaseEnabled`: init `firebase_core` then wire Analytics +
///    Crashlytics autocollection from the snapshot prefs.
/// 7. Register the FCM background handler (only after Firebase is initialised).
/// 8. Install AuthLifecycle, drain cold-start deep link, subscribe to runtime
///    deep links (these all need Supabase + the container).
/// 9. If `prefs.crashReportsEnabled` AND `Env.sentryDsn` is non-empty:
///    `SentryFlutter.init` wraps `runApp`. Otherwise `runApp` is invoked
///    directly. Either way the entire app is wrapped in a
///    `SentryErrorBoundary` for build-phase capture.
Future<void> main() async {
  // 1. Flutter binding (required before any plugin access).
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Production invariants (throws StateError in prod if placeholders remain).
  Env.requireProdInvariants();

  // 3. Provider container — single instance shared with ConnectApp.
  final ProviderContainer container = ProviderContainer();

  // 4. Gate on telemetry rehydration. After this completes, prefs are known
  //    and we can safely decide whether to init Sentry / Firebase telemetry.
  await container.read(telemetryReadyProvider.future);
  final TelemetryPrefs prefs = container.read(telemetryProvider).requireValue;

  // Subscribe synchronously to session updates - wins the race vs
  // cold-start deep links.
  // ignore: deprecated_member_use, unused_local_variable
  final Stream<dynamic> _ = container.read(sessionProvider.stream);

  // 5. Boot Supabase. After this completes the supabase singleton is usable
  //    and `currentSession` is restored from secure storage.
  await container.read(supabaseInitProvider.future);

  // 6. Firebase init (gated by Env flag) + telemetry collection toggles.
  if (Env.firebaseEnabled) {
    try {
      await ensureFirebaseInitialized();
      await initFirebaseTelemetry(
        firebaseEnabled: true,
        analyticsEnabled: prefs.analyticsEnabled,
        crashReportsEnabled: prefs.crashReportsEnabled,
      );
      // 7. FCM background handler must be registered after Firebase boots.
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    } catch (_) {
      // Best-effort - never block app boot on a Firebase init failure.
    }
  }

  // Restore persisted locale BEFORE we read the router so the first frame
  // renders in the user's saved language. Falls back to 'en' when nothing
  // has been persisted yet (fresh install).
  final Locale savedLocale =
      await container.read(languageServiceProvider).load();
  container.read(localeProvider.notifier).state = savedLocale;

  // Install the lifecycle observer (toggles auth auto-refresh on
  // resume/pause). Reading the provider materialises the AuthLifecycle.
  container.read(authLifecycleProvider);

  final AppLinks appLinks = AppLinks();

  // Cold-start deep link (Android: from intent, iOS: from launchOptions).
  try {
    final Uri? initial = await appLinks.getInitialLink();
    if (initial != null) {
      await _dispatchUri(container, initial);
    }
  } catch (_) {
    // Some platforms (web in this binding) may not implement initial-link.
  }

  // Runtime deep links - dispatch by path.
  appLinks.uriLinkStream.listen((Uri uri) async {
    await _dispatchUri(container, uri);
  });

  // 8/9. Sentry init wraps runApp. When disabled, runApp runs directly.
  await telemetry.initSentry(
    dsn: Env.sentryDsn,
    environment: Env.sentryEnv,
    enabled: prefs.crashReportsEnabled,
    appRunner: () => runApp(
      UncontrolledProviderScope(
        container: container,
        child: const SentryErrorBoundary(
          child: ConnectApp(),
        ),
      ),
    ),
  );
}

/// Routes an incoming deep-link [uri] to either the auth callback handler
/// or go_router based on the path.
///
/// `/auth` -> AuthService.createSessionFromUrl (PKCE / implicit token exchange)
/// other  -> router.go(uri.path) for universal links (e.g. /p/handle)
///           and `connect-mobile://` custom-scheme variants.
Future<void> _dispatchUri(ProviderContainer container, Uri uri) async {
  if (uri.path == '/auth') {
    try {
      await container.read(authServiceProvider).createSessionFromUrl(uri);
    } catch (_) {
      // Surface via AuthCallbackScreen if the router lands there.
    }
    return;
  }

  // Universal link (https://APP_LINKS_HOST/...) or custom scheme
  // (connect-mobile://...). Only dispatch when the host / scheme matches
  // our configured domain to avoid acting on unrelated deep links.
  final bool matchesUniversal = uri.scheme == 'https' &&
      (uri.host == Env.appLinksHost || uri.host == 'www.${Env.appLinksHost}');
  final bool matchesCustomScheme = uri.scheme == Env.appScheme;
  if (!matchesUniversal && !matchesCustomScheme) return;

  final String path = uri.path.isEmpty ? '/home' : uri.path;
  final String query = uri.query.isEmpty ? '' : '?${uri.query}';
  try {
    container.read(appRouterProvider).go('$path$query');
  } catch (_) {
    // Best-effort - bad routes fall back via go_router's notFound handler.
  }
}
