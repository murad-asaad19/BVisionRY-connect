import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../push/data/fcm_token_store.dart';
import '../../settings/data/persisted_stores.dart';
import '../data/auth_service.dart';
import '../data/profile_repository.dart';
import '../data/social_auth_service.dart';

/// Production [AuthGateway] adapter — delegates every call straight to the
/// live `GoTrueClient` on the supplied Supabase client.
class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this._client);
  final SupabaseClient _client;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  Stream<AuthState> onAuthStateChange() => _client.auth.onAuthStateChange;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) => _client.auth.signInWithPassword(email: email, password: password);

  @override
  Future<void> signInWithOtp({
    required String email,
    required String emailRedirectTo,
  }) => _client.auth.signInWithOtp(
    email: email,
    emailRedirectTo: emailRedirectTo,
  );

  @override
  Future<bool> signInWithOAuth(
    OAuthProvider provider, {
    required String redirectTo,
  }) => _client.auth.signInWithOAuth(provider, redirectTo: redirectTo);

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String emailRedirectTo,
  }) => _client.auth.signUp(
    email: email,
    password: password,
    emailRedirectTo: emailRedirectTo,
  );

  @override
  Future<AuthResponse> setSession({
    required String accessToken,
    required String refreshToken,
  }) => _client.auth.setSession(refreshToken, accessToken: accessToken);

  @override
  Future<AuthSessionUrlResponse> exchangeCodeForSession(String code) =>
      _client.auth.exchangeCodeForSession(code);

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) =>
      _client.auth.signOut(scope: scope);

  @override
  Future<void> startAutoRefresh() async {
    _client.auth.startAutoRefresh();
  }

  @override
  Future<void> stopAutoRefresh() async {
    _client.auth.stopAutoRefresh();
  }
}

/// Production [FunctionsGateway] adapter — wraps `FunctionsClient.invoke`.
class SupabaseFunctionsGateway implements FunctionsGateway {
  SupabaseFunctionsGateway(this._client);
  final SupabaseClient _client;

  @override
  Future<FunctionResponse> invoke(String name, {Object? body}) =>
      _client.functions.invoke(name, body: body);
}

/// The single [AuthGateway] instance the auth feature depends on. Tests
/// override this with a `FakeAuthGateway`.
final Provider<AuthGateway> authGatewayProvider = Provider<AuthGateway>((
  Ref<AuthGateway> ref,
) {
  return SupabaseAuthGateway(ref.watch(supabaseClientProvider));
});

/// The single [FunctionsGateway] instance for edge-function invocations.
final Provider<FunctionsGateway> functionsGatewayProvider =
    Provider<FunctionsGateway>((Ref<FunctionsGateway> ref) {
      return SupabaseFunctionsGateway(ref.watch(supabaseClientProvider));
    });

/// Persists the most-recently-registered FCM token. Phase 12 wires the full
/// FCM lifecycle; the store is exposed here so [AuthService.signOut] can
/// clear and deregister it.
final Provider<FcmTokenStore> fcmTokenStoreProvider = Provider<FcmTokenStore>((
  Ref<FcmTokenStore> ref,
) {
  return FcmTokenStore();
});

/// Aggregated persisted-store handle whose `resetAllOnSignOut()` clears every
/// Zustand-equivalent local store. Placeholders for Phases 5/10/14.
final Provider<PersistedStores> persistedStoresProvider =
    Provider<PersistedStores>((Ref<PersistedStores> ref) {
      return PersistedStores();
    });

/// Best-effort FCM deregister callback wired through the Supabase RPC
/// `unregister_device_token`. Phase 12 will replace this with the full
/// Firebase Messaging integration; for Phase 2 we just need the hook so
/// [AuthService.signOut] honours its contract.
final Provider<Future<void> Function(String token)?> fcmDeregisterProvider =
    Provider<Future<void> Function(String token)?>((
      Ref<Future<void> Function(String token)?> ref,
    ) {
      final SupabaseClient client = ref.watch(supabaseClientProvider);
      return (String token) async {
        try {
          await client.rpc<dynamic>(
            'unregister_device_token',
            params: <String, dynamic>{'p_token': token},
          );
        } catch (_) {
          // best-effort — sign-out must still proceed even if RPC fails.
        }
      };
    });

/// The fully-wired [AuthService] the UI consumes. Tests override this with a
/// hand-built `AuthService` whose collaborators are fakes.
final Provider<AuthService> authServiceProvider = Provider<AuthService>((
  Ref<AuthService> ref,
) {
  return AuthService(
    auth: ref.watch(authGatewayProvider),
    functions: ref.watch(functionsGatewayProvider),
    tokens: ref.watch(fcmTokenStoreProvider),
    stores: ref.watch(persistedStoresProvider),
    deregisterFcm: ref.watch(fcmDeregisterProvider),
    // resetTelemetry wired in Phase 14.
  );
});

/// Apple + Google OAuth entry-point service.
final Provider<SocialAuthService> socialAuthServiceProvider =
    Provider<SocialAuthService>((Ref<SocialAuthService> ref) {
      return SocialAuthService(ref.watch(authGatewayProvider));
    });

/// Production [ProfileRepository] wired against the real Supabase client.
/// Tests override this with a hand-built repo whose query runner is a fake.
final Provider<ProfileRepository> profileRepositoryProvider =
    Provider<ProfileRepository>((Ref<ProfileRepository> ref) {
      final SupabaseClient client = ref.watch(supabaseClientProvider);
      return ProfileRepository(SupabaseProfileQueryRunner(client));
    });
