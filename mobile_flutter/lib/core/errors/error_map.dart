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
    // Phase 9 — office hours `book_slot` / `cancel_booking` hints.
    ('P0001', 'slot_unavailable') => SlotUnavailableException(),
    ('P0001', 'slot_too_soon') => SlotTooSoonException(),
    ('P0001', 'host_self') => HostSelfException(),
    ('P0001', 'oh_disabled') => OhDisabledException(),
    ('P0001', 'weekly_cap') => WeeklyCapException(),
    ('P0001', 'blocked') => BlockedException(),
    ('P0001', 'bad_meeting_url') => BadMeetingUrlException(),
    ('P0001', 'topic_invalid') =>
      ValidationException('officeHours.book.errorTopicInvalid'),
    ('P0001', 'not_booked') =>
      ValidationException('officeHours.bookings.errorNotBooked'),
    ('P0001', 'not_authorised') => ForbiddenException(),
    ('23505', _) => DuplicateException(),
    ('P0002', _) => NotOnboardedException(),
    ('22023', _) => _map22023(error),
    ('42501', _) => ForbiddenException(),
    _ => GenericAppException(error),
  };
}

/// Disambiguates `22023` by sniffing the message string.
///
/// `accept_intro` raises `22023 wrong intro kind` when given a `warm_request`
/// row; `send_intro` / `send_warm_request` / `forward_warm_intro` raise
/// `22023` with a `char_length(btrim(note))` predicate in the message when
/// the note falls outside `[80, 400]`. `propose_meeting` raises `22023`
/// with a `duration` / `slots` / `https` substring when the corresponding
/// CHECK constraint fails. We sniff the message for each known token and
/// fall through to the intro note-range default.
AppException _map22023(PostgrestException error) {
  final msg = error.message.toLowerCase();
  if (msg.contains('wrong intro kind')) return WrongIntroKindException();
  if (msg.contains('duration')) {
    return ValidationException('meetings.propose.errors.duration');
  }
  if (msg.contains('slot')) {
    return ValidationException('meetings.propose.errors.slotsRange');
  }
  if (msg.contains('https')) {
    return ValidationException('meetings.propose.errors.url');
  }
  return IntroNoteRangeException();
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
