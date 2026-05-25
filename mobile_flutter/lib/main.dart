import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/env.dart';
import 'core/supabase/supabase_client.dart';
import 'features/auth/providers/auth_lifecycle.dart';
import 'features/auth/providers/auth_service_provider.dart';
import 'features/auth/providers/session_provider.dart';

/// Application bootstrap.
///
/// Order matters (spec §5.2):
///
/// 1. Initialise the Flutter binding so plugins can be registered.
/// 2. Build a [ProviderContainer] and subscribe to [sessionProvider]
///    **synchronously** — this wins the race against any cold-start deep
///    link, so the auth listener is installed before Supabase's
///    `initialSession` event fires.
/// 3. Await Supabase boot.
/// 4. Install the [AuthLifecycle] observer for auto-refresh start/stop.
/// 5. Drain the cold-start app-link (if any) — only `/auth` URLs are
///    forwarded to `createSessionFromUrl`; public profile deep-links like
///    `/p/<handle>` must NOT trigger an auth exchange.
/// 6. Register the runtime deep-link listener (same `/auth` filter).
/// 7. Run the app with the prepared container.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.requireProdInvariants();

  final ProviderContainer container = ProviderContainer();

  // Subscribe synchronously — wins the race vs cold-start deep links.
  // `sessionProvider` is a StreamProvider; touching `.stream` attaches the
  // upstream listener immediately.
  // ignore: unused_local_variable
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
    if (initial != null && initial.path == '/auth') {
      try {
        await container.read(authServiceProvider).createSessionFromUrl(
              initial,
            );
      } catch (_) {
        // Surface via AuthCallbackScreen if the router lands there;
        // otherwise crashlytics picks this up in Phase 14.
      }
    }
  } catch (_) {
    // Some platforms (web in this binding) may not implement initial-link.
  }

  // Runtime deep links — filter strictly to /auth.
  appLinks.uriLinkStream.listen((Uri uri) async {
    if (uri.path != '/auth') return;
    try {
      await container.read(authServiceProvider).createSessionFromUrl(uri);
    } catch (_) {
      // best-effort — surfaced by AuthCallbackScreen on next visit.
    }
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ConnectApp(),
    ),
  );
}
