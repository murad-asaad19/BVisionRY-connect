import 'package:flutter/foundation.dart';

abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const sentryEnv = String.fromEnvironment(
    'SENTRY_ENV',
    defaultValue: 'dev',
  );
  static const firebaseEnabled = bool.fromEnvironment('FIREBASE_ENABLED');
  static const appLinksHost = String.fromEnvironment(
    'APP_LINKS_HOST',
    defaultValue: 'DOMAIN_PLACEHOLDER',
  );
  static const appScheme = String.fromEnvironment(
    'APP_SCHEME',
    defaultValue: 'connect-mobile',
  );

  /// Invite-gated launch flag. When TRUE, sign-up requires a valid invite
  /// code (the submit button blocks without one) and the waitlist link is
  /// surfaced prominently; when FALSE (the default), the invite code is
  /// optional and the waitlist is just an available link. Defaulting to
  /// false keeps dev / CI / testing flows unblocked. Inject via
  /// `--dart-define=INVITE_ONLY=true` for a gated build.
  static const inviteOnly = bool.fromEnvironment('INVITE_ONLY');

  static void requireProdInvariants() {
    validateProdConfig(
      sentryEnv: sentryEnv,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      appLinksHost: appLinksHost,
    );
  }
}

/// Pure validator. Throws [StateError] when [sentryEnv] is `'prod'` and any
/// required placeholder remains. Exposed for unit testing — production code
/// should call [Env.requireProdInvariants].
@visibleForTesting
void validateProdConfig({
  required String sentryEnv,
  required String supabaseUrl,
  required String supabaseAnonKey,
  required String appLinksHost,
}) {
  if (sentryEnv != 'prod') return;
  if (appLinksHost == 'DOMAIN_PLACEHOLDER') {
    throw StateError('APP_LINKS_HOST must be set in production builds');
  }
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError('SUPABASE_URL and SUPABASE_ANON_KEY must be set');
  }
}
