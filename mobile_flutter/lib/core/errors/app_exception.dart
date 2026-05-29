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

/// A requested row is missing / no longer visible (deep-link to a deleted,
/// expired, closed, or RLS-hidden record). Carries an optional domain key so
/// callers can show a tailored "no longer available" message; defaults to the
/// generic not-found copy.
class NotFoundException extends AppException {
  NotFoundException([super.i18nKey = 'errors.notFound']);
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

// ---------------------------------------------------------------------------
// Office Hours (Phase 9) — typed P0001 hint mappings for `book_slot` and
// `cancel_booking`. The server raises one of these via `RAISE EXCEPTION ...
// USING HINT = '<name>'`; the mapping in error_map.dart funnels each hint
// into one of these exception types so the UI can show a localized toast.
// ---------------------------------------------------------------------------

/// `book_slot` raised `slot_unavailable` — the slot is no longer `open`
/// (already booked / cancelled while the user lingered).
class SlotUnavailableException extends AppException {
  SlotUnavailableException() : super('officeHours.book.errorSlotUnavailable');
}

/// `book_slot` raised `slot_too_soon` — slot starts within the 15-minute
/// lead-time window.
class SlotTooSoonException extends AppException {
  SlotTooSoonException() : super('officeHours.book.errorTooSoon');
}

/// `book_slot` raised `host_self` — caller is the host of this slot.
class HostSelfException extends AppException {
  HostSelfException() : super('officeHours.book.errorHostSelf');
}

/// `book_slot` raised `oh_disabled` — the host turned office hours off.
class OhDisabledException extends AppException {
  OhDisabledException() : super('officeHours.book.errorOhDisabled');
}

/// `book_slot` raised `weekly_cap` — caller has already booked
/// `max_bookings_per_week` slots with this host in the current Monday-UTC
/// week bucket.
class WeeklyCapException extends AppException {
  WeeklyCapException() : super('officeHours.book.errorWeeklyCap');
}

/// `book_slot` raised `blocked` — host has blocked caller or vice-versa.
class BlockedException extends AppException {
  BlockedException() : super('officeHours.book.errorBlocked');
}

/// `book_slot` raised `bad_meeting_url` — host's `meeting_link_template`
/// resolved to a non-`https://` URL after `{slot_id}` substitution.
class BadMeetingUrlException extends AppException {
  BadMeetingUrlException() : super('officeHours.book.errorBadMeetingUrl');
}

// ---------------------------------------------------------------------------
// Settings (Phase 13) — flagged when a planned server-side RPC has not yet
// shipped. The UI surfaces a `ComingSoonCard` next to the toggle instead of
// failing silently or pretending the write succeeded.
// ---------------------------------------------------------------------------

/// A required server RPC has not yet been implemented (spec §17.2).
/// Carries the RPC name on the exception so the surfaced UI banner can
/// indicate which toggle is still server-blocked.
class UnimplementedRpcException extends AppException {
  UnimplementedRpcException(this.rpcName)
      : super('settings.publicInvestorPage.comingSoon');
  final String rpcName;
  @override
  String toString() => 'UnimplementedRpcException(rpc=$rpcName)';
}

// ---------------------------------------------------------------------------
// Verification (manual-review proofs) — `submit_verification` raises one of
// these via `RAISE EXCEPTION ... USING HINT = '<name>'` when a live submission
// already exists for the requested kind.
// ---------------------------------------------------------------------------

/// `submit_verification` raised `already_pending` — a submission for this kind
/// is already awaiting team review.
class VerificationAlreadyPendingException extends AppException {
  VerificationAlreadyPendingException()
      : super('verification.errors.alreadyPending');
}

/// `submit_verification` raised `already_approved` — the caller is already
/// verified for this kind.
class VerificationAlreadyApprovedException extends AppException {
  VerificationAlreadyApprovedException()
      : super('verification.errors.alreadyApproved');
}
