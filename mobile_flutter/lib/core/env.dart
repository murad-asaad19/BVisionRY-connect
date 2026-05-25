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

  static void requireProdInvariants() {
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
}
