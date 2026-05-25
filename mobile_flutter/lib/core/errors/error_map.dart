import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

/// Converts a Postgrest error into a typed [AppException].
///
/// The (code, hint) pairs come straight from the SQL functions that raise
/// `P0001` errors in the schema migrations — keep this switch in sync with
/// the `RAISE EXCEPTION ... USING HINT = '...'` calls in `supabase/`.
AppException mapPostgrestError(Object error) {
  if (error is! PostgrestException) return GenericAppException(error);
  final String code = error.code ?? '';
  final String hint = error.hint ?? '';
  return switch ((code, hint)) {
    ('28000', _) => UnauthenticatedException(),
    ('P0001', 'cooldown') => IntroCooldownException(),
    ('P0001', 'daily_cap') => DailyCapException(),
    ('23505', _) => DuplicateException(),
    ('P0002', _) => NotOnboardedException(),
    ('22023', _) => ValidationException('intros.compose.errorRange'),
    ('42501', _) => ForbiddenException(),
    _ => GenericAppException(error),
  };
}

/// Converts a GoTrue auth error into a typed [AppException].
///
/// Messages are matched case-insensitively against the substrings GoTrue
/// returns in production (the explicit `code` field on `AuthException` was
/// added in later versions but is still null for some flows).
AppException mapAuthError(Object error) {
  if (error is AuthException) {
    final String m = error.message.toLowerCase();
    if (m.contains('invalid login')) {
      return ValidationException('auth.errors.invalidCredentials');
    }
    if (m.contains('email not confirmed')) {
      return ValidationException('auth.errors.emailNotConfirmed');
    }
    if (m.contains('rate limit')) {
      return ValidationException('auth.errors.rateLimited');
    }
    return GenericAppException(error);
  }
  return GenericAppException(error);
}
