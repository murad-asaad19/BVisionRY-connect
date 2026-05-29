import 'package:supabase_flutter/supabase_flutter.dart';

import '../../push/data/fcm_token_store.dart';
import '../../settings/data/persisted_stores.dart';
import 'auth_redirect.dart';

/// Test-seam abstraction over the slice of `GoTrueClient` our auth feature
/// touches. Concrete implementation in `providers/auth_service_provider.dart`
/// delegates to `Supabase.instance.client.auth`; tests inject `FakeAuthGateway`.
abstract class AuthGateway {
  /// Latest restored session, or null when signed out. Synchronous.
  Session? get currentSession;

  /// Broadcasts every auth-state transition (`signedIn`, `signedOut`,
  /// `tokenRefreshed`, `initialSession`, etc.).
  Stream<AuthState> onAuthStateChange();

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signInWithOtp({
    required String email,
    required String emailRedirectTo,
  });

  Future<bool> signInWithOAuth(
    OAuthProvider provider, {
    required String redirectTo,
  });

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String emailRedirectTo,
  });

  Future<AuthResponse> setSession({
    required String accessToken,
    required String refreshToken,
  });

  Future<AuthSessionUrlResponse> exchangeCodeForSession(String code);

  Future<void> signOut({SignOutScope scope = SignOutScope.local});

  Future<void> startAutoRefresh();

  Future<void> stopAutoRefresh();

  /// `supabase.rpc(name, params)` — used to call SECURITY DEFINER functions
  /// against the caller's own JWT (e.g. `record_signup_consent`). Returns
  /// whatever Postgrest echoes back.
  Future<Object?> rpc(String name, {Map<String, dynamic>? params});
}

/// Test-seam abstraction over the slice of `FunctionsClient` our auth code
/// uses. Wraps a single `invoke(name, body)` call.
abstract class FunctionsGateway {
  Future<FunctionResponse> invoke(String name, {Object? body});
}

/// Coordinates Supabase auth flows for the feature: magic-link OTP, password
/// sign-in/up, handle-based sign-in (via the `auth-handle-login` edge fn),
/// PKCE + implicit deep-link callback resolution, and local-scope sign-out
/// with FCM deregistration + persisted-store reset.
///
/// Errors are surfaced as-is — callers map them via `mapAuthError(...)`.
class AuthService {
  AuthService({
    required AuthGateway auth,
    required FunctionsGateway functions,
    required FcmTokenStore tokens,
    required PersistedStores stores,
    Future<void> Function(String token)? deregisterFcm,
    Future<void> Function()? resetTelemetry,
    void Function()? invalidateAuthedProviders,
  })  : _auth = auth,
        _functions = functions,
        _tokens = tokens,
        _stores = stores,
        _deregisterFcm = deregisterFcm,
        _resetTelemetry = resetTelemetry,
        _invalidateAuthedProviders = invalidateAuthedProviders;

  final AuthGateway _auth;
  final FunctionsGateway _functions;
  final FcmTokenStore _tokens;
  final PersistedStores _stores;
  final Future<void> Function(String token)? _deregisterFcm;
  final Future<void> Function()? _resetTelemetry;
  final void Function()? _invalidateAuthedProviders;

  String _normaliseEmail(String email) => email.trim().toLowerCase();

  String _normaliseHandle(String h) =>
      h.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();

  /// Sends a passwordless magic-link OTP to [email]. The redirect URL is the
  /// app-scheme `connect-mobile://auth` (see [authRedirectUri]).
  Future<void> sendMagicLink(String email) async {
    await _auth.signInWithOtp(
      email: _normaliseEmail(email),
      emailRedirectTo: authRedirectUri(),
    );
  }

