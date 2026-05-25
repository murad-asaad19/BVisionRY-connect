/// Typed exception hierarchy the app uses to translate backend errors into
/// user-facing copy. Every subclass carries an [i18nKey] so UI code can show
/// a localized message without inspecting the underlying error.
sealed class AppException implements Exception {
  AppException(this.i18nKey, {this.cause});

  /// Translation key used by the UI to render this error.
  final String i18nKey;

  /// Original error (a `PostgrestException`, `AuthException`, network error,
  /// etc.). Kept for logging and Sentry breadcrumbs.
  final Object? cause;

  @override
  String toString() => '$runtimeType($i18nKey)';
}

/// Fallback when no specific mapping fits. UI shows the generic
/// "Something went wrong" copy.
class GenericAppException extends AppException {
  GenericAppException([Object? cause])
      : super('auth.errors.generic', cause: cause);
}

/// Signed-out / invalid session (Postgrest code `28000`).
class UnauthenticatedException extends AppException {
  UnauthenticatedException() : super('auth.errors.signInFailed');
}

/// `intros.send` triggered the 30-day cooldown after a decline
/// (Postgrest `P0001` + hint `cooldown`).
class IntroCooldownException extends AppException {
  IntroCooldownException() : super('intros.compose.errorCooldown');
}

/// `intros.send` hit the per-user daily cap (Postgrest `P0001` + hint
/// `daily_cap`).
class DailyCapException extends AppException {
  DailyCapException() : super('intros.compose.errorRateLimit');
}

/// Unique-constraint violation (Postgrest `23505`) — usually a duplicate
/// intro/contact request.
class DuplicateException extends AppException {
  DuplicateException() : super('intros.compose.errorDuplicate');
}

/// The acting user has not finished onboarding (Postgrest `P0002`).
class NotOnboardedException extends AppException {
  NotOnboardedException() : super('intros.compose.errorExpired');
}

/// Server-side validation failure (Postgrest `22023` or auth invalid input).
/// Carries a domain-specific [i18nKey] supplied by the caller.
class ValidationException extends AppException {
  ValidationException(super.i18nKey);
}

/// RLS policy denied access (Postgrest `42501`).
class ForbiddenException extends AppException {
  ForbiddenException() : super('auth.errors.signInFailed');
}

/// `accept_intro` was called against a `warm_request` row, which the
/// server refuses with Postgrest `22023` + message `"wrong intro kind"`.
/// The UI should route to the forward sheet instead.
class WrongIntroKindException extends AppException {
  WrongIntroKindException() : super('intros.detail.acceptFailed');
}

/// The intro note failed the server-side 80-400 char range check
/// (Postgrest `22023` with `char_length(btrim(note))` in the message).
class IntroNoteRangeException extends AppException {
  IntroNoteRangeException() : super('intros.compose.errorRange');
}
