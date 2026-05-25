import '../../../core/env.dart';

/// Builds the OAuth / magic-link redirect URI the app passes to Supabase.
///
/// Defaults to `${Env.appScheme}://auth` so the platform deep-link handler
/// routes the callback to `AuthCallbackScreen`. Tests can override [scheme]
/// to assert the formatting without depending on `Env`.
String authRedirectUri({String? scheme}) {
  final s = scheme ?? Env.appScheme;
  return '$s://auth';
}
