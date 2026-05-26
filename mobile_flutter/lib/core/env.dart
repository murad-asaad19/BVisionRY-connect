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
  static const easProjectId = String.fromEnvironment(
    'EAS_PROJECT_ID',
    defaultValue: 'PROJECT_ID_PLACEHOLDER',
  );

  /// Anthropic API key for the onboarding bio drafter (claude-haiku-4-5).
  /// Optional — when empty the bio draft step falls back to a local
  /// deterministic template. Inject via `--dart-define=ANTHROPIC_API_KEY=...`.
  static const anthropicApiKey =
      String.fromEnvironment('ANTHROPIC_API_KEY');

  static void requireProdInvariants() {
    validateProdConfig(
      sentryEnv: sentryEnv,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      appLinksHost: appLinksHost,
      easProjectId: easProjectId,
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
  required String easProjectId,
}) {
  if (sentryEnv != 'prod') return;
  if (appLinksHost == 'DOMAIN_PLACEHOLDER') {
    throw StateError('APP_LINKS_HOST must be set in production builds');
  }
  if (easProjectId == 'PROJECT_ID_PLACEHOLDER') {
    throw StateError('EAS_PROJECT_ID must be set in production builds');
  }
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError('SUPABASE_URL and SUPABASE_ANON_KEY must be set');
  }
}
