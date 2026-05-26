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

  if (session == null) return;

  final bool ready = await service.initialize();
  if (!ready) return;
  await service.registerToken();
  service.subscribeTokenRefresh();
});
