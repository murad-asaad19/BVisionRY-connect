import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/env.dart';
import 'core/push/firebase_init.dart';
import 'core/routing/app_router.dart';
import 'core/supabase/supabase_client.dart';
import 'features/auth/providers/auth_lifecycle.dart';
import 'features/auth/providers/auth_service_provider.dart';
import 'features/auth/providers/session_provider.dart';

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
/// Order matters (spec section 5.2):
///
/// 1. Initialise the Flutter binding so plugins can be registered.
/// 2. Register the FCM background message handler when firebase is enabled.
/// 3. Build a [ProviderContainer] and subscribe to [sessionProvider]
///    synchronously - this wins the race against any cold-start deep
///    link, so the auth listener is installed before Supabase's
///    `initialSession` event fires.
/// 4. Await Supabase boot.
/// 5. Install the [AuthLifecycle] observer for auto-refresh start/stop.
/// 6. Drain the cold-start app-link (if any) - route to the appropriate
///    consumer based on path (/auth -> AuthService, anything else -> router).
/// 7. Register the runtime deep-link listener with the same dispatch logic.
/// 8. Run the app with the prepared container.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.requireProdInvariants();

  if (Env.firebaseEnabled) {
    try {
      await ensureFirebaseInitialized();
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    } catch (_) {
      // Best-effort - never block app boot on a Firebase init failure.
    }
  }

  final ProviderContainer container = ProviderContainer();

  // Subscribe synchronously - wins the race vs cold-start deep links.
  // ignore: deprecated_member_use, unused_local_variable
  final Stream<dynamic> _ = container.read(sessionProvider.stream);

  // Boot Supabase. After this completes the supabase singleton is usable
  // and `currentSession` is restored from secure storage.
  await container.read(supabaseInitProvider.future);

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

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ConnectApp(),
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
  final query = uri.query.isEmpty ? '' : '?${uri.query}';
  try {
    container.read(appRouterProvider).go('$path$query');
  } catch (_) {
    // Best-effort - bad routes fall back via go_router's notFound handler.
  }
}