  /// Creates an email-password account. Throws [ArgumentError] when
  /// [password] is shorter than 8 characters (the message carries the
  /// `auth.errors.passwordTooShort` i18n key for the UI layer).
  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    if (password.length < 8) {
      throw ArgumentError.value(
        password,
        'password',
        'auth.errors.passwordTooShort',
      );
    }
    return _auth.signUp(
      email: _normaliseEmail(email),
      password: password,
      emailRedirectTo: authRedirectUri(),
    );
  }

  /// Records the age-gate + legal consent captured at sign-up against the
  /// caller's own `profiles` row via the `record_signup_consent` RPC.
  ///
  /// The server is the source of truth: it re-validates that the caller is old
  /// enough (age threshold lives in the migration) and that both legal
  /// documents were accepted, raising otherwise. Pass [dateOfBirth] as a plain
  /// `date` and the two accept flags (the UI only ever calls this with both
  /// true, but the RPC re-checks). Throws on failure so callers can surface it.
  Future<void> recordSignupConsent({
    required DateTime dateOfBirth,
    required bool acceptTos,
    required bool acceptPrivacy,
  }) async {
    await _auth.rpc(
      'record_signup_consent',
      params: <String, dynamic>{
        'p_date_of_birth': _formatDate(dateOfBirth),
        'p_accept_tos': acceptTos,
        'p_accept_privacy': acceptPrivacy,
      },
    );
  }

  /// `YYYY-MM-DD` (Postgres `date` literal) from the date portion of [d].
  String _formatDate(DateTime d) {
    final String mm = d.month.toString().padLeft(2, '0');
    final String dd = d.day.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-$mm-$dd';
  }

  /// Signs in with a normalised email + password.
  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(
      email: _normaliseEmail(email),
      password: password,
    );
  }

  /// Sign in by either email (when [identifier] contains `@`) or by handle
  /// via the `auth-handle-login` edge function. The edge function returns
  /// `access_token` + `refresh_token`; we install them via [setSession].
  ///
  /// Non-2xx edge responses or malformed bodies surface as [AuthException]
  /// so callers can route them through `mapAuthError`.
  Future<AuthResponse> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    final trimmed = identifier.trim();
    if (trimmed.contains('@') && !trimmed.startsWith('@')) {
      return signInWithEmailPassword(email: trimmed, password: password);
    }
    final handle = _normaliseHandle(trimmed);
    final res = await _functions.invoke(
      'auth-handle-login',
      body: <String, String>{'handle': handle, 'password': password},
    );
    if (res.status >= 400) {
      throw AuthException(
        'Invalid login credentials',
        statusCode: res.status.toString(),
      );
    }
    final data = res.data;
    if (data is! Map ||
        data['access_token'] is! String ||
        data['refresh_token'] is! String) {
      throw const AuthException('Invalid login credentials');
    }
    return _auth.setSession(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
  }

  /// Resolve an incoming auth-callback URL into a [Session]:
  /// * PKCE — `?code=...` → [AuthGateway.exchangeCodeForSession]
  /// * Implicit — `#access_token=...&refresh_token=...` → [AuthGateway.setSession]
  /// * Bare `connect-mobile://auth` — returns `null` with no side effect.
  Future<Session?> createSessionFromUrl(Uri uri) async {
    final code = uri.queryParameters['code'];
    if (code != null && code.isNotEmpty) {
      final res = await _auth.exchangeCodeForSession(code);
      return res.session;
    }
    final fragment = uri.fragment;
    if (fragment.isNotEmpty) {
      final params = Uri.splitQueryString(fragment);
      final at = params['access_token'];
      final rt = params['refresh_token'];
      if (at != null && rt != null && at.isNotEmpty && rt.isNotEmpty) {
        final res = await _auth.setSession(accessToken: at, refreshToken: rt);
        return res.session;
      }
    }
    return null;
  }

  /// Signs out with the canonical order required by spec §5.1 + §10.3:
  ///
  /// 1. Read the last persisted FCM token and invoke the deregister callback
  ///    (best-effort — failures are swallowed so sign-out always proceeds).
  /// 2. Clear the FCM token store.
  /// 3. Local-scope [signOut] (revokes the refresh token on-device only).
  /// 4. Reset all persisted Zustand-equivalent stores.
  /// 5. Force telemetry consent to opt-out (Phase 14 wires the real
  ///    notifier — placeholder here resets the shared-pref key).
  Future<void> signOut() async {
    final last = await _tokens.read();
    if (last != null && _deregisterFcm != null) {
      try {
        await _deregisterFcm(last);
      } catch (_) {
        // best-effort; never block sign-out on FCM transport errors.
      }
    }
    await _tokens.clear();

    await _auth.signOut(scope: SignOutScope.local);

    await _stores.resetAllOnSignOut();

    if (_resetTelemetry != null) {
      try {
        await _resetTelemetry();
      } catch (_) {
        // best-effort.
      }
    }

    // Drop every Riverpod cache that was keyed to the now-defunct UID. If we
    // skip this, the next sign-in renders the previous session's
    // conversation list, blocked count, intros, and so on until each
    // provider happens to refresh. The wiring lives in authServiceProvider.
    _invalidateAuthedProviders?.call();
  }
}
