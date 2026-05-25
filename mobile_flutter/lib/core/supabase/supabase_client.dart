import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../env.dart';
import 'session_storage.dart';

/// Initialises the Supabase singleton with our PKCE auth flow and the
/// secure-storage session backend. Watch this provider's [Future] from
/// `main.dart` before mounting `ConnectApp` so the rest of the app can
/// read [supabaseClientProvider] synchronously.
final FutureProvider<void> supabaseInitProvider =
    FutureProvider<void>((Ref<void> ref) async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      localStorage: SecureSessionStorage(),
    ),
    realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 10),
  );
});

/// Synchronous accessor for the Supabase client. Must be reached only after
/// `await ref.read(supabaseInitProvider.future)` completes (typically in
/// `main()` before `runApp`).
final Provider<SupabaseClient> supabaseClientProvider =
    Provider<SupabaseClient>((Ref<SupabaseClient> ref) {
  ref.watch(supabaseInitProvider);
  return Supabase.instance.client;
});
