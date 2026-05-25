// test/helpers/fake_supabase.dart
//
// Reusable test doubles for the Supabase surface our auth code touches.
// The real `SupabaseClient` constructor is sealed, so instead we abstract the
// gateways our service layer needs (`AuthGateway`, `FunctionsGateway`) and
// provide in-memory `Fake*` implementations here that the tests can drive
// via `on*` callbacks and `pushAuthState`.
import 'dart:async';

import 'package:connect_mobile/features/auth/data/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// In-memory implementation of [AuthGateway]. Tests provide behaviour via
/// the `on*` callback fields; calls without a matching callback throw
/// [StateError] so missing setup surfaces loudly.
class FakeAuthGateway implements AuthGateway {
  Session? _session;
  final StreamController<AuthState> _ctrl =
      StreamController<AuthState>.broadcast();

  // Hooks the test can override.
  Future<AuthResponse> Function({
    required String email,
    required String password,
  })? onSignIn;
  Future<void> Function({
    required String email,
    required String emailRedirectTo,
  })? onOtp;
  Future<bool> Function(
    OAuthProvider provider, {
    required String redirectTo,
  })? onOAuth;
  Future<AuthResponse> Function({
    required String email,
    required String password,
    required String emailRedirectTo,
  })? onSignUp;
  Future<AuthResponse> Function({
    required String accessToken,
    required String refreshToken,
  })? onSetSession;
  Future<AuthSessionUrlResponse> Function(String code)? onExchange;
  Future<void> Function({SignOutScope scope})? onSignOut;

  int autoRefreshStarted = 0;
  int autoRefreshStopped = 0;

  /// Push a synthetic auth-state change onto the stream. Updates
  /// [currentSession] synchronously so callers can read it without awaiting.
  void pushAuthState(AuthChangeEvent event, Session? session) {
    _session = session;
    _ctrl.add(AuthState(event, session));
  }

  @override
  Session? get currentSession => _session;

  @override
  Stream<AuthState> onAuthStateChange() => _ctrl.stream;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    final h = onSignIn;
    if (h == null) throw StateError('onSignIn not set');
    return h(email: email, password: password);
  }

  @override
  Future<void> signInWithOtp({
    required String email,
    required String emailRedirectTo,
  }) {
    final h = onOtp;
    if (h == null) throw StateError('onOtp not set');
    return h(email: email, emailRedirectTo: emailRedirectTo);
  }

  @override
  Future<bool> signInWithOAuth(
    OAuthProvider provider, {
    required String redirectTo,
  }) {
    final h = onOAuth;
    if (h == null) throw StateError('onOAuth not set');
    return h(provider, redirectTo: redirectTo);
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String emailRedirectTo,
  }) {
    final h = onSignUp;
    if (h == null) throw StateError('onSignUp not set');
    return h(
      email: email,
      password: password,
      emailRedirectTo: emailRedirectTo,
    );
  }

  @override
  Future<AuthResponse> setSession({
    required String accessToken,
    required String refreshToken,
  }) {
    final h = onSetSession;
    if (h == null) throw StateError('onSetSession not set');
    return h(accessToken: accessToken, refreshToken: refreshToken);
  }

  @override
  Future<AuthSessionUrlResponse> exchangeCodeForSession(String code) {
    final h = onExchange;
    if (h == null) throw StateError('onExchange not set');
    return h(code);
  }

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    final h = onSignOut;
    if (h != null) await h(scope: scope);
    pushAuthState(AuthChangeEvent.signedOut, null);
  }

  @override
  Future<void> startAutoRefresh() async {
    autoRefreshStarted++;
  }

  @override
  Future<void> stopAutoRefresh() async {
    autoRefreshStopped++;
  }

  Future<void> close() => _ctrl.close();
}

/// In-memory implementation of [FunctionsGateway].
class FakeFunctionsGateway implements FunctionsGateway {
  Future<FunctionResponse> Function(String name, {Object? body})? onInvoke;

  @override
  Future<FunctionResponse> invoke(String name, {Object? body}) {
    final h = onInvoke;
    if (h == null) throw StateError('onInvoke not set for $name');
    return h(name, body: body);
  }
}

/// Construct a [Session] with the supplied identifiers — convenient stand-in
/// for the Supabase response payload our tests assert against.
Session fakeSession({
  String id = 'user-1',
  String accessToken = 'access-1',
  String refreshToken = 'refresh-1',
  String email = 'user@example.com',
}) {
  return Session(
    accessToken: accessToken,
    refreshToken: refreshToken,
    tokenType: 'bearer',
    expiresIn: 3600,
    user: User(
      id: id,
      appMetadata: const <String, dynamic>{},
      userMetadata: const <String, dynamic>{},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    ),
  );
}
