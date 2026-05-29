import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env.dart';
import '../../../core/push/fcm_service.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../auth/providers/session_provider.dart';

/// Singleton [FcmService] injected once, overridable in tests.
final Provider<FcmService> fcmServiceProvider = Provider<FcmService>((
  Ref<FcmService> ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return FcmService(supabase: client);
});

/// Watches the session and runs the FCM bootstrap pipeline whenever a
/// user becomes authenticated. Tears down via the [FcmService] own
/// `dispose` when the provider rebuilds (e.g. on sign-out).
///
/// Returns void; consumers `await ref.read(fcmLifecycleProvider.future)`
/// only to surface the work in the current frame (e.g. from `_PushBootstrap`).
final FutureProvider<void> fcmLifecycleProvider =
    FutureProvider<void>((ref) async {
  if (!Env.firebaseEnabled) return;

  final session = ref.watch(currentSessionProvider);
  final FcmService service = ref.watch(fcmServiceProvider);

  ref.onDispose(() => service.dispose());

  if (session == null) {
    // Session was cleared by any path (explicit signOut, server-side
    // revoke, refresh-token expiry). AuthService.signOut already runs
    // its own pre-signOut unregister with the live JWT; this branch
    // covers the OTHER paths where no signOut() ran — without it the
    // device_tokens row stays live on the server and the device keeps
    // receiving pushes addressed to the prior user. unregisterToken is
    // a best-effort RPC + LastTokenStorage clear; FcmService swallows
    // its own errors so a failure here can't crash the boot path.
    await service.unregisterToken();
    return;
  }

  final bool ready = await service.initialize();
  if (!ready) return;
  await service.registerToken();
  service.subscribeTokenRefresh();
});
